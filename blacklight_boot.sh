#!/bin/bash

cd /opt/natural_history
source /home/ec2-user/.rvm/environments/default
bundle exec puma -C config/puma.rb
