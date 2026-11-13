# deployment

This directory holds Ansible instructions for provisioning the East Bay for
Everyone web server.

## Prerequisites

- Ansible (ansible-core 2.15 or newer, for `ansible.builtin.deb822_repository`)

- The `ansible.mysql` collection, which provides `mysql_user` and `mysql_db`
  (the `community.mysql` versions of those modules are deprecated):

  ```
  ansible-galaxy collection install ansible.mysql
  ```

- Syncthing

- SSH key: Create a new SSH key in `~/.ssh`. Name it `yourname_ed25519`

- A running DigitalOcean droplet with your SSH key. Add your SSH key to the
droplet so you can use it to SSH in.

## Applying Updates to Running Server

To provision the server from scratch, or to apply updates:

1. Put a host in your ~/.ssh/config named `eastbayforeveryone`, with the details
for the SSH server.

```
Host eastbayforeveryone
    User root
    IdentityFile ~/.ssh/eb4e_ed25519
    # This IP address may change over time, the source of truth is in
    # DigitalOcean, or (should be) mirrored in the Terraform repo.
    HostName 137.184.6.115
```

1a. Ensure you can SSH to that server without a password, ie. copy your SSH
public key to `/root/.ssh/authorized_keys` on the remote host.

2. Grab the `passwords/ansible-vault.password` file from someone who has it
   (most likely Kevin).

3. Then run:

```
make stage.eastbayforeveryone.org group=digitalocean_group
```

3a. Before any full deploy, do a dry run and read every task that says
"changed":

```
make check.stage.eastbayforeveryone.org
```

This changes nothing on the host and deliberately has no `--diff`, because the
diff of a rendered template (wp-config.php, the crontroller env files) prints
passwords and API tokens. Tasks that run commands are skipped in check mode, so
a quiet dry run is not a guarantee, but a "changed" you did not expect is a
reason to stop. Tasks that unzip a plugin whose download was only simulated
(a new pinned version, say) show as "...ignoring" and count under `ignored=` in
the recap; that happens only in check mode, a real run still fails on them. Take a DigitalOcean snapshot before a deploy that changes
packages, PHP, or apt sources.

4. Verify the change looks OK at stage.eastbayforeveryone.org.

5. Deploy the same change to prod:

```
make eastbayforeveryone.org group=digitalocean_group
```

### What a full deploy does and does not do

A full run (no `--tags`) is meant to be safe to run at any time:

- It never kills apt or dpkg. It waits up to five minutes for the dpkg lock
  (unattended-upgrades holds it around 00:34 UTC and the apt-daily timers), and
  stops with instructions if `dpkg --audit` reports a half-installed package.
- It does not upgrade packages as a side effect. The apt tasks use
  `state: present`; security updates come from the nightly unattended-upgrades
  cron job.
- It does not talk to the Snap Store. (`snap refresh core` was removed: it
  failed whenever api.snapcraft.io was unreachable.)
- It does not push local certificates. certbot on the host owns
  `/etc/letsencrypt`. The `certs/` directory is not used.
- It does re-extract the pinned WordPress, Divi and plugin versions from the
  playbook variables over what is on disk. If you update a plugin in wp-admin,
  change the version in the playbook too, or the next deploy puts the old one
  back.
- Everything it downloads is pinned. wp-cli is a release with a SHA-256 checksum
  (`wp_cli_version` and `wp_cli_sha256` in `roles/wordpress/vars/main.yml`) and
  the wordpress-importer is a release tag (`wordpress_importer_version`). These
  used to be the wp-cli nightly build and the importer's `master` branch, so a
  deploy replaced them with whatever upstream had that day. To upgrade wp-cli,
  change the version and the checksum together.
- It leaves the `php` user's primary group alone. The sites share that user,
  and each site's deploy used to set its primary group to the site's own group.
- `force_handlers` is on (ansible.cfg): if a later task fails, handlers that
  were already notified (nginx reload, php-fpm restart) still run, so the
  running service matches the files on disk. nginx validates its config before
  reloading, so a broken config leaves the old one serving.

### Certificate renewal

certbot is the snap, and the snap's timer (`snap.certbot.renew.timer`) renews.
Ansible installs a deploy hook,
`/etc/letsencrypt/renewal-hooks/deploy/reload-nginx.sh`, which tests the nginx
config and reloads nginx after every successful renewal, and removes the old
cron job (it ran `cd /opt/certbot`, a directory that does not exist) and the
Ubuntu `certbot.timer` (a second renewal run against the same certificates).

