# Bugzilla Tools

This project has started as a [HackWeek](https://hackweek.suse.com/) project
to automate as much as possible. And because people tend to forget, the first
focus were tools to remind users that someone is waiting for info from them.

## needinfo-checker

Connects to a given bugzilla URL, checks whether any bug is waiting for some
information from the given e-mail address (login). If any bug is found,
the needinfo-checker creates new e-mail text, just ready to be sent to the
usual suspect, e.g., using *mailx*.

Required rubygems: nokogiri, xml-simple, yaml

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

## fate-checker

Connects to a FATE instance and checks whether there is an info requested from
a given person (login, e-mail, or full name). If such features are found, the
script generates text for an e-mail informing the user to provide the requested
info.

Required rubygems: crack, yaml

```bash
#!/bin/bash

for login in login_1 login_2 login_3; do
  echo "Checking needinfo for ${login}"
  checker_out=`ruby fate-checker.rb ${login}@suse.com`

  if [ "${checker_out}" != "" ]; then
    recipient="${login}@suse.com"
    echo "Sending e-mail to ${recipient}"
    echo -e "${checker_out}" \
      | mailx -r mail_from@address.org \
        -s "FATE: Information Still Needed" \
        ${recipient}
  fi
done
```

Server configuration can be kept in your home directory in *~/.fate.conf* file:

```yaml
---
https://keeper.suse.com/sxkeeper/:
  user: user-name
  pass: YourU$erPa$$word
```
