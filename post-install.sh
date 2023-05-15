#!/usr/bin/env bash

main() {
    config_dir="$1"
    script_path="$(cd -- "$(dirname "$0")" >/dev/null 2>&1; pwd -P)"
    packages=$(grep -s -v '^#' "${script_path}/${config_dir}/pkgs.txt")
    aur_packages=$(grep -s -v '^#' "${script_path}/${config_dir}/aur-pkgs.txt")
    user="saiba"
    dotfiles_repo="https://github.com/saiba-tenpura/dotfiles"

    [[ -n "${packages}" ]] && install_packages
    install_aur_packages
    install_ge_proton
    setup_yay $user $aur_pkgs
    setup_additional_services
    setup_autologin $user
    setup_dotfiles $user $dotfiles_repo
    setup_user_configs $user
}

install_packages() {
    pacman -S --noconfirm --needed $packages
}

install_aur_packages() {
    temp_sudo="/etc/sudoers.d/01_temp"
    echo "${user} ALL=(ALL) NOPASSWD: ALL" > $temp_sudo

	su - "${user}" <<-EOF
	if ! type yay > /dev/null 2>&1; then
	    git clone https://aur.archlinux.org/yay.git ~/yay
	    (cd ~/yay; makepkg --noconfirm -si > /dev/null 2>&1; rm -rf ~/yay)
	fi

	[[ -n "${aur_packages}" ]] && yay -S --noconfirm --needed $aur_packages
	EOF

    rm $temp_sudo
}

install_ge_proton() {
	su - ${user} <<-EOF
	json=\$(curl -s 'https://api.github.com/repos/GloriousEggroll/proton-ge-custom/releases/latest')
	[[ \$json =~ .*(https.*\.tar\.gz).* ]] && url="\${BASH_REMATCH[1]}"
	filename="\${url##*/}"
	steam_dir=\$HOME/.steam/root/compatibilitytools.d
	mkdir -p "\$steam_dir"
	cd "\$steam_dir"
	curl -sLO "\$url"
	hash=\$(curl -Lf \${url//.tar.gz/.sha512sum})
	if printf '%s' "\${hash%% *} \${filename}" | sha512sum -c -; then
	    tar -xf "\$filename"
	fi

	rm "\$filename"
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

setup_additional_services() {
    systemctl enable bluetooth.service
    systemctl enable libvirtd.service
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

main "$1"
