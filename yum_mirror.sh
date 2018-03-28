#!/bin/bash 
#
# Let's replace our yum repos with a mirror
#

ARTIFACTORY_URL=${ARTIFACTORY_URL:-'http://xwtcvpartifactrepo.corp.dom:8081/artifactory'}
CENTOS_MIRROR="${ARTIFACTORY_URL}/centos"
EPEL_MIRROR="${ARTIFACTORY_URL}/epel"

cat > /etc/yum.repos.d/CentOS-Base.repo <<EOC
[base]
name=CentOS-\$releasever - Base
baseurl=${CENTOS_MIRROR}/\$releasever/os/\$basearch/
gpgcheck=1
gpgkey=${CENTOS_MIRROR}/RPM-GPG-KEY-CentOS-7

#released updates
[updates]
name=CentOS-\$releasever - Updates
baseurl=${CENTOS_MIRROR}/\$releasever/updates/\$basearch/
gpgcheck=1
gpgkey=${CENTOS_MIRROR}/RPM-GPG-KEY-CentOS-7

#additional packages that may be useful
[extras]
name=CentOS-\$releasever - Extras
baseurl=${CENTOS_MIRROR}/\$releasever/extras/\$basearch/
gpgcheck=1
gpgkey=${CENTOS_MIRROR}/RPM-GPG-KEY-CentOS-7

#additional packages that extend functionality of existing packages
[centosplus]
name=CentOS-\$releasever - Plus
baseurl=${CENTOS_MIRROR}/\$releasever/centosplus/\$basearch/
gpgcheck=1
enabled=0
gpgkey=${CENTOS_MIRROR}/RPM-GPG-KEY-CentOS-7
EOC

cat > /etc/yum.repos.d/epel.repo <<EOC
[epel]
name=Extra Packages for Enterprise Linux 7 - \$basearch
baseurl=${EPEL_MIRROR}/7/\$basearch
failovermethod=priority
enabled=1
gpgcheck=1
gpgkey=${EPEL_MIRROR}/RPM-GPG-KEY-EPEL-7

[epel-debuginfo]
name=Extra Packages for Enterprise Linux 7 - \$basearch - Debug
baseurl=${EPEL_MIRROR}/7/\$basearch/debug
failovermethod=priority
enabled=0
gpgcheck=1
gpgkey=${EPEL_MIRROR}/RPM-GPG-KEY-EPEL-7

[epel-source]
name=Extra Packages for Enterprise Linux 7 - \$basearch - Source
baseurl=${EPEL_MIRROR}/7/SRPMS
failovermethod=priority
enabled=0
gpgcheck=1
gpgkey=${EPEL_MIRROR}/RPM-GPG-KEY-EPEL-7
EOC
