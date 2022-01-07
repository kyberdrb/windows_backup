#!/bin/sh

ESTIMATED_BACKUP_SIZE_IN_KB="$1"

# Capture signals with 'trap'. POSIX standard ommits the leading 'SIG' - the name of the interrupt is sufficient
# - SIGTERM/TERM (kill)
#   - default signal for 'kill'. I assume this would be sufficient for simplicity, readability reasons.
#   - This is the way I use it from caller scripts.
# - SIGINT/INT (Ctrl+C)
# - SIGQUIT/QUIT (kill -? / exit)
# - SIGKILL/KILL (kill -9)
trap handle_default_kill TERM
trap handle_Ctrl_C_interrupt INT
trap handle_pause_interrupt STOP
trap handle_continue_interrupt CONT

CONTINUE_EXECUTION_OF_SCRIPT="true"

# For usual script termination
handle_default_kill() {
  CONTINUE_EXECUTION_OF_SCRIPT="false"
}

# For standalone script testing
handle_Ctrl_C_interrupt() {
  handle_default_kill
}

clear_current_line() {
  local progress_message=""
  local terminal_width=$( stty --file=/dev/tty size | cut -d' ' -f2 2>/dev/null)
  #local terminal_width=$(mode con:cols=80)
  
  # to avoid newline at last character
  local reduced_terminal_width=$(( terminal_width - 1 ))
  # clear last line of backup progress
  for i in $(seq ${reduced_terminal_width})
  do
    progress_message+=" "
  done
  
  echo "${progress_message}"
}

main() {
  local animation_steps=(
    "-"
    "\\"
    "|"
    "/"
  )

  local step_index=0
  local number_of_steps=${#animation_steps[@]}
  while true
  do
    local progress_message=""

    if [ -n "${ESTIMATED_BACKUP_SIZE_IN_KB}" ]
    then
      # Because we're doing the beckup on a clean drive, we can use 'df' utility
      local current_amount_of_backed_up_data_in_kb=$(df | grep D: | tr -s ' ' | cut -d ' ' -f3)

      local percent_completed=$(( current_amount_of_backed_up_data_in_kb * 100 / ESTIMATED_BACKUP_SIZE_IN_KB ))
      progress_message+="${percent_completed}% completed    "
      progress_message+="$current_amount_of_backed_up_data_in_kb/$ESTIMATED_BACKUP_SIZE_IN_KB    "
      
      if [ "${CONTINUE_EXECUTION_OF_SCRIPT}" = "false" ]
      then
        progress_message="$(clear_current_line)"
        
        echo -ne "${progress_message} \r"
        
        local clean_termination=0
        exit ${clean_termination}
      fi
      
      echo -ne "${progress_message} \r"
      
      continue
    fi

    progress_message+="${animation_steps[step_index]}    "

    if [ "${CONTINUE_EXECUTION_OF_SCRIPT}" = "false" ]
    then
      progress_message="$(clear_current_line)"
      
      echo -ne "${progress_message} \r"
      
      local clean_termination=0
      exit ${clean_termination}
    fi
    
    echo -ne "${progress_message} \r"
    
    index_of_next_step=$((step_index + 1))
    step_index=${index_of_next_step}
    
    test $step_index -eq $number_of_steps
    local is_on_the_last_animation_step=$?
    if [ ${is_on_the_last_animation_step} -eq 0 ]
    then
      local index_of_first_step=0
      step_index=${index_of_first_step}
    fi
    
    local delay=0.07
    sleep $delay
  done
}

main
