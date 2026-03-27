variable "env" {
    description = "Environment Name"
    type = string
}

variable "vpc_cidr" {
    default = "10.0.0.0/16"  
}