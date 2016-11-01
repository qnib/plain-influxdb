#! /bin/bash

exec influxd -pidfile /var/run/influxdb.pid -config /etc/influxdb/influxdb.conf ${INFLUXD_OPTS}
