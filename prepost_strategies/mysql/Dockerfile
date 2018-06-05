FROM blacklabelops/volumerize

RUN apk add --no-cache \
    mysql-client pv

COPY postexecute /postexecute
COPY prexecute /prexecute