The deploy does not delete certificates. If `systemctl --failed` lists
`snap.certbot.renew.service`, a certificate that can no longer renew is the
usual cause. Find it with:

```
certbot certificates
certbot renew --dry-run
```

Before deleting a lineage, make sure nothing uses it. nginx refuses to load a
config whose `ssl_certificate` file is missing, and the next reload (a deploy,
or the renewal deploy hook) would fail. Check for references:

```
grep -rn 'live/<name>/' /home/nginx/etc/includes/
```

If a vhost or redirect block still names the certificate, remove that domain
from the playbook (e.g. `redirect_domains`), deploy with `--tags crawl_defense`
so nginx stops referencing it, and only then delete the lineage by hand:

```
certbot delete --cert-name <name> --non-interactive
```

As of November 2026 two lineages could not renew, both for names that no longer
resolve in DNS: `stage2.eastbayforeveryone.org` (expired 2021; it was only a
redirect block, removed from `redirect_domains`) and
`stage.transportoakland.org` (expired 2022; it is still a full vhost, so
deleting its certificate requires retiring or re-pointing that site first).

### Editing secrets files

There are several encrypted files in this repository.

The database passwords are checked in to `secrets/<domain>.yml`. Edit with e.g.

```
ansible-vault edit --vault-password-file=passwords/ansible-vault.password secrets/eastbayforeveryone.org.yml
```

You will need the password file, which you can get from Kevin. Place it in
`passwords/ansible-vault.password`.

### Manual steps necessary

I wrote down this list when we ported the website from wordpress.com.

1. Edit stage.eastbayforeveryone.org.yml to set `wordpress_ssl_enabled` to `false`

2. Deploy the site

3. Edit DNS to point stage and www.stage A records at the new host

4. Wait one minute for DNS to propagate. Note Wordpress.com DNS hosting sets
   long expiration.

5. Run the commented out certbot commands at the bottom of
   stage.eastbayforeveryone.org.yml to create certificates

6. go to https://stage.eastbayforeveryone.org and create an admin user/password

8. dump the old Wordpress database as XML from production: https://eastbayforeveryone.org/wp-admin/export.php?return=https%3A%2F%2Fwordpress.com%2Fhosting-config%2Feastbayforeveryone.org

9. import into the new site

```
scp ~/Downloads/eastbayforeveryone.WordPress.2021-09-05.xml eastbayforeveryone:/var/tmp
```

10. Activate all plugins and the Divi theme. Note you need to do this before you
run the site importer or it won't work.

10. On the server, run

```
sudo -u php -i -- /home/php/bin/wp import --debug=bootstrap --authors=create --path=/home/eb4e-stage/public/ /var/tmp/eastbayforeveryone.WordPress.2021-09-05.xml
```

In prod we needed to copy the "uploads" directory from stage because the prod
site was now pointing at our own server.

11. export Divi Library, import to new site. Don't do this before you run the
    import script above.

12. export Divi Customizer, import to new site. Don't do this before you run the
    import script above.

13. Set static page as homepage in "Reading" option pane.

14. In theme customizer go to "Menus", click "Primary", at the bottom check
    "Primary Menu"

15. Change "calendar" menu bar link to "/events"

16. Add new events calendar key

## Manual changes

Edited journal.conf to reduce size of /var/log/journal
Tried to reduce binlog size

October 2025 - updated to Ubuntu 24.04 using do-release-upgrade

## Upgrading PHP

The PHP minor version is set in one place: `php_minor` in
`roles/php/vars/main.yml`. Package names, config paths, the systemd unit, the
`/usr/sbin/php-fpm` symlink and the `php` CLI alternative all derive from it,
and the role installs versioned packages (`php8.5-fpm`, not the unversioned
`php-fpm` metapackage) so an `apt upgrade` cannot silently move the host to a
different minor version. opcache is built into PHP 8.5, so there is no
`php8.5-opcache` package; the role only lists it for older minors.

**Stage and prod share one server and one php-fpm**, so deploying to stage
first does NOT test a PHP version change in isolation - it flips the version
for prod at the same moment.

### Deploying only the PHP role

All php tasks carry the tag `php_upgrade`, so the rest of the playbook (git,
letsencrypt/snap, wordpress, mysql, ...) is skipped. Any of the four playbooks
runs the same php tasks against the same host; use the prod one:

```
make eastbayforeveryone.org ANSIBLE_ARGS="--tags php_upgrade"
```

To preview which tasks the tag selects (this changes nothing and does not
connect to the host):

