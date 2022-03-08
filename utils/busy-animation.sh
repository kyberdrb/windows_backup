#!/bin/sh

#set -x

ESTIMATED_BACKUP_SIZE_IN_KB="$1"

DISK_WITH_BACKUP_DIR_IN_GIT_BASH_IN_WINDOWS="$2"

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

clear_current_line() {  
  starting_character_number=1
  current_character_number=$starting_character_number
  terminal_width=$(stty --file=/dev/tty size | cut -d' ' -f2 2>/dev/null)
  while [ $current_character_number -le $terminal_width ]
  do
    printf " "
    current_character_number=$(( current_character_number + 1 ))
  done

  printf "\r"
}

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


main() { 
  animation_steps="-:\:|:/"

  first_step_index=0
  index_of_next_step=$first_step_index
  number_of_steps=4

  # TODO move free/used space monitoring to the while loop in function 'backup_files_and_folders' in 'backup.sh'
  #   Here only read a file with 'usedKB;availableKB;percent_completed;currently_backed_up_file' info of the backup drive 
  #   that the backup.sh will recalculate and overwrite after each copied file
  #   and the busy-animation will only calculate the next animation step
  #   which will make the animation smooth, even when copying a file, which looks prettier
  free_space_on_disk_with_backup_dir_at_start=$(df | grep --ignore-case "${DISK_WITH_BACKUP_DIR_IN_GIT_BASH_IN_WINDOWS}" | tr -s ' ' | cut -d ' ' -f4)

  while true
  do
    progress_message=""
    index_of_next_step=$(( 1 + index_of_next_step % number_of_steps ))
    animation_step=" $(printf -- "%s" "${animation_steps}" | cut -d ':' -f "${index_of_next_step}")   "

    if [ -n "${ESTIMATED_BACKUP_SIZE_IN_KB}" ]
    then
      current_free_space_on_disk_with_backup_dir=$(df | grep --ignore-case "${DISK_WITH_BACKUP_DIR_IN_GIT_BASH_IN_WINDOWS}" | tr -s ' ' | cut -d ' ' -f4)
      current_amount_of_backed_up_data_in_kb=$(( free_space_on_disk_with_backup_dir_at_start - current_free_space_on_disk_with_backup_dir ))

      percent_completed=$(( current_amount_of_backed_up_data_in_kb * 100 / ESTIMATED_BACKUP_SIZE_IN_KB ))
      percent_completed_message="${percent_completed}% completed   "
      amount_of_backed_up_data="$current_amount_of_backed_up_data_in_kb/${ESTIMATED_BACKUP_SIZE_IN_KB}   "

      currently_backed_up_file=""
      # check for file presence for standalone testing
      if [ -f "/tmp/currently_backed_up_file.txt" ]; then
        currently_backed_up_file="$(cat /tmp/currently_backed_up_file.txt)"

        terminal_width=$(stty --file=/dev/tty size | cut -d' ' -f2 2>/dev/null)
        animation_step_str_length="${#animation_step}"
        percent_completed_message_str_length="${#percent_completed_message}"
        amount_of_backed_up_data_str_length="${#amount_of_backed_up_data}"

        space_left_in_terminal_row=$(( terminal_width - animation_step_str_length  - percent_completed_message_str_length - amount_of_backed_up_data_str_length - 1 ))
        
        # MULTIBYTE CHARACTERS FIX
        #   fix refreshing file paths that fit in the terminal width character-wise but not byte-wise
        #   by truncating them until their byte length fits the terminal width.
        #   Assumption '1 character = 1 byte' prooves false when displaying localized characters
        #   and creates newlines instead of refreshing the same line in spite of the '\r' mechanism
        currently_backed_up_file_with_truncated_path="${currently_backed_up_file:0:$space_left_in_terminal_row}"
        
        str_length_of_currently_backed_up_file_path="$(printf "%s" "${currently_backed_up_file}" | wc --chars)"
        
        final_str_length_of_currently_backed_up_file_path_with_regard_to_multibyte_characters=$str_length_of_currently_backed_up_file_path
        
        byte_length_of_currently_backed_up_file_path="$(printf "%s" "${currently_backed_up_file}" | wc --bytes)"
        
        byte_length_of_currently_backed_up_file_path_truncated=$byte_length_of_currently_backed_up_file_path
        
        while [ $byte_length_of_currently_backed_up_file_path_truncated -ge $space_left_in_terminal_row ]
        do
          # update variable e.g. final_str_length_with_regard_to_multibyte_characters ?
          final_str_length_of_currently_backed_up_file_path_with_regard_to_multibyte_characters=$(( final_str_length_of_currently_backed_up_file_path_with_regard_to_multibyte_characters - 1 ))
          
          # trucate path by 1 character
          currently_backed_up_file_with_truncated_path=${currently_backed_up_file:0:final_str_length_of_currently_backed_up_file_path_with_regard_to_multibyte_characters}
          
          
          # update the variable by measuring the byte length
          byte_length_of_currently_backed_up_file_path_truncated="$(printf "%s" "${currently_backed_up_file_with_truncated_path}" | wc --bytes)"
        done
        
      fi

      if [ "${CONTINUE_EXECUTION_OF_SCRIPT}" = "false" ]
      then
        progress_message="$(clear_current_line)"

        printf -- "%s\r" "${progress_message}"

        clean_termination=0
        exit ${clean_termination}
      fi
    fi

    progress_message="${animation_step}${percent_completed_message}${amount_of_backed_up_data}${currently_backed_up_file_with_truncated_path}"

    printf -- "%s" "${progress_message}"

    # fill the rest of the line with blank spaces
    #  to clean residual characters from previous output
    starting_character_number=1
    current_character_number=$starting_character_number
    terminal_width=$(stty --file=/dev/tty size | cut -d' ' -f2 2>/dev/null)
    progress_message_str_length="${#progress_message}"
    amount_of_residual_space_in_current_row=$(( terminal_width - progress_message_str_length ))
    while [ $current_character_number -le $amount_of_residual_space_in_current_row ]
    do
      printf " "
      current_character_number=$(( current_character_number + 1 ))
    done

    printf "\r"

    #delay=0.07
    #sleep $delay
  done
}

main

