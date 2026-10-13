variable "cloud_id" {
  type        = string
  description = "Yandex Cloud ID"
}

variable "folder_id" {
  type        = string
  description = "Yandex Cloud folder ID"
}

variable "zone" {
  type        = string
  default     = "ru-central1-a"
  description = "Зона доступности"
}

variable "network_name" {
  type        = string
  default     = "future20-vpc"
  description = "Имя VPC"
}

variable "public_subnet_cidr" {
  type        = string
  default     = "10.10.1.0/24"
}

variable "private_subnet_cidr" {
  type        = string
  default     = "10.10.2.0/24"
}

variable "data_subnet_cidr" {
  type        = string
  default     = "10.10.3.0/24"
}

variable "ssh_public_key" {
  type        = string
  description = "Публичный SSH-ключ для пользователя ubuntu"
}

variable "vm_user" {
  type        = string
  default     = "ubuntu"
}

variable "vm_platform_id" {
  type        = string
  default     = "standard-v3"
}

variable "vm_image_family" {
  type        = string
  default     = "ubuntu-2204-lts"
}

variable "disk_type" {
  type        = string
  default     = "network-ssd"
}

variable "bucket_name" {
  type        = string
  description = "Глобально уникальное имя bucket для Lakehouse"
}

variable "vms" {
  type = map(object({
    subnet        = string
    cores         = number
    memory        = number
    disk_size     = number
    public_ip     = bool
    core_fraction = number
  }))

  default = {
    bastion = {
      subnet        = "public"
      cores         = 2
      memory        = 2
      disk_size     = 20
      public_ip     = true
      core_fraction = 20
    }
    kafka = {
      subnet        = "private"
      cores         = 4
      memory        = 8
      disk_size     = 50
      public_ip     = false
      core_fraction = 100
    }
    data-platform = {
      subnet        = "private"
      cores         = 4
      memory        = 8
      disk_size     = 100
      public_ip     = false
      core_fraction = 100
    }
    fintech = {
      subnet        = "private"
      cores         = 4
      memory        = 8
      disk_size     = 50
      public_ip     = false
      core_fraction = 100
    }
    ai = {
      subnet        = "private"
      cores         = 4
      memory        = 16
      disk_size     = 100
      public_ip     = false
      core_fraction = 100
    }
    clinical = {
      subnet        = "private"
      cores         = 2
      memory        = 4
      disk_size     = 50
      public_ip     = false
      core_fraction = 100
    }
  }
}