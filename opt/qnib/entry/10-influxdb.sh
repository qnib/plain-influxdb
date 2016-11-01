#!/bin/bash

consul-template -once -template="/etc/consul-templates/influxdb/influxdb.conf.ctmpl:/etc/influxdb/influxdb.conf"
