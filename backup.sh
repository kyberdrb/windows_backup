#!/bin/sh

SCRIPT_DIR="$(dirname "$(readlink --canonicalize "$0")")"
LOG_DIR="${SCRIPT_DIR}/logs"

DATE_AND_TIME_FOR_FILENAME=$(date "+%Y_%m_%d-%H_%M_%S")

LOG_FILE="${LOG_DIR}/backup-${DATE_AND_TIME_FOR_FILENAME}.log"

TMP_DIR="${SCRIPT_DIR}/tmp"

SHUTDOWNGUARD_PID=0
ANIMATION_PID=0

ESTIMATED_BACKUP_SIZE_IN_KB=0

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

  {
  echo
  
  # THIS COMMAND CAN BE DESTRUCTIVE. Comment out for safer debugging/execution
  rm --verbose --recursive --force "${TMP_DIR}"
  mkdir --parents "${TMP_DIR}"
  } >> "${LOG_FILE}" 2>&1
  
  printf "¤ Clearing temporary files\n"
 
  # THIS COMMAND CAN BE TIME-CONSUMING. Comment out for faster debugging/execution
  "${SCRIPT_DIR}/utils/windows_cleaner/windows_cleaner-clean.sh"
  echo
}

clean_backup_directory() {
  printf "¤ Cleaning backup directory\n"
  
  "${SCRIPT_DIR}"/utils/busy-animation.sh &
  ANIMATION_PID="$!"
  
  # at first, clean configuration file from carriage return characters
  #  to prevent (surprising and confusing) error messages
  #  when reading lines with paths from file 
  #  and doing operations with them like 'ls' or 'cp'
  #  and ending up with errors like "No such file or directory"
  
  # THIS COMMAND CAN BE DESTRUCTIVE. Comment out for safer debugging/execution
  grep -v '^[[:space:]]*$' backup.conf | tr -d '\r' > "${TMP_DIR}/backup.conf.cleansed.tmp"

  BACKUP_DIR="$(head -n 1 "${TMP_DIR}/backup.conf.cleansed.tmp" | cut -d'=' -f2)"
  
  # THIS COMMAND CAN BE DESTRUCTIVE. Comment out for safer debugging/execution
  tail -n +2 "${TMP_DIR}/backup.conf.cleansed.tmp" > "${TMP_DIR}/backup_source_paths.tmp"

  # THIS COMMAND CAN BE DESTRUCTIVE. Comment out for safer debugging/execution
  tail -n +2 "${TMP_DIR}/backup.conf.cleansed.tmp" | cut -d'/' -f2 --complement | sed "s:^:${BACKUP_DIR}:g" > "${TMP_DIR}/backup_destination_paths.tmp"
  
  # THIS COMMAND CAN BE TIME-CONSUMING. Comment out for faster debugging/execution
  <"${TMP_DIR}/backup_destination_paths.tmp" xargs -I "{}" rm --verbose --recursive --force "{}" >> "${LOG_FILE}"
  
  kill $ANIMATION_PID
  wait $ANIMATION_PID 2>/dev/null
  
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
  <"${TMP_DIR}/backup_source_paths.tmp" xargs -I "{}" sh -c "du --summarize ""{}"" 2>/dev/null | tr '\t' '#' | cut -d'#' -f1 >> ""${TMP_DIR}/estimated_backed_up_directory_sizes.tmp"""
  arithmetic_expression="$(paste --serial --delimiters=+ "${TMP_DIR}/estimated_backed_up_directory_sizes.tmp")"
  ESTIMATED_BACKUP_SIZE_IN_KB="$((arithmetic_expression))"

  kill $ANIMATION_PID
  wait $ANIMATION_PID 2>/dev/null
  
  echo "Estimated backup size: $ESTIMATED_BACKUP_SIZE_IN_KB kB"
  echo
  
  {
  echo "$(date "+%s"):$(date "+%Y/%m/%d %H:%M:%S") - LOG_BACKUP_INFO - Estimated backup size: $ESTIMATED_BACKUP_SIZE_IN_KB kB"
  echo
  } >> "${LOG_FILE}"

  echo "$(date "+%s"):$(date "+%Y/%m/%d %H:%M:%S") - LOG_BACKUP_INFO - Estimate Backup Time - End Time" >> "${LOG_FILE}"
  echo >> "${LOG_FILE}"
}

check_free_space() {
  echo "$(date "+%s"):$(date "+%Y/%m/%d %H:%M:%S") - LOG_BACKUP_INFO - Check sufficient free space on the backup drive - Start Time" >> "${LOG_FILE}"
  echo >> "${LOG_FILE}"

  linux_style_backup_disk_mountpoint_of_backup_dir_in_git_bash_in_windows="$(echo "${BACKUP_DIR}" | cut -d '/' -f 2 | tr '[:upper:]' '[:lower:]'):"
  free_space_on_disk_with_backup_dir_at_start=$(df | grep "${linux_style_backup_disk_mountpoint_of_backup_dir_in_git_bash_in_windows}" | tr -s '[:space:]' | cut -d ' ' -f 4)
  if [ $free_space_on_disk_with_backup_dir_at_start -lt $ESTIMATED_BACKUP_SIZE_IN_KB ]
  then
    echo "$(date "+%s"):$(date "+%Y/%m/%d %H:%M:%S") - LOG_BACKUP_INFO - Check sufficient free space on the backup drive - HALT: Backup size is larger than the free space on the backup drive - End Time" >> "${LOG_FILE}"
    exit 1
  fi
  
  echo "$(date "+%s"):$(date "+%Y/%m/%d %H:%M:%S") - LOG_BACKUP_INFO - Check sufficient free space on the backup drive - PASS: Enough free space available for backup on the backup drive - continuing... - End Time" >> "${LOG_FILE}"
  echo >> "${LOG_FILE}"
}

