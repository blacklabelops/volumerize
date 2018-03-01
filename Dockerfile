FROM alpine:3.7
MAINTAINER Steffen Bleul <sbl@blacklabelops.com>

ARG JOBBER_VERSION=1.3.2
ARG 17.12.1

ENV VOLUMERIZE_HOME=/etc/volumerize \
    VOLUMERIZE_CACHE=/volumerize-cache \
    PATH=$PATH:/etc/volumerize \
    GOOGLE_DRIVE_SETTINGS=/credentials/cred.file \
    GOOGLE_DRIVE_CREDENTIAL_FILE=/credentials/googledrive.cred \
    GPG_TTY=/dev/console


RUN apk --no-cache add \
  tzdata \
  ca-certificates \
  curl \
  tini \
  duply \
  duplicity \
  py-pip \
  openssl \
  openssh \
  libffi \
  rsync \
  lftp


RUN apk --no-cache add \
      python-dev \
      libffi-dev \
      openssl-dev \
      gcc \
      alpine-sdk \
      linux-headers \
      musl-dev \
      make \
    && \
    pip install --upgrade pip && \
    pip install \
      PyDrive \
      azure-storage \
      boto \
      lockfile \
      fasteners \
      mediafire \
      paramiko \
      pycryptopp \
      python-keystoneclient \
      python-swiftclient \
      requests \
      requests_oauthlib \
      urllib3 \
      dropbox==6.9.0 \
    && apk del \
      python-dev \
      libffi-dev \
      openssl-dev \
      gcc \
      alpine-sdk \
      linux-headers \
      musl-dev \
      make 

# Install Docker CLI
RUN curl -fSL "https://download.docker.com/linux/static/stable/x86_64/docker-${DOCKER_VERSION}-ce.tgz" \
      -o /tmp/docker.tgz && \
	  tar -xzvf /tmp/docker.tgz -C /tmp && \
	  mv /tmp/docker/docker /usr/local/bin/ && \
      rm -rf /tmp/docker.tgz /tmp/docker

RUN  mkdir -p /etc/volumerize /volumerize-cache /opt/volumerize && \
    touch /etc/volumerize/remove-all-inc-of-but-n-full /etc/volumerize/remove-all-but-n-full /etc/volumerize/startContainers /etc/volumerize/stopContainers \
      /etc/volumerize/backup /etc/volumerize/backupIncremental /etc/volumerize/backupFull /etc/volumerize/restore \
      /etc/volumerize/periodicBackup /etc/volumerize/verify /etc/volumerize/cleanup /etc/volumerize/remove-older-than /etc/volumerize/cleanCacheLocks && \
    chmod +x /etc/volumerize/remove-all-inc-of-but-n-full /etc/volumerize/remove-all-but-n-full /etc/volumerize/startContainers /etc/volumerize/stopContainers \
      /etc/volumerize/backup /etc/volumerize/backupIncremental /etc/volumerize/backupFull /etc/volumerize/restore \
      /etc/volumerize/periodicBackup /etc/volumerize/verify /etc/volumerize/cleanup /etc/volumerize/remove-older-than /etc/volumerize/cleanCacheLocks

RUN curl -Ls https://github.com/dshearer/jobber/releases/download/v${JOBBER_VERSION}/jobber-${JOBBER_VERSION}-r0_alpine3.6and3.7.apk -o /tmp/jobber.apk && \
    apk add --allow-untrusted --no-scripts /tmp/jobber.apk && \
    rm -f /tmp/jobber.apk
 

WORKDIR /etc/volumerize
VOLUME ["/volumerize-cache"]
COPY imagescripts/*.sh /opt/volumerize/
ENTRYPOINT ["/sbin/tini","--","/opt/volumerize/docker-entrypoint.sh"]
CMD ["volumerize"]
