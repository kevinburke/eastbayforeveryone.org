stage.eastbayforeveryone.org: passwords/ansible-vault.password
ifeq ($(group),)
	$(error "no $$group variable set")
endif
	ansible-playbook stage.eastbayforeveryone.org.yml \
		--inventory hosts \
		--limit $(group) \
		--extra-vars @secrets/stage.eastbayforeveryone.org.yml \
		--vault-password-file passwords/ansible-vault.password

eastbayforeveryone.org: passwords/ansible-vault.password
ifeq ($(group),)
	$(error "no $$group variable set")
endif
	ansible-playbook eastbayforeveryone.org.yml \
		--inventory hosts \
		--limit $(group) \
		--extra-vars @secrets/eastbayforeveryone.org.yml \
		--vault-password-file passwords/ansible-vault.password

passwords/ansible-vault.password:
	mkdir -p passwords
	rsync --recursive --verbose ~/share/syncthing/eastbayforeveryone.org/deployment/passwords/ ./passwords/
