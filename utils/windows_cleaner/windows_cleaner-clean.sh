#!/bin/sh

SCRIPT_DIR="$(dirname "$(readlink --canonicalize "$0")")"

ANIMATION_PID=0

CLEAN_MANAGER_INVOKED=1

wait_for_cleanmgr_to_finish() {
  # wait to make sure the clean manager had enough time to start and open and is really running
  sleep 15
  
  while true
  do
    if [ $CLEAN_MANAGER_INVOKED -eq 1 ] && [ -z "$(tasklist | findstr "cleanmgr")" ]
    then
      printf "$(date +%s): Waiting for cleanmgr.exe to start...\r"
      continue
    fi
    
    printf "cleanmgr.exe started.\r"
    
    # TODO extract function and use it in busy-animation.sh too
    # clear line - beginning of function
    starting_character_number=1
    current_character_number=$starting_character_number
    while [ $current_character_number -le $terminal_width ]
    do
      printf " "
      current_character_number=$(( current_character_number + 1 ))
    done
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
  echo "$message"
}

clean_systemspace() {
  "${SCRIPT_DIR}"/../busy-animation.sh &
  ANIMATION_PID="$!"

  gsudo cleanmgr /SAGERUN:0
  
  wait_for_cleanmgr_to_finish "  • systemspace cleaning done"
}

clean_userspace() {
  "${SCRIPT_DIR}"/../busy-animation.sh &
  ANIMATION_PID="$!"
  
  cleanmgr /SAGERUN:0
  
  wait_for_cleanmgr_to_finish "  • userspace cleaning done"
}


main() {
  clean_systemspace
  clean_userspace
}

main
