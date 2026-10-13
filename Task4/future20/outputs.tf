output "network_id" {
  value = yandex_vpc_network.this.id
}

output "subnet_ids" {
  value = local.subnet_ids
}

output "vm_internal_ips" {
  value = {
    for k, v in yandex_compute_instance.vm :
    k => v.network_interface[0].ip_address
  }
}

output "bastion_public_ip" {
  value = yandex_compute_instance.vm["bastion"].network_interface[0].nat_ip_address
}

output "lakehouse_bucket" {
  value = yandex_storage_bucket.lakehouse.bucket
}