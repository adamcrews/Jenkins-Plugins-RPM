FROM centos:7
ADD yum_mirror.sh /
RUN /yum_mirror.sh
RUN yum install -y /usr/bin/spectool /usr/bin/rpmbuild /usr/bin/jq /usr/bin/curl /usr/bin/wget

