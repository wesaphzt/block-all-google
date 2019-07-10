# block-all-google.sh

## Overview
This BASH (Linux) script simplifies the process of cutting Google out of your digital life.

This will block all Google services - GMail, YouTube, Google Play, ads, tracking and so on, both good and bad.
It's worth noting that any sites that depend on Google to serve their content most likely will break, or at a minimum not function properly.

It works by adding all the downloaded Google IP ranges to the routing table, which get routed to localhost and thus stays local to your machine and doesn't reach any Google servers.

Tested on Ubuntu 18.04 only.

Contacts third-party network services to retrieve proxies and IP ranges.

If you don't agree to their respective terms of service (ToS), don't use the script or modify it to suit your needs.

## Using the script
Using the terminal, navigate to the directory where the script is; e.g;
```
cd $HOME/Downloads
```

Make the script executable
```
chmod +x block-all-google.sh
```

The script needs to be run as root to be able to modify the routing table, and takes an argument to either block or unblock Google.
To avoid issues where Google has already been blocked, it will attempt to download the IP ranges through proxies when unreachable.

To block Google;
```
sudo ./block-all-google.sh -b
```

To unblock Google;
```
sudo ./block-all-google.sh -u
```

## Scheduling
Regular updating of the Google IP range list can be scheduled through crontab.

Open the root crontab;
```
sudo crontab -e
```

Add the crontab, e.g;
```
# block-all-google
00 18 * * 7 "$HOME/Scripts/block-all-google.sh -b"
```

This example will run the script every Sunday at 6:00pm.

To add logging;
```
# block-all-google
00 18 * * 7 "$HOME/Scripts/block-all-google.sh -b" >> /var/log/block-all-google.cron.log 2>&1
```
Save and exit.

## Improvements
Code improvements and refinements, reporting issues or general suggestions are welcomed, using the issue tracker https://github.com/wesaphzt/block-all-google/issues.

## Unlicense
Unlicensed.
See [UNLICENSE](https://github.com/wesaphzt/block-all-google/UNLICENSE) for more information.
