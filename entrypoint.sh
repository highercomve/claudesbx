#!/bin/sh
# Match the container user to the invoking host user, then exec the command.
set -eu

HOST_UID="${HOST_UID:-0}"
HOST_GID="${HOST_GID:-0}"

if [ "$HOST_UID" = "0" ]; then
    exec "$@"
fi

if ! getent group "$HOST_GID" >/dev/null 2>&1; then
    addgroup -g "$HOST_GID" host >/dev/null
fi
group_name=$(getent group "$HOST_GID" | awk -F: '{print $1; exit}')

if ! getent passwd "$HOST_UID" >/dev/null 2>&1; then
    adduser -D -u "$HOST_UID" -G "$group_name" -h /root -s /bin/bash host >/dev/null
fi
user_name=$(getent passwd "$HOST_UID" | awk -F: '{print $1; exit}')

# Chown root-owned paths inside the home volume so they become writable by the
# host user. -xdev keeps us on the volume's filesystem — bind mounts from the
# host sit on a different device, so their contents are never touched.
find /root -xdev -uid 0 -exec chown -h "$HOST_UID:$HOST_GID" {} +

if [ -S /var/run/docker.sock ]; then
    sock_gid=$(stat -c %g /var/run/docker.sock)
    if [ "$sock_gid" != "0" ]; then
        if ! getent group "$sock_gid" >/dev/null 2>&1; then
            addgroup -g "$sock_gid" dockersock >/dev/null
        fi
        sock_group=$(getent group "$sock_gid" | awk -F: '{print $1; exit}')
        addgroup "$user_name" "$sock_group" >/dev/null 2>&1 || true
    fi
fi

export HOME=/root
exec su-exec "$user_name" "$@"
