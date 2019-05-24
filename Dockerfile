FROM alpine:20190508
MAINTAINER Steffen Bleul <sbl@blacklabelops.com>

ARG JOBBER_VERSION=1.3.4
ARG DOCKER_VERSION=1.12.2
ARG DUPLICITY_VERSION=0.7.18.2
ARG DUPLICITY_SERIES=0.7

RUN apk upgrade --update && \
    apk add \
      bash \
      tzdata \
      vim \
      tini \
      su-exec \
      gzip \
      tar \
      wget \
      curl \
      build-base \
      glib-dev \
      gmp-dev \
      asciidoc \
      curl-dev \
      tzdata \
      openssh \
      libressl-dev \
      libressl \
      duply \
      ca-certificates \
      python-dev \
      libffi-dev \
      librsync-dev \
      gcc \
      alpine-sdk \
      linux-headers \
      musl-dev \
      rsync \
      lftp \
      py-cryptography \
      librsync \
      librsync-dev \
      python2-dev \
      duplicity \
      py-pip && \
    pip install --upgrade pip && \
    pip install \
      setuptools \
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
    curl -fSL "https://code.launchpad.net/duplicity/${DUPLICITY_SERIES}-series/${DUPLICITY_VERSION}/+download/duplicity-${DUPLICITY_VERSION}.tar.gz" -o /tmp/duplicity.tar.gz && \
    export DUPLICITY_SHA=7fb477b1bbbfe060daf130a5b0518a53b7c6e6705e5459c191fb44c8a723c9a5e2126db98544951ffb807a5de7e127168cba165a910f962ed055d74066f0faa5 && \
    echo 'Calculated checksum: '$(sha512sum /tmp/duplicity.tar.gz) && \
    # echo "$DUPLICITY_SHA  /tmp/duplicity.tar.gz" | sha512sum -c - && \
    tar -xzvf /tmp/duplicity.tar.gz -C /tmp && \
    cd /tmp/duplicity-${DUPLICITY_VERSION} && python setup.py install && \
    # Install Jobber
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
    # Install Jobber
    addgroup -g $CONTAINER_GID jobber_client && \
    adduser -u $CONTAINER_UID -G jobber_client -s /bin/bash -S jobber_client && \
    wget --directory-prefix=/tmp https://github.com/dshearer/jobber/releases/download/v${JOBBER_VERSION}/jobber-${JOBBER_VERSION}-r0.apk && \
    apk add --allow-untrusted --no-scripts /tmp/jobber-${JOBBER_VERSION}-r0.apk && \
    # Install Docker CLI
    curl -fSL "https://get.docker.com/builds/Linux/x86_64/docker-${DOCKER_VERSION}.tgz" -o /tmp/docker.tgz && \
    export DOCKER_SHA=43b2479764ecb367ed169076a33e83f99a14dc85 && \
    echo 'Calculated checksum: '$(sha1sum /tmp/docker.tgz) && \
    echo "$DOCKER_SHA  /tmp/docker.tgz" | sha1sum -c - && \
	  tar -xzvf /tmp/docker.tgz -C /tmp && \
	  cp /tmp/docker/docker /usr/local/bin/ && \
    # Install MEGAtools
    curl -fSL "https://megatools.megous.com/builds/megatools-1.9.98.tar.gz" -o /tmp/megatools.tgz && \
    tar -xzvf /tmp/megatools.tgz -C /tmp && \
    cd /tmp/megatools-1.9.98 && \
    ./configure && \
    make && \
    make install && \
    # Cleanup
    apk del \
      go \
      git \
      curl \
      wget \
      python-dev \
      libffi-dev \
      libressl-dev \
      libressl \
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
    VOLUMERIZE_SCRIPT_DIR=/opt/volumerize \
    PATH=$PATH:/etc/volumerize \
    GOOGLE_DRIVE_SETTINGS=/credentials/cred.file \
    GOOGLE_DRIVE_CREDENTIAL_FILE=/credentials/googledrive.cred \
    GPG_TTY=/dev/console

USER root
WORKDIR /etc/volumerize
VOLUME ["/volumerize-cache"]
COPY imagescripts/ /opt/volumerize/
COPY scripts/ /etc/volumerize/
ENTRYPOINT ["/sbin/tini","--","/opt/volumerize/docker-entrypoint.sh"]
CMD ["volumerize"]
