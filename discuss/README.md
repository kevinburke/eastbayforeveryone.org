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
