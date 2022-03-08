# Windows Backup Script
 
Add this tutorial to my repo "Windows_tutorials"
 
## Usage
 
        cd /path/to/repository/
        ./backup.sh
 
The rest will handle the script with the configuration file.
 
## Script description
 
Script operations
 
1. Clean backup folers listed in configuration
1. Clean up Windows
1. Backup folders listed in configuration
1. Show message that the backup has completed
 
## Task scheduling
 
- as current user - without elevated priviledges - priviledges will be requested at runtime
 
1. Right click on `My computer -> Manage`. Enter admin password if prompted.
1. In the left panel navigate to `System Tools -> Task Scheduler -> Task Scheduler Library`
1. In the right panel click on `Create Task`
    1. Tab `General`
        - Name: `Start KVM server`
    1. Tab `Triggers`
        - Begin the task: `On a schedule`
        - In the `Settings` section
            - `Weekly`
            - Start: `<the date of this or next Sunday>` `6:00:00` (in the morning hours)
                - because on Sunday morning there is the least chance someone will be working on the computer
            - Recur every `1` weeks on: `Sunday`
        - check `Enabled` at the bottom of the window
        - uncheck/disable everything else
    1. Tab `Actions`
        - `New...`
          - Action: `Start a program`
          - Program/script: `C:\Programme\Git\git-bash.exe`
          - Add arguments (optional): `"/c/Users/Ňuchovia/git/windows_backup/windows_backup/backup.sh"`
          - OK
    1. Tab `Conditions`
        - uncheck `Start the task only if the computer is on AC power`
    1. Tab `Settings`
        - If the task is already running, then the following rule applies: `Do not start a new instance`
    1. OK
1. OK
 
Test whether the task launches
 
## Syncing between computers
 
        rm -rf "/run/media/laptop/7E88A51688A4CE49/$(pwd | rev | cut -d '/' -f1 | rev)"
        mkdir "/run/media/laptop/7E88A51688A4CE49/$(pwd | rev | cut -d '/' -f1 | rev)"
 
        # TODO pre-commit/pre-add? routine - copying to/from NTFS`<->`ext4 filesystems changes executable permissions
        find . -name *.txt | grep -v ".*\.git\>" | xargs chmod -x
        find . -name *.log | grep -v ".*\.git\>" | xargs chmod -x
        find . -name *.tmp | grep -v ".*\.git\>" | xargs chmod -x
        find . -name *.ini | grep -v ".*\.git\>" | xargs chmod -x
        find . -name *.md | grep -v ".*\.git\>" | xargs chmod -x
        chmod -x .gitignore
        # end of pre-push routine
 
        rsync --archive --verbose --progress "." "/run/media/laptop/7E88A51688A4CE49/$(pwd | rev | cut -d '/' -f1 | rev)" --exclude ".git" --dry-run
 
Or one-liner
 
        rm -rf "/run/media/laptop/7E88A51688A4CE49/$(pwd | rev | cut -d '/' -f1 | rev)" && mkdir "/run/media/laptop/7E88A51688A4CE49/$(pwd | rev | cut -d '/' -f1 | rev)" && rsync --archive --verbose --progress "." "/run/media/laptop/7E88A51688A4CE49/$(pwd | rev | cut -d '/' -f1 | rev)" --exclude ".git"
 
## Sources - Task Scheduler
 
- https://www.windowstricks.in/2018/08/how-to-run-the-powershell-script-in-scheduled-task-with-run-as-administrator.html
-  https://www.sevenforums.com/tutorials/211758-task-scheduler-create-task-display-message-reminder.html
- https://stackoverflow.com/questions/11013132/how-can-i-enable-the-windows-server-task-scheduler-history-recording/14651161#14651161
- http://woshub.com/schedule-task-to-start-when-another-task-finishes/
- https://stackoverflow.com/questions/41497122/keeping-powershell-window-open-and-task-scheduler
- https://stackoverflow.com/questions/41497122/keeping-powershell-window-open-and-task-scheduler/41497344#41497344
- https://stackoverflow.com/questions/20886243/press-any-key-to-continue/20886446#20886446
- https://www.dev-tips-and-tricks.com/run-a-node-script-with-windows-task-scheduler
- https://joshuatz.com/posts/2020/using-windows-task-scheduler-to-automate-nodejs-scripts/
 
## Sources - Shell
 
