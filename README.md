# Arch Linux Sway desktop configuration

This repository contains Sway desktop configuration files adapted from
[Manjaro Sway](https://github.com/manjaro-sway/manjaro-sway). It includes
Sway defaults, session helpers, themes, and Waybar integration; it does not
include application binaries, package manifests, or an application installer.

The files under [`arch/files/`](./arch/files/) mirror their destination paths
under `/etc` and `/usr`. Review them before installing, especially if you
already have Sway configuration. Run the installer from this repository:

```sh
./install.sh --dry-run
sudo ./install.sh
```

The installer backs up any existing destination it replaces under
`/var/backups/swayde-arch/`. It installs `/etc/skel` defaults but does not
change files in your current home directory. To seed only missing files in
your home after installation, run `cp -an /etc/skel/. "$HOME"/`.

Services and helpers are only provided as configuration. Any commands used by
the Sway config must be installed separately on Arch Linux. The Waybar package
update module uses `checkupdates` from `pacman-contrib`. The user services
expect `sway-services` to provide `sway-session.target`.

The weather and sun-time helpers use the configurable `SWAYDE_ARCH_GEO_URL`
endpoint for approximate location; its default endpoint receives the
machine's public IP. Set the variable to a trusted endpoint or remove those
Waybar modules if you do not want that request.

The upstream project is distributed under the MIT license; see
[`arch/UPSTREAM-LICENSE`](./arch/UPSTREAM-LICENSE). These adaptations are based
on upstream revision `60d13c139cf92ce21fc33c5ee321e3f197d04732`.
