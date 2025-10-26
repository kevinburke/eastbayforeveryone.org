# Discuss server

Kevin SSH settings:

```
ssh eastbayforeveryone-discuss
```

There are no external backups.

The firewall is disabled.

Everything runs in Docker containers

To upgrade the server (if the web-based upgrade fails)

```
cd /var/discourse
./launcher rebuild redis
```

https://github.com/discourse/discourse/blob/main/docs/INSTALL-cloud.md#9-post-install-maintenance

### Maintenance Log

May 11, 2022:

- Updated do-agent https://docs.digitalocean.com/products/monitoring/how-to/upgrade-legacy-agent/

- Updated disk space to 80 GB

- Updated Ubuntu version to 18. Some files I kept our version of - ufw,
  /etc/sysctl.conf.

July 21 2025

```
find /var/lib/docker/containers -name '*-json.log' -type f -exec truncate -s 0 {} \;
```

take a backup:

./launcher enter app --skip-prereqs
discourse backup

log out, then do e.g.

```
scp eastbayforeveryone-discuss:/var/discourse/shared/standalone/backups/default/east-bay-for-everyone-2025-07-21-193421-v20240110040813.tar.gz .
```

update Ubuntu to version 20 and then version 22