```
ansible-playbook eastbayforeveryone.org.yml --inventory hosts \
    --extra-vars @secrets/eastbayforeveryone.org.yml \
    --vault-password-file passwords/ansible-vault.password \
    --list-tasks --tags php_upgrade
```

`--check` does not work for the first 8.5 run: `/etc/php/8.5` does not exist
until the packages are installed, so the template tasks fail in check mode.

### Pre-flight checklist

1. Take a DigitalOcean snapshot of the droplet.
2. Pick a quiet period. PHP is down for a few seconds (see below).
3. Confirm the WordPress version, Divi and the plugins support the new PHP
   version. The transportoakland.org sites run WordPress 5.9.2 (prod) and
   6.1.1 (stage), which predate PHP 8.1 support and are not documented as
   supporting 8.4 or 8.5.
4. `ssh eastbayforeveryone 'apt-cache policy php8.5-fpm'` shows a candidate
   (the PPA is configured) and `df -h /` has a few hundred MB free.
5. Know the rollback command (below) before you start.

### What the run does

1. Installs `php8.5-{cli,fpm,gd,intl,mbstring,mysql,zip}` (plus `-common` and
   `-readline` as dependencies). The package postinst also starts
   `php8.5-fpm.service` with the stock Debian pool (its own socket under
   `/run/php/`, not `/var/run/php-fpm.sock`); nginx does not use it.
2. Writes `/etc/php/8.5/fpm/pool.d/php-fpm.conf`, `/etc/php/8.5/fpm/php.ini`,
   `/etc/php/8.5/cli/conf.d/php.ini` and the systemd override for
   `php8.5-fpm`, points `/usr/sbin/php-fpm` and the `php` command
   (`update-alternatives --set php`) at 8.5, and runs `php-fpm8.5 --test` on
   the result. If the config is invalid the run fails here, before anything
   was stopped.
3. Stops and disables `php8.4-fpm.service`. The packaged unit has no
   `ExecStop`, so systemd sends SIGTERM and php-fpm exits immediately:
   in-flight requests are dropped. Both versions use `/var/run/php-fpm.sock`,
   so the old one must be gone before the new one restarts.
4. Reloads systemd and restarts `php8.5-fpm.service` with the real config,
   enables it, waits for `/var/run/php-fpm.sock` and checks that `php` reports
   8.5.

Downtime is the time between steps 3 and 4: normally 2-5 seconds of 502s from
nginx. It is not graceful across versions. The 8.4 packages and
`/etc/php/8.4` stay on disk.

### Rolling back

Set `php_minor: '8.4'` in `roles/php/vars/main.yml` and run the same command.
The role then stops and disables `php8.5-fpm`, starts and enables
`php8.4-fpm`, and moves the symlink and the `php` alternative back. It is the
same few seconds of downtime. If Ansible itself is unusable, by hand:

```
systemctl disable --now php8.5-fpm
systemctl enable --now php8.4-fpm
ln -sfn /usr/sbin/php-fpm8.4 /usr/sbin/php-fpm
update-alternatives --set php /usr/bin/php8.4
```

### After deploying

- `systemctl status php8.5-fpm` is active; `systemctl is-enabled php8.4-fpm`
  says disabled; `ls -l /var/run/php-fpm.sock` exists.
- `php -v` says 8.5.x; `php -m` matches what it was on 8.4 (minus the
  separate OPcache module, which is now built in but still listed).
- Load the home page, `/events`, a Divi-built page and `/wp-admin` on
  eastbayforeveryone.org and stage, and the home page and `/wp-admin` of
  transportoakland.org and its stage (`make verify-prod` covers the first).
- `tail /var/log/nginx/error.log` for `PHP message: PHP Fatal error` and
  `Warning` lines, and `/var/log/php/php-fpm.log` and `error.log`. Note that
  `error_reporting` excludes `E_DEPRECATED`, so deprecations are not logged.

Once a version has been stable for a while, remove the old packages
(`apt purge 'php8.4*'`) and their leftover `/etc/php/8.4` directory by hand,
and delete the stale `/etc/php/8.0` and `/etc/php/8.1` directories.

### Known follow-ups

- `templates/php-fpm.ini` is a full copy of an old php.ini. It would be
  easier to maintain as a small `conf.d` drop-in on top of the packaged
  `php.ini`, so that new defaults arrive with each PHP version.
- `session.sid_length` and `session.sid_bits_per_character` are deprecated
  since PHP 8.4 and log a startup deprecation. WordPress does not use PHP
  sessions; they can be dropped.
