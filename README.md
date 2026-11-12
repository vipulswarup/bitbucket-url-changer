# bitbucket-url-changer

Bitbucket Cloud is moving SSH traffic from `bitbucket.org` to `ssh.bitbucket.org` (effective Nov 12, 2026).
This script rewrites the SSH remotes of every git repo under a folder.

```bash
./bitbucket-ssh-migrate.sh --dry-run ~/code   # preview
./bitbucket-ssh-migrate.sh ~/code             # apply
```

- Rewrites `git@bitbucket.org:ws/repo.git` and `ssh://git@bitbucket.org/...` (`url` and `pushurl`, all remotes).
- Leaves HTTPS and non-Bitbucket remotes alone.
- Does not touch `~/.ssh/config` (change `Host bitbucket.org` to `Host ssh.bitbucket.org` yourself) or `.gitmodules`.

Announcement: https://community.atlassian.com/forums/Bitbucket-articles/Upcoming-change-to-Bitbucket-Cloud-SSH-access-move-from/ba-p/3234032
