#! /bin/bash

influxd -pidfile /var/run/influxdb.pid -config /etc/influxdb/influxdb.conf ${INFLUXD_OPTS} &
sleep 5
if [ "X${INFLUXDB_DATABASES}" != "X" ];then
    for db in $(echo ${INFLUXDB_DATABASES} |sed -e 's/,/ /g');do 
        echo "[INFO] Create database ${db}"
        influx -host localhost -port 8086 -execute "create database ${db}"
    done
fi
fg
