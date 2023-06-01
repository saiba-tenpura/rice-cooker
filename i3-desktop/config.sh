# Main user
user="saiba"

# Additional groups the user is added to
groups=""

# Repository of dotfiles which should be installed
dotfiles_url="https://github.com/saiba-tenpura/dotfiles"

# Conflicting packages to remove
conflicting=""

# systemd services to enable by default
services="bluetooth cronie cups dhcpcd libvirtd"

# Optional user setup steps to include
# 
# Available options:
# ge_proton         - Install the latest GE Proton
# user_configs      - Initialise user setup
# x11_autologin     - Setup autologin for Xorg Server
# wayland_autologin - Setup autologin for Wayland
user_setup="ge_proton user_configs x11_autologin"

