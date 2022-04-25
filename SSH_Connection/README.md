# Toolkit - Quick connexion to ssh servers

## Execution

To execute the file, please run the following command `./ssh_keyloading.sh` and make sure to be on bash / zsh console.
Some trouble can be experienced if the script is used on Windows software. If so, please check the path where ssh key are stocked and make sure you have a recent version of bash.

When running, please select the server you want then enter your sudo password.
To leave the console, do Ctl+D or write logout.

If you need to modify some information, please edit the keys.json file.

### Troubles

* If the code can't insert data on the JSON file, you need to make file writable for the script with this command `sudo chmod a+x keys.json`
* Sometimes the program could end like this :
  ``` bash
   client_loop: send disconnect: Broken pipe
    ./ssh_keyloading.sh: line 158: unexpected EOF while looking for matching `"'
    ./ssh_keyloading.sh: line 161: syntax error: unexpected end of file
  ```
  Don't worry, this appears when you are connected to the server for too long or if your Wi-Fi / Ethernet connexion lagged. The loop is therefore broken which make these errors.

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

### Version 1.1 : With the console

Select the "Insert_new_connection" then follow the few steps to save this new connection then connect to your server.
You will only need the absolute path to your private key somewhere in your file. Don't worry, you don't need to manually move it in your "~/.ssh" folder, the program will do it for you.
