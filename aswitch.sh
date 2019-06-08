#!/bin/bash
#
# Bash script to switch audio output and
# send a notification using libnotify.
#
# Accepts the '-r' or '--restart' argument
# to kill and bring pulseaudio back on.
#
# Thanks to tsvetan (Ubuntu Forums)
# 
# Original source:
# https://ubuntuforums.org/archive/index.php/t-1370383.html

if [[ "$1" = "-r" || "$1" = "--restart" ]]; then
pulseaudio -k
pulseaudio --start -D & disown
notify-send -i notification-audio-volume-high --hint=string:x-canonical-private-synchronous: "Sound output restarted" "" -t 3000
sleep 1; fi

declare -i sinks=(`pacmd list-sinks | sed -n -e 's/\**[[:space:]]index:[[:space:]]\([[:digit:]]\)/\1/p'`)
declare -i sinks_count=${#sinks[*]}
declare -i active_sink_index=`pacmd list-sinks | sed -n -e 's/\*[[:space:]]index:[[:space:]]\([[:digit:]]\)/\1/p'`
declare -i next_sink_index=${sinks[0]}

# find the next sink (not always the next index number)
declare -i ord=0
while [ $ord -lt $sinks_count ];
do
echo ${sinks[$ord]}
if [ ${sinks[$ord]} -gt $active_sink_index ] ; then
    next_sink_index=${sinks[$ord]}
    break
fi
let ord++
done

# change the default sink
pacmd "set-default-sink ${next_sink_index}"

# move all inputs to the new sink
for app in $(pacmd list-sink-inputs | sed -n -e 's/index:[[:space:]]\([[:digit:]]\)/\1/p');
do
pacmd "move-sink-input $app $next_sink_index"
done

# display notification
declare -i ndx=0
pacmd list-sinks | sed -n -e 's/device.description[[:space:]]=[[:space:]]"\(.*\)"/\1/p' | while read line;
do
if [ $(( $ord % $sinks_count )) -eq $ndx ] ; then
    notify-send -i notification-audio-volume-high --hint=string:x-canonical-private-synchronous: "Sound output switched" "$line" -t 3000
    exit
fi
let ndx++
done
