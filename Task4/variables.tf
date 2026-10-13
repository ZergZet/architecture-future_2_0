variable "cloud_id" {
  type        = string
  description = "Yandex Cloud ID"
}

variable "folder_id" {
  type        = string
  description = "Yandex Cloud folder ID"
}

variable "network_name" {
  type        = string
  default     = "future20-vpc"
  description = "Имя VPC"
}

variable "public_subnet_cidr" {
  type        = string
  default     = "10.10.1.0/24"
  description = "CIDR публичной подсети"
}

variable "ssh_public_key" {
  type        = string
  description = "Публичный SSH-ключ для пользователя ubuntu"
}

variable "vm_user" {
  type        = string
  default     = "ubuntu"
  description = "Имя пользователя для SSH"
}

variable "vm_platform_id" {
  type        = string
  default     = "standard-v3"
  description = "Платформа для ВМ"
}

variable "vm_image_family" {
  type        = string
  default     = "ubuntu-2204-lts"
  description = "Семейство образов ОС"
}

variable "bucket_name" {
  type        = string
  description = "Глобально уникальное имя bucket для Lakehouse"
}

# Приватные подсети — только в доступных зонах
variable "private_subnets" {
  type = map(object({
    zone = string
    cidr = string
  }))
  default = {
    "ru-central1-d" = { zone = "ru-central1-d", cidr = "10.10.2.0/24" }
    "ru-central1-e" = { zone = "ru-central1-e", cidr = "10.10.12.0/24" }
  }
}

# Распределение ВМ по доступным зонам
variable "vms" {
  type = map(object({
    zone          = string
    cores         = number
    memory        = number
    disk_size     = number
    disk_type     = string
    public_ip     = bool
    core_fraction = number
  }))

  default = {
    bastion = {
      zone          = "ru-central1-d"
      cores         = 2
      memory        = 2
      disk_size     = 10
      disk_type     = "network-hdd"
      public_ip     = true
      core_fraction = 20
    }
    kafka = {
      zone          = "ru-central1-d"
      cores         = 2
      memory        = 2
      disk_size     = 10
      disk_type     = "network-hdd"
      public_ip     = false
      core_fraction = 20
    }
    data-platform = {
      zone          = "ru-central1-e"
      cores         = 2
      memory        = 2
      disk_size     = 10
      disk_type     = "network-hdd"
      public_ip     = false
      core_fraction = 20
    }
    fintech = {
      zone          = "ru-central1-e"
      cores         = 2
      memory        = 2
      disk_size     = 10
      disk_type     = "network-hdd"
      public_ip     = false
      core_fraction = 20
    }
    ai = {
      zone          = "ru-central1-d"
      cores         = 2
      memory        = 2
      disk_size     = 10
      disk_type     = "network-ssd"
      public_ip     = false
      core_fraction = 20
    }
    clinical = {
      zone          = "ru-central1-e"
      cores         = 2
      memory        = 2
      disk_size     = 10
      disk_type     = "network-ssd"
      public_ip     = false
      core_fraction = 20
    }
  }
}