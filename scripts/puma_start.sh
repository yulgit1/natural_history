#!/bin/bash
set -e

source /home/ec2-user/.rvm/scripts/rvm
rvm use ruby-3.3.11

cd /opt/natural_history
exec bundle exec puma -C config/puma.rb
