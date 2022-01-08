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

CONTINUE_EXECUTION_OF_SCRIPT="true"

# For usual script termination
handle_default_kill() {
  clear_current_line
      
  clean_termination=0
  exit ${clean_termination}
}

# For standalone script testing
handle_Ctrl_C_interrupt() {
  handle_default_kill
}

clear_current_line() {  
  terminal_width=$( stty --file=/dev/tty size | cut -d' ' -f2 2>/dev/null)
  
  starting_character_number=1
  current_character_number=$starting_character_number
  while [ $current_character_number -le $terminal_width ]
  do
    printf " "
    current_character_number=$(( current_character_number + 1 ))
  done
}

main() { 
  animation_steps="-:\:|:/"

  first_step_index=0
  index_of_next_step=$first_step_index
  number_of_steps=4
  
  while true
  do
    progress_message=""
    
    index_of_next_step=$((1 + index_of_next_step % $number_of_steps))
    
    animation_step="$(printf -- "$animation_steps" | cut -d ':' -f $((index_of_next_step)))    "

    if [ -n "${ESTIMATED_BACKUP_SIZE_IN_KB}" ]
    then
      # I'm doing the beckup on a clean drive, therefore I use 'df' utility
      current_amount_of_backed_up_data_in_kb=$(df | grep D: | tr -s ' ' | cut -d ' ' -f3)

      percent_completed=$(( current_amount_of_backed_up_data_in_kb * 100 / ESTIMATED_BACKUP_SIZE_IN_KB ))
      percent_completed_message="${percent_completed}%% completed    "
      amount_of_backed_up_data="$current_amount_of_backed_up_data_in_kb/$ESTIMATED_BACKUP_SIZE_IN_KB    "
      
      if [ "${CONTINUE_EXECUTION_OF_SCRIPT}" = "false" ]
      then
        progress_message="$(clear_current_line)"
        
        printf -- "${progress_message} \r"
        
        clean_termination=0
        exit ${clean_termination}
      fi
    fi
    
    progress_message="${animation_step}${percent_completed_message}${amount_of_backed_up_data}"
    
    printf -- "${progress_message} \r"
    
    delay=0.07
    sleep $delay
  done
}

main
