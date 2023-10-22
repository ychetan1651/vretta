#!/bin/bash

# Description: This script updates the API on a remote system and optionally checks its health.
#              It assumes some setup requirements, including certain environment configuration and user permissions.

# Set API build source and destination variables
api_build_file="sample_path/api_build/${build_file}"  # Use sample paths and names
api_build_src="/${api_build_file}"
api_build_dest="/sample_path/api_dest"

# API check script variables
check_api=true 
check_script_src="/sample_path/check_api_mock.sh"
check_script_dest="/sample_path_dest/check_api_mock.sh"

# Find old API files to delete in the application directory
files_to_delete=$(find /sample_path/api_dest -name 'sample_file_pattern')
for file in $files_to_delete; do
    rm -f "$file"
done

# Backup previous API build with timestamp-based naming convention
timestamp=$(date +%Y%m%d%H%M%S)
backup_file="$backup_dir/api_backup_$timestamp.tar.gz"
tar -czvf "$backup_file" "$api_build_dest"

# Copy API build to the destination
cp -r "$api_build_src" "$api_build_dest"
chown -R sample_user "$api_build_dest"
chmod -R 775 "$api_build_dest"

# Decompress API build archive 
tar -xzvf "${api_build_dest}/${build_file}" -C "$api_build_dest"

# Copy API check script to the remote system
if [ "$check_api" = true ]; then
    cp "$check_script_src" "$check_script_dest"
    chown sample_user "$check_script_dest"
    chmod 774 "$check_script_dest"
fi

# Restart API
sudo -u sample_user . ~/.profile ; sample_api_command

# API validation script
if [ "$check_api" = true ]; then
    sleep 30
    chmod +x "$check_script_dest"
    bash "$check_script_dest"
fi
