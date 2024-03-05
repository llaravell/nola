#!/bin/bash

# Color codes for formatting
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to display the custom logo
display_logo() {
    printf "${YELLOW}"
    printf "    _   ______  __    ___ \n"
    printf "   / | / / __ \/ /   /   |\n"
    printf "  /  |/ / / / / /   / /| |\n"
    printf " / /|  / /_/ / /___/ ___ |\n"
    printf "/_/ |_/\____/_____/_/  |_|\n"
    printf "${NC}\n"
}

# Function to prompt user for FTP information
prompt_ftp_info() {
    printf "Enter FTP host (tab for suggestions): "
    read -e FTP_HOST
    printf "Enter FTP username (tab for suggestions): "
    read -e FTP_USER
    printf "Enter FTP password (tab for suggestions): "
    read -e FTP_PASS
    printf "Enter FTP directory (tab for suggestions): "
    read -e FTP_DIR

    # Save FTP information to configuration file
    printf "FTP_HOST=\"$FTP_HOST\"\n" > backup_config.conf
    printf "FTP_USER=\"$FTP_USER\"\n" >> backup_config.conf
    printf "FTP_PASS=\"$FTP_PASS\"\n" >> backup_config.conf
    printf "FTP_DIR=\"$FTP_DIR\"\n" >> backup_config.conf
}

# Function to prompt user for Docker container name
prompt_container_name() {
    printf "Enter Docker container name (tab for suggestions): "
    read -e CONTAINER_NAME

    # Save container name to configuration file
    printf "CONTAINER_NAME=\"$CONTAINER_NAME\"\n" >> backup_config.conf
}

# Function to prompt user for backup directory
prompt_backup_dir() {
    printf "Enter backup directory (tab for suggestions): "
    read -e BACKUP_DIR

    # Save backup directory to configuration file
    printf "BACKUP_DIR=\"$BACKUP_DIR\"\n" >> backup_config.conf
}

# Function to prompt user for backup configuration
setup_backup_config() {
    printf "Let's set up the backup configuration:\n"
    
    # Check if the configuration file exists to determine if it's the first setup
    if [ ! -f "backup_config.conf" ]; then
        printf "${YELLOW}This seems to be your first setup. Let's begin by configuring FTP information.${NC}\n"
        prompt_ftp_info
    fi

    prompt_container_name
    prompt_backup_dir
}

# Function to perform backup now
perform_backup_now() {
    # Check if configuration file exists
    if [ ! -f "backup_config.conf" ]; then
        printf "${RED}Configuration file not found. Please set up the backup configuration first.${NC}\n"
        return 1
    fi

    # Execute the backup script
    ./backup.sh
}

# Function to perform automatic backup
perform_automatic_backup() {
    # Check if configuration file exists
    if [ ! -f "backup_config.conf" ]; then
        printf "${RED}Configuration file not found. Please set up the backup configuration first.${NC}\n"
        return 1
    fi

    # Prompt user for backup interval in hours
    read -p "Enter backup interval in hours (e.g., 24 for daily backup): " INTERVAL
    while ! [[ "$INTERVAL" =~ ^[0-9]+$ ]]; do
        printf "${RED}Error: Invalid input. Please enter a valid integer.${NC}\n"
        read -p "Enter backup interval in hours: " INTERVAL
    done
    printf "${GREEN}Automatic backup scheduled every $INTERVAL hours.${NC}\n"

    # Check if cron job is already set
    if sudo crontab -l | grep -q 'backup.sh'; then
        printf "${YELLOW}Automatic backup is already scheduled.${NC}\n"
        return 1
    fi

    # Schedule the cron job
    (sudo crontab -l ; echo "0 */$INTERVAL * * * $(pwd)/backup.sh") | sudo crontab -
    printf "${GREEN}Automatic backup scheduled successfully.${NC}\n"
}


# Function to delete automatic backup cron job
delete_automatic_backup() {
    # Check if cron job is set
    if ! sudo crontab -l | grep -q 'backup.sh'; then
        printf "${YELLOW}Automatic backup is not scheduled.${NC}\n"
        return 1
    fi

    # Delete the cron job
    sudo crontab -l | grep -v 'backup.sh' | sudo crontab -
    printf "${GREEN}Automatic backup cron job deleted successfully.${NC}\n"
}

# Function to change configuration file
change_config_file() {
    printf "Let's change the configuration file:\n"
    prompt_ftp_info
    prompt_container_name
    prompt_backup_dir

    # Save configuration to the new configuration file
    printf "Configuration file updated successfully.\n"
}

# Main function
main() {
    clear
    display_logo

    printf "${CYAN}Welcome to Nola - MongoDB Backup Utility${NC}\n"
    printf "${YELLOW}-------------------------------------------${NC}\n"
    printf "${GREEN}Choose an option:${NC}\n"
    printf "${CYAN}1. Setup Backup Configuration${NC}\n"
    printf "${CYAN}2. Perform Backup Now${NC}\n"
    printf "${CYAN}3. Perform Automatic Backup${NC}\n"
    printf "${CYAN}4. Delete Automatic Backup${NC}\n"
    printf "${CYAN}5. Change Configuration File${NC}\n"

    read -p "Enter your choice (1, 2, 3, 4, or 5): " choice

    case "$choice" in
        1) setup_backup_config ;;
        2) perform_backup_now ;;
        3) perform_automatic_backup ;;
        4) delete_automatic_backup ;;
        5) change_config_file ;;
        *) printf "Invalid choice. Please enter 1, 2, 3, 4, or 5.\n" ;;
    esac

    # Check if configuration file exists after setup and display success message
    if [ -f "backup_config.conf" ]; then
        printf "${GREEN}Backup configuration is set up successfully.${NC}\n"
    fi
}

# Execute main function
main
