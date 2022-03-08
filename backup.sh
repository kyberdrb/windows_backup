#!/bin/sh

#set -x

SCRIPT_DIR="$(dirname "$(readlink --canonicalize "$0")")"
LOG_DIR="${SCRIPT_DIR}/logs"

DATE_AND_TIME_FOR_FILENAME=$(date "+%Y_%m_%d-%H_%M_%S")

LOG_FILE="${LOG_DIR}/backup-${DATE_AND_TIME_FOR_FILENAME}.log"

TMP_DIR="${SCRIPT_DIR}/tmp"
BACKUP_DIR="empty"
FILE_WITH_CURRENTLY_COPIED_FILE="/tmp/currently_backed_up_file.txt"

SHUTDOWNGUARD_PID=0
ANIMATION_PID=0

ESTIMATED_BACKUP_SIZE_IN_KB=0

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

is_backup_drive_mounted() {
  # at first, clean configuration file from carriage return characters
  #  to prevent (surprising and confusing) error messages
  #  when reading lines with paths from file 
  #  and doing operations with them like 'ls' or 'cp'
  #  and ending up with errors like "No such file or directory"

  mkdir --parents "${TMP_DIR}" 2>&1
  mkdir --parents "${LOG_DIR}" 2>&1

  # THIS COMMAND CAN BE DESTRUCTIVE. Comment out for safer debugging/execution
  grep -v '^[[:space:]]*$' "${SCRIPT_DIR}/backup.conf" | tr -d '\r' > "${TMP_DIR}/backup.conf.cleansed.tmp"

  BACKUP_DIR="$(head -n 1 "${TMP_DIR}/backup.conf.cleansed.tmp" | cut -d'=' -f2)"

  linux_style_backup_disk_mountpoint_of_backup_dir_in_git_bash_in_windows="$(echo "${BACKUP_DIR}" | cut -d '/' -f 2 | tr '[:upper:]' '[:lower:]'):"

  backup_drive_info="$(df | grep --ignore-case "${linux_style_backup_disk_mountpoint_of_backup_dir_in_git_bash_in_windows}")"

  if [ -z "${backup_drive_info}" ]
  then
    echo "$(date "+%s"):$(date "+%Y/%m/%d %H:%M:%S") - LOG_BACKUP_INFO - is_backup_drive_mounted - Drive Not Mounted. Exitting..." >> "${LOG_FILE}" 2>&1

    echo "Backup drive not mounted."
    echo "Make sure the drive is inserted and has assigned a drive letter."

    exit 2
  fi
}

start_support_processes() {
  "${SCRIPT_DIR}"/utils/ShutdownGuard/ShutdownGuard.exe &
  SHUTDOWNGUARD_PID="$!"
}

show_info_message() {
  echo "Teraz sa cisti pocitac a zalohuju sa subory"
  echo

  echo "Zálohovanie bude chvilu trvat..."
  echo
}

clean_temp_files() {
  mkdir --parents "${LOG_DIR}"

  echo "$(date "+%s"):$(date "+%Y/%m/%d %H:%M:%S") - LOG_BACKUP_INFO - Cleanup - Start Time" >> "${LOG_FILE}" 2>&1
  
  rm --force "${FILE_WITH_CURRENTLY_COPIED_FILE}"

  {
  echo

  # THIS COMMAND CAN BE DESTRUCTIVE. Comment out for safer debugging/execution
  rm --verbose --recursive --force "${TMP_DIR}"
  mkdir --parents "${TMP_DIR}"
  } >> "${LOG_FILE}" 2>&1

  printf "%s\n" "¤ Cleaning temporary files"

  # THIS COMMAND CAN BE TIME-CONSUMING. Comment out for faster debugging/execution
  # TODO uncomment cleaning up of temporary files in Windows when done debugging and testing
  "${SCRIPT_DIR}/utils/windows_cleaner/windows_cleaner-clean.sh"
  echo
}

