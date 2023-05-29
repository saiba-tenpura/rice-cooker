# Main user
user="saiba"

# Additional groups the user is added to
groups=""

# Repository of dotfiles which should be installed
dotfiles_url="https://github.com/saiba-tenpura/dotfiles"

# systemd services to enable by default
services="bluetooth cronie cups dhcpcd libvirtd"

# Optional user setup steps to include
# 
# Available options:
# ge_proton    - Install the latest GE Proton
# user_configs - Initialise user setup
# xautologin   - Setup autologin for Xorg Server
user_setup="ge_proton user_configs x11_autologin"