- https://stackoverflow.com/questions/39847496/cp-cannot-create-directory-no-such-file-or-directory
- https://unix.stackexchange.com/questions/511477/cannot-create-directory-no-such-file-or-directory/511480#511480
- Execute Bash Script (Using Git Bash) from Windows Task Scheduler
 - https://gist.github.com/damc-dev/eb5e1aef001eef78c0f4
- https://stackoverflow.com/questions/3432555/remove-blank-lines-with-grep
https://github.com/shivansh/TCP-IP-Regression-TestSuite/commit/8f1fb4c4f5a96b1605f72f3fc109ec93ae188929
- https://duckduckgo.com/?q=xargs+pipe&ia=web&iax=qa
- https://duckduckgo.com/?q=bash+sum+number&ia=web
- https://duckduckgo.com/?q=concatenate+files+by+columns+bash&ia=web
- https://duckduckgo.com/?q=cut+by+tab+linux&ia=web
- https://www.ibm.com/docs/en/zos/2.2.0?topic=descriptions-xargs-construct-argument-list-run-command
- https://duckduckgo.com/?q=xargs+pipe&ia=web&iax=qa
- https://unix.stackexchange.com/questions/209249/piping-commands-after-a-piped-xargs#209250
- https://duckduckgo.com/?q=bash+sum+number&ia=web
- https://stackoverflow.com/questions/3096259/bash-command-to-sum-a-column-of-numbers#3096575
- https://duckduckgo.com/?q=concatenate+files+by+columns+bash&ia=web
- https://stackoverflow.com/questions/11160145/merge-two-files-in-linux-with-different-column#11160289
- https://duckduckgo.com/?q=cut+by+tab+linux&ia=web
- https://unix.stackexchange.com/questions/35369/how-to-define-tab-delimiter-with-cut-in-bash#35370
- https://duckduckgo.com/?q=iterate+two+files+bash&ia=web&iax=qa
- https://stackoverflow.com/questions/18909957/how-to-use-bash-script-to-loop-through-two-files#18910011
- https://stackoverflow.com/questions/27601143/replace-shortest-string-match-in-bash
- https://unix.stackexchange.com/questions/144298/delete-the-last-character-of-a-string-using-string-manipulation-in-shell-script/144308#144308
- https://askubuntu.com/questions/743493/best-way-to-read-a-config-file-in-bash
- https://stackoverflow.com/questions/39552070/how-to-copy-contents-in-a-directory-to-my-current-directory-in-shell/39552096#39552096
- https://duckduckgo.com/?q=posix+shell+cheat+sheet&ia=cheatsheet
- https://steinbaugh.com/posts/posix.html
- https://tecadmin.net/create-a-infinite-loop-in-shell-script/
- https://duckduckgo.com/?q=posix+and+if+statement+compound&ia=web
- https://duckduckgo.com/?q=while+if+condition+statement+bash+compound&ia=web
- https://stackoverflow.com/questions/14964805/groups-of-compound-conditions-in-bash-test
- https://duckduckgo.com/?q=while+loop+condition+bash&ia=web
- https://linuxize.com/post/bash-while-loop/
- https://duckduckgo.com/?q=printf+dash+print+invalid+argument&ia=web
- https://duckduckgo.com/?q=posix+shell+concatenate+append+string&ia=web
- https://www.baeldung.com/linux/concatenate-strings-to-build-path
- **https://github.com/koalaman/shellcheck/wiki/Checks**
- https://gist.github.com/eggplants/9fbe03453c3f3fd03295e88def6a1324#file-_shellcheck-csv
- https://github.com/koalaman/shellcheck/wiki/SC3024
- https://unix.stackexchange.com/questions/519315/using-printf-to-print-variable-containing-percent-sign-results-in-bash-p
- https://duckduckgo.com/?q=compound+variable+name+bash&ia=web
- https://github.com/koalaman/shellcheck/wiki/SC3054
- https://unix.stackexchange.com/questions/9468/how-to-get-the-char-at-a-given-position-of-a-string-in-shell-script
- https://duckduckgo.com/?q=cut+substring+character+wise+posix+shell&ia=web
- https://stackoverflow.com/questions/18397698/how-to-cut-a-string-after-a-specific-character-in-unix
- https://www.cyberciti.biz/faq/unix-linux-appleosx-bsd-bash-count-characters-variables/
- https://duckduckgo.com/?q=redirect+error+output+to+stdout+and+append+to+file&ia=web
- https://stackoverflow.com/questions/876239/how-to-redirect-and-append-both-standard-output-and-standard-error-to-a-file-wit#876242
- https://www.cyberciti.biz/faq/linux-redirect-error-output-to-file/
- https://unix.stackexchange.com/questions/32180/testing-if-a-variable-is-empty-in-a-shell-script
- https://pubs.opengroup.org/onlinepubs/009695399/utilities/test.html#tag_04_140_05
- https://duckduckgo.com/?q=directory+name+posix+shell&ia=web
- https://stackoverflow.com/questions/4585929/how-to-use-cp-command-to-exclude-a-specific-directory/14789400#14789400
- https://unix.stackexchange.com/questions/3593/using-xargs-with-input-from-a-file/3598#3598
- https://www.tutorialspoint.com/how-to-find-and-sort-files-based-on-modification-date-and-time-in-linux
- ShellCheck: Consider using { cmd1; cmd2; } >> file instead of individual redirects.: https://github.com/koalaman/shellcheck/wiki/SC2129
- ShellCheck: To redirect stdout+stderr, 2>&1 must be last (or use `{ cmd > file; } 2>&1` to clarify).: https://www.shellcheck.net/wiki/SC2069 -- To redirect stdout+stderr, 2>&1 m...
- ShellCheck: Word is of the form "A"B"C" (B indicated). Did you mean "ABC" or "A\\"B\\"C"?:  https://www.shellcheck.net/wiki/SC2140 -- Word is of the form "A"B"C" (B in...
- ShellCheck: Consider using pgrep instead of grepping ps output.: https://www.shellcheck.net/wiki/SC2009 -- Consider using pgrep instead of g...
  - `pgrep` no available in `Git Bash`. Using `ps` + `grep` instead. At the thime of writing it gives the expected output of returning the PID and the state of the process (running/stopped).
