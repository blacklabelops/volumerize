FROM alpine:3.13.5 as megacmd-compiler

RUN apk add --repository https://dl-cdn.alpinelinux.org/alpine/edge/testing --update \
      libtool \
      autoconf \
      automake \
      c-ares-dev \
      crypto++-dev \
      curl \
      curl-dev \
      file \
      g++ \
      gcc \
      git \
      sqlite-dev \
      pcre-dev \
      libc-dev \
      libffi-dev \
      libressl-dev \
      libsodium \
      libsodium-dev \
      libuv-dev \
      make \
      openssl \
      openssl-dev \
      readline-dev \
      zlib-dev \
      freeimage-dev && \
    git clone https://github.com/meganz/MEGAcmd.git /opt/MEGAcmd && \
    cd /opt/MEGAcmd && \
    git submodule update --init --recursive && \
    sh autogen.sh && \
    ./configure && \
    make -j $(nproc) && \
    make install


FROM alpine:3.13.5
MAINTAINER Steffen Bleul <sbl@blacklabelops.com>

ARG JOBBER_VERSION=1.4.4
ARG DOCKER_VERSION=20.10.6
ARG DUPLICITY_VERSION=0.8.19
ARG DUPLICITY_SERIES=0.8

COPY --from=megacmd-compiler /usr/local/bin/mega-* /usr/local/bin/
COPY --from=megacmd-compiler /usr/local/lib/libmega* /usr/local/lib/

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
      python3-dev \
      duplicity \
      py3-pip && \
    pip install --upgrade pip && \
    pip install \
      setuptools \
      fasteners \
      google-api-python-client>=2.2.0 \
      PyDrive \
      chardet \
      azure-storage-blob \
      azure-storage-queue \
      boto \
      lockfile \
      paramiko \
      python-keystoneclient \
      python-swiftclient \
      requests \
      requests_oauthlib \
      urllib3 \
      b2 \
      dropbox && \
    mkdir -p /etc/volumerize /volumerize-cache /opt/volumerize && \
    curl -fSL "https://code.launchpad.net/duplicity/${DUPLICITY_SERIES}-series/${DUPLICITY_VERSION}/+download/duplicity-${DUPLICITY_VERSION}.tar.gz" -o /tmp/duplicity.tar.gz && \
    export DUPLICITY_SHA=2d048377c839ae56fc2828997c9aa7ba8c339e815e1e2ae738652037508ec276a2c72583687da34408fadd4839011e242b51bc73cca954227fc51db5683c258c && \
    echo 'Calculated checksum: '$(sha512sum /tmp/duplicity.tar.gz) && \
    # echo "$DUPLICITY_SHA  /tmp/duplicity.tar.gz" | sha512sum -c - && \
    tar -xzvf /tmp/duplicity.tar.gz -C /tmp && \
    cd /tmp/duplicity-${DUPLICITY_VERSION} && python3 setup.py install && \
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
    curl -fSL "https://download.docker.com/linux/static/stable/x86_64/docker-${DOCKER_VERSION}.tgz" -o /tmp/docker.tgz && \
    export DOCKER_SHA=3aab01ab17734866df8b98938243f3f4c835592c && \
    echo 'Calculated checksum: '$(sha1sum /tmp/docker.tgz) && \
    echo "$DOCKER_SHA  /tmp/docker.tgz" | sha1sum -c - && \
	  tar -xzvf /tmp/docker.tgz -C /tmp && \
	  cp /tmp/docker/docker /usr/local/bin/ && \
    # Install MEGAtools
    curl -fSL "https://megatools.megous.com/builds/megatools-1.10.3.tar.gz" -o /tmp/megatools.tgz && \
    tar -xzvf /tmp/megatools.tgz -C /tmp && \
    cd /tmp/megatools-1.10.3 && \
    ./configure && \
    make && \
    make install && \
    # Install MegaCMD dependencies
    apk add --repository https://dl-cdn.alpinelinux.org/alpine/edge/testing --update --no-cache \
      c-ares \
      crypto++ \
      libcurl \
      libtool \
      libuv \
      libpcrecpp \
      libsodium \
      sqlite-libs \
      sqlite \
      pcre \
      readline \
      freeimage \
      zlib && \
    # Test MegaCMD binaries
    find /usr/local/bin -type f -executable -name 'mega-*' | \
      while read binary; do command -v $binary > /dev/null; done && \
    # Cleanup
    apk del \
      go \
      git \
      curl \
      wget \
      python3-dev \
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
