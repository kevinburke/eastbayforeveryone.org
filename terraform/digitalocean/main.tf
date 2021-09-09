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
  name   = "eb4e-website-2021-09-07"
  region = "sfo3"
  size   = "s-1vcpu-1gb"
  ipv6   = false
}

resource "digitalocean_droplet" "discuss" {
  # image ID found by importing and then running "make plan"
  image   = "25399919"
  name    = "discuss.eastbayforeveryone.org"
  region  = "sfo1"
  size    = "s-2vcpu-4gb"
  ipv6    = false
  backups = true
}

resource "digitalocean_floating_ip" "website" {
  droplet_id = digitalocean_droplet.website.id
  region     = digitalocean_droplet.website.region
}

resource "digitalocean_domain" "default" {
  name = "eastbayforeveryone.org"
}

resource "digitalocean_record" "eastbayforeveryone_wildcard" {
  domain = digitalocean_domain.default.name
  type   = "CNAME"
  name   = "*.eastbayforeveryone.org"
  value  = "eastbayforeveryone.org."
}

resource "digitalocean_record" "eastbayforeveryone_a" {
  domain = digitalocean_domain.default.name
  type   = "A"
  name   = "@"
  value  = "192.0.78.246"
}

resource "digitalocean_record" "eastbayforeveryone_a2" {
  domain = digitalocean_domain.default.name
  type   = "A"
  name   = "@"
  value  = "192.0.78.152"
}

resource "digitalocean_record" "eastbayforeveryone_meet_cname" {
  domain = digitalocean_domain.default.name
  type   = "CNAME"
  name   = "auth.meet.eastbayforeveryone.org"
  value  = "meet.eastbayforeveryone.org."
}

resource "digitalocean_record" "eastbayforeveryone_meet_guest" {
  domain = digitalocean_domain.default.name
  type   = "CNAME"
  name   = "guest.meet.eastbayforeveryone.org"
  value  = "meet.eastbayforeveryone.org."
}

resource "digitalocean_record" "eastbayforeveryone_meet_a" {
  domain = digitalocean_domain.default.name
  type   = "A"
  name   = "meet"
  value  = digitalocean_droplet.discuss.ipv4_address
}

resource "digitalocean_record" "eastbayforeveryone_notes" {
  domain = digitalocean_domain.default.name
  type   = "A"
  name   = "notes"
  value  = digitalocean_droplet.discuss.ipv4_address
}

resource "digitalocean_record" "eastbayforeveryone_organizing" {
  domain = digitalocean_domain.default.name
  type   = "CNAME"
  name   = "organizing"
  value  = "organizing.eastbayforeveryone.org.herokudns.com."
}

resource "digitalocean_record" "eastbayforeveryone_recorder" {
  domain = digitalocean_domain.default.name
  type   = "CNAME"
  name   = "recorder.eastbayforeveryone.org"
  value  = "meet.eastbayforeveryone.org."
}

resource "digitalocean_record" "eastbayforeveryone_discuss" {
  domain = digitalocean_domain.default.name
  type   = "A"
  name   = "discuss"
  value  = digitalocean_droplet.discuss.ipv4_address
}

resource "digitalocean_record" "eastbayforeveryone_mx1" {
  domain   = digitalocean_domain.default.name
  type     = "MX"
  name     = "@"
  priority = 5
  value    = "alt1.aspmx.l.google.com."
}

resource "digitalocean_record" "eastbayforeveryone_mx2" {
  domain   = digitalocean_domain.default.name
  type     = "MX"
  name     = "@"
  priority = 5
  value    = "alt2.aspmx.l.google.com."
}

resource "digitalocean_record" "eastbayforeveryone_mx3" {
  domain   = digitalocean_domain.default.name
  type     = "MX"
  name     = "@"
  priority = 10
  value    = "alt3.aspmx.l.google.com."
}

resource "digitalocean_record" "eastbayforeveryone_mx4" {
  domain   = digitalocean_domain.default.name
  type     = "MX"
  name     = "@"
  priority = 10
  value    = "alt4.aspmx.l.google.com."
}

resource "digitalocean_record" "eastbayforeveryone_mx" {
  domain   = digitalocean_domain.default.name
  type     = "MX"
  name     = "@"
  priority = 1
  value    = "aspmx.l.google.com."
}

resource "digitalocean_record" "eastbayforeveryone_google_verification" {
  domain = digitalocean_domain.default.name
  type   = "TXT"
  name   = "@"
  value  = "google-site-verification=uAipA1xaItiLcQ4Ks5kE2PbYySGTwrKWDZmhZPQSxUc"
}

resource "digitalocean_record" "eastbayforeveryone_spf" {
  domain = digitalocean_domain.default.name
  type   = "TXT"
  name   = "@"
  value  = "v=spf1 include:_spf.google.com include:mailgun.org ~all"
}

resource "digitalocean_record" "eastbayforeveryone_mailgun" {
  domain = digitalocean_domain.default.name
  type   = "CNAME"
  name   = "email.m.eastbayforeveryone.org"
  value  = "mailgun.org."
}

resource "digitalocean_record" "eastbayforeveryone_mailgun2" {
  domain = digitalocean_domain.default.name
  type   = "CNAME"
  name   = "email.m2.eastbayforeveryone.org"
  value  = "mailgun.org."
}

resource "digitalocean_record" "eastbayforeveryone_mcsv1" {
  domain = digitalocean_domain.default.name
  type   = "CNAME"
  name   = "k1._domainkey.eastbayforeveryone.org"
  value  = "dkim.mcsv.net."
}

resource "digitalocean_record" "eastbayforeveryone_mcsv2" {
  domain = digitalocean_domain.default.name
  type   = "CNAME"
  name   = "krs._domainkey.eastbayforeveryone.org"
  value  = "dkim.mcsv.net."
}

resource "digitalocean_record" "eastbayforeveryone_smtp" {
  domain = digitalocean_domain.default.name
  type   = "TXT"
  name   = "smtp._domainkey.m.eastbayforeveryone.org"
  value  = "k=rsa; p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDwGHem+U6LGi65vZAYVvAdWdClADSMGNaESxIkavxzNLA0xroc7qwEhylAOKiSIbmPPUlH5BSGkbCAqiYxL2/j9afZ9PN9uYMzi9qkJL1gGMQO3pFyOndzyTN4Hp0u+92GZx8tKv1YfyqoI6e6hPU6OetxAVaMsq0cTeU2cC/UlQIDAQAB"
}

resource "digitalocean_record" "eastbayforeveryone_stage" {
  domain = digitalocean_domain.default.name
  type   = "A"
  name   = "stage.eastbayforeveryone.org"
  value  = digitalocean_floating_ip.website.ip_address
}
