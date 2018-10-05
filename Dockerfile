FROM blacklabelops/alpine:3.8
MAINTAINER Steffen Bleul <sbl@blacklabelops.com>

ARG JOBBER_VERSION=1.1
ARG DOCKER_VERSION=1.12.2
ARG DUPLICITY_VERSION=0.7.18
ARG DUPLICITY_SERIES=0.7

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
      librsync-dev \
      gcc \
      alpine-sdk \
      linux-headers \
      musl-dev \
      rsync \
      lftp \
      py-pip \
      duplicity && \
    pip install --upgrade pip && \
    pip install \
      fasteners \
      PyDrive \
      chardet \
      azure-storage \
      boto \
      lockfile \
      paramiko \
      pycryptopp \
      python-keystoneclient \
      python-swiftclient \
      requests==2.14.2 \
      requests_oauthlib \
      urllib3 \
      b2 \
      dropbox==6.9.0 && \
    mkdir -p /etc/volumerize /volumerize-cache /opt/volumerize && \
    touch /etc/volumerize/remove-all-inc-of-but-n-full /etc/volumerize/remove-all-but-n-full /etc/volumerize/startContainers /etc/volumerize/stopContainers \
      /etc/volumerize/backup /etc/volumerize/backupIncremental /etc/volumerize/backupFull /etc/volumerize/restore \
      /etc/volumerize/periodicBackup /etc/volumerize/verify /etc/volumerize/cleanup /etc/volumerize/remove-older-than /etc/volumerize/cleanCacheLocks \
      /etc/volumerize/prepoststrategy /etc/volumerize/list && \
    chmod +x /etc/volumerize/remove-all-inc-of-but-n-full /etc/volumerize/remove-all-but-n-full /etc/volumerize/startContainers /etc/volumerize/stopContainers \
      /etc/volumerize/backup /etc/volumerize/backupIncremental /etc/volumerize/backupFull /etc/volumerize/restore \
      /etc/volumerize/periodicBackup /etc/volumerize/verify /etc/volumerize/cleanup /etc/volumerize/remove-older-than /etc/volumerize/cleanCacheLocks \
      /etc/volumerize/prepoststrategy /etc/volumerize/list
RUN curl -fSL "https://code.launchpad.net/duplicity/${DUPLICITY_SERIES}-series/${DUPLICITY_VERSION}/+download/duplicity-${DUPLICITY_VERSION}.tar.gz" -o /tmp/duplicity.tar.gz && \
    export DUPLICITY_SHA=75940a82b7887846778633bc6256913df7834c5afdc8d75c54018f42b0e79b1048cd8807c00092b93d1504ac4850ba3426cb96307eadd89e59ad18e54ded3780 && \
    echo 'Calculated checksum: '$(sha512sum /tmp/duplicity.tar.gz) && \
    echo "$DUPLICITY_SHA  /tmp/duplicity.tar.gz" | sha512sum -c - && \
    tar -xzvf /tmp/duplicity.tar.gz -C /tmp && \
    cd /tmp/duplicity-${DUPLICITY_VERSION} && python setup.py install
    # Install Jobber
RUN export JOBBER_HOME=/tmp/jobber && \
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
    # Cleanup
    apk del \
      go \
      git \
      curl \
      wget \
      python-dev \
      libffi-dev \
      openssl-dev \
      openssl \
      alpine-sdk \
      linux-headers \
      gcc \
      musl-dev \
      librsync-dev \
      make && \
    apk add \
        openssl && \
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
ENTRYPOINT ["/sbin/tini","--","/opt/volumerize/docker-entrypoint.sh"]
CMD ["volumerize"]
