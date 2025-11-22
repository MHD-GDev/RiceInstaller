# MHD RiceInstaller V1.0

## Installer Script
```sh
chmod +x RiceInstaller.sh && ./RiceInstaller.sh
```

## Manual Installation

### If you want to copy everything manually without the installer script then this is the path for eatch file to go: 

1. "ConfigFiles" should go to .config dir.
3. ".zshrc" should go to the /home/$(whoami).
4. also you have to download the needed packages for the system to be a dailydrive using this command : 
- Gentoo:
```sh
 sudo emerge --sync && sudo emerge $(cat Gentoo-Rice-packages.md)
```
- note : Do not blindly install the world.txt file, check the use flags and gpu before doing it.

- Arch:
```sh
 paru -Syu --no-confirm && paru -S --no-confirm $(cat arch-rice-wayland-packs.txt)
```
- note : Don't forget to download the gpu packages as well.

- note 2: There are niche targeted packages for the type of os that you want, you can choose to install them after RiceInstaller script if you want.
