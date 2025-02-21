#!/usr/bin/env bash

capacity="$(cat /sys/class/power_supply/BAT*/capacity 2> /dev/null)" || exit 1
status="$(cat /sys/class/power_supply/BAT*/status 2> /dev/null)" || exit 1

if [ ! "$status" = "Discharging" ]; then
	label=""
else
	label=""
fi

echo "$label $capacity%"
