variable "region" {
  type        = string
  description = "The region to use"
  default     = "us-east-1"
}

variable "vpc_cidr" {
  type        = string
  description = "The cidr block of the vpc"
  default     = "10.0.0.0/16"
}

variable "public_subnets" {
  type        = map(any)
  description = "Map of AZs to public subnet cidrs"
  default = {
    us-east-1a = "10.0.1.0/24"
    us-east-1b = "10.0.2.0/24"
  }
}

variable "private_subnets" {
  type        = map(any)
  description = "Map of AZs to private subnet cidrs"
  default = {
    us-east-1c = "10.0.3.0/24"
    us-east-1d = "10.0.4.0/24"
  }
}

variable "db_instance_type" {
  type        = string
  description = "The db instance type"
  default     = "db.t3.micro"
}

variable "rds_username" {
  type        = string
  description = "The rds db username"
  sensitive   = true
}

variable "rds_password" {
  type        = string
  description = "The rds db password"
  sensitive   = true
}

variable "ldb_username" {
  type        = string
  description = "The local db username"
  sensitive   = true
}

variable "ldb_password" {
  type        = string
  description = "The local db password"
  sensitive   = true
}

variable "key_name" {
  type = string
  description = "The ssh key name"
}

variable "key_path" {
  type = string
  description = "The path to the private ssh key"
}