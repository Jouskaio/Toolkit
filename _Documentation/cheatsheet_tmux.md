# Cheatsheet tmux - Sessions that survive a lost connection

The prefix is `Ctrl+b`: press it, release, then the key.

## Sessions (from the shell)

| Topic   | Command | Command details              | Description                                       |
|---------|---------|------------------------------|---------------------------------------------------|
| start   | tmux    | `tmux new -s work`           | New session called `work`                         |
| list    | tmux    | `tmux ls`                    | The sessions that are running                     |
| attach  | tmux    | `tmux attach -t work`        | Go back to a session (after an SSH drop too)      |
| stop    | tmux    | `tmux kill-session -t work`  | End a session                                     |

## Inside tmux (after the prefix)

| Keys          | Description                                  |
|---------------|----------------------------------------------|
| `d`           | Detach: the session keeps running            |
| `c`           | New window                                   |
| `n` / `p`     | Next / previous window                       |
| `0`..`9`      | Go to a window by its number                 |
| `,`           | Rename the window                            |
| `%`           | Split into two side by side                  |
| `"`           | Split into two, one above the other          |
| arrow keys    | Move between the panes                       |
| `z`           | Zoom a pane (again to go back)               |
| `x`           | Close the pane                               |
| `[`           | Scroll mode (`q` to leave, arrows or PgUp)   |

## Tip with the SSH menu

On a flaky connection, connect with the Toolkit menu and run `tmux new -A -s main`: it opens the session `main`, or re-attaches it.
