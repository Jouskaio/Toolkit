# Cheatsheet Linux - Basic commands

## Navigation

| Topic       | Command | Command details                                   | Description                                                       |
|-------------|---------|---------------------------------------------------|-------------------------------------------------------------------|
| folder/file | find    | `find / -type d -name "apt"`                      | Find a directory called "apt" in root file system                 |
| folder/file | find    | `find . print`                                    | Print all files in current direction                              |
| folder/file | find    | `find / criteria action 2/dev/null` \             | If getting "Permission denied", add `2>/dev/null`                 |
| folder/file | find    | `sudo find $HOME -type d -name "apt" 2>/dev/null` | If getting "Permission denied", add `2>/dev/null`                 |
| folder/file | find    | `find / -name "apt" -ls`                          | List all apt file/folder in ls command output                     |
| filter      | grep    | `grep -i --color=always wordSearched`             | Search the case insensitive word "wordSearch" with colored output |
| filter      | grep    | `grep err /var/log/*`                             | Search all error pattern in this folder "non recursive"           |
| filter      | grep    | `grep -r -n cow *`                                | Recursive search in all folder with line number                   |
| filter      | grep    | `grep -v vache /tmp/test `                        | Search for all lines who does not contain the word vache          |
| filter      | grep    | `grep -m2 vache /tmp/test`                        | Limit the search to only 2 elements                               |
| filter      | grep    | `grep -l "sl.h" *.c`                              | Search .c files with sl.h reference in it                         |
| filter      | grep    | `grep -c err /var/log/messages*`                  | Count occurrences of error pattern in this folder                 |
| filter      | grep    |                                                   |                                                                   |


## Performance

| Topic   | Command | Command details | Description                                                                                   |
|---------|---------|-----------------|-----------------------------------------------------------------------------------------------|
| process | top     | `top`           | Display dynamically the top all the running and active real-time processes in an ordered list |
| process | ps      | `ps -aux`       | Display process currently running (not dynamic)                                               |
| process | lsof    | `lsof I less`   | Display all scripts/task/process running                                                      |                                                                                      |                                                                                               |
|         |         |                 |                                                                                               |
