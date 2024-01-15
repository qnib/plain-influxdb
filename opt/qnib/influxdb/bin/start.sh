#! /bin/bash
set -xe

/usr/lib/influxdb/scripts/init.sh start
tail -f /var/log/influxdb/influxd.log