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
    [[ -n "${conflicting}" ]] && pacman -R --noconfirm $conflicting

    packages=$(grep -s -v '^#' "${setup_dir}/pkgs.txt")
    install_packages $user $packages
    install_dotfiles $user $dotfiles_url
    [[ -n "${services}" ]] && install_services $services

    for group in ${groups}; do
        usermod -a -G $group $user
    done

    for func in ${user_setup}; do
        setup_$func $user
    done
}

install_packages() {
    # Usage: install_aur_packages "user" "packages"
    local user=$1 packages="${@:2}" temp_sudo

    temp_sudo="/etc/sudoers.d/01_temp"
    echo "${user} ALL=(ALL) NOPASSWD: ALL" > $temp_sudo

	su - "${user}" <<-EOF
	if ! type -p yay > /dev/null 2>&1; then
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
	curl -sO "${url/github/raw.githubusercontent}/master/install.sh"
	chmod 740 install.sh
	./install.sh ${url}
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

setup_x11_autologin() {
    # Usage: setup_xautologin "user"
    local user=$1

    setup_autologin $user "x11"
}

setup_wayland_autologin() {
    # Usage: setup_hyprland_autologin "user"
    local user=$1

    setup_autologin $user "wayland"
}

setup_autologin() {
    # Usage: setup_hyprland_autologin "user"
    local user=$1 type=$2

    mkdir -p /etc/systemd/system/getty@tty1.service.d
	cat <<-EOF > /etc/systemd/system/getty@tty1.service.d/override.conf
	[Service]
	Environment=XDG_SESSION_TYPE=${type}
	ExecStart=
	ExecStart=-/usr/bin/agetty -o '-p -f -- \\\\u' --noclear -a ${user} %I \$TERM
	EOF
}

setup_user_configs() {
    # Usage: setup_user_configs "user"
    local user=$1

	su - "${user}" <<-EOF
	# Generate Pywal cache for current wallpaper
	wal -i ~/wallpapers/current.png
	
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
