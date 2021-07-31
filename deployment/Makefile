stage.eastbayforeveryone.org:
ifeq ($(group),)
	$(error "no $$group variable set")
endif
	ansible-playbook stage.eastbayforeveryone.org.yml \
		--inventory hosts \
		--limit $(group) \
		--vault-password-file passwords/ansible-vault.password
