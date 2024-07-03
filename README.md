Here is a `README.md` file for automating user and group management with the provided bash script.

---

# User Management Script

## Overview

This repository contains a Bash script for managing user creation on Linux systems. The script reads a list of usernames and optionally groups from an input file, creates users, assigns them to personal groups, sets passwords, and logs actions.

## Features

- Creates users and their personal groups.
- Sets random passwords for new users.
- Logs user creation actions to `/var/log/user_management.log`.
- Stores usernames and passwords securely in `/var/secure/user_passwords.csv`.

## Prerequisites

- Linux operating system (tested on Ubuntu).
- Bash shell (`/bin/bash`).
- OpenSSL for password generation (`openssl`).
- Root privileges (`sudo`).

## Usage

1. **Clone the repository**

   ```bash
   git clone <repository-url>
   cd <repository-directory>
   ```

2. **Create an input file**

   Create a text file (e.g., `user_list.txt`) with each line formatted as `username;group`.

   Example:
   ```
   alice;admin
   bob;users
   charlie;
   ```

3. **Run the script**

   Ensure the script is executable:
   ```bash
   chmod +x create_users.sh
   ```

   Execute with sudo (root privileges required):
   ```bash
   sudo ./create_users.sh user_list.txt
   ```

4. **View logs and passwords**

   - **Log file** (`/var/log/user_management.log`):
     ```bash
     sudo cat /var/log/user_management.log
     ```

   - **Passwords file** (`/var/secure/user_passwords.csv`):
     ```bash
     sudo cat /var/secure/user_passwords.csv
     ```

## Notes

- Ensure the input file (`user_list.txt`) is correctly formatted with usernames and groups separated by a semicolon (`;`).
- Existing users are skipped during execution to prevent duplicates.
- The script requires root privileges to create users and modify system files.

## Script

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

# Read each line from the input file
while IFS=';' read -r username groups; do
    # Trim whitespace
    username=$(echo "$username" | tr -d '[:space:]')

    # Check if the user already exists
    if user_exists "$username"; then
        echo "User $username already exists."
        continue
    fi

    # Create user
    sudo useradd -m "$username"

    # Create personal group (same as username)
    sudo groupadd "$username"

    # Add user to personal group
    sudo usermod -aG "$username" "$username"

    # Create home directory
    sudo mkdir -p "/home/$username"
    sudo chown "$username:$username" "/home/$username"

    # Generate random password
    password=$(openssl rand -base64 12)

    # Set password for user
    echo "$username:$password" | sudo chpasswd

    # Log actions
    echo "User $username created. Password: $password"

    # Store passwords securely
    echo "$username,$password" | sudo tee -a "$PASSWORD_FILE"

done < "$1"
```

## Conclusion

This script automates the process of user and group management, making it easier to handle large numbers of user accounts efficiently and securely. Ensure to follow the instructions carefully to prevent any issues during execution.
