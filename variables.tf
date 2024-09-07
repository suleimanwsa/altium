variable "ec2_subnet" {
  description = "subnets of apps"
  type        = string
  default     = "172.31.48.0/20"
}

variable "mysql_subnet" {
  description = "subnet of DBs"
  type        = string
  default     = "172.31.64.0/20"
}

variable "alb1_subnet" {
  description = "subnet of alb zone 1"
  type        = string
  default     = "172.31.80.0/20"
}

variable "alb2_subnet" {
  description = "subnet of alb zone 2"
  type        = string
  default     = "172.31.96.0/20"
}


variable "ips_allowed_to_access_cde" {
  description = "allowed ips to access app"
  type        = list(string)
  default     = ["203.0.113.4/32", "198.51.100.5/32"]
}



variable "secureweb_ips" {
  description = "allowed to access secureweb"
  type        = list(string)
  default     = ["192.185.148.211/32"]
}