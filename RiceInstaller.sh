#!/bin/bash

#-----------------------#
#      COLOR CODES     #
#-----------------------#
RED='\e[31m'
GREEN='\e[32m'
YELLOW='\e[33m'
BLUE='\e[34m'
MAGENTA='\e[35m'
CYAN='\e[36m'
RESET='\e[0m'

#-----------------------#
#   INTRODUCTION BANNER #
#-----------------------#
function show_banner() {
    echo -e "${MAGENTA}"
    cat << "EOF"
            ███╗   ███╗██╗  ██╗██████╗
            ████╗ ████║██║  ██║██╔══██╗
            ██╔████╔██║███████║██║  ██║
            ██║╚██╔╝██║██╔══██║██║  ██║
            ██║ ╚═╝ ██║██║  ██║██████╔╝
            ╚═╝     ╚═╝╚═╝  ╚═╝╚═════╝

            MHD rice installer script
EOF
    echo -e "${RESET}"
    sleep 1
}

#-----------------------#
#    SUDO CHECK         #
#-----------------------#
function check_sudo() {
    if [ "$(id -u)" = 0 ]; then
        echo -e "${RED}Do not run this script as root!${RESET}"
        exit 1
    fi
}

#-----------------------#
# CREATE USER DIRS      #
#-----------------------#
function create_user_dirs() {
    echo -e "${YELLOW}Creating user directories...${RESET}"
    sleep 1

    mkdir -p ~/Downloads ~/Documents ~/Pictures ~/Videos ~/Music ~/Desktop ~/Templates

    read -rp "Which type of system do you want to create? (gaming/work/both): " which_os

    if [[ "$which_os" == "gaming" ]]; then
        mkdir -p ~/Games ~/Emulations
    elif [[ "$which_os" == "work" ]]; then
        mkdir -p ~/Projects
    elif [[ "$which_os" == "both" ]]; then
        mkdir -p ~/Projects ~/Games ~/Emulations
    else
        echo -e "${RED}Invalid system type. Exiting.${RESET}"
        exit 1
    fi

    echo -e "${GREEN}User directories created successfully!${RESET}"
    sleep 3
    clear
}

#-----------------------#
# INSTALL PACKAGES      #
#-----------------------#
function install_packages() {
    echo -e "${YELLOW}Installing required packages...${RESET}"
    sleep 1

    read -rp "Which operating system is this? (Arch/Gentoo): " current_os
    read -rp "Which GPU do you have? (AMD/Intel/Nvidia): " selected_gpu

    if [[ "$current_os" =~ ^[Aa]rch$ ]]; then
        sudo pacman -Syu --noconfirm && sudo pacman -S --noconfirm git

        git clone https://aur.archlinux.org/paru.git && cd paru && makepkg -si --noconfirm
        cd ..

        if [[ -f arch-rice-wayland-packs.txt ]]; then
            paru -S --noconfirm $(<arch-rice-wayland-packs.txt)
        else
            echo -e "${RED}Missing arch-rice-wayland-packs.txt file!${RESET}"
            exit 1
        fi

        case "$selected_gpu" in
            [Nn]vidia)
                paru -S --noconfirm nvidia-cg-toolkit nvidia nvidia-utils cuda-tools cuda
                ;;
            [Ii]ntel)
                paru -S --noconfirm vulkan-intel
                ;;
            [Aa][Mm][Dd])
                paru -S --noconfirm amdsmi amdvlk radeontop radeontool
                ;;
        esac

        echo -e "${GREEN}Packages installed successfully!${RESET}"
    elif [[ "$current_os" =~ ^[Gg]entoo$ ]]; then
        echo -e "${GREEN}You're on Gentoo. Install packages manually.${RESET}"
    else
        echo -e "${RED}Unknown OS. Exiting.${RESET}"
        exit 1
    fi
    sleep 3
    clear
}

