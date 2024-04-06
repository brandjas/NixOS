# NixOS

## Setup

`configuration.nix` expects to find a (symlink to a) directory with machine-specific configuration files at `local-machine`, which can be created as follows:

```
ln -s machines/<name> local-machine
```
