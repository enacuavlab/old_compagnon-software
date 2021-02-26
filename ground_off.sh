#!/bin/bash
FILE="/tmp/ground.pid"
if [ -f "$FILE" ]; then 
  kill `cat $FILE`
  rm $FILE
fi
