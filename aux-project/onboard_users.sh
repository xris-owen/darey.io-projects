#! /bin/bash

#create a variable to store the csv file
FILE="names.csv"
PASSWORD="password"

# Check if file exits.
if [ -f "$FILE" ]; then
	echo "$FILE exists"
    # Check if the current user has sudo privileges
    if [ $(id -u) -eq 0 ]; then
        echo "User has sudo privileges"
        while IFS="," read -r name
        # IFS="," for comma delimited file.
        do
            if [ "$name" == "" ]
            then continue;
            fi
            echo $name
        done < names.csv
    else
        echo "User has NO sudo privileges"
    fi
else
	echo "$FILE does not exist";
    exit 99;
fi

