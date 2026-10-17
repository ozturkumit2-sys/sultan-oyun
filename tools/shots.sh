#!/bin/bash
# usage: tools/shots.sh name "x,y,z,yaw[,pitch,dist]" [frames]
cd /root/cati-kedisi
timeout 240 xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --rendering-driver opengl3 res://tools/shot.tscn -- scene=res://scenes/game.tscn out=/root/cati-kedisi/build/$1.png frames=${3:-90} spawn=$2 2>&1 | grep -E "SCRIPT|SHOT" | head -5
