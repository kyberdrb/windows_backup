# Windows Disk Cleaner

An utility for automatic cleaning of safe files.

## Dependencies / Prerequisites

[gsudo](https://github.com/gerardog/gsudo/releases/latest)

Reboot after installation, although it's not requested in the installation wizard.


### `gsudo` configuration

**Enable password cache to prolong duration validity of sudo password.**

For convenience.

Execute these commands in Git Bash, **cmd** or PowerShell

    gsudo config CacheMode auto
    gsudo config CacheDuration "3:00:00"
    gsudo cache off
    gsudo --reset-timestamp
    gsudo cache on
	
From now on you will not be annoyed with UAC password prompt at every `gsudo` invocation.

### Disk Clean-up configuration

1. Open _Command Prompt_

        cmd
		
1. Change to the directory with this script, e.g.

        cd C:\Users\%USERNAME%\git\Windows_tutorials\windows_cleaner

1. Set cleanup parameters

        windows_cleaner-set_parameters.cmd

    Selected categories that will be cleaned.
	
    Confirm settings by clicking on _OK_
	
	Repeat this step for the cleanup with administrator priviledges - more thorough cleaning

## Sources

- https://ss64.com/nt/cleanmgr.html
- https://ss64.com/nt/cleanmgr-registry.html
- https://answers.microsoft.com/en-us/windows/forum/all/cleanmgr-sageset-and-sagerun/f58f131f-ddd4-4e61-a013-0fe745204234
- https://www.sevenforums.com/tutorials/76383-disk-cleanup-extended.html
- https://zamarax.com/2020/08/26/how-to-run-disk-cleanup-cleanmgr-exe-on-windows-server-2016-2012-r2-2008-r2/
- https://ss64.com/nt/runas.html
- https://superuser.com/questions/42537/is-there-any-sudo-command-for-windows/42540#42540
- https://www.windows-commandline.com/windows-runas-command-prompt/
- https://answers.microsoft.com/en-us/windows/forum/windows_10-windows_install/how-to-elevate-to-administrator-from-cmd-prompt/cefedf35-7409-4f24-b30a-f1ab363fa97e
- https://superuser.com/questions/735457/elevate-cmd-to-admin-with-command-prompt
- https://superuser.com/questions/1381355/sudo-equivalent-on-windows-cmd
- https://github.com/gerardog/gsudo

---

Bash arrays

- 'for' loop that processes each element separately was inspired by https://stackoverflow.com/questions/38602587/bash-for-loop-output-index-number-and-element/43979315#43979315
- https://linuxhandbook.com/bash-arrays/
- https://www.shell-tips.com/bash/arrays/
- https://www.cyberciti.biz/faq/finding-bash-shell-array-length-elements/
- https://stackoverflow.com/questions/46136611/how-to-define-array-in-multiple-lines-in-shell

---

- https://codesteps.com/2018/07/31/windows-display-running-processes-from-command-prompt-using-tasklist-exe/
- https://linuxize.com/post/bash-wait/
- https://askubuntu.com/questions/25681/can-scripts-run-even-when-they-are-not-set-as-executable/25690#25690
- https://www.diskinternals.com/linux-reader/bash-wait-for-command-to-finish/
- https://stackoverflow.com/questions/8435112/batch-file-tasklist-findstr
- https://www.cyberciti.biz/faq/unix-linux-bash-script-check-if-variable-is-empty/
- https://unix.stackexchange.com/questions/464652/is-there-any-difference-between-tee-and-when-using-echo/464654#464654
- https://www.man7.org/linux/man-pages/man1/tee.1.html
- https://www.tecmint.com/empty-delete-file-content-linux/
- https://askubuntu.com/questions/385528/how-to-increment-a-variable-in-bash#385532
- https://stackoverflow.com/questions/9258387/bash-ampersand-operator
- https://unix.stackexchange.com/questions/75616/always-redirect-error-to-dev-null
- https://stackoverflow.com/questions/35244508/supressing-permission-denied-warning-in-du-command
- https://stackoverflow.com/questions/81520/how-to-suppress-terminated-message-after-killing-in-bash#5722874
- https://stackoverflow.com/questions/9008824/how-do-i-get-the-difference-between-two-dates-under-bashň
- https://stackoverflow.com/questions/41793634/subtracting-two-timestamps-in-bash-script/41794010#41794010
- https://stackoverflow.com/questions/12199631/convert-seconds-to-hours-minutes-seconds/29269811#29269811
- https://www.unix.com/shell-programming-and-scripting/170808-bash-clearing-value-variable.html
- https://stackoverflow.com/questions/1089813/bash-dash-and-string-comparison/1089852#1089852
- http://www.compciv.org/topics/bash/variables-and-substitution/
- https://stackoverflow.com/questions/19052273/bash-variable-substitution/19052636#19052636
- https://stackoverflow.com/questions/2059794/what-is-the-meaning-of-the-0-syntax-with-variable-braces-and-hash-chara/2059836#2059836
- https://tldp.org/LDP/abs/html/string-manipulation.html
- https://unix.stackexchange.com/questions/461058/what-is-the-concept-of-shortest-sub-string-match-in-unix-shell#461064
- https://wiki.sharewiz.net/doku.php?id=bash:cheat_sheet

---

Notepad++ settings

https://stackoverflow.com/questions/8197812/how-do-i-configure-notepad-to-use-spaces-instead-of-tabs

---


