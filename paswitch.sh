#!/bin/bash
#
# Bash script to switch audio output and
# send a notification using libnotify.

SEND_NOTIFICATION=1

if [ "$1" = "-r" ] || [ "$1" = "--restart" ]
then
    pulseaudio -k; sleep 1
    pulseaudio --start -D
    notify-send -i notification-audio-volume-high --hint=string:x-canonical-private-synchronous: "Sound output restarted" "" -t 3000
    exit
fi

declare -i sinks=(`pacmd list-sinks | sed -n -e 's/\**[[:space:]]index:[[:space:]]\([[:digit:]]\)/\1/p'`)
declare -i sinks_count=${#sinks[*]}
declare -i active_sink_index=`pacmd list-sinks | sed -n -e 's/\*[[:space:]]index:[[:space:]]\([[:digit:]]\)/\1/p'`
declare -i next_sink_index=${sinks[0]}
declare -i sink_echo_cancel=(`pacmd list-sinks | grep device.description | grep -n echo\ cancelled  | cut -c1`)

# ignore echo cancelled sink (repeated output)
[ ! $sink_echo_cancel = '' ] &&
declare -i sink_echo_cancel=$(($sink_echo_cancel - 1 ))

# find the next sink (not always the next index number)
declare -i ord=0
while [ $ord -lt $sinks_count ]
do
    echo ${sinks[$ord]}
    if [ ${sinks[$ord]} -gt $active_sink_index ]
    then
        next_sink_index=${sinks[$ord]}
        [ $next_sink_index -ne $sink_echo_cancel ] &&
        break
    fi
    let ord++
done

# change the default sink
pacmd "set-default-sink ${next_sink_index}"

# move all inputs to the new sink
for app in $(pacmd list-sink-inputs | sed -n -e 's/index:[[:space:]]\([[:digit:]]\)/\1/p')
do
    pacmd "move-sink-input $app $next_sink_index"
done

# send notification
declare -i ndx=0
pacmd list-sinks | sed -n -e 's/device.description[[:space:]]=[[:space:]]"\(.*\)"/\1/p' |
while read sink
do
    if [ $SEND_NOTIFICATION = 1 ] && [ $(( $ord % $sinks_count )) -eq $ndx ]
    then
        notify-send -i notification-audio-volume-high --hint=string:x-canonical-private-synchronous: "Sound output switched" "$sink" -t 3000
        exit
    fi
    let ndx++
done
