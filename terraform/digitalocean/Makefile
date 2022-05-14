# TODO add remote state and state locking here.

plan:
	terraform plan

apply:
	terraform apply

init:
	terraform init

terraform.tfvars: ~/share/syncthing/eastbayforeveryone.org/terraform/digitaloceanterraform.tfvars
	rsync --recursive --verbose ~/share/syncthing/eastbayforeveryone.org/terraform/digitalocean/terraform.tfvars terraform.tfvars
