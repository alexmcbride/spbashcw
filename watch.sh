#! /bin/bash

# Watch script for junk.sh command. Watches junk directory and notifies of file changes.

trap "echo \"Watch script terminated\"; exit 1" 2

echo "Starting watch script..."
watch -n 15 ls ~/.junkdir 

