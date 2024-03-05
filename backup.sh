#!/bin/bash

# Color codes for formatting
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Load configuration from backup_config.conf
source backup_config.conf

# Function to perform backup
backup() {
    DATE=$(date +"%Y%m%d_%H%M%S")
    BACKUP_FILENAME="mongodb_backup_$DATE.tar.gz"

    printf "${GREEN}🚀 Starting backup process...${NC}\n"

    # Remove existing backup directory
    sudo rm -rf "$BACKUP_DIR" > /dev/null 2>&1

    # Create backup directory
    mkdir -p "$BACKUP_DIR" > /dev/null 2>&1

    # Set permissions for backup directory
    sudo chmod -R 777 "$BACKUP_DIR" > /dev/null 2>&1

    # Backup MongoDB data silently
    sudo docker exec "$CONTAINER_NAME" mongodump --out /tmp/mongobackup > /dev/null 2>&1

    # Copy backup data from container to host
    sudo docker cp "$CONTAINER_NAME:/tmp/mongobackup" "$BACKUP_DIR/$DATE" > /dev/null 2>&1

    # Compress backup data
    tar -zcvf "$BACKUP_DIR/$BACKUP_FILENAME" -C "$BACKUP_DIR" . > /dev/null 2>&1

    # Remove temporary backup directory and compressed file
    #rm -rf "$BACKUP_DIR/$BACKUP_FILENAME"
    rm -rf "$BACKUP_DIR/$DATE" > /dev/null 2>&1

    printf "${GREEN}🎉 Backup completed successfully!${NC}\n"
    
    # Upload backup file to FTP server
    printf "${CYAN}🚀 Uploading backup file to FTP server...${NC}\n"

    # Transfer backup file using FTP
    ftp -n "$FTP_HOST" <<EOF > /dev/null 2>&1
user "$FTP_USER" "$FTP_PASS"
put "$BACKUP_DIR/$BACKUP_FILENAME" "$FTP_DIR/$BACKUP_FILENAME"
bye
EOF

    printf "${GREEN}🎉 Backup and FTP upload completed successfully!${NC}\n"
}

# Main function
main() {
    # Perform the backup
    backup
}

# Execute main function
main
