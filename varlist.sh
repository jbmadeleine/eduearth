#!/bin/bash
#ncdump -h $1 | grep -E 'float|double' | cut -f 1 -d '(' | cut -f 2 -d ' '
ncdump -h $1 | grep -E 'long_name' 
