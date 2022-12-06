#!/usr/bin/env bash

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

setup_essential_services()
{
    systemctl enable cups.service
    systemctl enable dhcpcd.service
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
    if [[ $gpu_type =~ "NVIDIA|GeForce" ]]; then
        pacman -S --noconfirm --needed nvidia nvidia-xconfig
    elif [[ $gpu_type =~ "VGA.*(Radeon|AMD)" ]]; then
        pacman -S --noconfirm --needed xf86-video-amdgpu
    fi
}

main() {
    user="saiba"
    dotfiles_repo="https://github.com/saiba-tenpura/dotfiles"
    aur_pkgs="betterlockscreen"

    setup_yay $user $aur_pkgs
    setup_autologin $user
    setup_dotfiles $user $dotfiles_repo
    setup_user_configs $user
    setup_essential_services
}

main