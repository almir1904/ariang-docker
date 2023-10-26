#!/bin/sh

# Define variables
conf_path=/aria2/conf
conf_copy_path=/aria2/conf-copy
data_path=/aria2/data
ariang_path=/usr/local/www/ariang
ariang_js_path=/usr/local/www/ariang/js/aria-ng*.js
ariang_js_dir=/usr/local/www/ariang/js/

# Function to copy default config
copy_default_config() {
    if [ ! -f "$conf_path/aria2.conf" ]; then
        cp "$conf_copy_path/aria2.conf" "$conf_path/aria2.conf"
    fi
}

# Function to set and embed the RPC secret
set_rpc_secret() {
    if [ -n "$RPC_SECRET" ]; then
        sed -i '/^rpc-secret=/d' "$conf_path/aria2.conf"
        printf 'rpc-secret=%s\n' "${RPC_SECRET}" >> "$conf_path/aria2.conf"

        if [ -n "$EMBED_RPC_SECRET" ]; then
            echo "Embedding RPC secret into AriaNg Web UI"
            RPC_SECRET_BASE64=$(echo -n "${RPC_SECRET}" | base64 -w 0)
            find "/usr/local/www/ariang/js/" -name 'aria-ng*.js' -exec sed -i 's,secret:"[^"]*",secret:"'"${RPC_SECRET_BASE64}"'",g' {} \;
        fi
    fi
}

# Function to change RPC request port
change_rpc_port() {
    if [ -n "$ARIA2RPCPORT" ]; then
        echo "Changing RPC request port to $ARIA2RPCPORT"
        sed -i "s/6800/${ARIA2RPCPORT}/g" "$ariang_js_path"
    fi
}

# Main script
copy_default_config
set_rpc_secret
change_rpc_port
touch "$conf_path/aria2.session"


# Get user and group IDs
userid="$(id -u)"  # 65534 - nobody, 0 - root
groupid="$(id -g)"

if [ -n "$PUID" ] && [ -n "$PGID" ]; then
    echo "Running as user $PUID:$PGID"
    userid="$PUID"
    groupid="$PGID"
fi

# Change ownership of config, data, and AriaNg paths
chown -R "$userid:$groupid" "$conf_path" "$data_path" "$ariang_path"

# Start darkhttpd with or without basic authentication
if [ -n "$BASIC_AUTH_USERNAME" ] && [ -n "$BASIC_AUTH_PASSWORD" ]; then
    darkhttpd /usr/local/www/ariang --port 6888 --auth "$BASIC_AUTH_USERNAME:$BASIC_AUTH_PASSWORD" &
else
    darkhttpd /usr/local/www/ariang --port 6888 &
fi

# Run aria2c as the specified user and group
su-exec "$userid:$groupid" aria2c "$@"
