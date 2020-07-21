# homelab_automation
Some of the automation I use for my homelab

The cryptovault is a plugin for cockpit. It relies on a .img file that contains a LUKS container. The container has a password that the user knows, and is typed in on the cockpit page. For security, the password is written to a file in the /tmp folder and passed to the LUKS container opening utility as the password, then deleted. The use case for this cryptovault is for a secure enclave that the user wishes to have available only during specific times; i.e. a sub-folder in a shared drive or FTP share which the user wants to access, but doesn't want the contents available all the time, in case of issues such as a nosy user on the network or malware scanning the share for interesting documents.

The nightly_nvme script exists to give data protection for content on the very fast drive in the system. The contents of several specific locations are tarball'd and written to the slower, snapraid protected array of spinning disks. Weekly, monthly and yearly 'snapshots' are also maintained, to allow for recovery at a future date.

The snapraid_nightly script is one that I found and added to in order to give me a nightly update of the state of the snapraid-protected array of disks. It also performs automatic sync and scrub actions in the event that I forget to do this myself after adding new data. It sends an email using the mutt tool. I run these scripts with cron overnight.