clean_backup_directory() {
  printf "¤ Cleaning backup directory\n"
  
  "${SCRIPT_DIR}"/utils/busy-animation.sh &
  ANIMATION_PID="$!"
  
  echo >> "${LOG_FILE}" 2>&1

  # THIS COMMAND CAN BE DESTRUCTIVE. Comment out for safer debugging/execution
  grep -v '^[[:space:]]*$' "${SCRIPT_DIR}/backup.conf" | tr -d '\r' > "${TMP_DIR}/backup.conf.cleansed.tmp"

  # THIS COMMAND CAN BE DESTRUCTIVE. Comment out for safer debugging/execution
  tail -n +2 "${TMP_DIR}/backup.conf.cleansed.tmp" > "${TMP_DIR}/backup_source_paths.tmp"

  # THIS COMMAND CAN BE DESTRUCTIVE. Comment out for safer debugging/execution
  tail -n +2 "${TMP_DIR}/backup.conf.cleansed.tmp" | cut -d'/' -f2 --complement | sed "s:^:${BACKUP_DIR}:g" > "${TMP_DIR}/backup_destination_paths.tmp"
  
  while IFS= read -r line
  do
    destination_file_or_directory="${line}"
    
    # THIS COMMAND CAN BE TIME-CONSUMING. Comment out for faster debugging/execution
    # TODO uncomment cleaning up of backed up files on the backup dir when done debugging and testing
    rm --verbose --recursive --force "${destination_file_or_directory}"
    "${SCRIPT_DIR}/utils/delete_empty_directories_upwards.sh" "${destination_file_or_directory}"
  done < "${TMP_DIR}/backup_destination_paths.tmp" >> "${LOG_FILE}" 2>&1

  kill $ANIMATION_PID
  wait $ANIMATION_PID 2>/dev/null
  clear_current_line

  {
  echo
  echo "$(date "+%s"):$(date "+%Y/%m/%d %H:%M:%S") - LOG_BACKUP_INFO - Cleanup - End Time"
  echo
  } >> "${LOG_FILE}"
}

estimate_backup_size() {
  echo "$(date "+%s"):$(date "+%Y/%m/%d %H:%M:%S") - LOG_BACKUP_INFO - Estimate Backup Time - Start Time" >> "${LOG_FILE}"
  echo >> "${LOG_FILE}"

  printf "\n"
  printf "¤ Estimating backup size\n"

  "${SCRIPT_DIR}"/utils/busy-animation.sh &
  ANIMATION_PID="$!"

  # empty content of file with previous computed directory sizes
  # THIS COMMAND CAN BE DESTRUCTIVE. Comment out for safer debugging/execution
  cat /dev/null > "${TMP_DIR}/estimated_backed_up_directory_sizes.tmp"

  # compute new directory sizes
  # THIS COMMAND CAN BE TIME-CONSUMING. Comment out for faster debugging/execution
  # TODO uncomment the computation of ESTIMATED_BACKUP_SIZE_IN_KB when done debugging and testing
  <"${TMP_DIR}/backup_source_paths.tmp" xargs -I "{}" sh -c "du --summarize ""{}"" 2>/dev/null | tr '\t' '#' | cut -d'#' -f1 >> ""${TMP_DIR}/estimated_backed_up_directory_sizes.tmp"""
  arithmetic_expression="$(paste --serial --delimiters=+ "${TMP_DIR}/estimated_backed_up_directory_sizes.tmp")"
  ESTIMATED_BACKUP_SIZE_IN_KB="$((arithmetic_expression))"

  # TODO remove fixed ESTIMATED_BACKUP_SIZE_IN_KB when done debugging and testing
  #ESTIMATED_BACKUP_SIZE_IN_KB="208608393"

  kill $ANIMATION_PID
  wait $ANIMATION_PID 2>/dev/null
  clear_current_line

  echo "  • Estimated backup size:      $ESTIMATED_BACKUP_SIZE_IN_KB kB"

  {
  echo "$(date "+%s"):$(date "+%Y/%m/%d %H:%M:%S") - LOG_BACKUP_INFO - Estimated backup size: $ESTIMATED_BACKUP_SIZE_IN_KB kB"
  echo
  } >> "${LOG_FILE}"

  echo "$(date "+%s"):$(date "+%Y/%m/%d %H:%M:%S") - LOG_BACKUP_INFO - Estimate Backup Time - End Time" >> "${LOG_FILE}"
  echo >> "${LOG_FILE}"
}

