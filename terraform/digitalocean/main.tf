terraform {
  required_version = ">= 0.13"
}

terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "2.11.1"
    }
  }
}

variable "digitalocean_token" {}

provider "digitalocean" {
  token = var.digitalocean_token
}

resource "digitalocean_droplet" "website" {
  image  = "ubuntu-20-04-x64"
  name   = "eastbayforeveryone.org"
  region = "sfo3"
  size   = "s-1vcpu-1gb"
  ipv6   = false
}

resource "digitalocean_floating_ip" "website" {
  droplet_id = digitalocean_droplet.website.id
  region     = digitalocean_droplet.website.region
}