#-----------------------#
# COPY CONFIG FILES     #
#-----------------------#
function copy_configs() {
    echo -e "${YELLOW}Copying rice directories...${RESET}"
    sleep 1

    if [[ -d ConfigFiles ]]; then
        cp -r ConfigFiles/* ~/.config
        echo -e "${GREEN}Config directories copied!${RESET}"
    else
        echo -e "${RED}Missing ConfigFiles directory!${RESET}"
        exit 1
    fi
    sleep 3
    clear
}

#-----------------------#
# COPY .zshrc           #
#-----------------------#
function copy_zshrc() {
    echo -e "${YELLOW}Copying .zshrc into user's directory...${RESET}"
    sleep 1

    if [[ -f .zshrc ]]; then
        cp .zshrc .fonts ~ && sudo cp -r plugins /usr/share/zsh/
        echo -e "${GREEN}.zshrc copied successfully!${RESET}"
    else
        echo -e "${RED}.zshrc file missing!${RESET}"
        exit 1
    fi
    sleep 3
    clear
}

#-----------------------#
# INSTALL SDDM THEME    #
#-----------------------#
function install_sddm_theme() {
    echo -e "${YELLOW}Installing the SDDM theme...${RESET}"
    sleep 1

    read -rp "Install default SDDM theme? (Y/n): " sddm_ans

    if [[ "$sddm_ans" =~ ^[Yy]$ ]]; then
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/keyitdev/sddm-astronaut-theme/master/setup.sh)" && \
        echo -e "${GREEN}SDDM theme installed successfully!${RESET}"
    else
        echo -e "${RED}SDDM theme installation skipped.${RESET}"
    fi
    sleep 3
    clear
}

#-----------------------#
# INSTALL GRUB THEME    #
#-----------------------#
function install_grub_theme() {
    echo -e "${YELLOW}Installing GRUB theme...${RESET}"
    sleep 1

    read -rp "Install GRUB theme? (Y/n): " grub_theme

    if [[ "$grub_theme" =~ ^[Yy]$ ]]; then
        if [[ -d grub2-theme-shodan/Shodan ]]; then
            sudo cp -r grub2-theme-shodan/Shodan /boot/grub/themes
            sudo sed -i 's|#GRUB_THEME=.*|GRUB_THEME="/boot/grub/themes/Shodan/theme.txt"|' /etc/default/grub
            sudo grub-mkconfig -o /boot/grub/grub.cfg
            echo -e "${GREEN}GRUB theme installed successfully!${RESET}"
        else
            echo -e "${RED}GRUB theme skipped!${RESET}"
        fi
    fi
    sleep 3
    clear
}

#-----------------------#
# BUILD LLAMA.CPP       #
#-----------------------#
function build_llama() {
    echo -e "${YELLOW}Building llama.cpp for local LLMs...${RESET}"
    sleep 1

    cd ~/Templates
    git clone https://github.com/ggml-org/llama.cpp.git
    cd llama.cpp

    while true; do
        echo -e "${YELLOW}Choose build type:${RESET}"
        echo "1) CUDA (Nvidia)"
        echo "2) CPU"
        echo "3) AMD (Vulkan)"
        read -rp "Choice (1-3): " build_choice

        case "$build_choice" in
            1)
                echo -e "${GREEN}CUDA build selected.${RESET}"
                cmake -B build -DGGML_CUDA=ON && cmake --build build --config Release
                break
                ;;
            2)
                echo -e "${GREEN}CPU build selected.${RESET}"
                cmake -B build && cmake --build build --config Release
                break
                ;;
            3)
                echo -e "${GREEN}Vulkan build selected.${RESET}"
                paru -S --noconfirm vulkan-extra-layers vulkan-tools vulkan-headers
                cmake -B build -DGGML_VULKAN=ON && cmake --build build --config Release
                break
                ;;
            *)
                echo -e "${RED}Invalid choice. Try again.${RESET}"
                ;;
        esac
    done

    mkdir -p ~/.config/AI
    mv ~/Templates/llama.cpp ~/.config/AI
    mv ~/.config/AI/llama.cpp/build/bin/{llama-cli,llama-server} ~/.local/bin/
    echo -e "${GREEN}llama.cpp build complete!${RESET}"
    sleep 3
    clear
}

#-----------------------#
# COPY CUSTOM UI FILE   #
#-----------------------#
function add_llama_ui() {
    echo -e "${YELLOW}Adding custom UI for llama.cpp...${RESET}"
    sleep 1

    if [[ -f ~/Templates/RiceInstaller/LlamaUI-vMHD.html ]]; then
        mv ~/Templates/RiceInstaller/LlamaUI-vMHD.html ~/.config/AI
        echo -e "${GREEN}Custom UI added successfully!${RESET}"
    else
        echo -e "${RED}Custom UI file missing!${RESET}"
    fi
    sleep 3
    clear
}

#-----------------------#
# WRITE README NOTE     #
#-----------------------#
function write_notes() {
    echo -e "${CYAN}Writing installation notes...${RESET}"
    echo -e "REMEMBER: Copy your AI models into ~/.local/share/AI-Models" >> ~/Templates/IMPORTANT-README.txt
    echo -e "Use llama.cpp via the LlamaUI-vMHD.html in your browser." >> ~/Templates/IMPORTANT-README.txt
    sleep 5
    clear
}

#-----------------------#
# CHANGE PERMISSIONS    #
#-----------------------#
function fix_permissions() {
    echo -e "${YELLOW}Fixing file permissions...${RESET}"
    sleep 1
    sudo chown -R "$(whoami)":"$(whoami)" ~/.zshrc ~/.config ~/.local
    echo -e "${GREEN}Permissions updated!${RESET}"
    sleep 3
    clear
}

#-----------------------#
# ENABLE SDDM           #
#-----------------------#
function enable_sddm() {
    if sudo systemctl enable --now sddm; then
        echo -e "${GREEN}sddm enabled successfully!${RESET}"
    else
        echo -e "${RED}Failed to enable sddm!${RESET}"
        exit 1
    fi
}

#-----------------------#
# RUN SCRIPT SECTIONS   #
#-----------------------#
show_banner
check_sudo
create_user_dirs
install_packages
copy_configs
copy_zshrc
install_sddm_theme
install_grub_theme
build_llama
add_llama_ui
write_notes
fix_permissions
enable_sddm

