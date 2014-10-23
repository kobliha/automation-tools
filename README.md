# Bugzilla Tools

This project has started as a [HackWeek](https://hackweek.suse.com/) project.
It currently contains just one tool...

## needinfo-checker.rb

Connects to a given bugzilla URL, checks whether any bug is waiting for some
information from the given e-mail address (login). If any bug is found,
the needinfo-checker creates new e-mail text, just ready to be sent to the
usual suspect, e.g., using *mailx*.

Example of usage:

```bash
#!/bin/bash

for login in login_1 login_2 login_3; do
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

If such file exists and contains just one configuration, it's automatically
used. If there are more server configuration, you have to choose one by defining
the second parameter for the script:

```bash
ruby needinfo-checker.rb e-mail@address.org https://bugzilla.url.org
```
