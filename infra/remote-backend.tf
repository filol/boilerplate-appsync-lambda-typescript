terraform {
  backend "s3" {
    encrypt = false
    bucket  = "cerise-backend"
    key     = "dev-cerise.tfstate"
    region  = "us-east-1"
    profile = "revolve"
  }
}