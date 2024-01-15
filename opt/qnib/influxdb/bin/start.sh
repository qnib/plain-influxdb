#! /bin/bash
set -xe

/usr/lib/influxdb/scripts/init.sh start

influx setup \
  --username ${INFLUX_USER} \
  --password ${INFLUX_PASSWD} \
  --token ${INFLUXDB_OPERATOR_TOKEN} \
  --org ${INFLUXDB_ORG_NAME} \
  --bucket ${INFLUXDB_BUCKET} \
  --force

tail -f /var/log/influxdb/influxd.log