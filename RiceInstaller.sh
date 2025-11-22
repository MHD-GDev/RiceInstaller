#!/bin/bash

RED='\e[31m'
GREEN='\e[32m'
YELLOW='\e[33m'
MAGENTA='\e[35m'
CYAN='\e[36m'
RESET='\e[0m'

function show_banner() {
    echo -e "${MAGENTA}"
    cat <<"EOF"
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

function check_sudo() {
    if [ "$(id -u)" = 0 ]; then
        echo -e "${RED}Do not run this script as root!${RESET}"
        exit 1
    fi
}

function choose_build_type() {
    while true; do
        echo -e "${YELLOW}Choose your build type:${RESET}"
        echo "1) Gaming"
        echo "2) Programming"
        echo "3) Both"
        read -rp "Enter choice [1-3]: " choice
        case "$choice" in
        1)
            BUILD_TYPE="gaming"
            break
            ;;
        2)
            BUILD_TYPE="programming"
            break
            ;;
        3)
            BUILD_TYPE="both"
            break
            ;;
        *) echo -e "${RED}Invalid choice. Try again.${RESET}" ;;
        esac
    done
    echo -e "${GREEN}Build type set to: $BUILD_TYPE${RESET}"
    sleep 2
    clear
}

function create_user_dirs() {
    until {
        echo -e "${YELLOW}Creating user directories...${RESET}"
        mkdir -p ~/Downloads ~/Documents ~/Pictures ~/Videos ~/Music ~/Desktop ~/Templates ~/MyNotes
        case "$BUILD_TYPE" in
        gaming) mkdir -p ~/Games ~/Emulations ;;
        programming) mkdir -p ~/Projects ;;
        both) mkdir -p ~/Projects ~/Games ~/Emulations ;;
        esac
    } do
        echo -e "${RED}Failed creating directories, retrying...${RESET}"
        sleep 2
    done
    echo -e "${GREEN}User directories created successfully!${RESET}"
    sleep 3
    clear
}

function install_packages() {
    until {
        echo -e "${YELLOW}Installing required packages...${RESET}"
        echo "Select your operating system:"
        echo "1) Arch"
        echo "2) Gentoo"
        read -rp "Enter choice [1-2]: " os_choice
        case "$os_choice" in
        1) current_os="Arch" ;;
        2) current_os="Gentoo" ;;
        *)
            echo -e "${RED}Invalid choice.${RESET}"
            false
            ;;
        esac

        if [[ "$current_os" == "Arch" ]]; then
            sudo pacman -Syu --noconfirm && sudo pacman -S --noconfirm git || false

            git clone https://aur.archlinux.org/paru.git && cd paru && makepkg -si --noconfirm || false
            cd ..

            if [[ -f arch-rice-wayland-packs.txt ]]; then
                paru -S --noconfirm $(<arch-rice-wayland-packs.txt) || false
                rustup default stable
            else
                echo -e "${RED}Missing arch-rice-wayland-packs.txt file!${RESET}"
                false
            fi

            echo "Select your GPU:"
            echo "1) Nvidia"
            echo "2) Intel"
            echo "3) AMD"
            echo "4) Hybrid"
            read -rp "Enter choice [1-4]: " gpu_choice

            case "$gpu_choice" in
            1) paru -S --noconfirm nvidia-cg-toolkit nvidia nvidia-utils cuda-tools cuda || false ;;
            2)
                paru -S --noconfirm vulkan-intel intel-oneapi-basekit || false
                # Post-install step: source oneAPI environment
                if [[ -f /opt/intel/oneapi/setvars.sh ]]; then
                    source /opt/intel/oneapi/setvars.sh
                    echo -e "${GREEN}Intel oneAPI environment initialized.${RESET}"
                else
                    echo -e "${RED}setvars.sh not found! Please check oneAPI installation.${RESET}"
                fi
                ;;
            3) paru -S --noconfirm amdsmi amdvlk radeontop radeontool || false ;;
            4)
                paru -S --noconfirm amdsmi amdvlk radeontop radeontool nvidia-cg-toolkit nvidia nvidia-utils cuda-tools cuda || false
                ;;
            *)
                echo -e "${RED}Invalid GPU choice.${RESET}"
                false
                ;;
            esac
        else
            echo -e "${GREEN}You're on Gentoo. Install packages manually from Gentoo-Rice-packages.md.${RESET}"
        fi
    }; do
        echo -e "${RED}Package installation failed, retrying...${RESET}"
        sleep 2
    done
    echo -e "${GREEN}Packages installed successfully!${RESET}"
    sleep 3
    clear
}

