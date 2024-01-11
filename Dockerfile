FROM alpine:3.19 AS down
ARG INFLUXDB_VER=2.7.5
WORKDIR /opt/
RUN wget -qO- https://dl.influxdata.com/influxctl/releases/influxctl-v2.4.2-linux-x86_64.tar.gz |tar xfz - --strip-components=0
RUN wget -qO- https://dl.influxdata.com/influxdb/releases/influxdb2-${INFLUXDB_VER}_linux_amd64.tar.gz |tar xfz - --strip-components=1
COPY init.sh /opt/usr/lib/influxdb/scripts/init.sh

FROM qnib/alplain-init
ENV ROOT_PASSWORD=root \
    METRIC_DATABASE=carbon \
    METRIC_USERNAME=carbon \
    METRIC_PASSWORD=carbon \
    DASHBOARD_DATABASE=default \
    DASHBOARD_USERNAME=default \
    DASHBOARD_PASSWORD=default \
    INFLUX_USER=influxdb \
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
COPY --from=down /opt/influxctl /usr/bin/
COPY --from=down /opt/usr/bin/influxd /usr/bin/
COPY --from=down /opt/usr/share/influxdb /usr/share/influxdb
COPY --from=down /opt/usr/lib/influxdb /usr/lib/influxdb
RUN adduser --disabled-password --home /home/${INFLUX_USER} ${INFLUX_USER} \
 && mkdir -p /var/log/influxdb /var/run/influxdb \
 && chown -R ${INFLUX_USER}: /var/log/influxdb \
 && chown -R ${INFLUX_USER}: /var/run/influxdb
RUN apk add --no-cache --virtual .build-deps wget gnupg tar ca-certificates \
 && apk del .build-deps \
 && apk --no-cache add wget curl \
 && wget -qO /usr/local/bin/go-github https://github.com/qnib/go-github/releases/download/0.2.2/go-github_0.2.2_MuslLinux \
 && chmod +x /usr/local/bin/go-github \
 && echo -n "# Download: " \
 && mkdir -p /usr/share/collectd/ \
 && wget -qO /usr/share/collectd/types.db https://raw.githubusercontent.com/collectd/collectd/master/src/types.db \
 && curl -Lso /tmp/consul-template.zip https://releases.hashicorp.com/consul-template/${CT_VER}/consul-template_${CT_VER}_linux_amd64.zip \
 && cd /usr/local/bin \
 && unzip /tmp/consul-template.zip \
 && apk --no-cache del unzip wget curl \
 && rm -f /tmp/consul-template.zip

COPY opt/qnib/influxdb/bin/start.sh /opt/qnib/influxdb/bin/
COPY opt/healthchecks/20-influxdb.sh /opt/healthchecks/
COPY etc/consul-templates/influxdb/influxdb.conf.ctmpl /etc/consul-templates/influxdb/
COPY opt/qnib/entry/10-influxdb.sh /opt/qnib/entry/
HEALTHCHECK --interval=5s --retries=15 --timeout=1s \
  CMD /usr/local/bin/healthcheck.sh
CMD ["/opt/qnib/influxdb/bin/start.sh"]
