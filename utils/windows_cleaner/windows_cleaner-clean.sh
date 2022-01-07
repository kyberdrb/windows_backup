SCRIPT_DIR="$(dirname "$(readlink --canonicalize "$0")")"

ANIMATION_PID=0

wait_for_cleanmgr_to_finish() {
# wait to make sure the clean manager had enough time to start and open and is really running
  sleep 5
  
  while true
  do
    cleanmgr_process_info=$(tasklist | findstr "cleanmgr")
    
    if [[ -z "$cleanmgr_process_info" ]]
    then
      break
    fi
  done
  
  kill $ANIMATION_PID
  wait $ANIMATION_PID 2>/dev/null
  
  local message="$1"
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
