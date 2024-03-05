#!/bin/bash

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

# Function to prompt user for FTP information, container name, and backup directory
setup_backup_config() {
    printf "Let's set up the backup configuration:\n"
    prompt_ftp_info
    prompt_container_name
    prompt_backup_dir
}

# Check if configuration file exists
if [ ! -f "backup_config.conf" ]; then
    # If configuration file doesn't exist, prompt user to set it up
    setup_backup_config
else
    printf "Configuration file already exists.\n"
fi
