#!/usr/bin/env bash

# Install AUR helper & AUR packages
install_aur() {
    # Usage: install_aur <user> <aur_pkgs>
	su - "${1}" <<-EOF
	git clone https://aur.archlinux.org/yay.git ~/yay
	(cd ~/yay; makepkg --noconfirm -si > /dev/null 2>&1; rm -rf ~/yay)
	yay --noconfirm -S ${2} > /dev/null 2>&1
	EOF
}

autologin() {
    # Usage: autologin <user>
    mkdir -p /etc/systemd/system/getty@tty1.service.d
	cat <<-EOF > /etc/systemd/system/getty@tty1.service.d/override.conf
	[Service]
	ExecStart=
	ExecStart=-/usr/bin/agetty -a ${1} --noclear %I \$TERM
	EOF
}

dotfiles() {
    # Usage: dotfiles <user> <dotfiles_repo>
	su - "${1}" <<-EOF
	curl -sO "${2/github/raw.githubusercontent}/master/install.sh"
	chmod 744 install.sh
	./install.sh ${2}
	EOF
}

main() {
    user="saiba"
    dotfiles_repo="https://github.com/saiba-tenpura/dotfiles"
    aur_pkgs="betterlockscreen"
    install_aur $user $aur_pkgs
    autologin $user
    dotfiles $user $dotfiles_repo
}

main
