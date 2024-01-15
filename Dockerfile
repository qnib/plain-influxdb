# syntax=docker/dockerfile:1.4
FROM alpine:3.19 AS down
ARG INFLUXDB_VER=2.7.5
ARG TARGETARCH
WORKDIR /opt/
RUN <<eot ash
  if [[ ${TARGETARCH} == "amd64" ]];then
    wget -qO- https://dl.influxdata.com/influxctl/releases/influxctl-v2.4.2-linux-x86_64.tar.gz |tar xfz - --strip-components=0
  else
    wget -qO- https://dl.influxdata.com/influxctl/releases/influxctl-v2.4.2-linux-arm64.tar.gz |tar xfz - --strip-components=0
  fi
  wget -qO- https://dl.influxdata.com/influxdb/releases/influxdb2-${INFLUXDB_VER}_linux_${TARGETARCH}.tar.gz |tar xfz - --strip-components=1
  wget -qO- https://dl.influxdata.com/influxdb/releases/influxdb2-client-2.7.3-linux-${TARGETARCH}.tar.gz |tar xfz - --strip-components=0
eot

COPY init.sh /opt/usr/lib/influxdb/scripts/init.sh

FROM qnib/alplain-init:3.19.0
ARG TARGETARCH
ENV ROOT_PASSWORD=root \
    METRIC_DATABASE=carbon \
    METRIC_USERNAME=carbon \
    METRIC_PASSWORD=carbon \
    DASHBOARD_DATABASE=default \
    DASHBOARD_USERNAME=default \
    DASHBOARD_PASSWORD=default \
    INFLUXDB_ORG_NAME=qnib \
    INFLUXDB_OPERATOR_TOKEN=qnib \
    INFLUX_USER=influxdb \
    INFLUXDB_BUCKET=qnib \
    INFLUX_PASSWD=influxdb \
    INFLUX_GROUP=influxdb \
    INFLUXDB_META_PORT=8088 \
    INFLUXDB_META_HTTP_PORT=8091 \
    INFLUXDB_ADMIN_HOST=0.0.0.0 \
    INFLUXDB_ADMIN_PORT=8083 \
    INFLUXDB_HTTP_PORT=8086 \
    INFLUXDB_OPENTSDB_PORT=4242 \
    INFLUXDB_GRAPHITE_ENABLED=false \
    INFLUXDB_COLLECTD_ENABLED=false \
    INFLUXDB_OPENTSDB_ENABLED=false \
    INFLUXDB_DATABASES=qcollect \
    INFLUXDB_META_DIR=/opt/influxdb/shared/meta \
    INFLUXDB_META_LOGGING=false \
    INFLUXDB_DATA_DIR=/opt/influxdb/shared/data \
    INFLUXDB_WAL_DIR=/opt/influxdb/shared/wal \
    INFLUXDB_WAL_LOGGING=false \
    INFLUXDB_QUERY_LOGGING=false \
    INFLUXDB_HTTP_LOGGING=false \
    INFLUXDB_TRACE_LOGGING=false \
    ENTRYPOINTS_DIR=/opt/qnib/entry \
    PATH=${PATH}:/opt/influxdb/
ARG INFLUXDB_VER=2.7.5
ARG CT_VER=0.18.5
WORKDIR /opt/influxdb/
COPY --from=down /opt/influx /usr/bin/
COPY --from=down /opt/config.toml .
COPY --from=down /opt/usr/bin/influxd /usr/bin/
COPY --from=down /opt/usr/share/influxdb /usr/share/influxdb
COPY --from=down /opt/usr/lib/influxdb /usr/lib/influxdb
RUN <<eot ash
  adduser --disabled-password --home /home/${INFLUX_USER} ${INFLUX_USER}
 mkdir -p /var/log/influxdb /var/run/influxdb
 chown -R ${INFLUX_USER}: /var/log/influxdb
 chown -R ${INFLUX_USER}: /var/run/influxdb
eot

COPY opt/qnib/influxdb/bin/start.sh /opt/qnib/influxdb/bin/
COPY opt/healthchecks/20-influxdb.sh /opt/healthchecks/
COPY opt/qnib/entry/10-influxdb.sh /opt/qnib/entry/
HEALTHCHECK --interval=5s --retries=3 --timeout=1s \
  CMD /usr/local/bin/healthcheck.sh
CMD ["/opt/qnib/influxdb/bin/start.sh"]
