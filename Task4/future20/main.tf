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
  zone      = var.zone
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

resource "yandex_vpc_subnet" "public" {
  name           = "${var.network_name}-public"
  zone           = var.zone
  network_id     = yandex_vpc_network.this.id
  v4_cidr_blocks = [var.public_subnet_cidr]
}

resource "yandex_vpc_subnet" "private" {
  name           = "${var.network_name}-private"
  zone           = var.zone
  network_id     = yandex_vpc_network.this.id
  v4_cidr_blocks = [var.private_subnet_cidr]
  route_table_id = yandex_vpc_route_table.private.id
}

resource "yandex_vpc_subnet" "data" {
  name           = "${var.network_name}-data"
  zone           = var.zone
  network_id     = yandex_vpc_network.this.id
  v4_cidr_blocks = [var.data_subnet_cidr]
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
    protocol       = "ANY"
    description    = "internal"
    v4_cidr_blocks = [
      var.public_subnet_cidr,
      var.private_subnet_cidr,
      var.data_subnet_cidr
    ]
  }

  egress {
    protocol       = "ANY"
    description    = "any"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

locals {
  subnet_ids = {
    public  = yandex_vpc_subnet.public.id
    private = yandex_vpc_subnet.private.id
    data    = yandex_vpc_subnet.data.id
  }

  sg_ids = {
    public  = yandex_vpc_security_group.bastion.id
    private = yandex_vpc_security_group.app.id
    data    = yandex_vpc_security_group.app.id
  }
}

resource "yandex_compute_instance" "vm" {
  for_each    = var.vms
  name        = "future20-${each.key}"
  platform_id = var.vm_platform_id
  zone        = var.zone

  resources {
    cores         = each.value.cores
    memory        = each.value.memory
    core_fraction = each.value.core_fraction
  }

  boot_disk {
    initialize_params {
      image_family = var.vm_image_family
      size         = each.value.disk_size
      type         = var.disk_type
    }
  }

  network_interface {
    subnet_id          = local.subnet_ids[each.value.subnet]
    nat                = each.value.public_ip
    security_group_ids = [local.sg_ids[each.value.subnet]]
  }

  metadata = {
    ssh-keys = "${var.vm_user}:${var.ssh_public_key}"
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