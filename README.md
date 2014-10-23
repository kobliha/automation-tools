# Bugzilla Tools

This project has started as a [HackWeek](https://hackweek.suse.com/) project.
It currently contains just one tool...

## needinfo-checker.rb

Connects to bugzilla.suse.com checks whather any bug is waiting for some
information from the given e-mail address (login). If any bug is found,
the needinfo-checker created new e-mail, just ready to be sent to the
usual suspect.

Example of usage:

```bash
#!/bin/bash

for login in bugzilla_login_1 bugzilla_login_2 bugzilla_login_3; do
  echo "Checking needinfo for ${login}"
  checker_out=`ruby needinfo-checker.rb ${login}@suse.com`

  if [ "${checker_out}" != "" ]; then
    recipient="${login}@suse.com"
    echo "Sending e-mail to ${recipient}"
    echo -e "${checker_out}" \
      | mailx -r mail_from@address.org \
        -s "Bugzilla: Information Still Needed" \
        ${recipient}
  fi
done
```

Server configuration can be kept in your home directory in *~/.bugzilla.conf* file:

```yaml
---
https://bugzilla.suse.com:
  user: user-name
  pass: YourU$erPa$$word
```