check_free_space() {
  echo "$(date "+%s"):$(date "+%Y/%m/%d %H:%M:%S") - LOG_BACKUP_INFO - Estimate Backup Time - Start Time" >> "${LOG_FILE}"
  echo >> "${LOG_FILE}"

  printf "\n"
  printf "%s\n" "¤ Checking free space"

  "${SCRIPT_DIR}"/utils/busy-animation.sh &
  ANIMATION_PID="$!"

  free_space_on_disk_with_backup_dir_at_start=$(df | grep --ignore-case "${linux_style_backup_disk_mountpoint_of_backup_dir_in_git_bash_in_windows}" | tr --squeeze-repeats '[:space:]' | cut --delimiter=' ' --fields=4)

  printf "%s\n" "  • Free space on backup drive: ${free_space_on_disk_with_backup_dir_at_start} kB"

  if [ $free_space_on_disk_with_backup_dir_at_start -lt $ESTIMATED_BACKUP_SIZE_IN_KB ]
  then
    echo "$(date "+%s"):$(date "+%Y/%m/%d %H:%M:%S") - LOG_BACKUP_INFO - Check sufficient free space on the backup drive - HALT: Backup size is larger than the free space on the backup drive - End Time" >> "${LOG_FILE}"

    printf "%s\n" "   • The backup needs more space on the backup drive."

    kill $ANIMATION_PID
    wait $ANIMATION_PID 2>/dev/null
    clear_current_line

    kill $SHUTDOWNGUARD_PID 2>/dev/null
    wait $SHUTDOWNGUARD_PID 2>/dev/null

    SHUTDOWNGUARD_WINPID="$(ps --windows | grep ShutdownGuard | tr -s ' ' | cut -d ' ' -f5)"
    taskkill //F //PID "${SHUTDOWNGUARD_WINPID}" 1>/dev/null 2>&1
    tskill "${SHUTDOWNGUARD_WINPID}" 1>/dev/null 2>&1
    
    rm --force "${FILE_WITH_CURRENTLY_COPIED_FILE}"

    exit 1
  fi

  kill $ANIMATION_PID
  wait $ANIMATION_PID 2>/dev/null
  clear_current_line

  printf "%s\n" "  • Enough space for backup on the backup drive. Proceeding..."

  echo "$(date "+%s"):$(date "+%Y/%m/%d %H:%M:%S") - LOG_BACKUP_INFO - Check sufficient free space on the backup drive - PASS: Enough free space available for backup on the backup drive - continuing... - End Time" >> "${LOG_FILE}"
  echo >> "${LOG_FILE}"
}

generate_files_and_dirs_list() {
  echo "$(date "+%s"):$(date "+%Y/%m/%d %H:%M:%S") - LOG_BACKUP_INFO - Estimate Backup Time - Start Time" >> "${LOG_FILE}"
  echo >> "${LOG_FILE}"

  printf "\n"
  printf "%s\n" "¤ Generating source and destination file lists."

  "${SCRIPT_DIR}"/utils/busy-animation.sh &
  ANIMATION_PID="$!"

  paste --delimiter=';' "${TMP_DIR}/backup_source_paths.tmp" "${TMP_DIR}/backup_destination_paths.tmp" > "${TMP_DIR}/backup_source_and_destination_paths.tmp"

  kill $ANIMATION_PID
  wait $ANIMATION_PID 2>/dev/null
  clear_current_line
}

