#!/bin/sh

SCRIPT_DIR="$(dirname "$(readlink --canonicalize "$0")")"
LOG_DIR="${SCRIPT_DIR}/logs"

DATE_AND_TIME_FOR_LOG_ENTRIES=$(date "+%s")
DATE_AND_TIME_FOR_FILENAME=$(date "+%Y_%m_%d-%H_%M_%S")

LOG_FILE="${LOG_DIR}/backup-${DATE_AND_TIME_FOR_FILENAME}.log"

SHUTDOWNGUARD_PID=0
ANIMATION_PID=0

ESTIMATED_BACKUP_SIZE_IN_KB=0

#TODO replace BACKUP_FOLDER with the line below
#BACKUP_FOLDER="$(cat backup.conf | head -n 1 | cut -d'=' -f2)"
BACKUP_FOLDER="/d"

#TODO remove array because it doesn't conform to POSIX standard - using backup.conf file and xargs instead
DIRECTORIES_FOR_BACKUP=(
  "/c/Users/${USERNAME}/Desktop"
  "/c/Users/${USERNAME}/AppData"
  "/c/Users/${USERNAME}/Downloads"
  "/c/Users/${USERNAME}/Documents"
  "/c/Users/${USERNAME}/Pictures"
  "/c/Programme"
)

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
  
  echo "¤ Clearing temporary files"
  ${SCRIPT_DIR}/utils/windows_cleaner/windows_cleaner-clean.sh
  echo
}

clean_backup_directory() {
  echo "¤ Cleaning backup directory"
  echo
  
  "${SCRIPT_DIR}"/utils/busy-animation.sh &
  ANIMATION_PID="$!"

  for dir_index in ${!DIRECTORIES_FOR_BACKUP[@]}
  do
    directory_for_deletion="${DIRECTORIES_FOR_BACKUP[$dir_index]}"
    path_for_deletion="${BACKUP_FOLDER}"
    source_drive="/$(echo "$directory_for_deletion" | cut -d'/' -f2)"
    directory_for_deletion_without_drive_name=$(echo ${directory_for_deletion#$source_drive})
    path_for_deletion+="${directory_for_deletion_without_drive_name}"
    
    rm -vrf "${path_for_deletion}" >> "${LOG_FILE}" 2>&1
  done

  #TODO replace for loop with xargs command
  #cat backup.conf | tail -n +1 | xargs -I '{}' printf "{}\n"
  #cat backup.conf | tail -n +1 | xargs -I '{}' rm --verbose --recursive --force "{}"
  
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
  cat /dev/null > "${LOG_DIR}/backup_entries_size.log"
  
  # compute new directory sizes
  cat --squeeze-blank backup.conf | grep -v '^[[:space:]]*$' | tail -n +2 | xargs -I "{}" sh -c "du --summarize "{}" 2>/dev/null | tr '\t' '#' | cut -d'#' -f1 >> "${LOG_DIR}/backup_entries_size.log""
  
  arithmetic_expression="$(paste --serial --delimiters=+ "${LOG_DIR}/backup_entries_size.log")"
  ESTIMATED_BACKUP_SIZE_IN_KB="$((arithmetic_expression))"

  kill $ANIMATION_PID
  wait $ANIMATION_PID 2>/dev/null
  
  echo "  Estimated backup size: $ESTIMATED_BACKUP_SIZE_IN_KB" KB
  echo
  
  echo "${DATE_AND_TIME_FOR_LOG_ENTRIES}:$(date "+%Y/%m/%d %H:%M:%S") - LOG_BACKUP_INFO - Estimate Backup Time - End Time" >> "${LOG_FILE}"
  echo >> "${LOG_FILE}"
}

copy_file() {
  SOURCE="$1"
  DESTINATION="$2"
  
  # Prevent error "cp cannot create directory No such file or directory" present in the log file
  #  by creating a destination directory before actual copying
  #  https://unix.stackexchange.com/questions/511477/cannot-create-directory-no-such-file-or-directory/511480#511480
  mkdir --parents "${DESTINATION}" 2>/dev/null
  cp --recursive --verbose --force --preserve=mode,ownership,timestamps "${SOURCE}" "${DESTINATION}" >> "${LOG_FILE}" 2>&1
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
  
  ESTIMATED_BACKUP_SIZE_IN_KB=200000000
  "${SCRIPT_DIR}"/utils/busy-animation.sh "$ESTIMATED_BACKUP_SIZE_IN_KB" &
  ANIMATION_PID="$!"
  
  echo "${DATE_AND_TIME_FOR_LOG_ENTRIES}:$(date "+%Y/%m/%d %H:%M:%S") - LOG_BACKUP_INFO - Preparation for Backup of Files And Folders - End Time" >> "${LOG_FILE}"
  echo >> "${LOG_FILE}"

  echo >> "${LOG_FILE}"
  echo "${DATE_AND_TIME_FOR_LOG_ENTRIES}:$(date "+%Y/%m/%d %H:%M:%S") - LOG_BACKUP_INFO - Backup Files And Folders - Start Time" >> "${LOG_FILE}"
  echo >> "${LOG_FILE}"
  
  for dir_index in ${!DIRECTORIES_FOR_BACKUP[@]}
  do
    directory_for_backup="${DIRECTORIES_FOR_BACKUP[$dir_index]}"
    backup_path="${BACKUP_FOLDER}"
    source_drive="/$(echo "$directory_for_backup" | cut -d'/' -f2)"
    directory_for_backup_without_drive_name=$(echo ${directory_for_backup#$source_drive})
    backup_path+="${directory_for_backup_without_drive_name}"
    
    copy_file "${directory_for_backup}" "${backup_path}" >> "${LOG_FILE}" 2>&1
  done
  
  #TODO replace for loop with xargs command
  #cat backup.conf | tail -n +1 | grep -v "^$" | xargs -I '{}' printf "{}\n"
  #cat backup.conf | grep -v "^$" | tail -n +2 > LOG_DIR/backup_source_paths.log
  #cat backup.conf | grep -v "^$" | tail -n +2 | cut -d'/' -f2 --complement | sed 's:^:/d:g' > LOG_DIR/backup_destination_paths.log
  #paste LOG_DIR/backup_source_paths.log LOG_DIR/backup_destination_paths.log > LOG_DIR/backup_source_and_destination_paths.log
  #cat LOG_DIR/backup_source_and_destination_paths.log | xargs -I '{}' sh -c "copy_file "$(echo '{}' | cut -d'  ' -f1)" "$(echo '{}' | cut -d'  ' -f2)""

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
  
  read -r -p "Stlacte lubovolnu klavesu na zatvorenie okna..."
  echo
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

