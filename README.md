# Table of Contents

- [Introduction](#introduction)
- [Maintainer](#maintainer)
- [Contributors](#contributors)
- [Usage](#usage)
    - [Creating a Docker Container](#creating-a-docker-container)
    - [Using a docker-compose File](#using-a-docker-compose-file)
- [Container Process Tree](#container-process-tree)    
- [Parameters](#parameters)
    - [Additional Enivorenment Variables](#additional-enivorenment-variables)
- [User / Group Identifiers](#user-group-identifiers)
- [Application Setup](Application-setup)
    - [Validation and Initial Setup](#validation-and-initial-setup)
    - [Site config and Reverse Proxy](#Site-config-and-reverse-proxy)
    - [Using-Certs-in-Other-Containers](#using-certs-in-other-containers)
    - [using-fail2ban](#using-fail2ban)
 - [Support Info](#support-info)
 - [Updating-Info](#updating-info)
    - [Via Docker Run/Create](#via-docker-run-create)
    - [Via Docker Compose](#via-docker-compose)
 - [Base Image](https://github.com/linuxserver/docker-letsencrypt)

# Introduction

[Letsencrypt](https://letsencrypt.org/) sets up an Nginx webserver and reverse proxy with php support and a built-in letsencrypt client that automates free SSL server certificate generation and renewal processes. It also contains fail2ban for intrusion prevention.

* [s6 overlay](https://github.com/just-containers/s6-overlay) enabled for PID 1 Init capabilities
* [zabbix-agent](https://zabbix.org) based on 4.0.x compiled for individual container monitoring.
* Cron installed along with other tools (bash,curl, less, logrotate, nano, vim) for easier management.
* MSMTP enabled to send mail from container to external SMTP server.
* Ability to update User ID and Group ID Permissions for Development Purposes dyanmically.

# Maintainer

- [Chinthaka Deshapriya](https://www.linkedin.com/in/chinthakadeshapriya/)

# Contributors
 
 - [Amila Kothalawala](https://www.linkedin.com/in/amila-m-kothalawala/)

# Usage

Here are some example snippets to help you get started creating a container.

## Creating a Docker Container

```
docker create \
  --name=letsencrypt \
  --cap-add=NET_ADMIN \
  -e PUID=1001 \
  -e PGID=1002 \
  -e TZ=Asia/Colombo \
  -e URL=openemail.io \
  -e SUBDOMAINS=www, \
  -e VALIDATION=http \
  -e EMAIL=devops@openemail.io `#optional` \
  -e DHLEVEL=2048 `#optional` \
  -e ONLY_SUBDOMAINS=false `#optional` \
  -e EXTRA_DOMAINS=mail.cybergatelab.com `#optional` \
  -e STAGING=false `#optional` \
  -p 443:443 \
  -p 80:80 `#optional` \
  -v </path/to/appdata/config>:/config \
  --restart unless-stopped \
  openemail/letsencrypt:latest
```
## Using a docker-compose File

Compatible with docker-compose v2 schemas.

```
---
version: "2.1"
services:
  letsencrypt-openemail:
    image: openemail/letsencrypt:latest
    container_name: letsencrypt-openemail
    hostname: letsencrypt-openemail
    cap_add:
      - NET_ADMIN
    environment:
      - PUID=1001
      - PGID=1002
      - TZ=Asia/Colomobo
      - URL=openemail.io
      - SUBDOMAINS=mail,
      - VALIDATION=http
      - EMAIL=devops@openemail.io #optional
      - DHLEVEL=2048 #optional
      - ONLY_SUBDOMAINS=true #optional
      - EXTRA_DOMAINS=mail.cybergatelab.com #optional
      - STAGING=false #optional
    volumes:
      - ./data/conf/letsencrypt/config:/config
    ports:
      - 443:443
      - 80:80 #optional
    restart: unless-stopped
```
# Container Process Tree

If you run `docker top letsencrypt-openemail axcf` command you will get an output like below. `letsencrypt-openemail` is the container's name here.
```
PID                 TTY                 STAT                TIME                COMMAND
27504               ?                   Ss                  0:00                \_ s6-svscan
27589               ?                   S                   0:00                \_ s6-supervise
27595               ?                   Ss                  0:00                | \_ zabbix_agentd
29158               ?                   S                   0:00                | \_ zabbix_agentd
29159               ?                   S                   0:00                | \_ zabbix_agentd
29160               ?                   S                   0:00                | \_ zabbix_agentd
29161               ?                   S                   0:00                | \_ zabbix_agentd
27590               ?                   S                   0:00                \_ s6-supervise
27591               ?                   S                   0:00                \_ s6-supervise
27592               ?                   S                   0:00                \_ s6-supervise
27593               ?                   Ss                  0:00                | \_ crond
29103               ?                   S                   0:00                \_ s6-supervise
29111               ?                   Ssl                 0:06                | \_ fail2ban-client
29104               ?                   S                   0:00                \_ s6-supervise
29110               ?                   Ss                  0:00                | \_ crond
29105               ?                   S                   0:00                \_ s6-supervise
29109               ?                   Ss                  0:00                | \_ nginx
29162               ?                   S                   0:00                | \_ nginx
29163               ?                   S                   0:00                | \_ nginx
29164               ?                   S                   0:00                | \_ nginx
29165               ?                   S                   0:00                | \_ nginx
29166               ?                   S                   0:00                | \_ nginx
29106               ?                   S                   0:00                \_ s6-supervise
29108               ?                   Ss                  0:00                \_ php-fpm7
29168               ?                   S                   0:00                \_ php-fpm7
29169               ?                   S                   0:00                \_ php-fpm7
```
As per the above output `s6-svscan` will be the PID 1 inside the container which is exactly similar to `systemd` in your Linux host.

# Parameters

Container images are configured using parameters passed at runtime (such as those above). These parameters are separated by a colon and indicate `<external>:<internal>` respectively. For example, `-p 8080:80` would expose port `80` from inside the container to be accessible from the host's IP on port `8080` outside the container.

| Parameter | Function |
| :----: | --- |
| `-p 443` | Https port |
| `-p 80` | Http port (required for http validation only) |
| `-e PUID=1000` | for UserID - see below for explanation |
| `-e PGID=1000` | for GroupID - see below for explanation |
| `-e TZ=Europe/London` | Specify a timezone to use EG Europe/London. |
| `-e URL=yourdomain.url` | Top url you have control over (`customdomain.com` if you own it, or `customsubdomain.ddnsprovider.com` if dynamic dns). |
| `-e SUBDOMAINS=www,` | Subdomains you'd like the cert to cover (comma separated, no spaces) ie. `www,ftp,cloud`. For a wildcard cert, set this _exactly_ to `wildcard` (wildcard cert is available via `dns` and `duckdns` validation only) |
| `-e VALIDATION=http` | Letsencrypt validation method to use, options are `http`, `tls-sni`, `dns` or `duckdns` (`dns` method also requires `DNSPLUGIN` variable set) (`duckdns` method requires `DUCKDNSTOKEN` variable set, and the `SUBDOMAINS` variable set to `wildcard`). |
| `-e DNSPLUGIN=cloudflare` | Required if `VALIDATION` is set to `dns`. Options are `cloudflare`, `cloudxns`, `digitalocean`, `dnsimple`, `dnsmadeeasy`, `google`, `luadns`, `nsone`, `ovh`, `rfc2136` and `route53`. Also need to enter the credentials into the corresponding ini file under `/config/dns-conf`. |
| `-e DUCKDNSTOKEN=<token>` | Required if `VALIDATION` is set to `duckdns`. Retrieve your token from https://www.duckdns.org |
| `-e EMAIL=<e-mail>` | Optional e-mail address used for cert expiration notifications. |
| `-e DHLEVEL=2048` | Dhparams bit value (default=2048, can be set to `1024` or `4096`). |
| `-e ONLY_SUBDOMAINS=false` | If you wish to get certs only for certain subdomains, but not the main domain (main domain may be hosted on another machine and cannot be validated), set this to `true` |
| `-e EXTRA_DOMAINS=<extradomains>` | Additional fully qualified domain names (comma separated, no spaces) ie. `extradomain.com,subdomain.anotherdomain.org` |
| `-e STAGING=false` | Set to `true` to retrieve certs in staging mode. Rate limits will be much higher, but the resulting cert will not pass the browser's security test. Only to be used for testing purposes. |
| `-v /config` | All the config files including the webroot reside here. |

## Additional Enivorenment Variables

Below is the complete list of available options that can be used to customize your installation.

| Parameter         | Description                                                    |
|-------------------|----------------------------------------------------------------|
| `DEBUG_MODE`      | Enable Debug Mode - Default: `FALSE`                            |
| `DEBUG_SMTP`      | Setup Mail Catch all on port 1025 (SMTP) and 8025 (HTTP) - Default: `FALSE` |
| `ENABLE_CRON`     | Enable Cron - Default: `TRUE`                                   |
| `ENABLE_SMTP`     | Enable SMTP services - Default: `TRUE`						|
| `ENABLE_ZABBIX`   | Enable Zabbix Agent - Default: `TRUE`                           |
| `TIMEZONE`        | Set Timezone - Default: `Asia/Colombo`                     |

If you wish to have this send mail, set `ENABLE_SMTP=TRUE` and configure the following environment variables. See the [MSMTP Configuration Options](http://msmtp.sourceforge.net/doc/msmtp.html) for further information on options to configure MSMTP

| Parameter         | Description                                                    |
|-------------------|----------------------------------------------------------------|
| `ENABLE_SMTP_GMAIL` | Add setting to supoprt sending through Gmail SMTP - Default: `FALSE` |
| `SMTP_HOST`      | Hostname of SMTP Server - Default: `postfix-openemail`                            |
| `SMTP_PORT`      | Port of SMTP Server - Default: `25`                            |
| `SMTP_DOMAIN`     | HELO Domain - Default: `docker`                                   |
| `SMTP_MAILDOMAIN`     | Mail Domain From - Default: `openemail.io`						|
| `SMTP_AUTHENTICATION`     | SMTP Authentication - Default: `none`                                   |
| `SMTP_USER`     | Enable SMTP services - Default: `user`						|
| `SMTP_PASS`   | Enable SMTP services - Default: `password`                           |
| `SMTP_TLS`        | Use TLS - Default: `off`                     |
| `SMTP_STARTTLS`   | Start TLS from within Dession - Default: `off` |
| `SMTP_TLSCERTCHECK` | Check remote certificate - Default: `off` |

See The [Official Zabbix Agent Documentation](https://www.zabbix.com/documentation/2.2/manual/appendix/config/zabbix_agentd) for information about the following Zabbix values

| Zabbix Parameters | Description                                                    |
|-------------------|----------------------------------------------------------------|
| `ZABBIX_LOGFILE` | Logfile Location - Default: `/var/log/zabbix/zabbix_agentd.log` |
| `ZABBIX_LOGFILESIZE` | Logfile Size - Default: `1` |
| `ZABBIX_DEBUGLEVEL` | Debug Level - Default: `1` |
| `ZABBIX_REMOTECOMMANDS` | Enable Remote Commands (0/1) - Default: `1` |
| `ZABBIX_REMOTECOMMANDS_LOG` | Enable Remote Commands Log (0/1)| - Default: `1` |
| `ZABBIX_SERVER` | Allow connections from Zabbix Server IP - Default: `0.0.0.0/0` |
| `ZABBIX_LISTEN_PORT` | Zabbix Agent Listening Port - Default: `10050` |
| `ZABBIX_LISTEN_IP` | Zabbix Agent Listening IP - Default: `0.0.0.0` |
| `ZABBIX_START_AGENTS` | How many Zabbix Agents to Start - Default: `3 | 
| `ZABBIX_SERVER_ACTIVE` | Server for Active Checks - Default: `zabbix-openemail` |
| `ZABBIX_HOSTNAME` | Container hostname to report to server - Default: `docker` |
| `ZABBIX_REFRESH_ACTIVE_CHECKS` | Seconds to refresh Active Checks - Default: `120` |
| `ZABBIX_BUFFER_SEND` | Buffer Send - Default: `5` |
| `ZABBIX_BUFFER_SIZE` | Buffer Size - Default: `100` |
| `ZABBIX_MAXLINES_SECOND` | Max Lines Per Second - Default: `20` |
| `ZABBIX_ALLOW_ROOT` | Allow running as root - Default: `1` |
| `ZABBIX_USER` | Zabbix user to start as - Default: `zabbix` |

If you enable `DEBUG_PERMISSIONS=TRUE` all the users and groups have been modified in accordance with Environmental Variables will be displayed in output.
e.g. If you add `USER_NGINX=1000` it will reset the containers `nginx` user id from `82` to `1000` - Hint, also change the Group ID to your local development users UID & GID
and avoid Docker permission issues when developing.

| Parameter | Description |
|-----------|-------------|
| `USER_<USERNAME>` |  The user's UID in /etc/passwd will be modified with new UID - Default `N/A` |
| `GROUP_<GROUPNAME>` | The group's GID in /etc/group and /etc/passwd will be modified with new GID - Default `N/A` |
| `GROUP_ADD_<USERNAME>` | The username will be added in /etc/group after the group name defined - Default `N/A` |

# User / Group Identifiers

When using volumes (`-v` flags) permissions issues can arise between the host OS and the container, we avoid this issue by allowing you to specify the user `PUID` and group `PGID`.

Ensure any volume directories on the host are owned by the same user you specify and any permissions issues will vanish like magic.

In this instance `PUID=1000` and `PGID=1000`, to find yours use `id user` as below:

```
  $ id username
    uid=1000(dockeruser) gid=1000(dockergroup) groups=1000(dockergroup)
```

# Application Setup

## Validation and Initial Setup

* Before running this container, make sure that the url and subdomains are properly forwarded to this container's host, and that port 443 (and/or 80) is not being used by another service on the host (NAS gui, another webserver, etc.).
* For `http` validation, port 80 on the internet side of the router should be forwarded to this container's port 80
* For `tls-sni` validation, port 443 on the internet side of the router should be forwarded to this container's port 443
* For `dns` validation, make sure to enter your credentials into the corresponding ini file under `/config/dns-conf`
  * Cloudflare provides free accounts for managing dns and is very easy to use with this image. Make sure that it is set up for "dns only" instead of "dns + proxy"
  * Google dns plugin is meant to be used with "Google Cloud DNS", a paid enterprise product, and not for "Google Domains DNS"
* For `duckdns` validation, set the `SUBDOMAINS` variable to `wildcard`, and set the `DUCKDNSTOKEN` variable with your duckdns token. Due to a limitation of duckdns, the resulting cert will only cover the sub-subdomains (ie. `*.yoursubdomain.duckdns.org`) but will not cover `yoursubdomain.duckdns.org`. Therefore, it is recommended to use a sub-subdomain like `www.yoursubdomain.duckdns.org` for subfolders. You can use our [duckdns image](https://hub.docker.com/r/linuxserver/duckdns/) to update your IP on duckdns.org.
* `--cap-add=NET_ADMIN` is required for fail2ban to modify iptables
* If you need a dynamic dns provider, you can use the free provider duckdns.org where the `URL` will be `yoursubdomain.duckdns.org` and the `SUBDOMAINS` can be `www,ftp,cloud` with http validation, or `wildcard` with dns validation.
* After setup, navigate to `https://yourdomain.url` to access the default homepage (http access through port 80 is disabled by default, you can enable it by editing the default site config at `/config/nginx/site-confs/default`).
* Certs are checked nightly and if expiration is within 30 days, renewal is attempted. If your cert is about to expire in less than 30 days, check the logs under `/config/log/letsencrypt` to see why the renewals have been failing. It is recommended to input your e-mail in docker parameters so you receive expiration notices from letsencrypt in those circumstances.

## Security and password protection

* The container detects changes to url and subdomains, revokes existing certs and generates new ones during start. It also detects changes to the DHLEVEL parameter and replaces the dhparams file.
* If you'd like to password protect your sites, you can use htpasswd. Run the following command on your host to generate the htpasswd file `docker exec -it letsencrypt htpasswd -c /config/nginx/.htpasswd <username>`
* You can add multiple user:pass to `.htpasswd`. For the first user, use the above command, for others, use the above command without the `-c` flag, as it will force deletion of the existing `.htpasswd` and creation of a new one
* You can also use ldap auth for security and access control. A sample, user configurable ldap.conf is provided, and it requires the separate image [linuxserver/ldap-auth](https://hub.docker.com/r/linuxserver/ldap-auth/) to communicate with an ldap server.

## Site config and Reverse Proxy

* The default site config resides at `/config/nginx/site-confs/default`. Feel free to modify this file, and you can add other conf files to this directory. However, if you delete the `default` file, a new default will be created on container start.
* Preset reverse proxy config files are added for popular apps. See the `_readme` file under `/config/nginx/proxy_confs` for instructions on how to enable them
* If you wish to hide your site from search engine crawlers, you may find it useful to add this configuration line to your site config, within the server block, above the line where ssl.conf is included
`add_header X-Robots-Tag "noindex, nofollow, nosnippet, noarchive";`
This will *ask* Google et al not to index and list your site. Be careful with this, as you will eventually be de-listed if you leave this line in on a site you wish to be present on search engines

## Using Certs in Other Containers

* This container includes auto-generated pfx and private-fullchain-bundle pem certs that are needed by other apps like Emby and Znc.
  * To use these certs in other containers, do either of the following:
  1. *(Easier)* Mount the letsencrypt config folder in other containers (ie. `-v /path-to-le-config:/le-ssl`) and in the other containers, use the cert location `/le-ssl/keys/letsencrypt/`
  2. *(More secure)* Mount the letsencrypt folder `etc/letsencrypt` that resides under `/config` in other containers (ie. `-v /path-to-le-config/etc/letsencrypt:/le-ssl`) and in the other containers, use the cert location `/le-ssl/live/<your.domain.url>/` (This is more secure because the first method shares the entire letsencrypt config folder with other containers, including the www files, whereas the second method only shares the ssl certs)
  * These certs include:
  1. `cert.pem`, `chain.pem`, `fullchain.pem` and `privkey.pem`, which are generated by letsencrypt and used by nginx and various other apps
  2. `privkey.pfx`, a format supported by Microsoft and commonly used by dotnet apps such as Emby Server (no password)
  3. `priv-fullchain-bundle.pem`, a pem cert that bundles the private key and the fullchain, used by apps like ZNC

## Using fail2ban

* This container includes fail2ban set up with 3 jails by default:
  1. nginx-http-auth
  2. nginx-badbots
  3. nginx-botsearch
* To enable or disable other jails, modify the file `/config/fail2ban/jail.local`
* To modify filters and actions, instead of editing the `.conf` files, create `.local` files with the same name and edit those because .conf files get overwritten when the actions and filters are updated. `.local` files will append whatever's in the `.conf` files (ie. `nginx-http-auth.conf` --> `nginx-http-auth.local`)
* You can check which jails are active via `docker exec -it letsencrypt fail2ban-client status`
* You can check the status of a specific jail via `docker exec -it letsencrypt fail2ban-client status <jail name>`
* You can unban an IP via `docker exec -it letsencrypt fail2ban-client set <jail name> unbanip <IP>`
* A list of commands can be found here: https://www.fail2ban.org/wiki/index.php/Commands  

# Support Info

* Shell access whilst the container is running: `docker exec -it letsencrypt /bin/bash`
* To monitor the logs of the container in realtime: `docker logs -f letsencrypt`
* container version number 
  * `docker inspect -f '{{ index .Config.Labels "build_version" }}' letsencrypt`
* image version number
  * `docker inspect -f '{{ index .Config.Labels "build_version" }}' linuxserver/letsencrypt`

# Updating Info

Most of our images are static, versioned, and require an image update and container recreation to update the app inside. With some exceptions (ie. nextcloud, plex), we do not recommend or support updating apps inside the container. Please consult the [Application Setup](#application-setup) section above to see if it is recommended for the image.  
  
Below are the instructions for updating containers:  
  
## Via Docker Run/Create

* Update the image: `docker pull openemail/letsencrypt`
* Stop the running container: `docker stop letsencrypt`
* Delete the container: `docker rm letsencrypt`
* Recreate a new container with the same docker create parameters as instructed above (if mapped correctly to a host folder, your `/config` folder and settings will be preserved)
* Start the new container: `docker start letsencrypt`
* You can also remove the old dangling images: `docker image prune`

## Via Docker Compose

* Update all images: `docker-compose pull`
  * or update a single image: `docker-compose pull letsencrypt-openemail`
* Let compose update all containers as necessary: `docker-compose up -d`
  * or update a single container: `docker-compose up -d letsencrypt-openemail`
* You can also remove the old dangling images: `docker image prune`

