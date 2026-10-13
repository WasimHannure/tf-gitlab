terraform {
  backend "s3" {
    bucket = "mybackend-bucket-050926"
    key    = "terraform.tfstate"
    region = "us-east-1"
  }
}
