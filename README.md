pulseaudio_switch_output
---

Bash script to switch audio output and send a notification using `libnotify`.

Ignores the echo cancelled sink added by loading module `module-echo-cancel`.

Also accepts the `-r` or `--restart` argument to kill and bring pulseaudio back.

Thanks to tsvetan ([Ubuntu Forums](https://ubuntuforums.org/archive/index.php/t-1370383.html)).
