#!/usr/bin/env bash
set -u
printf 'Notification server:\n'
gdbus call --session --dest org.freedesktop.Notifications --object-path /org/freedesktop/Notifications --method org.freedesktop.Notifications.GetServerInformation
printf '\nRunning hshell instances:\n'
qs list 2>&1
printf '\nSending test notification:\n'
notify-send -a hshell -t 5000 'Notifications ready' 'hshell test'
