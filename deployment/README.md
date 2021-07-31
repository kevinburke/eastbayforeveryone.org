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