- ShellCheck: Don't use variables in the printf format string. Use printf "..%s.." "$foo".: https://www.shellcheck.net/wiki/SC2059 -- Don't use variables in the printf...
- ShellCheck: Double quote to prevent globbing and word splitting.: https://www.shellcheck.net/wiki/SC2086 -- Double quote to prevent globbing ...
- ShellCheck: `$/${}` is unnecessary on arithmetic variables.: https://www.shellcheck.net/wiki/SC2004 -- $/${} is unnecessary on arithmeti...
- https://stackoverflow.com/questions/3298866/how-can-a-shell-script-control-another-script
- https://tldp.org/LDP/abs/html/extmisc.html#MKFIFOREF
- 16.9. Miscellaneous Commands: mkfifo: https://tldp.org/LDP/abs/html/extmisc.html#MKFIFOREF
- https://duckduckgo.com/?q=named+pipes+shell+two+scripts&ia=web
- https://linuxconfig.org/introduction-to-named-pipes-on-bash-shell
- https://stackoverflow.com/questions/32497732/give-output-of-one-shell-script-as-input-to-another-using-named-pipes
- https://duckduckgo.com/?q=stderr+redirect+2%3E%261+must+be+last&ia=web
- https://csatlas.com/bash-redirect-stdout-stderr/#order_matters
- https://unix.stackexchange.com/questions/631208/when-redirecting-both-stdout-and-stderr-to-a-file-why-must-the-redirection-of-s
- https://duckduckgo.com/?q=ntfs+path+length+limit&ia=web
- https://stackoverflow.com/questions/19214179/bash-get-intersection-from-multiple-files/19214329#19214329
- https://duckduckgo.com/?q=find+print0+xargs+-0&ia=web
- https://dbrinegar.github.io/2014/12/12/find-xargs/
- https://duckduckgo.com/?q=xargs+doesnt+handle+properly+null&ia=web
- https://www.golinuxcloud.com/find-exec-multiple-commands-examples-unix/
- https://www.gnu.org/software/findutils/manual/html_node/find_html/Unusual-Characters-in-File-Names.html
- https://stackoverflow.com/questions/19008614/find-files-with-illegal-windows-characters-in-the-name-on-linux
- https://duckduckgo.com/?q=bash+unary+operator+expected+-lt&ia=web
- https://debugah.com/solved-shell-script-ge-le-unary-operator-expected-standard_in-1-syntax-error-12747/
  - check, whether the variable is initialized, e.g. with `set -x` at the beginning of the script
