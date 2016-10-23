FROM blacklabelops/alpine:3.4
MAINTAINER Steffen Bleul <sbl@blacklabelops.com>

ARG DUPLICITY_VERSION=latest
ARG JOBBER_VERSION=latest

RUN apk upgrade --update && \
    # Install Duplicity
    if  [ "${DUPLICITY_VERSION}" = "latest" ]; \
      then apk add duplicity ; \
      else apk add "duplicity=${DUPLICITY_VERSION}" ; \
    fi && \
    mkdir -p /opt/volumerize && \
    mkdir -p /etc/volumerize && \
    touch /etc/volumerize/backup && \
    touch /etc/volumerize/backupFull && \
    touch /etc/volumerize/restore && \
    touch /etc/volumerize/periodicBackup && \
    touch /etc/volumerize/verify && \
    chmod +x /etc/volumerize/backup /etc/volumerize/backupFull /etc/volumerize/restore \
      /etc/volumerize/periodicBackup /etc/volumerize/verify && \
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
    go get github.com/dshearer/jobber && \
    if  [ "${JOBBER_VERSION}" != "latest" ]; \
      then \
        # wget --directory-prefix=/tmp https://github.com/dshearer/jobber/releases/download/v1.1/jobber-${JOBBER_VERSION}-r0.x86_64.apk && \
        # apk add --allow-untrusted /tmp/jobber-${JOBBER_VERSION}-r0.x86_64.apk ; \
        cd src/github.com/dshearer/jobber && \
        git checkout tags/${JOBBER_VERSION} && \
        cd $JOBBER_LIB ; \
    fi && \
    make -C src/github.com/dshearer/jobber install DESTDIR=$JOBBER_HOME && \
    cp $JOBBER_LIB/bin/* /usr/bin && \
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
      make && \
    rm -rf /var/cache/apk/* && rm -rf /tmp/*

ENV VOLUMERIZE_HOME=/etc/volumerize \
    PATH=$PATH:/etc/volumerize

USER root
WORKDIR /etc/volumerize
COPY imagescripts/*.sh /opt/volumerize/
ENTRYPOINT ["/bin/tini","--","/opt/volumerize/docker-entrypoint.sh"]
CMD ["volumerize"]
