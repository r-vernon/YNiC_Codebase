#!/bin/bash

# simple bash script to delete logs older than 5 days

find /scratch/home/r/rv519/logs* -mtime +5 -exec rm {} \;