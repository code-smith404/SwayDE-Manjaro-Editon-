# Arch Sway files

`files/` is a filesystem payload for Arch Linux. It contains desktop
configuration and Sway session helpers only. Application executables, package
lists, ISO-profile files, and Manjaro repository configuration are excluded.
The user service units expect the separately installed `sway-services` package
to provide `sway-session.target`.

The payload is adapted from [manjaro-sway/manjaro-sway](https://github.com/manjaro-sway/manjaro-sway),
revision `60d13c139cf92ce21fc33c5ee321e3f197d04732`, under the MIT license.
See [`UPSTREAM-LICENSE`](./UPSTREAM-LICENSE).

Install instructions and notes are in the repository [README](../README.md).
The repository-level [`install.sh`](../install.sh) installs the complete
payload and backs up replaced files first.
