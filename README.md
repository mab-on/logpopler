# LogPopler
Dig for wisdom in logfiles (or input stream). 🤓

## Examples

Get a list of invalid usernames that was used at least 3 times in login attempts in the last 24h
```
$ journalctl -u sshd -S-24h | logpopler 'Invalid user ([^\s]+)' --min 3
postgres
server
admin
steam
ubuntu
user
test
git
...
```

Get the most requested routes for GET and POST from a access.log
```
$ cat ./access.log | logpopler '(?:GET|POST) (/[^\s]+)' --show-count | sort -rn
98	/index.php/204
49	/ocs/v2.php/cloud/capabilities
28	/ocs/v2.php/apps/spreed/api/v1/signaling/settings
24	/ocs/v2.php/apps/notifications/api/v2/notifications
12	/apps/richdocumentscode/proxy.php?req=/hosting/capabilities
...
```

Add IP-Addresses to a firewall-dropzone from which smtp authentications failed at least 2 times in the past 3 days
```
$ journalctl -u postfix -S -3d | \
grep 'authentication failed' | \
logpopler --min 2  '\[([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)\]' | \
while read line; do /usr/bin/firewall-cmd -q --permanent --ipset=smtpd_auth_failed --add-entry="$line"; done;
```