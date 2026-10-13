output "network_id" {
  value = yandex_vpc_network.this.id
}

output "public_subnet_id" {
  value = yandex_vpc_subnet.public.id
}

output "private_subnet_ids" {
  value = {
    for zone, s in yandex_vpc_subnet.private : zone => s.id
  }
}

output "vm_internal_ips" {
  value = {
    for k, v in yandex_compute_instance.vm :
    k => v.network_interface[0].ip_address
  }
}

output "vm_zones" {
  value = {
    for k, v in yandex_compute_instance.vm :
    k => v.zone
  }
}

output "bastion_public_ip" {
  value = yandex_compute_instance.vm["bastion"].network_interface[0].nat_ip_address
}

output "lakehouse_bucket" {
  value = yandex_storage_bucket.lakehouse.bucket
}