#!/bin/sh

#set -x

SCRIPT_DIR="$(dirname "$(readlink --canonicalize "$0")")"

ANIMATION_PID=0

CLEAN_MANAGER_INVOKED=1

wait_for_cleanmgr_to_finish() {
  # wait for the clean manager to start and open to make sure is really running
  #  before doing anything else, to make sure only one instance of cleanmkgr is running
  #  for performance reasons
  while true
  do
    # THIS COMMAND CAN BE TIME-CONSUMING OR BLOCKING.
    #  Comment out the entire 'if' block below for faster debugging/execution
    if [ "$CLEAN_MANAGER_INVOKED" -eq "1" ] && [ -z "$(tasklist | findstr "cleanmgr")" ]
    then
      printf "      $(date +%s): Waiting for cleanmgr.exe to start...\r"
      continue
    fi
    
    # TODO extract function to script and use it here and in busy-animation.sh too
    # clear line - beginning of function
    starting_character_number=1
    current_character_number=$starting_character_number
    terminal_width=$( stty --file=/dev/tty size | cut -d' ' -f2 2>/dev/null)
    while [ "$current_character_number" -lt "$terminal_width" ]
    do
      printf " "
      current_character_number=$(( current_character_number + 1 ))
    done
    
    printf "\r"
    # clear line - end of function
    
    break
  done
  
  while true
  do
    cleanmgr_process_info=$(tasklist | findstr "cleanmgr")
    
    if [ -z "$cleanmgr_process_info" ]
    then
      break
    fi
  done
  
  kill $ANIMATION_PID
  wait $ANIMATION_PID 2>/dev/null
  
  CLEAN_MANAGER_INVOKED=0
  
  message="$1"
  printf "$message\n"
}

clean_systemspace() {
  "${SCRIPT_DIR}"/../busy-animation.sh &
  ANIMATION_PID="$!"

  # THIS COMMAND CAN BE TIME-CONSUMING. Comment out for faster debugging/execution
  gsudo cleanmgr /SAGERUN:0
  
  wait_for_cleanmgr_to_finish "  • systemspace cleaning done"
}

clean_userspace() {
  "${SCRIPT_DIR}"/../busy-animation.sh &
  ANIMATION_PID="$!"
  
  # THIS COMMAND CAN BE TIME-CONSUMING. Comment out for faster debugging/execution
  cleanmgr /SAGERUN:0
  
  wait_for_cleanmgr_to_finish "  • userspace cleaning done"
}

main() {
  clean_systemspace
  clean_userspace
}

main
