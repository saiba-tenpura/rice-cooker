#!/usr/bin/env bash

configure_autologin() {
    # Usage: configure_autologin

    mkdir -p /etc/systemd/system/getty@tty1.service.d
	cat <<-EOF > /etc/systemd/system/getty@tty1.service.d/override.conf
	[Service]
	ExecStart=
	ExecStart=-/usr/bin/agetty -a ${1} --noclear %I \$TERM
	EOF
}

post() {
    user="saiba"
    configure_autologin $user
}

while [ $# -gt 0 ]; do
    case "$1" in
        -p)
            post
            ;;
   esac
done

archinstall \
    --config archinstall/user_configuration.json \
    --creds archinstall/user_credentials.json \
    --disk-layout archinstall/user_disk_layout.json

