FROM blacklabelops/alpine:3.6
MAINTAINER Steffen Bleul <sbl@blacklabelops.com>

ARG DUPLICITY_VERSION=latest
ARG JOBBER_VERSION=1.1
ARG DOCKER_VERSION=1.12.2

RUN apk upgrade --update && \
    apk add \
      tzdata \
      openssh \
      openssl \
      duply \
      ca-certificates \
      python-dev \
      libffi-dev \
      openssl-dev \
      gcc \
      alpine-sdk \
      linux-headers \
      musl-dev \
      rsync \
      lftp \
      py-pip && \
    # Install Duplicity
    if  [ "${DUPLICITY_VERSION}" = "latest" ]; \
      then apk add duplicity ; \
      else apk add "duplicity=${DUPLICITY_VERSION}" ; \
    fi && \
    pip install --upgrade pip && \
    pip install \
      PyDrive \
      azure-storage \
      boto \
      lockfile \
      mediafire \
      paramiko \
      pycryptopp \
      python-keystoneclient \
      python-swiftclient \
      requests \
      requests_oauthlib \
      urllib3 \
      dropbox==6.9.0 && \
    mkdir -p /etc/volumerize /volumerize-cache /opt/volumerize && \
    touch /etc/volumerize/remove-all-inc-of-but-n-full /etc/volumerize/remove-all-but-n-full /etc/volumerize/startContainers /etc/volumerize/stopContainers \
      /etc/volumerize/backup /etc/volumerize/backupIncremental /etc/volumerize/backupFull /etc/volumerize/restore \
      /etc/volumerize/periodicBackup /etc/volumerize/verify /etc/volumerize/cleanup /etc/volumerize/remove-older-than /etc/volumerize/cleanCacheLocks && \
    chmod +x /etc/volumerize/remove-all-inc-of-but-n-full /etc/volumerize/remove-all-but-n-full /etc/volumerize/startContainers /etc/volumerize/stopContainers \
      /etc/volumerize/backup /etc/volumerize/backupIncremental /etc/volumerize/backupFull /etc/volumerize/restore \
      /etc/volumerize/periodicBackup /etc/volumerize/verify /etc/volumerize/cleanup /etc/volumerize/remove-older-than /etc/volumerize/cleanCacheLocks && \
    # Install Jobber
    export JOBBER_HOME=/tmp/jobber && \
    export JOBBER_LIB=$JOBBER_HOME/lib && \
    export GOPATH=$JOBBER_LIB && \
    export CONTAINER_UID=1000 && \
    export CONTAINER_GID=1000 && \
    export CONTAINER_USER=jobber_client && \
    export CONTAINER_GROUP=jobber_client && \
    # Install tools
    apk add \
      go \
      git \
      curl \
      wget \
      make && \
    mkdir -p $JOBBER_HOME && \
    mkdir -p $JOBBER_LIB && \
    # Install Jobber
    addgroup -g $CONTAINER_GID jobber_client && \
    adduser -u $CONTAINER_UID -G jobber_client -s /bin/bash -S jobber_client && \
    cd $JOBBER_LIB && \
    go get github.com/dshearer/jobber;true && \
    if  [ "${JOBBER_VERSION}" != "latest" ]; \
      then \
        # wget --directory-prefix=/tmp https://github.com/dshearer/jobber/releases/download/v1.1/jobber-${JOBBER_VERSION}-r0.x86_64.apk && \
        # apk add --allow-untrusted /tmp/jobber-${JOBBER_VERSION}-r0.x86_64.apk ; \
        cd src/github.com/dshearer/jobber && \
        git checkout tags/v${JOBBER_VERSION} && \
        cd $JOBBER_LIB ; \
    fi && \
    make -C src/github.com/dshearer/jobber install DESTDIR=$JOBBER_HOME && \
    cp $JOBBER_LIB/bin/* /usr/bin && \
    # Install Docker CLI
    curl -fSL "https://get.docker.com/builds/Linux/x86_64/docker-${DOCKER_VERSION}.tgz" -o /tmp/docker.tgz && \
    export DOCKER_SHA=43b2479764ecb367ed169076a33e83f99a14dc85 && \
    echo 'Calculated checksum: '$(sha1sum /tmp/docker.tgz) && \
    echo "$DOCKER_SHA  /tmp/docker.tgz" | sha1sum -c - && \
	  tar -xzvf /tmp/docker.tgz -C /tmp && \
	  cp /tmp/docker/docker /usr/local/bin/ && \
    # Install Tini Zombie Reaper And Signal Forwarder
    export TINI_VERSION=0.9.0 && \
    export TINI_SHA=fa23d1e20732501c3bb8eeeca423c89ac80ed452 && \
    curl -fsSL https://github.com/krallin/tini/releases/download/v${TINI_VERSION}/tini-static -o /bin/tini && \
    echo 'Calculated checksum: '$(sha1sum /bin/tini) && \
    chmod +x /bin/tini && echo "$TINI_SHA  /bin/tini" | sha1sum -c - && \
    # Cleanup
    apk del \
      go \
      git \
      curl \
      wget \
      python-dev \
      libffi-dev \
      openssl-dev \
      alpine-sdk \
      linux-headers \
      gcc \
      musl-dev \
      make && \
    rm -rf /var/cache/apk/* && rm -rf /tmp/*

ENV VOLUMERIZE_HOME=/etc/volumerize \
    VOLUMERIZE_CACHE=/volumerize-cache \
    PATH=$PATH:/etc/volumerize \
    GOOGLE_DRIVE_SETTINGS=/credentials/cred.file \
    GOOGLE_DRIVE_CREDENTIAL_FILE=/credentials/googledrive.cred \
    GPG_TTY=/dev/console

USER root
WORKDIR /etc/volumerize
VOLUME ["/volumerize-cache"]
COPY imagescripts/*.sh /opt/volumerize/
ENTRYPOINT ["/bin/tini","--","/opt/volumerize/docker-entrypoint.sh"]
CMD ["volumerize"]
