# Windows Backup Script

Add this tutorial to my repo "Windows_tutorials"

## Usage

        cd /path/to/repository/
        ./backup.sh

The rest will handle the script with the configuration file.

## Script description

Script operations

1. Format backup drive
1. Backup folders
1. Show message that the backup has completed

## Task scheduling

TODO add guide how to add a new backup task in `Task Scheduler` in Windows

- as current user - without elevated priviledges - priviledges will be requested at runtime

## Syncing between computers

        rm -rf "/run/media/laptop/7E88A51688A4CE49/$(pwd | rev | cut -d '/' -f1 | rev)"
        mkdir "/run/media/laptop/7E88A51688A4CE49/$(pwd | rev | cut -d '/' -f1 | rev)"

        # TODO pre-push routine - copying to/from NTFS`<->`ext4 filesystems changes executable permissions
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