estimate_backup_duration() {
  echo "$(date "+%s"):$(date "+%Y/%m/%d %H:%M:%S") - LOG_BACKUP_INFO - Estimate Backup Duration - Start Time" >> "${LOG_FILE}"
  echo >> "${LOG_FILE}"

  printf "\n"
  printf "%s\n" "¤ Estimating backup duration"

  "${SCRIPT_DIR}"/utils/busy-animation.sh &
  ANIMATION_PID="$!"

  grep --recursive --word-regexp "LOG_BACKUP_INFO - Cleanup - Start Time" "${LOG_DIR}" | sort | cut --delimiter=':' --fields=1 > "${TMP_DIR}/log_files_with_start_time.tmp"

  grep --recursive --word-regexp "LOG_BACKUP_INFO - Finish - End Time" "${LOG_DIR}" | sort | cut --delimiter=':' --fields=1 > "${TMP_DIR}/log_files_with_end_time.tmp"

  comm -12 "${TMP_DIR}/log_files_with_start_time.tmp" "${TMP_DIR}/log_files_with_end_time.tmp" | sort --reverse > "${TMP_DIR}/log_files_with_start_and_end_time.tmp"

  latest_complete_backup_log="$(head --lines=1 "${TMP_DIR}/log_files_with_start_and_end_time.tmp")"

  kill $ANIMATION_PID
  wait $ANIMATION_PID 2>/dev/null
  clear_current_line

  if [ -n "$latest_complete_backup_log" ]
  then
    start_timestamp=$(head -n 1 "${latest_complete_backup_log}" | cut -d ':' -f1)
    end_timestamp=$(tail -n 2 "${latest_complete_backup_log}" | tr -d '\n' | cut -d ':' -f1)
    duration_of_last_backup_in_seconds=$(( end_timestamp - start_timestamp ))

    duration_of_last_backup_in_seconds_in_human_readable_format=$(date -d@${duration_of_last_backup_in_seconds} -u "+%-k hod. %M minut")

    printf "%s\n" "  • Posledna zaloha trvala ${duration_of_last_backup_in_seconds_in_human_readable_format}"

    estimated_backup_finish_time=$(date -d "${duration_of_last_backup_in_seconds} seconds" +"%H:%M")
    echo "  • Zalohovanie bude trvat priblizne do ${estimated_backup_finish_time}"
    echo
  fi

  echo "$(date "+%s"):$(date "+%Y/%m/%d %H:%M:%S") - LOG_BACKUP_INFO - Estimate Backup Duration - End Time" >> "${LOG_FILE}"
  echo >> "${LOG_FILE}"
}

backup_files_and_folders() {
  printf "%s\n" "¤ Back up files and folders"

  disk_with_backup_dir_in_git_bash_in_windows="$(echo "${BACKUP_DIR}" | cut -d '/' -f 2):"

  {
  echo "$(date "+%s"):$(date "+%Y/%m/%d %H:%M:%S") - LOG_BACKUP_INFO - Backup Files And Folders - Start Time"
  echo
  } >> "${LOG_FILE}"

  printf "%s\n" "  • Backing up files..."

  # by iterating each line separately in a loop (instead of xargs)
  #   we can update the log file with current copying operation after each file
  while IFS= read -r line
  do
    source_file_or_directory="$(echo ${line} | cut --delimiter=';' --fields=1)"
    destination_file_or_directory="$(echo ${line} | cut --delimiter=';' --fields=2)"
    
    # Save currently copied file to tmpfs (RAM) to spare SSD/HDD storage for longevity and speed
    #   to pass it for the busy-animation to display
    printf "%s\n" "$(date "+%s"):$(date "+%Y/%m/%d %H:%M:%S") - LOG_BACKUP_INFO - Backup Files And Folders - Currently backing up: ${source_file_or_directory}" >> "${LOG_FILE}"
    
    printf "%s" "${source_file_or_directory}" > "${FILE_WITH_CURRENTLY_COPIED_FILE}"
    
    "${SCRIPT_DIR}"/utils/busy-animation.sh "${ESTIMATED_BACKUP_SIZE_IN_KB}" "${disk_with_backup_dir_in_git_bash_in_windows}" &
    ANIMATION_PID="$!"

    # Creating the directory first on the destination backup prevents the error 'No such file or directory'
    mkdir --verbose --parents "$(dirname "${destination_file_or_directory}")" >> "${LOG_FILE}" 2>&1
    
    # THIS COMMAND CAN BE TIME-CONSUMING. Comment out for faster debugging/execution
    cp --recursive --force --preserve=mode,ownership,timestamps "${source_file_or_directory}" "${destination_file_or_directory}" 1>/dev/null 2>&1
    
    kill $ANIMATION_PID 2>/dev/null
    wait $ANIMATION_PID 2>/dev/null
    clear_current_line
  done < "${TMP_DIR}/backup_source_and_destination_paths.tmp"

  echo >> "${LOG_FILE}"
  echo "$(date "+%s"):$(date "+%Y/%m/%d %H:%M:%S") - LOG_BACKUP_INFO - Backup Files And Folders - End Time" >> "${LOG_FILE}"
}

