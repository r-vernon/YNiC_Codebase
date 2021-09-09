#!/bin/bash

allUsers=$(qstat -u "*" -s r | tail -n +3 | awk '{print $4}')

echo "$allUsers" | uniq -c
