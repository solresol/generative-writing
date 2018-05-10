#!/bin/sh

while true
do
    wish gui.tcl -display :1
    ls best | wc -l
    sleep 60
done
