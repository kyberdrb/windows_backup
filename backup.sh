#!/bin/sh

SCRIPT_DIR="$(dirname "$(readlink --canonicalize "$0")")"
LOG_DIR="${SCRIPT_DIR}/logs"

DATE_AND_TIME_FOR_LOG_ENTRIES=$(date "+%s")
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

  echo "${DATE_AND_TIME_FOR_LOG_ENTRIES}:$(date "+%Y/%m/%d %H:%M:%S") - LOG_BACKUP_INFO - Cleanup - Start Time" >> "${LOG_FILE}"
  echo >> "${LOG_FILE}"
  
  rm --verbose --recursive --force "${TMP_DIR}" >> "${LOG_FILE}"
  mkdir --parents "${TMP_DIR}"
  
  echo "¤ Clearing temporary files"
  "${SCRIPT_DIR}/utils/windows_cleaner/windows_cleaner-clean.sh"
  echo
}

clean_backup_directory() {
  echo "¤ Cleaning backup directory"
  echo
  
  "${SCRIPT_DIR}"/utils/busy-animation.sh &
  ANIMATION_PID="$!"
  
  # at first, clean configuration file from carriage return characters
  #  to prevent (surprising and confusing) error messages
  #  when reading lines with paths from file 
  #  and doing operations with them like 'ls' or 'cp'
  #  and ending up with errors like "No such file or directory"
  
  cat backup.conf | grep -v '^[[:space:]]*$' | tr -d '\r' > "${TMP_DIR}/backup.conf.cleansed.tmp"

  BACKUP_FOLDER="$(cat "${TMP_DIR}/backup.conf.cleansed.tmp" | head -n 1 | cut -d'=' -f2)"
  
  cat "${TMP_DIR}/backup.conf.cleansed.tmp" | tail -n +2 > "${TMP_DIR}/backup_source_paths.tmp"
   
  cat "${TMP_DIR}/backup.conf.cleansed.tmp" | tail -n +2 | cut -d'/' -f2 --complement | sed "s:^:${BACKUP_FOLDER}:g" > "${TMP_DIR}/backup_destination_paths.tmp"
  
  cat "${TMP_DIR}/backup_destination_paths.tmp" | xargs -I "{}" rm --verbose --recursive --force ""{}"" >> "${LOG_FILE}"
  
  kill $ANIMATION_PID
  wait $ANIMATION_PID 2>/dev/null
  
  echo >> "${LOG_FILE}"
  echo "${DATE_AND_TIME_FOR_LOG_ENTRIES}:$(date "+%Y/%m/%d %H:%M:%S") - LOG_BACKUP_INFO - Cleanup - End Time" >> "${LOG_FILE}"
  echo >> "${LOG_FILE}"
}

estimate_backup_size() {
  echo "${DATE_AND_TIME_FOR_LOG_ENTRIES}:$(date "+%Y/%m/%d %H:%M:%S") - LOG_BACKUP_INFO - Estimate Backup Time - Start Time" >> "${LOG_FILE}"
  echo >> "${LOG_FILE}"

  echo "¤ Estimating backup size"
  
  "${SCRIPT_DIR}"/utils/busy-animation.sh &
  ANIMATION_PID="$!"
  
  # empty content of file with previous computed directory sizes
  cat /dev/null > "${TMP_DIR}/backup_source_paths.tmp"
  
  # compute new directory sizes
  cat --squeeze-blank "${TMP_DIR}/backup.conf.cleansed.tmp" | grep -v '^[[:space:]]*$' | tail -n +2 | xargs -I "{}" sh -c "du --summarize "{}" 2>/dev/null | tr '\t' '#' | cut -d'#' -f1 >> "${TMP_DIR}/backup_source_paths.tmp""
  
  arithmetic_expression="$(paste --serial --delimiters=+ "${TMP_DIR}/backup_source_paths.tmp")"
  ESTIMATED_BACKUP_SIZE_IN_KB="$((arithmetic_expression))"

  kill $ANIMATION_PID
  wait $ANIMATION_PID 2>/dev/null
  
  echo "  Estimated backup size: $ESTIMATED_BACKUP_SIZE_IN_KB" KB
  echo
  
  echo "${DATE_AND_TIME_FOR_LOG_ENTRIES}:$(date "+%Y/%m/%d %H:%M:%S") - LOG_BACKUP_INFO - Estimate Backup Time - End Time" >> "${LOG_FILE}"
  echo >> "${LOG_FILE}"
}

