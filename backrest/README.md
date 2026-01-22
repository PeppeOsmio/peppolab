## SFTP

For SFTP for example on Hetzner, put the client (Backrest) ssh key pair in /docker_data/backrest/configs/ssh.
Then create the repo with the credentials from Hetzner.
Then put this env variable `RESTIC_SFTP_ARGS="-i /root/.ssh/id_ed25519 -o IdentitiesOnly=yes"`.

then before the snapshot run:

`/scripts/before_backup.sh {{ .Plan.Id }}`

After the snapshot run:

`/scripts/after_backup.sh {{ .Plan.Id }}`
