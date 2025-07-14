# 安装

```shell
# 下载
wget -c https://github.com/netbirdio/netbird/archive/refs/tags/v0.50.3.zip
# 解压
unzip v0.50.3.zip
# 进入
cd netbird-0.50.3/infrastructure_files

# 配置
cp setup.env.example setup.env
```

# 申请idps

参考官方的https://docs.netbird.io/selfhosted/identity-providers#self-hosted-idps

本次采用Zitadel

Redirect Settings 需要配置 http://localhost:53000 (手机需要)

```properties
## example file, you can copy this file to setup.env and update its values
##
# Image tags
# you can force specific tags for each component; will be set to latest if empty
NETBIRD_DASHBOARD_TAG="v2.14.0"
NETBIRD_SIGNAL_TAG="0.50.3"
NETBIRD_MANAGEMENT_TAG="0.50.3"
COTURN_TAG="4.7.0"
NETBIRD_RELAY_TAG="0.50.3"
# Dashboard domain. e.g. app.mydomain.com
NETBIRD_DOMAIN="netbird.remember5.top"
# TURN server domain. e.g. turn.mydomain.com
# if not specified it will assume NETBIRD_DOMAIN
NETBIRD_TURN_DOMAIN="netbird.remember5.top"
# TURN server public IP address
# required for a connection involving peers in
# the same network as the server and external peers
# usually matches the IP for the domain set in NETBIRD_TURN_DOMAIN
NETBIRD_TURN_EXTERNAL_IP=""
# -------------------------------------------
# OIDC
#  e.g., https://example.eu.auth0.com/.well-known/openid-configuration
# -------------------------------------------
NETBIRD_AUTH_OIDC_CONFIGURATION_ENDPOINT=""
# The default setting is to transmit the audience to the IDP during authorization. However,
# if your IDP does not have this capability, you can turn this off by setting it to false.
#NETBIRD_DASH_AUTH_USE_AUDIENCE=false
NETBIRD_AUTH_AUDIENCE=""
# e.g. netbird-client
NETBIRD_AUTH_CLIENT_ID=""
# indicates the scopes that will be requested to the IDP
NETBIRD_AUTH_SUPPORTED_SCOPES="openid profile email offline_access api"
# NETBIRD_AUTH_CLIENT_SECRET is required only by Google workspace.
# NETBIRD_AUTH_CLIENT_SECRET=""
# if you want to use a custom claim for the user ID instead of 'sub', set it here
# NETBIRD_AUTH_USER_ID_CLAIM=""
# indicates whether to use Auth0 or not: true or false
NETBIRD_USE_AUTH0="false"
# if your IDP provider doesn't support fragmented URIs, configure custom
# redirect and silent redirect URIs, these will be concatenated into your NETBIRD_DOMAIN domain.
NETBIRD_AUTH_REDIRECT_URI="/auth"
NETBIRD_AUTH_SILENT_REDIRECT_URI="/silent-auth"
# Updates the preference to use id tokens instead of access token on dashboard
# Okta and Gitlab IDPs can benefit from this
# NETBIRD_TOKEN_SOURCE="idToken"
# -------------------------------------------
# OIDC Device Authorization Flow
# -------------------------------------------
NETBIRD_AUTH_DEVICE_AUTH_PROVIDER="hosted"
NETBIRD_AUTH_DEVICE_AUTH_CLIENT_ID=""
# Some IDPs requires different audience, scopes and to use id token for device authorization flow
# you can customize here:
NETBIRD_AUTH_DEVICE_AUTH_AUDIENCE=""
NETBIRD_AUTH_DEVICE_AUTH_SCOPE="openid"
NETBIRD_AUTH_DEVICE_AUTH_USE_ID_TOKEN=false
# -------------------------------------------
# OIDC PKCE Authorization Flow
# -------------------------------------------
# Comma separated port numbers. if already in use, PKCE flow will choose an available port from the list as an alternative
# eg. 53000,54000
NETBIRD_AUTH_PKCE_REDIRECT_URL_PORTS="53000"
# -------------------------------------------
# IDP Management
# -------------------------------------------
# eg. zitadel, auth0, azure, keycloak
NETBIRD_MGMT_IDP="zitadel"
# Some IDPs requires different client id and client secret for management api
NETBIRD_IDP_MGMT_CLIENT_ID="netbird"
NETBIRD_IDP_MGMT_CLIENT_SECRET=""
NETBIRD_IDP_MGMT_EXTRA_MANAGEMENT_ENDPOINT=""
# Required when setting up with Keycloak "https://<YOUR_KEYCLOAK_HOST_AND_PORT>/admin/realms/netbird"
# NETBIRD_IDP_MGMT_EXTRA_ADMIN_ENDPOINT=
# With some IDPs may be needed enabling automatic refresh of signing keys on expire
NETBIRD_MGMT_IDP_SIGNKEY_REFRESH=true
# NETBIRD_IDP_MGMT_EXTRA_ variables. See https://docs.netbird.io/selfhosted/identity-providers for more information about your IDP of choice.
# -------------------------------------------
# Letsencrypt
# -------------------------------------------
# Disable letsencrypt
#  if disabled, cannot use HTTPS anymore and requires setting up a reverse-proxy to do it instead
NETBIRD_DISABLE_LETSENCRYPT=true
# e.g. hello@mydomain.com
NETBIRD_LETSENCRYPT_EMAIL=""
# -------------------------------------------
# Extra settings
# -------------------------------------------
# Disable anonymous metrics collection, see more information at https://netbird.io/docs/FAQ/metrics-collection
NETBIRD_DISABLE_ANONYMOUS_METRICS=true
# DNS DOMAIN configures the domain name used for peer resolution. By default it is netbird.selfhosted
NETBIRD_MGMT_DNS_DOMAIN=netbird.selfhosted
# Disable default all-to-all policy for new accounts
NETBIRD_MGMT_DISABLE_DEFAULT_POLICY=false
# -------------------------------------------
# Relay settings
# -------------------------------------------
# Relay server domain. e.g. relay.mydomain.com
# if not specified it will assume NETBIRD_DOMAIN
NETBIRD_RELAY_DOMAIN=""
# NETBIRD_STORE_CONFIG_ENGINE=postgres
# NETBIRD_STORE_ENGINE_POSTGRES_DSN=postgres://netbird:wang_netbird!123456@172.18.0.3:5432/netbird_db?sslmode=disable
# Relay server connection port. If none is supplied
# it will default to 33080
# should be updated to match TLS-port of reverse proxy when netbird is running behind reverse proxy
NETBIRD_RELAY_PORT=""
# Management API connecting port. If none is supplied
# it will default to 33073
# should be updated to match TLS-port of reverse proxy when netbird is running behind reverse proxy
NETBIRD_MGMT_API_PORT="8012"
# Signal service connecting port. If none is supplied
# it will default to 10000
# should be updated to match TLS-port of reverse proxy when netbird is running behind reverse proxy
NETBIRD_SIGNAL_PORT="10000"
```

