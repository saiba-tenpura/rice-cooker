# Rice Cooker
Automated setup of [my](https://github.com/saiba-tenpura/dotfiles) riced Arch Linux installation.

## Installation
Perform a basic archinstall with the minimal profile preset.
```
#> archinstall
#> ...
```

After archinstall has finished drop into the chroot, clone the repository and execute the script with the intended type (e.g. i3-desktop, hyprland, hyprland-laptop).
```
#> sudo pacman -S git
#> git clone https://github.com/saiba-tenpura/rice-cooker
#> ./rice-cooker/post-install.sh [type]
#> rm -rf ./rice-cooker
```

