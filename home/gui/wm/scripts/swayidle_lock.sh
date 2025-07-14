#!/usr/bin/env bash

pkill swayidle

swayidle -w\
	lock '@locker@'\
	timeout 300 "notify-send 'going to sleep soon!' -t 3000"\
	timeout 360 '@wmmsg@ "output * dpms off"'\
		resume '@wmmsg@ "output * dpms on"'\
	timeout 420 'loginctl lock-session'\
	before-sleep 'playerctl -a pause; loginctl lock-session'

