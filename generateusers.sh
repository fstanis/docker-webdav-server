#!/bin/bash

results=""
usernames=""

while true; do
    read -rp "Enter username to add, leave empty if finished: " username
    if [[ -z "$username" ]]; then
        break
    fi

    if credentials="$(htpasswd -nB "$username")"; then
        if [[ -z "$results" ]]; then
            results="$credentials"
            usernames="$username"
        else
            results="$results;$credentials"
            usernames="$usernames, $username"
        fi
    fi
    echo -e "\nUsers added so far: $usernames"
done

echo -e "\nWEBDAV_USERS='$results'"
