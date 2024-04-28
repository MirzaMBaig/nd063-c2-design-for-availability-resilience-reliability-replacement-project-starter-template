variable "region_ordinals" {
    description = "List of ordinals for the regions ie primary and secondary"
    default = ""
}

variable "region" {
  description = "The primary region where AWS operations will take place"
  default     = "us-east-1"
  type        = string

}

variable "vpc_cidr_block" {
  description = "CIDR block for the VPC"
  default     = "10.1.0.0/16"
}

variable "vpc_name" {
  description = "Name of the VPC"
  default     = "Primary VPC"
}

variable "project_name" {
  description = "Name of the project"
  default     = "Udacity"
}

variable "public_subnet_cidr_a" {
  description = "CIDR block for the public subnet"
  default = "10.1.10.0/24"
}

variable "private_subnet_cidr_a" {
  description = "CIDR block for the private subnet"
    default = "10.1.20.0/24"
}

variable "public_subnet_cidr_b" {
  description = "CIDR block for the public subnet"
  default = "10.1.11.0/24"
}

variable "private_subnet_cidr_b" {
  description = "CIDR block for the private subnet"
    default = "10.1.21.0/24"
}

variable "availability_zones" {
  description = "List of availability zones"
  default = ["us-east-1a", "us-east-1b"]
}


