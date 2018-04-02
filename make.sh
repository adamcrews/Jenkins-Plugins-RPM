#!/usr/bin/env bash
set -e

MAX_PARALLEL=20
RELEASE=2

CACHE_DIR='.cache'

PKG_JSON="${CACHE_DIR}/update-center.json"
ART_JSON="${CACHE_DIR}/artifactory.json"
REPO_DEST='jenkins-plugins-rpm'

echo -n "Getting updates.json ... "
mkdir .cache > /dev/null 2>&1 || true
curl -s -k https://updates.jenkins-ci.org/current/update-center.actual.json > ${PKG_JSON}
echo "done"

echo -n "Caching jfrog creds ... "
cp ~/.jfrog/jfrog-cli.conf .cache
echo "done"

echo -n "Caching artifactory pkg list ... "
jfrog rt s ${REPO_DEST} > ${ART_JSON}
echo "done"

function checkpkg() {
  LC_ALL=C
  plugin=$1
  name=$(jq -r ".plugins[\"${plugin}\"].name" ${PKG_JSON})
  version=$(jq -r ".plugins[\"${plugin}\"].version" ${PKG_JSON})
  if fgrep -q "${REPO_DEST}/jenkins-plugin-${name}-${version}-${RELEASE}.noarch.rpm" ${ART_JSON} ; then
    echo "Found ${plugin}. Skipping." >&2
  else
    echo ${plugin}
  fi
}

# Find all the missing plugins and run $MAX_PARALLEL processes to build them
jq -r '.plugins|keys|"\(.[])"' ${PKG_JSON} | \
  while read p; do 
    checkpkg ${p} 
  done | \
  xargs --max-args=1 --max-procs=${MAX_PARALLEL} \
  docker run -e REPO_DEST=${REPO_DEST} -e PKG_JSON=${PKG_JSON} -e RELEASE=${RELEASE} -t -v ${PWD}:/work -w /work --rm jenkins-plugins-build ./build-1.sh
