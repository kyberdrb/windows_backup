#!/bin/sh

#set -x

ESTIMATED_BACKUP_SIZE_IN_KB="$1"

BACKUP_DIR="$2"

LOG_FILE="$3"

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
  starting_character_number=1
  current_character_number=$starting_character_number
  terminal_width=$( stty --file=/dev/tty size | cut -d' ' -f2 2>/dev/null)
  while [ $current_character_number -lt $terminal_width ]
  do
    printf " "
    current_character_number=$(( current_character_number + 1 ))
  done
  
  printf "\r"
}

main() { 
  animation_steps="-:\:|:/"

  first_step_index=0
  index_of_next_step=$first_step_index
  number_of_steps=4
  
  disk_with_backup_dir_in_git_bash_in_windows="$(echo "${BACKUP_DIR}" | cut -d '/' -f 2 | tr '[:lower:]' '[:upper:]'):"
  used_space_on_disk_with_backup_dir_at_start=$(df | grep "${disk_with_backup_dir_in_git_bash_in_windows}" | tr -s ' ' | cut -d ' ' -f3)

  while true
  do
    progress_message=""
    index_of_next_step=$(( 1 + index_of_next_step % $number_of_steps ))
    animation_step=" $(printf -- "${animation_steps}" | cut -d ':' -f "${index_of_next_step}")   "

    if [ -n "${ESTIMATED_BACKUP_SIZE_IN_KB}" ]
    then
      current_used_space_on_disk_with_backup_dir=$(df | grep "${disk_with_backup_dir_in_git_bash_in_windows}" | tr -s ' ' | cut -d ' ' -f3)
      current_amount_of_backed_up_data_in_kb=$(( current_used_space_on_disk_with_backup_dir - used_space_on_disk_with_backup_dir_at_start ))

      percent_completed=$(( current_amount_of_backed_up_data_in_kb * 100 / ESTIMATED_BACKUP_SIZE_IN_KB ))
      percent_completed_message="${percent_completed}%% completed    "
      amount_of_backed_up_data="$current_amount_of_backed_up_data_in_kb/$ESTIMATED_BACKUP_SIZE_IN_KB    "
      
      # TODO test currently backed up file - with 'tail -n 1 $LOG_FILE' ?
      currently_backed_up_file="    $(tail -n 1 ${LOG_FILE})"

      if [ "${CONTINUE_EXECUTION_OF_SCRIPT}" = "false" ]
      then
        progress_message="$(clear_current_line)"
        
        printf -- "${progress_message} \r"
        
        clean_termination=0
        exit ${clean_termination}
      fi
    fi
    
    # TODO add currently backed up file - with 'tail -n 1 $LOG_FILE' ?
    progress_message="${animation_step}${percent_completed_message}${amount_of_backed_up_data}${currently_backed_up_file}"
    
    printf -- "${progress_message} \r"
    
    delay=0.07
    sleep $delay
  done
}

main

