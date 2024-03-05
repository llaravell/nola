#!/bin/bash

# Load configuration from backup_config.conf
source backup_config.conf

# Function to perform backup
backup() {
    DATE=$(date +"%Y%m%d_%H%M%S")
    BACKUP_FILENAME="mongodb_backup_$DATE.tar.gz"

    # Create backup directory if it doesn't exist
    mkdir -p "$BACKUP_DIR"

    # Backup MongoDB data
    sudo docker exec "$CONTAINER_NAME" mongodump --out /tmp/mongobackup

    # Copy backup data from container to host
    sudo docker cp "$CONTAINER_NAME:/tmp/mongobackup" "$BACKUP_DIR/$DATE"

    # Compress backup data
    tar -zcvf "$BACKUP_DIR/$BACKUP_FILENAME" -C "$BACKUP_DIR" .

    # Remove temporary backup directory
    rm -rf "$BACKUP_DIR/$DATE"

    # Transfer backup file using FTP
    ftp -n "$FTP_HOST" <<EOF
user "$FTP_USER" "$FTP_PASS"
put "$BACKUP_DIR/$BACKUP_FILENAME" "$FTP_DIR/$BACKUP_FILENAME"
bye
EOF
}

# Main function
main() {
    # Perform the backup
    backup
}

# Execute main function
main
