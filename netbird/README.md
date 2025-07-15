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
NETBIRD_MGMT_API_PORT=""
# Signal service connecting port. If none is supplied
# it will default to 10000
# should be updated to match TLS-port of reverse proxy when netbird is running behind reverse proxy
NETBIRD_SIGNAL_PORT=""
```

修改

执行 `./configure.sh`

修改docker-compose.yaml

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
}

location /api {
    proxy_pass http://10.60.57.163:33073; 
}


location ^~ /management.ManagementService/ {
    grpc_pass grpc://10.60.57.163:33073; 
    
    grpc_ssl_verify off;
    grpc_read_timeout 300s;
    grpc_send_timeout 300s;
    grpc_socket_keepalive on;
    grpc_set_header X-Forwarded-For $proxy_add_x_forwarded_for; #helps getting the correct IP through npm to the server
}

location /signalexchange.SignalExchange/ {
    grpc_pass grpc://10.60.57.163:10000; 
    grpc_ssl_verify off;
    grpc_read_timeout 300s;
    grpc_send_timeout 300s;
    grpc_socket_keepalive on;
    grpc_set_header X-Forwarded-For $proxy_add_x_forwarded_for; #helps getting the correct IP through npm to the server
}

```


# management

```json
{
    "Stuns": [
        {
            "Proto": "udp",
            "URI": "stun:netbird.remember5.top:3478",
            "Username": "",
            "Password": ""
        }
    ],
    "TURNConfig": {
        "TimeBasedCredentials": false,
        "CredentialsTTL": "12h0m0s",
        "Secret": "secret",
        "Turns": [
            {
                "Proto": "udp",
                "URI": "turn:netbird.remember5.top:3478",
                "Username": "self",
                "Password": ""
            }
        ]
    },
    "Relay": {
        "Addresses": [
            "rels://netbird.remember5.top:443/relay"
        ],
        "CredentialsTTL": "24h0m0s",
        "Secret": ""
    },
    "Signal": {
        "Proto": "https",
        "URI": "netbird.remember5.top:443",
        "Username": "",
        "Password": ""
    },
    "Datadir": "/var/lib/netbird/",
    "DataStoreEncryptionKey": "",
    "HttpConfig": {
        "LetsEncryptDomain": "",
        "CertFile": "",
        "CertKey": "",
        "AuthAudience": "328698961244263737",
        "AuthIssuer": "https://netbird-dnzpyf.us1.zitadel.cloud",
        "AuthUserIDClaim": "",
        "AuthKeysLocation": "https://netbird-dnzpyf.us1.zitadel.cloud/oauth/v2/keys",
        "OIDCConfigEndpoint": "https://netbird-dnzpyf.us1.zitadel.cloud/.well-known/openid-configuration",
        "IdpSignKeyRefreshEnabled": true,
        "ExtraAuthAudience": ""
    },
    "IdpManagerConfig": {
        "ManagerType": "zitadel",
        "ClientConfig": {
            "Issuer": "https://netbird-dnzpyf.us1.zitadel.cloud",
            "TokenEndpoint": "https://netbird-dnzpyf.us1.zitadel.cloud/oauth/v2/token",
            "ClientID": "netbird",
            "ClientSecret": "",
            "GrantType": "client_credentials"
        },
        "ExtraConfig": {
            "ManagementEndpoint": "https://netbird-dnzpyf.us1.zitadel.cloud/management/v1"
        },
        "Auth0ClientCredentials": null,
        "AzureClientCredentials": null,
        "KeycloakClientCredentials": null,
        "ZitadelClientCredentials": null
    },
    "DeviceAuthorizationFlow": {
        "Provider": "hosted",
        "ProviderConfig": {
            "ClientID": "",
            "ClientSecret": "",
            "Domain": "netbird-dnzpyf.us1.zitadel.cloud",
            "Audience": "",
            "TokenEndpoint": "https://netbird-dnzpyf.us1.zitadel.cloud/oauth/v2/token",
            "DeviceAuthEndpoint": "https://netbird-dnzpyf.us1.zitadel.cloud/oauth/v2/device_authorization",
            "AuthorizationEndpoint": "",
            "Scope": "openid",
            "UseIDToken": false,
            "RedirectURLs": null,
            "DisablePromptLogin": false,
            "LoginFlag": 0
        }
    },
    "PKCEAuthorizationFlow": {
        "ProviderConfig": {
            "ClientID": "",
            "ClientSecret": "",
            "Domain": "",
            "Audience": "",
            "TokenEndpoint": "https://netbird-dnzpyf.us1.zitadel.cloud/oauth/v2/token",
            "DeviceAuthEndpoint": "",
            "AuthorizationEndpoint": "https://netbird-dnzpyf.us1.zitadel.cloud/oauth/v2/authorize",
            "Scope": "openid profile email offline_access api",
            "UseIDToken": false,
            "RedirectURLs": [
                "http://localhost:53000"
            ],
            "DisablePromptLogin": false,
            "LoginFlag": 0
        }
    },
    "StoreConfig": {
        "Engine": "sqlite"
    },
    "ReverseProxy": {
        "TrustedHTTPProxies": [],
        "TrustedHTTPProxiesCount": 0,
        "TrustedPeers": [
            "0.0.0.0/0"
        ]
    },
    "DisableDefaultPolicy": false
}
```


# turnserver.conf
就是默认生成的，不做更改


# FAQ

## /api/user http code 502

management回下载一个文件，国内下载很慢，需要等待, 这个是正常的, 可用`--disable-geolite-update=true` 关闭每次的更新
`2025-07-14T10:19:21Z INFO [context: SYSTEM] management/server/geolocation/database.go:34: Geolocation database file GeoLite2-City_20250616.mmdb not found, file will be downloaded`

## 单用户与多用户的区别

官方默认是单用户

- 单用户的话，只有管理员有控制台
- 多用户的话，所有用户都有控制台

# Reference

- https://lala.im/9024.html
- https://www.senra.me/nat-traversal-series-netbird-almost-perfect-tailscale-headscale-alternative-chapter-three-the-end/
