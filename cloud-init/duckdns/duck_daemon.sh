#!/bin/bash

# From https://www.duckdns.org/install.jsp#ec2

su - ec2-user -c "nohup ~/duckdns/duck.sh > ~/duckdns/duck.log 2>&1&"
