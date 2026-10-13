terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 1.3"
}

provider "yandex" {
  cloud_id  = var.cloud_id
  folder_id = var.folder_id
  zone      = "ru-central1-d"
}

data "yandex_compute_image" "vm_image" {
  family = var.vm_image_family
}

resource "yandex_vpc_network" "this" {
  name = var.network_name
}

resource "yandex_vpc_gateway" "nat" {
  name = "${var.network_name}-nat"
  shared_egress_gateway {}
}

resource "yandex_vpc_route_table" "private" {
  name       = "${var.network_name}-private-rt"
  network_id = yandex_vpc_network.this.id

  static_route {
    destination_prefix = "0.0.0.0/0"
    gateway_id         = yandex_vpc_gateway.nat.id
  }
}

# Публичная подсеть — в зоне bastion
resource "yandex_vpc_subnet" "public" {
  name           = "${var.network_name}-public"
  zone           = "ru-central1-d"
  network_id     = yandex_vpc_network.this.id
  folder_id      = var.folder_id
  v4_cidr_blocks = [var.public_subnet_cidr]
}

# Приватные подсети — по одной в каждой зоне
resource "yandex_vpc_subnet" "private" {
  for_each       = var.private_subnets
  name           = "${var.network_name}-private-${each.key}"
  zone           = each.value.zone
  network_id     = yandex_vpc_network.this.id
  folder_id      = var.folder_id
  v4_cidr_blocks = [each.value.cidr]
  route_table_id = yandex_vpc_route_table.private.id
}

resource "yandex_vpc_security_group" "bastion" {
  name       = "${var.network_name}-bastion-sg"
  network_id = yandex_vpc_network.this.id

  ingress {
    protocol       = "TCP"
    description    = "SSH"
    port           = 22
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol       = "ANY"
    description    = "any"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "yandex_vpc_security_group" "app" {
  name       = "${var.network_name}-app-sg"
  network_id = yandex_vpc_network.this.id

  ingress {
    protocol          = "TCP"
    description       = "SSH from bastion"
    port              = 22
    security_group_id = yandex_vpc_security_group.bastion.id
  }

  ingress {
    protocol    = "ANY"
    description = "internal"
    v4_cidr_blocks = concat(
      [var.public_subnet_cidr],
      [for s in var.private_subnets : s.cidr]
    )
  }

  egress {
    protocol       = "ANY"
    description    = "any"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

locals {
  private_subnet_by_zone = {
    for zone, s in yandex_vpc_subnet.private : zone => s.id
  }
}

resource "yandex_compute_instance" "vm" {
  for_each    = var.vms
  name        = "future20-${each.key}"
  platform_id = var.vm_platform_id
  zone        = each.value.zone
  folder_id   = var.folder_id

  resources {
    cores         = each.value.cores
    memory        = each.value.memory
    core_fraction = each.value.core_fraction
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.vm_image.id
      size     = each.value.disk_size
      type     = each.value.disk_type
    }
  }

  network_interface {
    subnet_id = (
      each.value.public_ip
      ? yandex_vpc_subnet.public.id
      : local.private_subnet_by_zone[each.value.zone]
    )

    nat = each.value.public_ip

    security_group_ids = [
      each.value.public_ip
      ? yandex_vpc_security_group.bastion.id
      : yandex_vpc_security_group.app.id
    ]
  }

  metadata = {
    ssh-keys = "${var.vm_user}:${var.ssh_public_key}"
  }

  lifecycle {
    ignore_changes = [boot_disk[0].initialize_params[0].image_id]
  }
}

resource "yandex_iam_service_account" "sa" {
  name      = "future20-sa"
  folder_id = var.folder_id
}

resource "yandex_resourcemanager_folder_iam_member" "sa_storage" {
  folder_id = var.folder_id
  role      = "storage.editor"
  member    = "serviceAccount:${yandex_iam_service_account.sa.id}"
}

resource "yandex_iam_service_account_static_access_key" "sa_key" {
  service_account_id = yandex_iam_service_account.sa.id
}

resource "yandex_storage_bucket" "lakehouse" {
  bucket     = var.bucket_name
  folder_id  = var.folder_id
  access_key = yandex_iam_service_account_static_access_key.sa_key.access_key
  secret_key = yandex_iam_service_account_static_access_key.sa_key.secret_key
}