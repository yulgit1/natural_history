#!/bin/bash

cd /opt/natural_history
source /home/ec2-user/.rvm/environments/ruby-2.4.1@bartram
bundle exec puma -C config/puma.rb
