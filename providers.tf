terraform {
    backend "s3"  {
        bucket = "myapp-terrabucket"
        key  = "myapp/state.tfstate"
        region = "us-east-2"
    }
}
provider "aws" {
    region = var.region 
}