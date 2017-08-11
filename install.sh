#!/bin/bash

echo "This script installs i3switcher into your ~/bin/ folder"
echo "Make sure that ~/bin/ is in your path or modify this script to select a different destination"
echo "also make sure to add i3switcher to your i3 config. See i3switcher --help for help"

DEST=$HOME/bin

cargo build --release
mkdir -p $DEST
cp target/release/i3switcher $DEST
