# Rice Cooker
Automated setup of a riced Arch Linux installation.

## Installation
Perform a basic archinstall with the Xorg (i3) or Sway for (Hyprland) profile depending on which rice you would like to install. After archinstall has finished drop into the chroot and clone the repository and execute the matching script.
```
#> archinstall
#> ..
#> git clone https://github.com/saiba-tenpura/rice-cooker
#> ./rice-cooker/post-install.sh i3-desktop
#> rm -rf ./rice-cooker
```

