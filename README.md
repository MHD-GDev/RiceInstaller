# MHD RiceInstaller

Welcome to the MHD RiceInstaller! This project provides a collection of beautiful rice configurations for your Linux desktop environment. Below, you can see previews of the available themes.
- Here is a demo:
![Rice](demo/Rice.mp4)
---

| Bubble | Rainbow |
|--------|---------|
| ![Bubble](demo/Bubble.gif) | ![Rainbow](demo/Rainbow.gif) |

| Frutiger | WinXP |
|----------|-------|
| ![Frutiger](demo/Frutiger.gif) | ![WinXP](demo/WinXP.gif) |

| Cream | Mono |
|-------|------|
| ![Cream](demo/Cream.gif) | ![Mono](demo/Mono.gif) |

| Pipboy | Solarized |
|--------|-----------|
| ![Pipboy](demo/Pipboy.gif) | ![Solarized](demo/Solarized.gif) |

| Yellowpunk | Redpunk |
|------------|---------|
| ![Yellowpunk](demo/Yellowpunk.gif) | ![Redpunk](demo/Redpunk.gif) |

| y2k |
|-----|
| ![y2k](demo/y2k.gif) |

## Installation

To install using the automated script, run the following command:

```sh
chmod +x RiceInstaller.sh && ./RiceInstaller.sh
```

## Manual Installation

If you prefer to install manually without the script, follow these steps:

1. Copy the "ConfigFiles" directory to your `.config` directory.
2. Copy the ".zshrc" file to your home directory (`/home/$(whoami)`).
3. Install the required packages for your system to function as a daily driver using the appropriate command below:

   - **Gentoo**:
     ```sh
     sudo emerge --sync && sudo emerge $(cat Gentoo-Rice-packages.md)
     ```
     **Note**: Do not install blindly. Please check the use flags and GPU requirements before proceeding.

   - **Arch**:
     ```sh
     paru -Syu --no-confirm && paru -S --no-confirm $(cat arch-rice-wayland-packs.txt)
     ```
     **Note**: Remember to install the appropriate GPU packages as well.

   **Additional Note**: There are specialized packages available for specific operating system types. You may choose to install them after running the RiceInstaller script if desired.

## Acknowledgments

Special thanks to:
- [OliveThePuffin](https://github.com/OliveThePuffin/yorha-grub-theme) for the GRUB theme.
- [stepanzubkov](https://github.com/stepanzubkov/where-is-my-sddm-theme) for the SDDM theme.
