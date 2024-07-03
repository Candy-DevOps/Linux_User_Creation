Here is a `README.md` file for automating user and group management with the provided bash script.

# Linux User Creation Bash Script

## Project Overview

This project is a Bash script designed to automate the creation of Linux users and their respective groups. The script reads from an input file containing usernames and their associated groups, ensuring the proper setup and security measures for each user.

## Features

- Verifies the existence of an input file before proceeding.
- Initializes log and secure directories to keep track of user management actions and passwords.
- Checks if users and groups already exist before creating them.
- Generates random passwords for new users and stores them securely.
- Adds users to specified groups, creating the groups if they do not exist.
- Logs all actions to a specified log file for auditing purposes.

## Script Usage

To use the script, provide it with a file containing the user information. The file should have each line formatted as follows:

```
username;group1,group2,group3
```

### Example

```
candy_esinam;admin,developers
janet_fiadeva;users,qa
```

### Running the Script

1. Save the user information in a file, for example, `username.txt`.
2. Execute the script with the user information file as an argument:

```bash
./user_creation_script.sh username.txt
```

## Script Details

```bash
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
```

## Security Considerations

- The password file is stored with restricted permissions (`600`) to ensure it is only accessible by the root user.
- The log file captures all actions taken by the script, providing a comprehensive audit trail.

---

## Conclusion

This script automates the process of user and group management, making it easier to handle large numbers of user accounts efficiently and securely. Ensure to follow the instructions carefully to prevent any issues during execution.

---
