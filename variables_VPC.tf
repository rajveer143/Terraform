# Variables
variable "access_key" {default = "XXXXXX"}
variable "secret_key" {default = "XXXXXX"}
variable "PROJECT_NAME" {default ="production"}
variable "VPC_CIDR_BLOCK" {default = "10.0.0.0/16"}
variable "VPC_PUBLIC_SUBNET_CIDR_BLOCK" {default="10.0.1.0/24"}
variable "VPC_PRIVATE_SUBNET_CIDR_BLOCK" {default ="10.0.3.0/24"}
variable "aws_region"   {default = "us-east-1"}
variable "ami_webserver" {default ="ami-0885b1f6bd170450c"}
variable "type_webserver" {default ="t2.micro"}
variable "aws_availability_zone"   {default = "us-east-1a"}


