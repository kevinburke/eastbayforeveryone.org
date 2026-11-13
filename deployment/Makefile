# Extra ansible-playbook arguments, e.g.
#   make eastbayforeveryone.org ANSIBLE_ARGS="--tags php_upgrade"
ANSIBLE_ARGS ?=

stage.eastbayforeveryone.org: passwords/ansible-vault.password tarballs/divi.zip
	ansible-playbook stage.eastbayforeveryone.org.yml \
		--inventory hosts \
		--extra-vars @secrets/stage.eastbayforeveryone.org.yml \
		--vault-password-file passwords/ansible-vault.password \
		$(ANSIBLE_ARGS)

eastbayforeveryone.org: passwords/ansible-vault.password tarballs/divi.zip
	ansible-playbook eastbayforeveryone.org.yml \
		--inventory hosts \
		--extra-vars @secrets/eastbayforeveryone.org.yml \
		--vault-password-file passwords/ansible-vault.password \
		$(ANSIBLE_ARGS)

# Dry runs. They connect to the host but change nothing, and print every task
# that WOULD change. Deliberately no --diff: the diff of a rendered template
# (wp-config.php, the crontroller env files) prints database passwords and API
# tokens. Tasks that run commands are skipped in check mode, so a clean dry run
# is not a guarantee, but "changed" lines you do not expect are a warning.
# Tasks that unzip a plugin an earlier task would have downloaded show as
# "...ignoring" (ignored=N in the recap): the download was only simulated, so
# the file is not there. That is expected and only happens in check mode.
check.eastbayforeveryone.org: passwords/ansible-vault.password tarballs/divi.zip
	ansible-playbook eastbayforeveryone.org.yml \
		--inventory hosts \
		--extra-vars @secrets/eastbayforeveryone.org.yml \
		--vault-password-file passwords/ansible-vault.password \
		--check $(ANSIBLE_ARGS)

check.stage.eastbayforeveryone.org: passwords/ansible-vault.password tarballs/divi.zip
	ansible-playbook stage.eastbayforeveryone.org.yml \
		--inventory hosts \
		--extra-vars @secrets/stage.eastbayforeveryone.org.yml \
		--vault-password-file passwords/ansible-vault.password \
		--check $(ANSIBLE_ARGS)

check.transportoakland.org: passwords/ansible-vault.password
	ansible-playbook transportoakland.org.yml \
		--inventory hosts \
		--extra-vars @secrets/transportoakland.org.yml \
		--vault-password-file passwords/ansible-vault.password \
		--check $(ANSIBLE_ARGS)

check.stage.transportoakland.org: passwords/ansible-vault.password
	ansible-playbook stage.transportoakland.org.yml \
		--inventory hosts \
		--extra-vars @secrets/stage.transportoakland.org.yml \
		--vault-password-file passwords/ansible-vault.password \
		--check $(ANSIBLE_ARGS)

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
	ansible-playbook stage.transportoakland.org.yml \
		--inventory hosts \
		--extra-vars @secrets/stage.transportoakland.org.yml \
		--vault-password-file passwords/ansible-vault.password \
		$(ANSIBLE_ARGS)

transportoakland.org: passwords/ansible-vault.password
	ansible-playbook transportoakland.org.yml \
		--inventory hosts \
		--extra-vars @secrets/transportoakland.org.yml \
		--vault-password-file passwords/ansible-vault.password \
		$(ANSIBLE_ARGS)
