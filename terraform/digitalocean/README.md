# Digital Ocean Terraform

Usage

```
make init
```

Initialize resources - these get saved in the local state on your filesystem.

```
make plan
```

Check what changes will be applied - this is safe to run as many times as you
like, it will never change the remote.

```
make apply
```

Apply the changes
