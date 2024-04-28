variable "secondary_region" {
  description = "The secondary region where AWS operations will take place"
  default     = "us-west-2"
  type        = string
}

variable "secondary_vpc_cidr_block" {
  description = "CIDR block for the VPC"
  default     = "10.2.0.0/16"
}

variable "secondary_vpc_name" {
  description = "Name of the VPC"
  default     = "Secondary VPC"
}

variable "secondary_project_name" {
  description = "Name of the project"
  default     = "Udacity -secondary"
}

variable "secondary_public_subnet_cidr_a" {
  description = "CIDR block for the public subnet"
  default = "10.2.10.0/24"
}

variable "secondary_private_subnet_cidr_a" {
  description = "CIDR block for the private subnet"
    default = "10.2.20.0/24"
}

variable "secondary_public_subnet_cidr_b" {
  description = "CIDR block for the public subnet"
  default = "10.2.11.0/24"
}

variable "secondary_private_subnet_cidr_b" {
  description = "CIDR block for the private subnet"
    default = "10.2.21.0/24"
}

variable "secondary_availability_zones" {
  description = "List of availability zones"
  default = ["us-west-2a", "us-west-2b"]
}