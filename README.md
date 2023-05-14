# Rice Cooker
Automated setup of a riced Arch Linux installation.

## Execution
To run the installation just define variable for where the configuration files are stored in the repository and then run archinstall with it as parameters.
```
#> repo_url="https://raw.githubusercontent.com/saiba-tenpura/rice-cooker/main/archinstall"
#> archinstall --config "${repo_url}/configuration.json"
```

