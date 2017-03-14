#!/bin/sh -xe

CONFIG=/etc/nginx/conf.d/default.conf; > $CONFIG

if [ "_$PROXY" = "_true" ] && [ "_$FPM" = "_true" ]; then
    echo "Do not use both PROXY and FPM at the same time"
    exit 1
fi

expand_vars_to_lines() {
    PREFIX=$1
    SPACE=$2

    i=0; while [ "$(eval echo \$${PREFIX}_${i})" ]; do
        echo "${SPACE}$(eval echo \$${PREFIX}_${i})"
        i=$((i+1))
    done
}

cat >> $CONFIG <<EOF
server {
    listen 80;
`[ "_$SSL" = "_true" ] && cat <<EOF
    listen 443 ssl;

    ssl_certificate     $SSL_CERT;
    ssl_certificate_key $SSL_KEY;
    ssl_session_timeout $SSL_TIMEOUT;
`

`expand_vars_to_lines CONFIG_SERVER "    "`

    location $LOCATION {

        $LOCATION_MODE $LOCATION_PATH;

`[ "$LOCATION_INDEX" ] && cat <<EOF
        index $LOCATION_INDEX;
`

`[ "_$LOCATION_AUTOINDEX" = "_true" ] && cat <<EOF
        autoindex on;
`

`expand_vars_to_lines CONFIG_LOCATION "        "`

`[ "_$PROXY" = "_true" ] && cat <<EOF
        proxy_set_header Host               \\$host;
        proxy_set_header X-Real-IP          \\$remote_addr;
        proxy_set_header X-Forwarded-For    \\$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto  \\$scheme;
        proxy_pass ${PROXY_PROTO}://${PROXY_HOST};
`

`[ "_$FPM" = "_true" ] && cat <<EOF
        location ~ \.php$ {
            include fastcgi.conf;
            fastcgi_param SCRIPT_FILENAME \\$request_filename;
            fastcgi_read_timeout ${FPM_TIMEOUT_READ};
            fastcgi_send_timeout ${FPM_TIMEOUT_SEND};
            fastcgi_pass ${FPM_HOST}:${FPM_PORT};
        }
`

    }
}
EOF

exec "$@"
