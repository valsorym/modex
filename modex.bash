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
#       for the script to work correctly
#   SAFE - equally 0 if safe mode is disabled, otherwise - 1
#   CMD - command to execute
#   HELP_TEXT - help information
SCRIPT_NAME=`basename "$0"`
TRACKING_PATH="$PWD"
REQUIREMENTS=("inotifywait") #("pkg_a" "pkg_b" "pkg_c" ...)
SAFE=0
RECURSIVE=0
CMD=""
HELP_TEXT="\
MODEX (Execute on Modification) it's script that executes the user's\
\ncommand every time when files are modified in the tracking directory.\n\
\nUsage:\
\n\t=> bash $SCRIPT_NAME --path=/path/to/tracking/dir/ '<command>'\n\
\nThe commands are:
\n\t-h or --help\
\n\t\tprint this help message and exit\
\n\t-r or --recursive\
\n\t\twatch directories recursively\
\n\t-s or --safe\
\n\t\tfirst run of the command only after changing the data in the tracking\
\n\t\tdirectory (otherwise, the first run of the command will be executed\
\n\t\timmediately after the script is run)\
\n\t-p or --path\
\n\t\tpath to the tracking directory: -p=/path/to/tracking/dir/\n
\nExamples:\
\n\tSet the custom command inside single quotes like:\
\n\t=> bash $SCRIPT_NAME --path=\"\$PWD\" 'date && echo \"changed...\"'\
\n\n\nErrors code:\
\n\t1 - all required packages are not installed: ${REQUIREMENTS[@]};\
\n\t2 - the executable command is not specified;\
\n\t3 - tracking path not found.\n"

# ARGUMENTS
# Parsing the argument line.
#   cmd_list - temporary list of commands to execute (used as a container for
#       parsing argument line)
cmd_list=()
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
    -r|--recursive) # set recursive mode
      RECURSIVE=1
      shift
      ;;
    -p=*|--path=*) # change tracking path
      TRACKING_PATH="${arg#*=}"
      shift
      ;;
    *)
      cmd_list+=("$1") # parse commad by parts
      CMD=${cmd_list[*]}
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
#   requirements_output - temporary buffer for dialog output
#   all_packages_is_available - equally 1 if all packets from the REQUIREMENTS
#       list installed in the system, otherwise - 0
requirements_output=""
all_packages_is_available=1
for pkg in "${REQUIREMENTS[@]}"
do
  is_exists=`whereis $pkg | cut -d\: -f2`
  if [ -z "$is_exists" ]
  then
    requirements_output+="\t[-] $pkg\n"
    all_packages_is_available=0
  else
    requirements_output+="\t[+] $pkg\n"
  fi
done

if [ $all_packages_is_available -eq 0 ]
then
  # Show only when at least one of the dependencies is not installed.
  echo "Requirements:"
  echo -e $requirements_output
  echo -e "Please, install the missing packages..."
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


while inotifywait $( [ $RECURSIVE -eq 1 ] && printf %s '-r' ) -e modify ${TRACKING_PATH}
do
  eval "$CMD"
done

if [ $RECURSIVE -ne 1 ]
then
  while inotifywait -e modify ${TRACKING_PATH}
  do
    eval "$CMD"
  done
else
  while inotifywait -r -e modify ${TRACKING_PATH}
  do
    eval "$CMD"
  done
fi

exit 0