修改

```
NETBIRD_MGMT_API_PORT=8012
NETBIRD_SIGNAL_PORT=10000
```

执行 `./configure.sh`

修改docker-compose.yaml

```docker
services:
  # UI dashboard
  dashboard:
    image: netbirdio/dashboard:v2.14.0
    restart: unless-stopped
    ports:
      - 8011:80
        #- 443:443
    environment:
      # Endpoints
      - NETBIRD_MGMT_API_ENDPOINT=https://netbird.remember5.top
      - NETBIRD_MGMT_GRPC_API_ENDPOINT=https://netbird.remember5.top
        #volumes:
        #- netbird-letsencrypt:/etc/letsencrypt/
    logging:
      driver: "json-file"
      options:
        max-size: "500m"
        max-file: "2"

  # Signal
  signal:
    image: netbirdio/signal:0.50.3
    restart: unless-stopped
    volumes:
      - netbird-signal:/var/lib/netbird
    ports:
      - 10000:80
  #      # port and command for Let's Encrypt validation
  #      - 443:443
  #    command: ["--letsencrypt-domain", "", "--log-file", "console"]
    logging:
      driver: "json-file"
      options:
        max-size: "500m"
        max-file: "2"

  # Relay
  relay:
    image: netbirdio/relay:0.50.3
    restart: unless-stopped
    environment:
    - NB_LOG_LEVEL=info
    - NB_LISTEN_ADDRESS=:33080
    - NB_EXPOSED_ADDRESS=rels://netbird.remember5.top:33080/relay
    ports:
      - 33080:33080
    logging:
      driver: "json-file"
      options:
        max-size: "500m"
        max-file: "2"

  # Management
  management:
    image: netbirdio/management:0.50.3
    restart: unless-stopped
    depends_on:
      - dashboard
    volumes:
      - netbird-mgmt:/var/lib/netbird
        #- netbird-letsencrypt:/etc/letsencrypt:ro
      - ./management.json:/etc/netbird/management.json
    ports:
      - 8012:443 #API port
  #    # command for Let's Encrypt validation without dashboard container
  #    command: ["--letsencrypt-domain", "", "--log-file", "console"]
    command: [
      "--port", "443",
      "--log-file", "console",
      "--log-level", "info",
      "--disable-anonymous-metrics=true",
      "--single-account-mode-domain=netbird.remember5.top",
      "--dns-domain=netbird.selfhosted"
      ]
    logging:
      driver: "json-file"
      options:
        max-size: "500m"
        max-file: "2"
    environment:
      - NETBIRD_STORE_ENGINE_POSTGRES_DSN=
      - NETBIRD_STORE_ENGINE_MYSQL_DSN=
      
  # Coturn
  coturn:
    image: coturn/coturn:4.7.0
    restart: unless-stopped
    #domainname: netbird.remember5.top # only needed when TLS is enabled
    volumes:
      - ./turnserver.conf:/etc/turnserver.conf:ro
    #      - ./privkey.pem:/etc/coturn/private/privkey.pem:ro
    #      - ./cert.pem:/etc/coturn/certs/cert.pem:ro
    network_mode: host
    command:
      - -c /etc/turnserver.conf
    logging:
      driver: "json-file"
      options:
        max-size: "500m"
        max-file: "2"

volumes:
  netbird-mgmt:
  netbird-signal:
  netbird-letsencrypt:

```