- https://unix.stackexchange.com/questions/432463/eq-unary-operator-expected-shell-argument-parsing
- https://duckduckgo.com/?q=shell+script+linux+terminal+substring+variable&ia=web
- https://www.baeldung.com/linux/bash-substring
- https://serverfault.com/questions/178101/most-simple-way-of-extracting-substring-in-unix-shell/178104#178104
- https://duckduckgo.com/?q=find+non+alphanumeric+characters+linux+-0&ia=web
- https://www.ed.ac.uk/records-management/guidance/records/practical-guidance/naming-conventions/non-ascii-characters
- https://askubuntu.com/questions/76808/how-do-i-use-variables-in-a-sed-command/76842#76842
- https://stackoverflow.com/questions/17075070/paste-side-by-side-multiple-files-by-numerical-order
- https://duckduckgo.com/?q=cut+by+tab&ia=web
- https://unix.stackexchange.com/questions/35369/how-to-define-tab-delimiter-with-cut-in-bash
- https://unix.stackexchange.com/questions/18886/why-is-while-ifs-read-used-so-often-instead-of-ifs-while-read/18936#18936
- https://duckduckgo.com/?q=while+read+bash+file&ia=web
- https://linuxhint.com/while_read_line_bash/
- https://stackpointer.io/unix/unix-linux-count-occurrences-character-string/531/
- https://itectec.com/unixlinux/bash-find-and-globbing-and-wildcards/
- https://www.geeksforgeeks.org/string-manipulation-in-shell-scripting/
- https://duckduckgo.com/?q=xargs+argument+line+too+long&ia=web&iax=qa
- https://serverfault.com/questions/496720/xargs-too-long-argument-list
- https://duckduckgo.com/?q=find+all+files+with+quotes+special+character+linux&ia=web
- https://www.linux.com/training-tutorials/linux-shell-tip-remove-files-names-contains-spaces-and-special-characters-such/
- https://stackoverflow.com/questions/19214179/bash-get-intersection-from-multiple-files/19214329#19214329
- https://duckduckgo.com/?q=git+bash+execute+batch+file&ia=web
- https://duckduckgo.com/?q=git+bash+taskkill&ia=web
- https://stackoverflow.com/questions/34981745/taskkill-pid-not-working-in-gitbash
- https://duckduckgo.com/?q=tskill+git+bash&ia=web
- https://duckduckgo.com/?q=cp+copy+only+directory+without+files&ia=web
- https://stackoverflow.com/questions/4073969/copy-folder-structure-without-files-from-one-location-to-another/4073992#4073992
- https://stackoverflow.com/questions/4073969/copy-folder-structure-without-files-from-one-location-to-another/4073999#4073999
- https://duckduckgo.com/?q=cp+copy+file+even+when+the+destination+directory+doesnt+not+exist&ia=web
- https://devblogs.microsoft.com/oldnewthing/20141031-00/?p=43723
- https://duckduckgo.com/?q=bash+variable+expansion+substring+longest&ia=web
- https://duckduckgo.com/?q=bash+longest+match+variable+substring&ia=web
- https://www.thegeekstuff.com/2010/07/bash-string-manipulation/
- https://stackoverflow.com/questions/6958689/running-multiple-commands-with-xargs#6958957
- https://www.computerhope.com/unix/urmdir.htm
- https://superuser.com/questions/455723/is-there-an-upwards-find
- https://man.openbsd.org/xargs.1
- https://stackoverflow.com/questions/15430877/bash-xargs-passing-variable/15434248#15434248
- https://www.systutorials.com/how-to-unexport-an-exported-variable-in-bash-on-linux/
 
Defining function before using/calling the function in shell scripts in this order seems to be important in shell scripts, to ensure safe and predictable execution, and avoid undefined behavior.
 
## Command Prompt
 
- https://www.shellhacks.com/windows-taskkill-kill-process-by-pid-name-port-cmd/
- https://stackoverflow.com/questions/4507312/how-to-redirect-stderr-to-null-in-cmd-exe#4507627
- https://docs.microsoft.com/en-us/previous-versions/windows/it-pro/windows-xp/bb490982(v=technet.10)?redirectedfrom=MSDN
- https://docs.microsoft.com/en-us/windows-server/administration/windows-commands/xcopy
- https://duckduckgo.com/?q=xcopy+%2Fe+%2Fi+%2Ff+%2Fc+%2Fk+%2Fr+%2Fh+%2Fm+%2Fo+%2Fx+%2Fy&ia=web
 
