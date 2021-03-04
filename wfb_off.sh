#!/bin/bash

PIDFILE=/tmp/wfb.pid

if [ -f "$PIDFILE" ]; then 
  kill `cat $PIDFILE` > /dev/null 2>&1
  rm $PIDFILE
fi
