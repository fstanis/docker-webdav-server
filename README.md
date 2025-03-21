# Docker-based WebDAV server

Easy to configure, docker-based WebDAV server. Based on Apache HTTP Server
Version 2.4 with [`mod_dav`](https://httpd.apache.org/docs/2.4/mod/mod_dav.html).

## Environment variables

### Core settings

- `SERVER_NAME`: How your server identifies itself. Set this to your domain
  name.

- `PORT`: The port to bind the server to.

- `WEBDAV_BASE`: Base directory where the WebDAV files are stored.

- `WEBDAV_DATA`: Path to folder that holds all your files, relative to
  `WEBDAV_BASE`.

### User Settings

- `WEBDAV_USERS`: List of users in `htpasswd` format
  ([see below on how to generate](#generating-webdav_users)). Must be set.

- `WEBDAV_PUBLIC`: Path to a folder that's publicly available. Omit to disable.

- `WEBDAV_SUPERUSER`: Special user that has full access to all folders. Omit to
  disable, must be part of `WEBDAV_USERS` if set.

- `WEBDAV_RO_USER`: Special user that has read access to all folders. Omit to
  disable, must be part of `WEBDAV_USERS` if set.

### SSL Configuration

- `WEBDAV_SSL_CERT`: Path to the SSL certificate file. Must be set unless
  `WEBDAV_FLAG_INSECURE` is set.

- `WEBDAV_SSL_CERT_KEY`: Path to the SSL certificate private key file. Must be
  set unless `WEBDAV_FLAG_INSECURE` is set.

### Optional Parameters

- `WEBDAV_USER_ID`: User ID to run the server as. Should match the user owning
  `WEBDAV_DATA`.

Default: `1000`

- `WEBDAV_GROUP_ID`: Group ID to run the server as.

Default: `1000`

- `WEBDAV_CONFIG`: Path to the WebDAV config file.

Default: `$HTTPD_PREFIX/conf/webdav.conf`

- `WEBDAV_USERS_CONFIG`: Path to the generated users config file.

Default: `$HTTPD_PREFIX/conf/webdav_users.conf`

### Feature flags

`_FLAG` parameters can have any value. Unset them to disable.

- `WEBDAV_FLAG_VERBOSE`: Log all requests to STDOUT.

- `WEBDAV_FLAG_CORS`: Enable CORS flags. Required for browser-based WebDAV
  clients.

- `WEBDAV_FLAG_HTTP2`: Enable HTTP/2 support.

- `WEBDAV_FLAG_INSECURE`: Disable HTTPS - not recommended, unless you're behind
  a reverse proxy.

- `WEBDAV_FLAG_HSTS`: Enable HTTP Strict Transport Security (HSTS).

#### Advanced flags

Enable the following two with care, they may break some clients.

- `WEBDAV_FLAG_PREFER_HTTP2`: Prefer HTTP/2 instead of using the protocol most
  preferred by the client.

- `WEBDAV_FLAG_MODERN_SSL`: Configure SSL to only support clients that support
  TLS 1.3.

## Generating `WEBDAV_USERS`

`WEBDAV_USERS` expects a semicolon-separated list of hashes generated via
`htpasswd`. You can use the provided [`generateusers.sh`](generateusers.sh)
script to easily create it.

```
$ bash generateusers.sh
Enter username to add, leave empty if finished: admin
New password: admin
Re-type new password: admin

Users added so far: admin
Enter username to add, leave empty if finished: reader
New password: reader
Re-type new password: reader

Users added so far: admin, reader
Enter username to add, leave empty if finished:

WEBDAV_USERS='admin:$2y$05$y8RdBk3uE0Ja..Ubk0RMVusH/SXNER7pqeQvCu8oiejQ708/VG7yC;reader:$2y$05$t.agH.tiNtB5VMlA1O2gqOLw09h.HFCkGhnW7NVEOILXbeKV5aUGS'
```

## Example use

```bash
docker run \
  --name docker-webdav-server \
  -p 443:443 \
  -e SERVER_NAME="example.com" \
  -e PORT="443" \
  -e WEBDAV_BASE="/webdav" \
  -e WEBDAV_DATA="data" \
  -e WEBDAV_PUBLIC="public" \
  -e WEBDAV_SUPERUSER="admin" \
  -e WEBDAV_RO_USER="reader" \
  -e WEBDAV_USERS='admin:$2y$05$y8RdBk3uE0Ja..Ubk0RMVusH/SXNER7pqeQvCu8oiejQ708/VG7yC;reader:$2y$05$t.agH.tiNtB5VMlA1O2gqOLw09h.HFCkGhnW7NVEOILXbeKV5aUGS' \
  -e WEBDAV_SSL_CERT="/run/secrets/fullchain.pem" \
  -e WEBDAV_SSL_CERT_KEY="/run/secrets/privkey.pem" \
  -e WEBDAV_FLAG_VERBOSE=1 \
  -e WEBDAV_FLAG_CORS=1 \
  -e WEBDAV_FLAG_HTTP2=1 \
  -e WEBDAV_FLAG_HSTS=1 \
  -v /path/to/data:/webdav/data \
  -v /path/to/secrets:/run/secrets:ro \
  ghcr.io/fstanis/docker-webdav-server:latest
```

## Example `docker-compose.yaml`

```yaml
version: '3.8'
services:
  webdav:
    image: ghcr.io/fstanis/docker-webdav-server:latest
    container_name: docker-webdav-server
    ports:
      - 443
    environment:
      SERVER_NAME: example.com
      PORT: 443
      WEBDAV_BASE: /webdav
      WEBDAV_DATA: data
      WEBDAV_PUBLIC: public
      WEBDAV_SUPERUSER: admin
      WEBDAV_RO_USER: reader
      WEBDAV_USERS: 'admin:$2y$05$y8RdBk3uE0Ja..Ubk0RMVusH/SXNER7pqeQvCu8oiejQ708/VG7yC;reader:$2y$05$t.agH.tiNtB5VMlA1O2gqOLw09h.HFCkGhnW7NVEOILXbeKV5aUGS'
      WEBDAV_SSL_CERT: /run/secrets/fullchain
      WEBDAV_SSL_CERT_KEY: /run/secrets/privkey
      WEBDAV_FLAG_VERBOSE: 1
      WEBDAV_FLAG_CORS: 1
      WEBDAV_FLAG_HTTP2: 1
      WEBDAV_FLAG_HSTS: 1
    volumes:
      - type: bind
        source: /path/to/your/data
        target: /webdav/data
    secrets:
      - fullchain
      - privkey
    restart: unless-stopped
secrets:
  fullchain:
    file: /path/to/secrets/fullchain.pem
  privkey:
    file: /path/to/secrets/privkey.pem
```
