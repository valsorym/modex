# MODEX
MODEX (Execute on Modification) it's script that executes the user's command every time when files are modified in the tracking directory.

**Usage:** `=> bash modex.bash --path=/path/to/tracking/dir/ '<command>'`

## Get script
Download script into work directory.
```
$ cd /path/to/your/workspace/
$ rm -Rf /tmp/modex && \
  git clone git@github.com:valsorym/modex.git /tmp/modex && \
  cp /tmp/modex/modex.bash ./
```

## Requirements
In the system must be installed:
- `inotifywait` (deb: `apt-get -y install inotify-tools`)

*Copyleft 2019 valsorym. Copy and use it.*