# nginx代理

| Endpoint                        | Protocol | Target service and internal-port |
|---------------------------------|----------|----------------------------------|
| /                               | HTTP     | dashboard:80                     |
| /signalexchange.SignalExchange/ | gRPC     | signal:80                        |
| /api                            | HTTP     | management:443                   |
| /management.ManagementService/  | gRPC     | management:443                   |


```



location / {
    proxy_pass http://10.60.57.163:8011; 
    proxy_set_header Host $host; 
    add_header Cache-Control no-cache; 
    proxy_ssl_server_name on; 
}

location /api {
    proxy_pass http://10.60.57.163:8012; 
    proxy_set_header Host $host; 
    add_header Cache-Control no-cache; 
    proxy_ssl_server_name on; 
}


location ^~ /management.ManagementService/ {
    grpc_pass grpc://10.60.57.163:8012; 
    
    grpc_ssl_verify off;
    grpc_read_timeout 1d;
    grpc_send_timeout 1d;
    grpc_socket_keepalive on;
    grpc_set_header Host $host;
    grpc_set_header Content-Type "application/grpc";
    grpc_set_header X-Real-IP $remote_addr;
    grpc_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    grpc_set_header X-Forwarded-Proto $scheme;
}

location /signalexchange.SignalExchange/ {
    grpc_pass grpc://10.60.57.163:10000; 
    grpc_ssl_verify off;
    grpc_read_timeout 1d;
    grpc_send_timeout 1d;
    grpc_socket_keepalive on;
    grpc_set_header Host $host;
    grpc_set_header Content-Type "application/grpc";
    grpc_set_header X-Real-IP $remote_addr;
    grpc_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    grpc_set_header X-Forwarded-Proto $scheme;
}

```

# Reference

- https://lala.im/9024.html
