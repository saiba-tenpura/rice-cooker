#!/usr/bin/env bash

main() {
    user="saiba"
    dotfiles_repo="https://github.com/saiba-tenpura/dotfiles"
    aur_pkgs="betterlockscreen"

    install_base_dependencies
    install_additional_software
    setup_yay $user $aur_pkgs
    setup_autologin $user
    setup_dotfiles $user $dotfiles_repo
    setup_user_configs $user
}

install_base_dependencies()
{
    install_rice_dependencies
    install_personal_software
}

install_rice_dependencies() {
    pacman -S --noconfirm --needed calc dunst feh i3-gaps libnotify neovim nnn papirus-icon-theme picom polkit polybar python-pywal rofi rxvt-unicode ttc-iosevka xorg-xset zathura zathura-pdf-mupdf
}

install_cpu_microcode() {
    proc_type=$(lscpu)
    if [[ $proc_type =~ "GenuineIntel" ]]; then
        pacman -S --noconfirm --needed intel-ucode
    elif [[ $proc_type =~ "AuthenticAMD" ]]; then
        pacman -S --noconfirm --needed amd-ucode
    fi
}

install_gpu_drivers() {
    gpu_type=$(lspci)
    if grep -E "NVIDIA|GeForce" <<< ${gpu_type}; then
        pacman -S --noconfirm --needed nvidia nvidia-xconfig
    elif lspci | grep 'VGA' | grep -E "Radeon|AMD"; then
        pacman -S --noconfirm --needed xf86-video-amdgpu vulkan-radeon lib32-vulkan-radeon
    elif grep -E "Integrated Graphics Controller" <<< ${gpu_type}; then
        pacman -S --noconfirm --needed libva-intel-driver libvdpau-va-gl lib32-vulkan-intel vulkan-intel libva-intel-driver libva-utils lib32-mesa
    elif grep -E "Intel Corporation UHD" <<< ${gpu_type}; then
        pacman -S --needed --noconfirm libva-intel-driver libvdpau-va-gl lib32-vulkan-intel vulkan-intel libva-intel-driver libva-utils lib32-mesa
    fi

    pacman -S --noconfirm --needed mesa lib32-mesa
}

install_additional_software() {
    install_administration_tools
    install_wine
    install_retroarch
    setup_additional_services
}

install_administration_tools() {
    pacman -S --noconfirm --needed htop lm_sensors openssh openvpn restic rsync udiskie udisks2 virt-manager
}

install_wine() {
    pacman -S --noconfirm --needed wine-staging giflib lib32-giflib libpng lib32-libpng libldap lib32-libldap gnutls lib32-gnutls mpg123 lib32-mpg123 openal lib32-openal v4l-utils lib32-v4l-utils libpulse lib32-libpulse libgpg-error lib32-libgpg-error alsa-plugins lib32-alsa-plugins alsa-lib lib32-alsa-lib libjpeg-turbo lib32-libjpeg-turbo sqlite lib32-sqlite libxcomposite lib32-libxcomposite libxinerama lib32-libgcrypt libgcrypt lib32-libxinerama ncurses lib32-ncurses opencl-icd-loader lib32-opencl-icd-loader libxslt lib32-libxslt libva lib32-libva gtk3 lib32-gtk3 gst-plugins-base-libs lib32-gst-plugins-base-libs vulkan-icd-loader lib32-vulkan-icd-loader
}

install_retroarch() {
    pacman -S --noconfirm --needed retroarch retroarch-assets-xmb
}

install_personal_software() {
    pacman -S --noconfirm --needed bluez bluez-utils firefox libreoffice lutris obsidian remmina signal-desktop steam thunderbird
}

setup_yay() {
    # Usage: setup_yay <user> <aur_pkgs>
    temp_sudo="/etc/sudoers.d/01_temp"
    printf "${1} ALL=(ALL) NOPASSWD: ALL" > $temp_sudo

	su - "${1}" <<-EOF
	git clone https://aur.archlinux.org/yay.git ~/yay
	(cd ~/yay; makepkg --noconfirm -si > /dev/null 2>&1; rm -rf ~/yay)
	yay --noconfirm -S ${2} > /dev/null 2>&1
	EOF

    rm $temp_sudo
}

setup_additional_services() {
    systemctl enable bluetooth.service
}

setup_autologin() {
    # Usage: setup_autologin <user>
    mkdir -p /etc/systemd/system/getty@tty1.service.d
	cat <<-EOF > /etc/systemd/system/getty@tty1.service.d/override.conf
	[Service]
	ExecStart=
	ExecStart=-/usr/bin/agetty -o '-p -f -- \\\\u' --noclear -a ${1} %I \$TERM
	EOF
}

setup_dotfiles() {
    # Usage: setup_dotfiles <user> <dotfiles_repo>
	su - "${1}" <<-EOF
	curl -sO "${2/github/raw.githubusercontent}/master/install.sh"
	chmod 744 install.sh
	./install.sh ${2}
	EOF
}

setup_user_configs() {
    # Usage: setup_user_configs <user>
	su - "${1}" <<-EOF
	# Generate Pywal cache for current wallpaper
	wal -i ~/wallpapers/current
	
	# Setup additional fonts
	mkdir -p ~/.local/share/fonts
	cp -rf ~/fonts/* ~/.local/share/fonts
	
	# Install vim-plug for Neovim
	curl -fLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
	
	# Install Neovim Plugins
	nvim --headless +PlugInstall +qall
	EOF
}

main