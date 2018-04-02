#!/bin/bash

PKG_JSON=${PKG_JSON:-'.cache/update-center.json'}
RELEASE=${RELEASE:-'2'}
REPO_DEST=${REPO_DEST:-'jenkins-plugins-rpm'}
BUILD_LOC="~rpm/rpmbuild"

mkdir ~/.jfrog > /dev/null 2>&1 
cp .cache/jfrog-cli.conf ~/.jfrog

su rpm -c "mkdir -p ${BUILD_LOC}/{BUILD,BUILDROOT,RPMS,SPECS,SRPMS,SOURCES}"

set -e
plugin=$1

name=$(jq -r ".plugins[\"${plugin}\"].name" ${PKG_JSON})
title=$(jq -r ".plugins[\"${plugin}\"].title" ${PKG_JSON})
version=$(jq -r ".plugins[\"${plugin}\"].version" ${PKG_JSON})
wiki=$(jq -r ".plugins[\"${plugin}\"].wiki" ${PKG_JSON})
url=$(jq -r ".plugins[\"${plugin}\"].url" ${PKG_JSON})
excerpt=$(jq -r ".plugins[\"${plugin}\"].excerpt" ${PKG_JSON})
core=$(jq -r ".plugins[\"${plugin}\"].requiredCore" ${PKG_JSON})
filename=$(basename $url| sed -e 's/.[j|h]pi$//')

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
echo "Release:        ${RELEASE}"
echo "License:        https://jenkins.io/project/governance"
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
echo "cp \$RPM_SOURCE_DIR/${filename}* \$RPM_BUILD_ROOT/var/lib/jenkins/plugins/${filename}.jpi"
echo "touch \$RPM_BUILD_ROOT/var/lib/jenkins/plugins/${filename}.hpi"
echo "touch \$RPM_BUILD_ROOT/var/lib/jenkins/plugins/${filename}.jpi.pinned"
echo "%files"
echo "%ghost /var/lib/jenkins/plugins/${filename}.hpi"
echo "%attr(644,jenkins,jenkins) /var/lib/jenkins/plugins/${filename}.jpi"
echo "%attr(444,jenkins,jenkins) /var/lib/jenkins/plugins/${filename}.jpi.pinned"

) > ${BUILD_LOC}/SPECS/jenkins-plugin-${plugin}.spec

spectool -C ~rpm/rpmbuild/SOURCES -g ${BUILD_LOC}/SPECS/jenkins-plugin-${plugin}.spec > /dev/null

su rpm -c "rpmbuild -bb ${BUILD_LOC}/SPECS/jenkins-plugin-${plugin}.spec"

jfrog rt upload ${BUILD_LOC}/RPMS/*/jenkins-plugin*rpm ${REPO_DEST}

