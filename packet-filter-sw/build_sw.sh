#!/bin/bash

while [ $# -gt 0 ]; do
  echo "Making $1"
  make MODULE=$1
  #rmmod ${1}
  insmod ${1}.ko
  lsmod

  # move to next module
  shift 1
done
