#!/bin/bash

# Check if the input file exists
if [ ! -f "$1" ]; then
    echo "Error: Input file not found."
    exit 1
fi

# Ensure log and secure directories are initialized once
LOG_FILE="/var/log/user_management.log"
PASSWORD_FILE="/var/secure/user_passwords.csv"

# Initialize log file
if [ ! -f "$LOG_FILE" ]; then
    sudo touch "$LOG_FILE"
    sudo chown root:root "$LOG_FILE"
fi

# Initialize password file
if [ ! -f "$PASSWORD_FILE" ]; then
    sudo mkdir -p /var/secure
    sudo touch "$PASSWORD_FILE"
    sudo chown root:root "$PASSWORD_FILE"
    sudo chmod 600 "$PASSWORD_FILE"
fi

# Redirect stdout and stderr to the log file
exec > >(sudo tee -a "$LOG_FILE") 2>&1

# Function to check if user exists
user_exists() {
    id "$1" &>/dev/null
}

# Function to check if a group exists
group_exists() {
    getent group "$1" > /dev/null 2>&1
}

# Function to check if a user is in a group
user_in_group() {
    id -nG "$1" | grep -qw "$2"
}

# Read each line from the input file
while IFS=';' read -r username groups; do
    # Trim whitespace
    username=$(echo "$username" | tr -d '[:space:]')
    groups=$(echo "$groups" | tr -d '[:space:]')

    # Check if the user already exists
    if user_exists "$username"; then
        echo "User $username already exists."
    else
        # Create user
        sudo useradd -m "$username"

        # Generate random password
        password=$(openssl rand -base64 12)

        # Set password for user
        echo "$username:$password" | sudo chpasswd

        # Log actions
        echo "User $username created. Password: $password"

        # Store passwords securely
        echo "$username,$password" | sudo tee -a "$PASSWORD_FILE"
    fi

    # Ensure the user's home directory and personal group exist
    sudo mkdir -p "/home/$username"
    sudo chown "$username:$username" "/home/$username"

    # Split the groups string into an array
    IFS=',' read -ra group_array <<< "$groups"

    # Check each group
    for group in "${group_array[@]}"; do
        if group_exists "$group"; then
            echo "Group $group exists."
        else
            echo "Group $group does not exist. Creating group $group."
            sudo groupadd "$group"
        fi

        if user_in_group "$username" "$group"; then
            echo "User $username is already in group $group."
        else
            echo "Adding user $username to group $group."
            sudo usermod -aG "$group" "$username"
        fi
    done
done < "$1"
