Create a new SSH key in `~/.ssh`. Name it `name_ed25519`

Create a droplet, add your SSH key so you can use it to SSH in.

## Provisioning

Put a host in your ~/.ssh/config named `eastbayforeveryone`

```
Host eastbayforeveryone
    User root
    IdentityFile ~/.ssh/eb4e_ed25519
    HostName 144.126.221.226
```

Then run:

```
make stage.eastbayforeveryone.org group=digitalocean_group
```

### Manual steps necessary

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

11. export Divi Library, import to new site. Don't do this before you run the
    import script above.

12. export Divi Customizer, import to new site. Don't do this before you run the
    import script above.

13. Set static page as homepage in "Reading" option pane.

14. In theme customizer go to "Menus", click "Primary", at the bottom check
    "Primary Menu"

15. Change "calendar" menu bar link to "/events"

16. Add new events calendar key
