#!/bin/sh
echo "Starting ping pong"
epmd &
./pingpong --hostname $@
