#!/bin/sh -xe

CONFIG=/etc/nginx/conf.d/default.conf; > $CONFIG

set_mode() {
    if [ ! "$MODE" ]; then
        export MODE=$1
    else
        echo "Do not use both $1 and $MODE in the same location"
        exit 1
    fi
}

[ "_$PROXY" = "_true" ] && set_mode PROXY
[ "_$UWSGI" = "_true" ] && set_mode UWSGI
[ "_$FPM" = "_true" ] && set_mode FPM

expand_vars_to_lines() {
    PREFIX=$1
    SPACE=$2

    i=0; while [ "$(eval echo \$${PREFIX}_${i})" ]; do
        echo "${SPACE}$(eval echo \$${PREFIX}_${i})"
        i=$((i+1))
    done
}

cat >> $CONFIG <<EOF
`expand_vars_to_lines CONFIG_GLOBAL_START "        "`

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

`[ "_$MODE" = "_UWSGI" ] && cat <<EOF
        include uwsgi_params;
        uwsgi_pass ${UWSGI_HOST}:${UWSGI_PORT};
`

`[ "_$MODE" = "_PROXY" ] && cat <<EOF
        proxy_set_header Host               \\$host;
        proxy_set_header X-Real-IP          \\$remote_addr;
        proxy_set_header X-Forwarded-For    \\$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto  \\$scheme;
        proxy_pass ${PROXY_PROTO}://${PROXY_HOST};
`

`[ "_$MODE" = "_FPM" ] && cat <<EOF
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

`expand_vars_to_lines CONFIG_GLOBAL_END "        "`
EOF

exec "$@"
