# Stateless NGINX for Docker [![](https://images.microbadger.com/badges/image/thedrhax/nginx-stateless.svg)](https://hub.docker.com/r/thedrhax/nginx-stateless)

This image can be configured by modifying environment variables at container startup. Feel free to contribute ;)

## Options

```bash
# PHP FPM
FPM=false
FPM_HOST=app
FPM_PORT=9000
FPM_TIMEOUT_READ=60s
FPM_TIMEOUT_SEND=60s

# Reverse proxy
PROXY=false
PROXY_PROTO=http
PROXY_HOST=app

# uWSGI
UWSGI=false
UWSGI_HOST=app
UWSGI_PORT=9000

# SSL termination
SSL=false
SSL_CERT=/ssl/cert.pem
SSL_KEY=/ssl/key.pem
SSL_TIMEOUT=5m

# Location options
LOCATION=/
LOCATION_MODE=root
LOCATION_PATH=/var/www/html
LOCATION_INDEX="index.php index.html index.htm"
LOCATION_AUTOINDEX=false

# Custom config lines
CONFIG_SERVER_0=""
CONFIG_SERVER_1=""
CONFIG_SERVER_...=""

CONFIG_LOCATION_0=""
CONFIG_LOCATION_1=""
CONFIG_LOCATION_...=""
```

## Examples

### Static content only

```
docker run -it --rm -v www:/var/www/html -p 80:80 thedrhax/nginx-stateless
```

### Static content with autoindex

```
docker run -it --rm -v www:/var/www/html -p 80:80 -e LOCATION_AUTOINDEX=true -e LOCATION_INDEX="" thedrhax/nginx-stateless
```

### Static content + PHP (Piwik, ownCloud, etc.)

```
docker run -it --rm -v www:/var/www/html -p 80:80 -e FPM=true -e FPM_HOST=your.fpm.host thedrhax/nginx-stateless
```

### Reverse proxy

```
docker run -it --rm -p 80:80 -e PROXY=true -e PROXY_HOST=another.server thedrhax/nginx-stateless
```

### SSL termination

```
docker run -it --rm -v ssl:/ssl -p 443:443 -e SSL=true -e SSL_CERT=/path/to/cert.pem -e SSL_KEY=/ssl/key.pem thedrhax/nginx-stateless
```

You can also combine SSL termination with all previous examples.

### Add custom config lines

You can add custom lines to server{} and location{} blocks by setting `CONFIG_SERVER_*` and `CONFIG_LOCATION_*`. Number of the first line must be **0**.

```bash
docker run --it --rm -v www:/var/www/html -p 81:81 -e CONFIG_SERVER_0="listen 81;" thedrhax/nginx-stateless
```
