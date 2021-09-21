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
  value  = digitalocean_floating_ip.website.ip_address
}

resource "digitalocean_record" "eastbayforeveryone_www" {
  domain = digitalocean_domain.default.name
  type   = "A"
  name   = "www"
  value  = digitalocean_floating_ip.website.ip_address
}

resource "digitalocean_record" "eastbayforeveryone_meet_cname" {
  domain = digitalocean_domain.default.name
  type   = "CNAME"
  name   = "auth.meet"
  value  = "meet.eastbayforeveryone.org."
}

resource "digitalocean_record" "eastbayforeveryone_meet_guest" {
  domain = digitalocean_domain.default.name
  type   = "CNAME"
  name   = "guest.meet"
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
  name   = "recorder"
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
  name   = "email.m"
  value  = "mailgun.org."
}

resource "digitalocean_record" "eastbayforeveryone_mailgun2" {
  domain = digitalocean_domain.default.name
  type   = "CNAME"
  name   = "email.m2"
  value  = "mailgun.org."
}

resource "digitalocean_record" "eastbayforeveryone_mcsv1" {
  domain = digitalocean_domain.default.name
  type   = "CNAME"
  name   = "k1._domainkey"
  value  = "dkim.mcsv.net."
}

resource "digitalocean_record" "eastbayforeveryone_mcsv2" {
  domain = digitalocean_domain.default.name
  type   = "CNAME"
  name   = "krs._domainkey"
  value  = "dkim.mcsv.net."
}

resource "digitalocean_record" "eastbayforeveryone_smtp" {
  domain = digitalocean_domain.default.name
  type   = "TXT"
  name   = "smtp._domainkey.m"
  value  = "k=rsa; p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDwGHem+U6LGi65vZAYVvAdWdClADSMGNaESxIkavxzNLA0xroc7qwEhylAOKiSIbmPPUlH5BSGkbCAqiYxL2/j9afZ9PN9uYMzi9qkJL1gGMQO3pFyOndzyTN4Hp0u+92GZx8tKv1YfyqoI6e6hPU6OetxAVaMsq0cTeU2cC/UlQIDAQAB"
}

resource "digitalocean_record" "eastbayforeveryone_stage" {
  domain = digitalocean_domain.default.name
  type   = "A"
  name   = "stage"
  value  = digitalocean_floating_ip.website.ip_address
}

resource "digitalocean_record" "eastbayforeveryone_www_stage" {
  domain = digitalocean_domain.default.name
  type   = "A"
  name   = "www.stage"
  value  = digitalocean_floating_ip.website.ip_address
}

resource "digitalocean_record" "eastbayforeveryone_www2" {
  domain = digitalocean_domain.default.name
  type   = "A"
  name   = "www2"
  value  = digitalocean_floating_ip.website.ip_address
}

resource "digitalocean_record" "eastbayforeveryone_xmpp_meet" {
  domain = digitalocean_domain.default.name
  type   = "CNAME"
  name   = "xmpp.meet"
  value  = "meet.eastbayforeveryone.org."
}

resource "digitalocean_record" "eastbayforeveryone_xmppconnect" {
  domain = digitalocean_domain.default.name
  type   = "CNAME"
  name   = "_xmppconnect.guest.meet"
  value  = "_xmppconnect.meet.eastbayforeveryone.org."
}

resource "digitalocean_record" "eastbayforeveryone_xmppconnect_meet" {
  domain = digitalocean_domain.default.name
  type   = "TXT"
  name   = "_xmppconnect.meet"
  value  = "_xmpp-client-xbosh=https://meet.eastbayforeveryone.org:443/http-bind"
}

resource "digitalocean_record" "eastbayforeveryone_domainconnect" {
  # not sure if we need this one after we port off
  domain = digitalocean_domain.default.name
  type   = "TXT"
  name   = "_domainconnect"
  value  = "public-api.wordpress.com/rest/v1.3/domain-connect"
}
