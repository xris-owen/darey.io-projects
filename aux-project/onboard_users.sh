#! /bin/bash

#create a variable to store the csv file
FILE="names.csv"
PASSWORD="password"

# Check if file exits.
if [ -f "$FILE" ]; then
	echo "$FILE exists"

    # Check if the user running this script has sudo privileges
    if [ $(id -u) -eq 0 ]; then
        
        while IFS="," read -r USER     # IFS="," for comma delimited file.
        do
            # Check if the current line is empty
            if [ "$USER" == "" ]
            then continue;
            fi

            # Check if the user exists and create if it doesn't
            if id "$USER" &> /dev/null; then 
                echo "User exists"
            else
                HOME_DIR=/home/$USER
                SSH_DIR=$HOME_DIR/.ssh

                sudo useradd -m -d $HOME_DIR -g developers $USER
                sudo chmod 700 $HOME_DIR
                sudo chown $USER:developers $HOME_DIR -R

                if [ -d "$SSH_DIR" ]
                then
                    echo "User's SSH folder already created"
                else
                    sudo mkdir $SSH_DIR
                    sudo chmod 700 $SSH_DIR
                fi

                # Create authorized_keys, assign necessary permission and ownership
                sudo touch $SSH_DIR/authorized_keys 
                sudo chmod 600 $SSH_DIR/authorized_keys 
                sudo chown $USER:developers $SSH_DIR -R

                # Copy and set public keys for users in the server
                cp -R "/home/ubuntu/.ssh/authorized_keys" "$SSH_DIR/authorized_keys"
                echo "User created"

                # Generate a password
                sudo echo -e "$PASSWORD\n$PASSWORD" | sudo passwd "$USER"

                # Reset password after logging in for five times
                sudo passwd -x 5 "$USER"


        done < names.csv
    else
        echo "Only Admin can onboard a user"
    fi
else
	echo "$FILE does not exist";
fi

