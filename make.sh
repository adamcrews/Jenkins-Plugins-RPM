#!/usr/bin/env bash
set -e

MAX_PARALLEL=10

CACHE_DIR='.cache'

# These vars are also passed to docker
PKG_JSON="${CACHE_DIR}/update-center.json"
RELEASE=2

echo -n "Getting updates.json ... "
mkdir .cache > /dev/null 2>&1 || true
curl -s -k https://updates.jenkins-ci.org/current/update-center.actual.json > ${PKG_JSON}
echo "done"

echo -n "Caching jfrog creds ... "
cp ~/.jfrog/jfrog-cli.conf .cache
echo "done"

# Find all the plugins in the updates file and run $MAX_PARALLEL processes
jq -r '.plugins|keys|"\(.[])"' ${PKG_JSON} | \
  xargs --max-args=1 --max-procs=${MAX_PARALLEL} \
  docker run -e PKG_JSON=$PKG_JSON -e RELEASE=$RELEASE -t -v $PWD:/work -w /work --rm jenkins-plugins-build ./build-1.sh
