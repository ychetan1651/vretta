#!/bin/bash

# Description: This script checks file consistency across multiple instances,
# retrieves the environment value, and notifies an external system (Mattermost) in case of inconsistencies.

# Variables
region="${region:-sample-region}"
instance_ids_input="${instance_ids:-}"
instances_list=($instance_ids_input)
search_pattern="sample_pattern"
mattermost_webhook_url="https://mattermost.example.com/hooks/your_webhook_token"
errors=()
success_messages=()

# Check if there are instance IDs
if [ ${#instances_list[@]} -eq 0 ]; then
    echo "No instance IDs provided!"
    exit 1
fi

# Connect and fetch file names from each instance
for instance_id in "${instances_list[@]}"; do
    command_output=$(aws ssm send-command --instance-ids "$instance_id" --document-name "AWS-RunShellScript" \
                     --region "$region" --parameters "commands=[\"ls /opt/mpt-api | grep $search_pattern\"]" \
                     --query "Command.CommandId" | tr -d '"')
    sleep 60  # Pause for SSM command execution

    ssm_output=$(aws ssm list-command-invocations --instance-id "$instance_id" --command-id "$command_output" \
                 --query "CommandInvocations[0].CommandPlugins[0].Output" --region "$region" | tr -d '"')

    # Assert file names consistency
    file_names=$(echo "$ssm_output" | tr -d '[:space:]')
    if [ "$(echo "$file_names" | tr ' ' '\n' | sort -u | wc -l)" -ne 1 ]; then
        errors+=("File names are not consistent across instances for $instance_id!")
    else
        success_messages+=("Success! Git hash files are the same across the servers for $instance_id.")
    fi
done

# Generate input JSON for sample command
echo '{
  "InstanceIds": '$(printf '%s\n' "${instances_list[@]}" | jq -c .)',
  "DocumentName": "sample-document",
  "Parameters": {
    "commands": ["sample-command"]
  }
}' > /tmp/input.json

# Notify Mattermost in case of inconsistencies
if [ ${#errors[@]} -ne 0 ]; then
    notification_text="Date: $(TZ=\"America/Toronto\" date) - Failure! Errors: $(IFS=$'\n'; echo "${errors[*]}")"
    curl -X POST -H "Content-Type: application/json" -d '{"text":"'"$notification_text"'"}' "$mattermost_webhook_url"
else
    notification_text="Date: $(TZ=\"America/Toronto\" date) - $(IFS=$'\n'; echo "${success_messages[*]}")"
fi
