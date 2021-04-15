# push-update_min
Portable version of push_update for RevengeOS official devices.

Usage:
-------
Run into WSL/your preferred Linux terminal: `bash push.sh`.
It'll ask automatically for all the required values: sourceforge's username, device codename.
Remember to put `changelog.txt` and, if needed, `notes.txt`.
The script will act differently in some cases:
- If the .zip file exists in your folder (or multiple ones), then it'll automatically pick the newer one.
- If the .zip file doesn't exist, then it'll be downloaded from the RevengeOS's CI server.

Automation:
-------
You can automate part of the process by adding a `push_config.conf` file right where the script is located.
An example is provided into the `sample_push_config.conf` file.

Dependencies:
-------
Deps required: `python3 wget`