#!/usr/bin/env bash

THEME=$1

if [ -z $THEME ]; then
	THEME="$(ls $HOME/.config/alacritty-*.toml | xargs -n1 basename | sed -E 's/^alacritty-([^.]+)\.toml$/\1/' | wofi -d)"
fi

rm "$HOME/.config/alacritty.toml"

ln -s "$HOME/.config/alacritty-$THEME.toml" "$HOME/.config/alacritty.toml"
