#!/bin/bash

# Execute on Modification
# Copyleft 2019 valsorym. Copy and use it.

# Choose the work directory.
# Note: the script can be run from any directories but the working
#       directory is the directory where the script is physically
#       located, this must be taken into account when specifying
#       relative paths.
cd $(dirname $(readlink -f $0))

# GLOBALS
# The following variables are available:
#   SCRIPT_NAME - script file name
#   TRACKING_PATH - path to file or tracking directory
#   REQUIREMENTS - ist of the packages that must be installed in the system
#                  for the script to work correctly
#   ALL_PACKAGES_IS_AVAILABLE - equally 1 if all packets from the REQUIREMENTS
#                              list installed in the system, otherwise - 0
#   SAFE - equally 0 if safe mode is disabled, otherwise - 1
#   CMD_LIST - temporary list of commands to execute (used as a container for
#              parsing argument line)
#   CMD - command to execute
#   HELP_TEXT - help information
SCRIPT_NAME=`basename "$0"`
TRACKING_PATH="$PWD"
REQUIREMENTS=("bash" "inotifywait")
ALL_PACKAGES_IS_AVAILABLE=1
SAFE=0
CMD_LIST=()
CMD=""
HELP_TEXT="\
MODEX (Execute on Modification) it's script that executes the user's\
\ncommand every time when files are modified in the tracking directory.\n\
\nUsage:\
\n\t=> bash $SCRIPT_NAME --path=/path/to/tracking/dir/ '<command>'\n\
\nThe commands are:
\n\t-h or --help\
\n\t\tprint this help message and exit 
\n\t-s or --safe\
\n\t\tfirst run of the command only after changing the data in the tracking\
\n\t\tdirectory (otherwise, the first run of the command will be executed\
\n\t\timmediately after the script is run)
\n\t-p or --path\
\n\t\tpath to the tracking directory: -p=/path/to/tracking/dir/\n
\nExamples:\
\n\tSet the custom command inside single quotes like:\
\n\t=> bash $SCRIPT_NAME --path=\"\$PWD\" 'date && echo \"changed...\"'\
\n\n\
\nErrors code:\
\n\t1 - all required packages are not installed: ${REQUIREMENTS[@]};\
\n\t2 - the executable command is not specified;\
\n\t3 - tracking path not found.\n"

# ARGUMENTS
# Parsing the argument line.
for arg in "$@"
do
  case $arg in
    -h|--help) # show help
      echo -e $HELP_TEXT
      exit 0
      ;;
    -s|--safe) # set safe mode
      SAFE=1
      shift
      ;;
    -p=*|--path=*) # change tracking path
      TRACKING_PATH="${arg#*=}"
      shift
      ;;
    *)
      CMD_LIST+=("$1") # parse commad by parts
      CMD=${CMD_LIST[*]}
      shift
      ;;
  esac
done

if [ ${#CMD} -lt 1 ]
then
  # If the command to execute is not specified.
  echo "Set the command to execute. See help for details."
  echo "=> bash $SCRIPT_NAME --help"
  exit 2
fi

# REQUIREMENTS
# Check the availability of all packages required to run the script.
echo "Requirements:"
for pkg in "${REQUIREMENTS[@]}"
do
  is_exists=`whereis $pkg | cut -d\: -f2`
  if [ -z "$is_exists" ]
  then
    echo -e "\t[-] $pkg"
    ALL_PACKAGES_IS_AVAILABLE=0
  else
    echo -e "\t[+] $pkg"
  fi
done

if [ $ALL_PACKAGES_IS_AVAILABLE -eq 0 ]
then
  echo -e "\nPlease, install the missing packages..."
  exit 1
fi

# CHECK DATA
# Check the tracking path and show tracking parameters.
if [ ! -e "$TRACKING_PATH" ]
then
  echo -e "\nPath not found: $TRACKING_PATH"
  exit 3
fi

echo -e "\nTracking path: $TRACKING_PATH"
echo "Command: $CMD"

# SCAN
# Start tracking.
if [ $SAFE -ne 1 ]
then
  # If safe mode is disabled.
  eval "$CMD"
fi

while inotifywait -e modify ${TRACKING_PATH}
do
  eval "$CMD"
done

exit 0
