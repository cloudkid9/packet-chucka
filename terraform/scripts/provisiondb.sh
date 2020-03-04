#!/bin/bash
wget -qO- https://repos.influxdata.com/influxdb.key | sudo apt-key add -
source /etc/lsb-release
echo "deb https://repos.influxdata.com/ubuntu bionic stable" | sudo tee /etc/apt/sources.list.d/influxdb.list
sudo apt-get update
sudo apt-get install -y influxdb
influxd run & sleep 5 && influx -execute 'CREATE DATABASE k6' && kill %1 && sleep 5
sudo chown -R influxdb:influxdb /var/lib/influxdb/*
sudo systemctl start influxdb
sudo systemctl enable influxdb

exit 0