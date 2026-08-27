# ~/.config/.secrets/

Machine-specific values kept out of git. Create the directory and populate the
files below; the scripts that read them degrade gracefully if they are missing.

| File | Read by | Contents |
|---|---|---|
| `notifications.token` | `waybar/scripts/github.sh` | GitHub PAT with `notifications` scope |
| `hostname.txt` | `waybar/scripts/connectssh.sh`, `tailscaleinfo.sh` | Tailscale hostname of the box to connect to |
| `ip-address.txt` | `waybar/scripts/wol.sh` | Broadcast IP for wake-on-LAN |
| `mac-address.txt` | `waybar/scripts/wol.sh` | MAC address of the machine to wake |
| `testserver.pass` | `scripts/testserver.sh`, `scripts/mount-servers.sh` | root password for the test server |
| `cobblemon.pass` | `scripts/cobblemon.sh`, `scripts/mount-servers.sh` | root password for the Cobblemon server |

```sh
mkdir -p ~/.config/.secrets && chmod 700 ~/.config/.secrets
printf 'ghp_xxx' > ~/.config/.secrets/notifications.token
chmod 600 ~/.config/.secrets/*
```

The `.pass` files are a stopgap — those two servers should move to SSH keys like
`agk` and `mrz` already have.