generate_files_and_dirs_list() {
  # generate source file list
  # THIS COMMAND CAN BE TIME-CONSUMING. Comment out for faster debugging/execution
  <"${TMP_DIR}/backup_source_paths.tmp" xargs -I "{}" sh -c "find "{}" >> "${TMP_DIR}/source_files_and_dirs_paths.tmp"

  # generate destination file list
  cut -d'/' -f2 --complement "${TMP_DIR}/source_files_and_dirs_paths.tmp" | cut -d'/' -f2 --complement | sed "s:^:${BACKUP_DIR}:g" > "${TMP_DIR}/destination_files_and_dirs_paths.tmp"
}

backup_files_and_folders() {
  echo "$(date "+%s"):$(date "+%Y/%m/%d %H:%M:%S") - LOG_BACKUP_INFO - Preparation for Backup of Files And Folders - Start Time" >> "${LOG_FILE}"
  echo >> "${LOG_FILE}"

  printf "¤ Backing up files\n"
  
  echo "Prosim, nechaj pocitac zapnuty, zalohuju sa subory"
  echo
  
  number_of_logs="$(find "${LOG_DIR}" -type f | wc -l)"
  
  if [ $number_of_logs -ge 2 ]
  then
    forelast_backup_log=$(find "${LOG_DIR}" -type f | sort --reverse | head -n 2 | tail -n 1)
    start_timestamp=$(head -n 1 "${forelast_backup_log}" | cut -d ':' -f1)
    end_timestamp=$(tail -n 2 "${forelast_backup_log}" | tr -d '\n' | cut -d ':' -f1)
    duration_of_last_backup_in_seconds=$(( end_timestamp - start_timestamp ))
    duration_of_last_backup_in_seconds_in_human_readable_format=$(date -d@${duration_of_last_backup_in_seconds} -u "+%-k hod. %M minut")
    echo "Posledna zaloha trvala ${duration_of_last_backup_in_seconds_in_human_readable_format}"

    estimated_backup_finish_time=$(date -d "${duration_of_last_backup_in_seconds} seconds" +"%H:%M")
    echo "Zalohovanie bude trvat priblizne 'do' ${estimated_backup_finish_time}"
    echo
  fi
  
  "${SCRIPT_DIR}"/utils/busy-animation.sh "${ESTIMATED_BACKUP_SIZE_IN_KB}" "${BACKUP_DIR}" "${LOG_FILE}" &
  ANIMATION_PID="$!"
  
  {
  echo "$(date "+%s"):$(date "+%Y/%m/%d %H:%M:%S") - LOG_BACKUP_INFO - Preparation for Backup of Files And Folders - End Time"
  echo

  echo "$(date "+%s"):$(date "+%Y/%m/%d %H:%M:%S") - LOG_BACKUP_INFO - Backup Files And Folders - Start Time"
  echo
  } >> "${LOG_FILE}"
  
  paste "${TMP_DIR}/source_files_and_dirs_paths.tmp" "${TMP_DIR}/destination_files_and_dirs_paths.tmp" | while read -r source_file destination_file
  do
    printf "%s\n%s\n\n" "${source_file}" "${destination_file}"

    #if [ -d "${TMP_DIR}/source_files_and_dirs_paths.tmp" ]; then
    #  mkdir --parents "${directory_path_from_destination_paths_file}" >> "${LOG_FILE}" 2>&1
    #fi

    # THIS COMMAND CAN BE TIME-CONSUMING. Comment out for faster debugging/execution
    #cp --verbose --force --preserve=mode,ownership,timestamps "${source_file}" "${destination_file}" >> "${LOG_FILE}" 2>&1
  done

  kill $ANIMATION_PID 2>/dev/null
  wait $ANIMATION_PID 2>/dev/null
  
  echo >> "${LOG_FILE}"
  echo "$(date "+%s"):$(date "+%Y/%m/%d %H:%M:%S") - LOG_BACKUP_INFO - Backup Files And Folders - End Time" >> "${LOG_FILE}"
}

finalize_backup() {
  kill $SHUTDOWNGUARD_PID 2>/dev/null
  wait $SHUTDOWNGUARD_PID 2>/dev/null

  SHUTDOWNGUARD_WINPID="$(ps --windows | grep ShutdownGuard | tr -s ' ' | cut -d ' ' -f5)"
  taskkill //F //PID "${SHUTDOWNGUARD_WINPID}" 2>&1 1>nul
  tskill "${SHUTDOWNGUARD_WINPID}" 2>&1 1>/dev/null

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
  kill $ANIMATION_PID 2>/dev/null
  wait $ANIMATION_PID 2>/dev/null
  
  kill $SHUTDOWNGUARD_PID 2>/dev/null
  wait $SHUTDOWNGUARD_PID 2>/dev/null
  
  SHUTDOWNGUARD_WINPID="$(ps --windows | grep ShutdownGuard | tr -s ' ' | cut -d ' ' -f5)"
  taskkill //F //PID "${SHUTDOWNGUARD_WINPID}" 2>&1 1>nul
  tskill "${SHUTDOWNGUARD_WINPID}" 2>&1 1>/dev/null

  printf "Backup exitted prematurely"
  exit 1
}

# For standalone script testing
handle_Ctrl_C_interrupt() {
  handle_default_kill
}

main() {
  start_support_processes
  show_info_message
  clean_temp_files
  clean_backup_directory
  estimate_backup_size

  # TODO test function check_free_space to check whether the backup drive has enough free space to carry the entire backup
  check_free_space
  generate_files_and_dirs_list

  backup_files_and_folders
  finalize_backup
}

main

