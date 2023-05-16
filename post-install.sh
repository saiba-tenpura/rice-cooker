#!/usr/bin/env bash

main() {
    # Usage: main "setup_name"
    setup_name="$1"
    script_path="$(cd -- "$(dirname "$0")" >/dev/null 2>&1; pwd -P)"
    setup_dir="${script_path}/${setup_name}"
    if [[ ! -f "${setup_dir}/config.sh" ]]; then
        printf "Configuration files does not exist."
        exit 2
    fi

    source "${setup_dir}/config.sh" 
    packages=$(grep -s -v '^#' "${setup_dir}/pkgs.txt")
    aur_packages=$(grep -s -v '^#' "${setup_dir}/aur-pkgs.txt")

    [[ -n "${packages}" ]] && install_packages $packages
    install_aur_packages $user $aur_packages

    install_dotfiles $user $dotfiles_url
    [[ -n "${services}" ]] && install_services $services

    for func in "${user_install}"; do
        setup_$func $user
    done
}

install_packages() {
    # Usage: install_packages "packages"
    pacman -S --noconfirm --needed $@
}

install_aur_packages() {
    # Usage: install_aur_packages "user" "packages"
    local user=$1 packages="${@:2}" temp_sudo

    temp_sudo="/etc/sudoers.d/01_temp"
    echo "${user} ALL=(ALL) NOPASSWD: ALL" > $temp_sudo

	su - "${user}" <<-EOF
	if ! type -p yay &>/dev/null; then
	    git clone https://aur.archlinux.org/yay.git ~/yay
	    (cd ~/yay; makepkg --noconfirm -si > /dev/null 2>&1; rm -rf ~/yay)
	fi

	[[ -n "${packages}" ]] && yay -S --noconfirm --needed $packages
	EOF

    rm $temp_sudo
}

install_dotfiles() {
    # Usage: setup_dotfiles "user" "url"
    local user=$1 url=$2

	su - "${user}" <<-EOF
	curl -sO "${repository/github/raw.githubusercontent}/master/install.sh"
	chmod 744 install.sh
	./install.sh ${repository}
	EOF
}

install_services() {
    # Usage: install_services "services"
    for service in "$@"; do
        systemctl enable $service.service
    done
}

# Optional user setup steps

setup_ge_proton() {
    # Usage: setup_ge_proton "user"
    local user=$1

	su - "${user}" <<-EOF
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

setup_xautologin() {
    # Usage: setup_xautologin "user"
    local user=$1

    mkdir -p /etc/systemd/system/getty@tty1.service.d
	cat <<-EOF > /etc/systemd/system/getty@tty1.service.d/override.conf
	[Service]
	ExecStart=
	ExecStart=-/usr/bin/agetty -o '-p -f -- \\\\u' --noclear -a ${user} %I \$TERM
	EOF
}

setup_user_configs() {
    # Usage: setup_user_configs "user"
    local user=$1

	su - "${user}" <<-EOF
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
