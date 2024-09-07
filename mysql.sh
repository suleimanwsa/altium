#!/bin/bash
# Update the system
apt-get update -y
apt install mysql-server -y
service mysql status
service mysql restart