#!/usr/bin/env bash

install_yay() {
    # Usage: install_yay <user> <aur_pkgs>
	su - "${1}" <<-EOF
	git clone https://aur.archlinux.org/yay.git ~/yay
	(cd ~/yay; makepkg --noconfirm -si > /dev/null 2>&1; rm -rf ~/yay)
	yay --noconfirm -S ${2} > /dev/null 2>&1
	EOF
}

setup_autologin() {
    # Usage: setup_autologin <user>
    mkdir -p /etc/systemd/system/getty@tty1.service.d
	cat <<-EOF > /etc/systemd/system/getty@tty1.service.d/override.conf
	[Service]
	ExecStart=
	ExecStart=-/usr/bin/agetty -a ${1} --noclear %I \$TERM
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

setup_network() {
    systemctl enable dhcpcd > /dev/null
}

setup_user_configs() {
    # Generate Pywal cache for current wallpaper
    wal -i ~/wallpaper/current

    # Install vim-plug for Neovim
    curl -fLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

    # Install Neovim Plugins
    nvim --headless +PlugInstall +qall
}

main() {
    user="saiba"
    dotfiles_repo="https://github.com/saiba-tenpura/dotfiles"
    aur_pkgs="betterlockscreen ttf-icomoon-feather"
    install_yay $user $aur_pkgs
    setup_autologin $user
    setup_dotfiles $user $dotfiles_repo
    setup_network

    export -f setup_user_configs
    su $user -c "bash setup_user_configs"
}

main