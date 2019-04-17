FROM linuxserver/letsencrypt:latest
LABEL maintainer="Chinthka Deshapriya (chinthaka@cybergate.lk)"
### Set Defaults
ENV DEBUG_MODE=FALSE \
    ENABLE_CRON=TRUE \
    ENABLE_SMTP=TRUE \
    ENABLE_ZABBIX=TRUE \
    TERM=xterm \
    ZABBIX_HOSTNAME=letsencrypt-openemail

RUN set -x && \

### Install MailHog
    apk add -t .mailhog-build-dependencies \
            go \
            git \
            musl-dev \
            && \
    mkdir -p /usr/src/gocode && \
    export GOPATH=/usr/src/gocode && \
    go get github.com/mailhog/MailHog && \
    go get github.com/mailhog/mhsendmail && \
    mv /usr/src/gocode/bin/MailHog /usr/local/bin && \
    mv /usr/src/gocode/bin/mhsendmail /usr/local/bin && \
    rm -rf /usr/src/gocode && \
    apk del --purge .mailhog-build-dependencies && \
    adduser -D -u 1025 mailhog && \
    \
### Add Core Utils
    apk upgrade && \
    apk add -t .base-rundeps \
         bash \
         curl \
         grep \
         less \
         logrotate \
         msmtp \
         nano \
         sudo \
         tzdata \
         vim \
         zabbix-agent \
         && \
    rm -rf /var/cache/apk/* && \
    rm -rf /etc/logrotate.d/acpid && \
    rm -rf /root/.cache /root/.subversion && \
    cp -R /usr/share/zoneinfo/Asia/Colombo /etc/localtime && \
    echo 'Asia/Colombo' > /etc/timezone &&  \
    echo '%zabbix ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers 

### Networking Configuration
EXPOSE 80 443 

### Add Folders
ADD /install /