backup_files_and_folders() {
  echo "${DATE_AND_TIME_FOR_LOG_ENTRIES}:$(date "+%Y/%m/%d %H:%M:%S") - LOG_BACKUP_INFO - Preparation for Backup of Files And Folders - Start Time" >> "${LOG_FILE}"
  echo >> "${LOG_FILE}"

  echo "¤ Backing up files"
  echo
  
  echo "Prosim, nechaj pocitac zapnuty, zalohuju sa subory"
  echo
  
  forelast_backup_log_filename=$(ls -c1 "${LOG_DIR}/" | head -n 2 | tail -n 1)
  forelast_backup_log="${LOG_DIR}/${forelast_backup_log_filename}"
  start_timestamp=$(head -n 1 "${forelast_backup_log}" | cut -d ':' -f1)
  end_timestamp=$(tail -n 2 "${forelast_backup_log}" | cut -d ':' -f1 | tr -d '\n')
  duration_of_last_backup_in_seconds=$(( end_timestamp - start_timestamp ))
  duration_of_last_backup_in_seconds_in_human_readable_format=$(date -d@${duration_of_last_backup_in_seconds} -u "+%-k hod. %M minut")
  echo "Posledna zaloha trvala ${duration_of_last_backup_in_seconds_in_human_readable_format}"
  
  estimated_backup_finish_time=$(date -d "${duration_of_last_backup_in_seconds} seconds" +"%H:%M")
  echo "Zalohovanie bude trvat priblizne do ${estimated_backup_finish_time}"
  echo
  
  "${SCRIPT_DIR}"/utils/busy-animation.sh "$ESTIMATED_BACKUP_SIZE_IN_KB" &
  ANIMATION_PID="$!"
  
  echo "${DATE_AND_TIME_FOR_LOG_ENTRIES}:$(date "+%Y/%m/%d %H:%M:%S") - LOG_BACKUP_INFO - Preparation for Backup of Files And Folders - End Time" >> "${LOG_FILE}"
  echo >> "${LOG_FILE}"

  echo >> "${LOG_FILE}"
  echo "${DATE_AND_TIME_FOR_LOG_ENTRIES}:$(date "+%Y/%m/%d %H:%M:%S") - LOG_BACKUP_INFO - Backup Files And Folders - Start Time" >> "${LOG_FILE}"
  echo >> "${LOG_FILE}"
  
  paste "${TMP_DIR}/backup_source_paths.tmp" "${TMP_DIR}/backup_destination_paths.tmp" | while read directory_path_from_source_paths_file directory_path_from_destination_paths_file
  do
    # to prevent duplicate target directory entries e.g.
    #   '/c/programme/programme'
    #  instead go in the directory structure one level up
    #  and copy it onto the current directory
    
    destination_directory_path_one_level_above="${directory_path_from_destination_paths_file}/.."
    
    # Prevent error "cp cannot create directory No such file or directory" present in the log file
    #  by creating a destination directory before actual copying
    #  https://unix.stackexchange.com/questions/511477/cannot-create-directory-no-such-file-or-directory/511480#511480
    
    mkdir --parents "${directory_path_from_destination_paths_file}" 2>/dev/null
    
    cp --recursive --verbose --force --preserve=mode,ownership,timestamps "${directory_path_from_source_paths_file}" "${destination_directory_path_one_level_above}" >> "${LOG_FILE}"
  done

  kill $ANIMATION_PID 2>/dev/null
  wait $ANIMATION_PID 2>/dev/null
  
  echo "${DATE_AND_TIME_FOR_LOG_ENTRIES}:$(date "+%Y/%m/%d %H:%M:%S") - LOG_BACKUP_INFO - Backup Files And Folders - End Time" >> "${LOG_FILE}"
  echo >> "${LOG_FILE}"
}

finalize_backup() {
  kill $SHUTDOWNGUARD_PID 2>/dev/null
  wait $SHUTDOWNGUARD_PID 2>/dev/null

  echo "¤ Backup complete"
  echo
  
  echo >> "${LOG_FILE}"
  echo "${DATE_AND_TIME_FOR_LOG_ENTRIES}:$(date "+%Y/%m/%d %H:%M:%S") - LOG_BACKUP_INFO - Finish - End Time" >> "${LOG_FILE}"
  echo >> "${LOG_FILE}"
  
  echo "Teraz mozes pocitac bezpecne vypnut"
  echo
  
  printf "Stlacte lubovolnu klavesu na zatvorenie okna..."
  read -r
}

trap handle_default_kill TERM
trap handle_Ctrl_C_interrupt INT

# For usual script termination
handle_default_kill() {
  kill $ANIMATION_PID 2>/dev/null
  wait $ANIMATION_PID 2>/dev/null
  
  kill $SHUTDOWNGUARD_PID 2>/dev/null
  wait $SHUTDOWNGUARD_PID 2>/dev/null
  
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
  backup_files_and_folders
  finalize_backup
}

main

