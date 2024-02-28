#!/bin/bash
for channel in $(xfconf-query -l | sed 1,1d); do 
	grepResult=$(xfconf-query -c $channel -l -v | grep -i theme)
	
	if [ $? -eq 0 ]; then
		echo -e "${channel}\n${grepResult}\n"
	fi
done
