stage.eastbayforeveryone.org: passwords/ansible-vault.password tarballs/divi.zip
ifeq ($(group),)
	$(error "no $$group variable set")
endif
	ansible-playbook stage.eastbayforeveryone.org.yml \
		--inventory hosts \
		--limit $(group) \
		--extra-vars @secrets/stage.eastbayforeveryone.org.yml \
		--vault-password-file passwords/ansible-vault.password

eastbayforeveryone.org: passwords/ansible-vault.password tarballs/divi.zip
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

tarballs/divi.zip:
	mkdir -p tarballs
	rsync --recursive --verbose ~/share/syncthing/eastbayforeveryone.org/deployment/tarballs/ ./tarballs/

# Post-deploy verification
tmp/verify-deploy: ../cmd/verify-deploy/main.go
	mkdir -p tmp
	go build -trimpath -o tmp/verify-deploy ../cmd/verify-deploy

verify-stage: tmp/verify-deploy
	./tmp/verify-deploy --domain stage.eastbayforeveryone.org

verify-prod: tmp/verify-deploy
	./tmp/verify-deploy --domain eastbayforeveryone.org

stage.transportoakland.org: passwords/ansible-vault.password
ifeq ($(group),)
	$(error "no $$group variable set")
endif
	ansible-playbook stage.transportoakland.org.yml \
		--inventory hosts \
		--limit $(group) \
		--extra-vars @secrets/stage.transportoakland.org.yml \
		--vault-password-file passwords/ansible-vault.password

transportoakland.org: passwords/ansible-vault.password
ifeq ($(group),)
	$(error "no $$group variable set")
endif
	ansible-playbook transportoakland.org.yml \
		--inventory hosts \
		--limit $(group) \
		--extra-vars @secrets/transportoakland.org.yml \
		--vault-password-file passwords/ansible-vault.password