function copy_configs() {
    until {
        echo -e "${YELLOW}Copying rice directories...${RESET}"
        if [[ -d ConfigFiles ]]; then
            cp -r mhd-theme ~/.vscode/extensions
            rm -rf ~/.config/hypr && cp -r ConfigFiles/* ~/.config
            rm -rf ~/.config/fcitx5/profile && cp -r profile ~/.config/fcitx5
            if [[ "$BUILD_TYPE" == "programming" || "$BUILD_TYPE" == "both" ]]; then
                echo "experimental-features = nix-command flakes" | sudo tee -a /etc/nix/nix.conf >/dev/null
                sudo systemctl restart nix-daemon
            fi
            FILE="$HOME/.config/fcitx5/profile"
            FSTYPE=$(df --output=fstype "$FILE" | tail -1)
            if [[ "$FSTYPE" == ext2 || "$FSTYPE" == ext3 || "$FSTYPE" == ext4 ]]; then
                chattr +i "$FILE"
            fi
        else
            echo -e "${RED}Missing ConfigFiles directory!${RESET}"
            false
        fi
    }; do
        echo -e "${RED}Copy configs failed, retrying...${RESET}"
        sleep 2
    done
    echo -e "${GREEN}Config directories copied!${RESET}"
    sleep 3
    clear
}

function copy_zshrc() {
    until {
        echo -e "${YELLOW}Copying .zshrc into user's directory...${RESET}"
        if [[ -f .zshrc ]]; then
            cp -r .zshrc ~ && sudo cp -r plugins /usr/share/zsh/
            cp -r fonts ~/.local/share
            mkdir .bash && mv .bash_logout .bashrc .bash_profile .bash
            chsh -s $(which zsh)
        else
            echo -e "${RED}.zshrc file missing!${RESET}"
            false
        fi
    }; do
        echo -e "${RED}Copy zshrc failed, retrying...${RESET}"
        sleep 2
    done
    echo -e "${GREEN}.zshrc copied successfully!${RESET}"
    sleep 3
    clear
}

function install_sddm_theme() {
    until {
        echo -e "${YELLOW}Installing the SDDM theme...${RESET}"
        echo "1) Yes"
        echo "2) No"
        read -rp "Enter choice [1-2]: " sddm_ans
        case "$sddm_ans" in
        1)
            git clone https://github.com/stepanzubkov/where-is-my-sddm-theme.git
            cd where-is-my-sddm-theme && sudo cp -r where_is_my_sddm_theme /usr/share/sddm/themes
            cd ../ && sudo cp -r sddm.conf /etc/
            ;;
        2) ;;
        *)
            echo -e "${RED}Invalid choice.${RESET}"
            false
            ;;
        esac
    } do
        echo -e "${RED}SDDM theme failed, retrying...${RESET}"
        sleep 2
    done
    echo -e "${GREEN}SDDM theme installed successfully or skipped.${RESET}"
    sleep 3
    clear
}

function install_grub_theme() {
    until {
        echo -e "${YELLOW}Installing GRUB theme...${RESET}"
        echo "1) Yes"
        echo "2) No"
        read -rp "Enter choice [1-2]: " grub_theme
        case "$grub_theme" in
        1)
            if [[ -d yorha-1920x1080 ]]; then
                sudo cp -r yorha-1920x1080 /boot/grub/themes
                sudo sed -i '/^#*GRUB_THEME=/d' /etc/default/grub
                echo 'GRUB_THEME="/boot/grub/themes/yorha-1920x1080/theme.txt"' | sudo tee -a /etc/default/grub >/dev/null
                sudo grub-mkconfig -o /boot/grub/grub.cfg
            fi
            ;;
        2) ;;
        *)
            echo -e "${RED}Invalid choice.${RESET}"
            false
            ;;
        esac
    } do
        echo -e "${RED}GRUB theme failed, retrying...${RESET}"
        sleep 2
    done
    echo -e "${GREEN}GRUB theme installed successfully or skipped.${RESET}"
    sleep 3
    clear
}

function build_llama() {
    echo -e "${YELLOW}Do you want to build llama.cpp for local LLMs?${RESET}"
    echo "1) Yes"
    echo "2) No"
    read -rp "Enter choice [1-2]: " llama_ans
    case "$llama_ans" in
    1)
        LLAMA_BUILT="yes"
        until {
            echo -e "${YELLOW}Building llama.cpp...${RESET}"
            cd ~/Templates || false
            git clone https://github.com/ggml-org/llama.cpp.git || false
            cd llama.cpp || false
            while true; do
                echo -e "${YELLOW}Choose build type:${RESET}"
                echo "1) CUDA (Nvidia)"
                echo "2) CPU"
                echo "3) AMD (Vulkan)"
                echo "4) Intel (SYCL/oneAPI)"
                read -rp "Choice (1-4): " build_choice
                case "$build_choice" in
                1) cmake -B build -DGGML_CUDA=ON && cmake --build build --config Release && break ;;
                2) cmake -B build -DBUILD_SHARED_LIBS=off && cmake --build build --config Release && break ;;
                3) paru -S --noconfirm vulkan-extra-layers vulkan-tools vulkan-headers && cmake -B build -DGGML_VULKAN=ON && cmake --build build --config Release && break ;;
                4)
                    echo -e "${GREEN}Intel SYCL build selected.${RESET}"
                    cmake -B build -DGGML_SYCL=ON && cmake --build build --config Release && break
                    ;;
                *) echo -e "${RED}Invalid choice. Try again.${RESET}" ;;
                esac
            done
            mkdir -p ~/.config/AI
            mv ~/Templates/llama.cpp ~/.config/AI
            mkdir -p ~/.local/bin/
            mv ~/.config/AI/llama.cpp/build/bin/{llama-cli,llama-server} ~/.local/bin/
            mkdir -p ~/.local/share/AI-Models
        }; do
            echo -e "${RED}llama.cpp build failed, retrying...${RESET}"
            sleep 2
        done
        echo -e "${GREEN}llama.cpp build complete!${RESET}"
        sleep 3
        clear
        ;;
    2)
        LLAMA_BUILT="no"
        echo -e "${CYAN}Skipping llama.cpp build.${RESET}"
        ;;
    *)
        LLAMA_BUILT="no"
        echo -e "${RED}Invalid choice. Skipping llama.cpp build.${RESET}"
        ;;
    esac
}

function add_llama_ui() {
    # Only run if llama.cpp was built
    if [[ "$LLAMA_BUILT" != "yes" ]]; then
        echo -e "${CYAN}Skipping custom UI because llama.cpp was not built.${RESET}"
        return
    fi

    until {
        echo -e "${YELLOW}Adding custom UI for llama.cpp...${RESET}"
        if [[ -f ~/Templates/RiceInstaller/LlamaUI-vMHD.html ]]; then
            mv ~/Templates/RiceInstaller/LlamaUI-vMHD.html ~/.config/AI
        else
            echo -e "${RED}Custom UI file missing!${RESET}"
            false
        fi
    }; do
        echo -e "${RED}Adding custom UI failed, retrying...${RESET}"
        sleep 2
    done
    echo -e "${GREEN}Custom UI added successfully!${RESET}"
    sleep 3
    clear
}

function write_notes() {
    until {
        echo -e "${CYAN}Writing installation notes...${RESET}"
        echo -e "- REMEMBER: Copy your AI models into ~/.local/share/AI-Models" >>~/Templates/IMPORTANT-README.md
        echo -e "- Use llama.cpp via the LlamaUI-vMHD.html in your browser." >>~/Templates/IMPORTANT-README.md
        echo -e "- Plans and notes in ~/MyNotes, also you can use todo command." >>~/Templates/IMPORTANT-README.md
    }; do
        echo -e "${RED}Writing notes failed, retrying...${RESET}"
        sleep 2
    done
    sleep 5
    clear
}

function fix_permissions() {
    until {
        echo -e "${YELLOW}Fixing file permissions...${RESET}"
        sudo chown -R "$(whoami)":"$(whoami)" ~/.zshrc ~/.config ~/.local
    }; do
        echo -e "${RED}Fixing permissions failed, retrying...${RESET}"
        sleep 2
    done
    echo -e "${GREEN}Permissions updated!${RESET}"
    sleep 3
    clear
}

function finish_and_restart() {
    echo -e "${YELLOW}Installation finished.${RESET}"
    echo "Do you want to restart now with sddm enabled?"
    echo "1) Yes"
    echo "2) No"
    read -rp "Enter choice [1-2]: " restart_choice
    case "$restart_choice" in
    1)
        until {
            sudo systemctl enable sddm && sudo reboot
        }; do
            echo -e "${RED}Failed to enable sddm or reboot, retrying...${RESET}"
            sleep 2
        done
        ;;
    2)
        echo -e "${CYAN}Exiting without restart.${RESET}"
        exit 0
        ;;
    *)
        echo -e "${RED}Invalid choice. Exiting.${RESET}"
        exit 1
        ;;
    esac
}

#-----------------------#
# RUN SCRIPT SECTIONS   #
#-----------------------#
show_banner
check_sudo
choose_build_type
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
finish_and_restart
