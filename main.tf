provider "aws" {
  region     = var.aws_region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}
resource "aws_instance" "my-atg-server" {
  ami = var.my-ami-id
  instance_type = "t3.micro"
}