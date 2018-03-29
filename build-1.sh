#!/bin/bash
set -x
set -v
PKG_JSON=${PKG_JSON:-'.cache/update-center.json'}
RELEASE=${RELEASE:-'2'}

mkdir ~/.jfrog
cp .cache/jfrog-cli.conf ~/.jfrog

set -e
plugin=$1
tmp=$(mktemp -d)

name=$(jq -r ".plugins[\"${plugin}\"].name" ${PKG_JSON})
title=$(jq -r ".plugins[\"${plugin}\"].title" ${PKG_JSON})
version=$(jq -r ".plugins[\"${plugin}\"].version" ${PKG_JSON})
wiki=$(jq -r ".plugins[\"${plugin}\"].wiki" ${PKG_JSON})
url=$(jq -r ".plugins[\"${plugin}\"].url" ${PKG_JSON})
excerpt=$(jq -r ".plugins[\"${plugin}\"].excerpt" ${PKG_JSON})
core=$(jq -r ".plugins[\"${plugin}\"].requiredCore" ${PKG_JSON})
filename=$(basename $url| sed -e 's/.[j|h]pi$//')

exit 0

PKG_LIST=$(jfrog rt s "jenkins-plugins-rpm/jenkins-plugin-$name-${RELEASE}\*rpm" | jq -r '. | length')
if [ "$PKG_LIST" == '0' ]; then
  echo Skip jenkins-plugin-$name-${RELEASE}
  exit 0
fi

(
cat << END
%define __os_install_post %{nil}
%define debug_package %{nil}
END
echo "Name:           jenkins-plugin-${name}"
echo "Summary:        Jenkins Plugin ${title}"
echo "BuildArch: noarch"
echo "AutoReqProv: no"
echo "Version:        ${version//-/_}"
echo "Release:        ${RELEASE}%{?dist}"
echo "Vendor:         %{?_host_vendor}"
echo "License:        https://wiki.jenkins-ci.org/display/JENKINS/Governance+Document#GovernanceDocument-License"
echo "Group:          Jenkins"
echo "URL:            ${wiki}"
echo "Source0:        ${url}"
echo "Provides:       jenkins-plugin(${name}) = ${version}"
echo "Requires:       jenkins >= ${core}"

jq -r ".plugins[\"${plugin}\"].dependencies|\"\(.[])\"" ${PKG_JSON} | \
  while read l; do
    echo $l | \
    jq -r "\"Requires:       jenkins-plugin(\"+.name+\") >= \"+.version";
  done

echo "%description"
echo "${excerpt}"
echo "%build"
echo "mkdir -p \$RPM_BUILD_ROOT/var/lib/jenkins/plugins"
echo "cp \$RPM_SOURCE_DIR/${filename}\* \$RPM_BUILD_ROOT/var/lib/jenkins/plugins/${filename}.jpi"
echo "touch \$RPM_BUILD_ROOT/var/lib/jenkins/plugins/${filename}.hpi"
echo "touch \$RPM_BUILD_ROOT/var/lib/jenkins/plugins/${filename}.jpi.pinned"
echo "%files"
echo "%ghost /var/lib/jenkins/plugins/${filename}.hpi"
echo "%attr(644,jenkins,jenkins) /var/lib/jenkins/plugins/${filename}.jpi"
echo "%attr(444,jenkins,jenkins) /var/lib/jenkins/plugins/${filename}.jpi.pinned"

) > jenkins-plugin-${plugin}.spec


su rpm -c "mkdir -p /tmp/d"
su rpm -c "spectool -C /tmp/d -g $PWD/jenkins-plugin-${plugin}.spec" > /dev/null
#su rpm -c "rm -f /home/rpm/rpmbuild/RPMS/*/* || true"
su rpm -c "rpmbuild -bb --define '_sourcedir /tmp/d' jenkins-plugin-${plugin}.spec"

su rpm -c "cp /home/rpm/rpmbuild/RPMS/*/* /work/build"
#su rpm -c "rm /home/rpm/rpmbuild/RPMS/*/*"
