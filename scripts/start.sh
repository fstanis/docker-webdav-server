#!/bin/bash

# Loads and validates the config file, generates the user routes and then starts
# the webserver.

die () { echo "$@" >&2; trap - EXIT; exit 1; }
set -e
trap 'die "Error executing start script"' EXIT

# Should be set by the base image
[[ -d "$HTTPD_PREFIX" ]] \
    || die '$HTTPD_PREFIX not set'

[[ -n "$SERVER_NAME" ]] \
    || die '$SERVER_NAME not set'

[[ "$PORT" -gt 0 ]] \
    || die '$PORT is invalid'

[[ -n "$WEBDAV_BASE" && "$WEBDAV_BASE" != '/' ]] \
    || die '$WEBDAV_BASE not set or invalid'

mkdir -p "$WEBDAV_BASE"
webdav_data_dir="$WEBDAV_BASE/$WEBDAV_DATA"

# Verify that the files and directories in the config are valid
[[ -d "$webdav_data_dir" ]] \
    || die '$WEBDAV_DATA set to invalid directory'
[[ -n "$WEBDAV_USERS" ]] \
    || die '$WEBDAV_USERS not set'
[[ -n "$WEBDAV_FLAG_INSECURE" || -f "$WEBDAV_SSL_CERT" ]] \
    || die '$WEBDAV_SSL_CERT set to invalid file'
[[ -n "$WEBDAV_FLAG_INSECURE" || -f "$WEBDAV_SSL_CERT_KEY" ]] \
    || die '$WEBDAV_SSL_CERT_KEY set to invalid file'

# Config defaults
[[ "$WEBDAV_USER_ID" -gt 0 ]] \
    || export WEBDAV_USER_ID=1000
[[ "$WEBDAV_GROUP_ID" -gt 0 ]] \
    || export WEBDAV_GROUP_ID=1000
[[ -n "$WEBDAV_CONFIG" ]] \
    || export WEBDAV_CONFIG="$HTTPD_PREFIX/conf/webdav.conf"
[[ -n "$WEBDAV_USERS_CONFIG" ]] \
    || export WEBDAV_USERS_CONFIG="$HTTPD_PREFIX/conf/webdav_users.conf"

# Create user (if needed)
if ! id webdav &> /dev/null; then
    grep -q ":$WEBDAV_GROUP_ID:" /etc/group \
        || addgroup --gid "$WEBDAV_GROUP_ID" group
    adduser --uid "$WEBDAV_USER_ID" webdav \
        --gecos "" --disabled-password --no-create-home --ingroup group
fi

# Generate the users config that rules for each user's directory
tr ';' '\n' <<< "$WEBDAV_USERS" > "$WEBDAV_BASE/users"
truncate -s 0 "$WEBDAV_USERS_CONFIG"
for user in $(grep -o '^[^:]\+' "$WEBDAV_BASE/users"); do
    if [[ "$user" == "$WEBDAV_SUPERUSER" ]]; then
        found_superuser=1
    elif [[ "$user" == "$WEBDAV_RO_USER" ]]; then
        found_ro_user=1
    else
        printf 'Use UserDir %s\n' "$user" >> "$WEBDAV_USERS_CONFIG"
        mkdir -p "$webdav_data_dir/$user"
    fi
done

# If WEBDAV_SUPERUSER is set, it must be a real user
if [[ -n "$WEBDAV_SUPERUSER" ]]; then
    [[ -n "$found_superuser" ]] \
        || die '$WEBDAV_SUPERUSER not found in users'
    export WEBDAV_FLAG_SUPERUSER=1
fi
# If WEBDAV_RO_USER is set, it must be a real user
if [[ -n "$WEBDAV_RO_USER" ]]; then
    [[ -n "$found_ro_user" ]] \
        || die '$WEBDAV_RO_USER not found in users'
    export WEBDAV_FLAG_RO_USER=1
fi
# If WEBDAV_PUBLIC is set, make sure it exists
if [[ -n "$WEBDAV_PUBLIC" ]]; then
    export WEBDAV_FLAG_PUBLIC=1
    mkdir -p "$webdav_data_dir/$WEBDAV_PUBLIC"
fi

# Set permissions if needed
chown -R "$WEBDAV_USER_ID" "$WEBDAV_BASE"
chmod -R u+rwx "$WEBDAV_BASE"

# Pass all exports that start with WEBDAV_FLAG_ as parameters to make them
# accessible from <IfDefine> in Apache config
flags=$(env | grep -o '^WEBDAV_FLAG_[^=]\+' | xargs printf '-D%s ')

trap - EXIT

httpd-foreground $flags
