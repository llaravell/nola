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
    prompt_ftp_info
    prompt_container_name
    prompt_backup_dir
}

# Function to perform backup now
perform_backup_now() {
    # Check if configuration file exists
    if [ ! -f "backup_config.conf" ]; then
        printf "${RED}❌ Configuration file not found. Please set up the backup configuration first.${NC}\n"
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

    # Check if crobtab is installed
    if ! command -v crontab &> /dev/null then
        printf "${BLUE}🚀 Starting install cron ...${NC}";
        apt-get install cron -y > /dev/null 2>&1;
        printf "${GREEN}🎉 Cron is installed successfully${NC}";
    fi

    # Prompt user for backup interval in hours
    read -p "Enter backup interval in hours (e.g., 24 for daily backup): " INTERVAL
    while ! [[ "$INTERVAL" =~ ^[0-9]+$ ]]; do
        printf "${RED}❌ Error: Invalid input. Please enter a valid integer.${NC}\n"
        read -p "Enter backup interval in hours: " INTERVAL
    done
    printf "${GREEN}⏰ Automatic backup scheduled every $INTERVAL hours.${NC}\n"

    # Check if cron job is already set
    if sudo crontab -l | grep -q 'backup.sh'; then
        printf "${YELLOW}⏰ Automatic backup is already scheduled.${NC}\n"
        return 1
    fi

    # Schedule the cron job
    (crontab -l ; echo "0 */$INTERVAL * * * bash $(pwd)/backup.sh") | crontab -
    printf "${GREEN}🎉 Automatic backup scheduled successfully.${NC}\n"
}


# Function to delete automatic backup cron job
delete_automatic_backup() {
    # Check if cron job is set
    if ! sudo crontab -l | grep -q 'backup.sh'; then
        printf "${YELLOW}⏰ Automatic backup is not scheduled.${NC}\n"
        return 1
    fi

    # Delete the cron job
    sudo crontab -l | grep -v 'backup.sh' | sudo crontab -
    printf "${GREEN}🎉 Automatic backup cron job deleted successfully.${NC}\n"
}

# Function to change configuration file
change_config_file() {
    printf "Let's change the configuration file:\n"
    prompt_ftp_info
    prompt_container_name
    prompt_backup_dir

    # Save configuration to the new configuration file
    printf "${GREEN}🎉 Configuration file updated successfully.${NC}\n"
}

# Function to restore backup
restore_backup() {
    printf "Enter the path to the backup file to restore (tab for suggestions): "
    read -e BACKUP_FILE_PATH

    # Check if configuration file exists
    if [ ! -f "backup_config.conf" ]; then
        printf "${RED}Configuration file not found. Please set up the backup configuration first.${NC}\n"
        return 1
    fi

    # Source the configuration file
    source backup_config.conf

    # Check if Docker container name is defined in the configuration file
    if [ -z "$CONTAINER_NAME" ]; then
        printf "${RED}Docker container name is not defined in the configuration file.${NC}\n"
        return 1
    fi

    # Check if the specified backup file exists
    if [ ! -f "$BACKUP_FILE_PATH" ]; then
        printf "${RED}Backup file not found.${NC}\n"
        return 1
    fi

    # Extract backup file to the same directory
    printf "${CYAN}📤 Extracting backup file...${NC}\n"
    tar -xzvf "$BACKUP_FILE_PATH" -C "$(dirname "$BACKUP_FILE_PATH")" > /dev/null 2>&1

    # Determine the extracted directory name
    extracted_dir=$(basename "${BACKUP_FILE_PATH/mongodb_backup_/}" .tar.gz)

    # Rename the extracted directory to 'asemooni'
    printf "${CYAN}🖊 Renaming extracted directory to 'asemooni'...${NC}\n"
    mv "$(dirname "$BACKUP_FILE_PATH")/$extracted_dir" "$(dirname "$BACKUP_FILE_PATH")/asemooni"

    # Navigate to renamed directory if it exists
    if [ -d "$(dirname "$BACKUP_FILE_PATH")/asemooni" ]; then
        printf "${CYAN}⏩ Navigating to renamed directory: asemooni${NC}\n"
        cd "$(dirname "$BACKUP_FILE_PATH")/asemooni" || { printf "${RED}Failed to navigate to renamed directory.${NC}\n"; return 1; }
    else
        printf "${RED}❌ Failed to determine renamed directory.${NC}\n"
        return 1
    fi

    # Restore backup file from within the Docker container
    printf "${CYAN}👨‍⚕️ Restoring backup file within Docker container...${NC}\n"
    sudo docker cp "$(dirname "$BACKUP_FILE_PATH")/asemooni" "$CONTAINER_NAME":/restore 2> /dev/null
    sudo docker exec "$CONTAINER_NAME" mongorestore --drop /restore 2> /dev/null

    # Check the exit status of the restoration process
    if [ $? -eq 0 ]; then
        printf "${GREEN}🎉 Backup restored successfully.${NC}\n"
    else
        printf "${RED}❌ Failed to restore backup.${NC}\n"
    fi
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
    printf "${CYAN}6. Restore Backup${NC}\n"

    read -p "Enter your choice (1, 2, 3, 4, 5, or 6): " choice

    case "$choice" in
        1) setup_backup_config ;;
        2) perform_backup_now ;;
        3) perform_automatic_backup ;;
        4) delete_automatic_backup ;;
        5) change_config_file ;;
        6) restore_backup ;;
        *) printf "Invalid choice. Please enter 1, 2, 3, 4, 5, or 6.\n" ;;
    esac
}

# Execute main function
main
