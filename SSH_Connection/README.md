# Toolkit - Quick connexion to ssh servers

## Execution

To execute the file, please run the following command `./ssh_keyloading.sh` and make sure to be on bash / zsh console.
Some trouble can be experienced if the script is used on Windows software. If so, please check the path where ssh key are stocked and make sure you have a recent version of bash.

When running, please select the server you want then enter your sudo password.
To leave the console, do Ctl+D or write logout.

If you need to modify some information, please edit the keys.json file.

## Add a new connection

### Version 1.0 : Add manually

For now, we have to add manually in the ssh folder the new key then add a new element in the array JSON like this :
``` json
    {
            "name" : "Name without space (one word)",
            "key" : "Name of the file in ssh folder (with extension)",
            "port" : "Port",
            "client": "Name of the client"
    }
```

### Version 1.2 : With the console