finalize_backup() {
  # TODO extract into separate function 'stop_background_processes'
  kill $ANIMATION_PID 2>/dev/null
  wait $ANIMATION_PID 2>/dev/null
  clear_current_line

  kill $SHUTDOWNGUARD_PID 2>/dev/null
  wait $SHUTDOWNGUARD_PID 2>/dev/null

  SHUTDOWNGUARD_WINPID="$(ps --windows | grep ShutdownGuard | tr -s ' ' | cut -d ' ' -f5)"
  taskkill //F //PID "${SHUTDOWNGUARD_WINPID}" 1>/dev/null 2>&1
  tskill "${SHUTDOWNGUARD_WINPID}" 1>/dev/null 2>&1
  
  rm --force "${FILE_WITH_CURRENTLY_COPIED_FILE}"
  # END OF FUNCTION

  printf "¤ Backup complete\n"

  echo >> "${LOG_FILE}"
  echo "$(date "+%s"):$(date "+%Y/%m/%d %H:%M:%S") - LOG_BACKUP_INFO - Finish - End Time" >> "${LOG_FILE}"

  echo "Teraz mozes pocitac bezpecne vypnut"
  echo

  printf "Stlacte lubovolnu klavesu na zatvorenie okna..."
  read -r
}

# TODO extract trap kill handling and use it in all scripts
#  maybe source the trap kill handling script to avoid duplicates?
trap handle_default_kill TERM
trap handle_Ctrl_C_interrupt INT

# For usual script termination
handle_default_kill() {
  # TODO extract into separate function 'stop_background_processes'
  kill $ANIMATION_PID 2>/dev/null
  wait $ANIMATION_PID 2>/dev/null
  clear_current_line

  kill $SHUTDOWNGUARD_PID 2>/dev/null
  wait $SHUTDOWNGUARD_PID 2>/dev/null

  SHUTDOWNGUARD_WINPID="$(ps --windows | grep ShutdownGuard | tr -s ' ' | cut -d ' ' -f5)"
  taskkill //F //PID "${SHUTDOWNGUARD_WINPID}" 1>/dev/null 2>&1
  tskill "${SHUTDOWNGUARD_WINPID}" 1>/dev/null 2>&1
  
  rm --force "${FILE_WITH_CURRENTLY_COPIED_FILE}"
  # END OF FUNCTION

  printf "%s\n" "Backup exitted prematurely"
  exit 1
}

# For standalone script testing
handle_Ctrl_C_interrupt() {
  handle_default_kill
}

main() {
  is_backup_drive_mounted

  start_support_processes
  show_info_message

  clean_temp_files
  clean_backup_directory

  estimate_backup_size
  check_free_space
  generate_files_and_dirs_list
  estimate_backup_duration

  backup_files_and_folders

  finalize_backup
}

main

