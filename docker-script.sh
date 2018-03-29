#!/bin/bash

. config.ini

set -e

echo -n "Getting updates.json ... "
#curl -s -k https://updates.jenkins-ci.org/current/update-center.json | \
#  sed -e 's/^updateCenter.post(//' | \
#  sed -e 's/);$//' > update-center.json
curl -s -k https://updates.jenkins-ci.org/current/update-center.actual.json > update-center.json
echo "done"

jq -r '.plugins|keys|"\(.[])"' update-center.json | \
  xargs -n 1 -p 8 ./build-1.sh {}

#
# | while read plugin
#do
#  ./build-1.sh $plugin
#done
