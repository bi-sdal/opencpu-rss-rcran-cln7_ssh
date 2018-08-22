FROM sdal/rss-rcran-c7sd_auth

ENV BRANCH 2.0.8

RUN \
  yum install -y epel-release

RUN \
  useradd -ms /bin/bash builder && \
  yum update -y && \
  yum upgrade -y && \
  yum install -y rpm-build make wget tar httpd-devel R-devel libapreq2-devel liburl-devel protobuf-devel openssl-devel libxml2-devel libicu-devel libssh2-devel createrepo && \
  yum clean all

USER builder

RUN \
  mkdir -p ~/rpmbuild/SOURCES && \
  mkdir -p ~/rpmbuild/SPECS

RUN \
cd ~ && \
wget https://github.com/jeffreyhorner/rapache/archive/v1.2.9.tar.gz -O rapache-1.2.9.tar.gz && \
tar xzvf rapache-1.2.9.tar.gz rapache-1.2.9/rpm/rapache.spec --strip-components 2 && \
mv -f rapache-1.2.9.tar.gz ~/rpmbuild/SOURCES/ && \
mv -f rapache.spec ~/rpmbuild/SPECS/ && \
rpmbuild -ba ~/rpmbuild/SPECS/rapache.spec

RUN \
  cd ~ && \
  wget https://github.com/opencpu/opencpu-server/archive/v${BRANCH}.tar.gz -O opencpu-server-${BRANCH}.tar.gz  && \
  tar xzvf opencpu-server-${BRANCH}.tar.gz opencpu-server-${BRANCH}/rpm/opencpu.spec --strip-components 2 && \
  mv -f opencpu-server-${BRANCH}.tar.gz ~/rpmbuild/SOURCES/ && \
  mv -f opencpu.spec ~/rpmbuild/SPECS/ && \
rpmbuild -ba ~/rpmbuild/SPECS/opencpu.spec --define "branch ${BRANCH}"

RUN \
  createrepo ~/rpmbuild/RPMS/x86_64/

USER root

RUN \
  cp -Rf /home/builder/rpmbuild/RPMS ~/ && \
  cp -Rf /home/builder/rpmbuild/SRPMS ~/ && \
  userdel -r builder

RUN \
  yum install -y MTA mod_ssl /usr/sbin/semanage && \
  cd ~/RPMS/x86_64/ && \
  rpm -i rapache-*.rpm && \
  rpm -i opencpu-lib-*.rpm && \
  rpm -i opencpu-server-*.rpm

RUN \
  yum remove -y httpd-devel libapreq2-devel && \
  yum clean all

RUN \
  useradd -ms /bin/bash opencpu
RUN \
  echo "opencpu:opencpu" | chpasswd

COPY Rprofile.site /usr/lib64/R/etc/
COPY Rprofile /etc/opencpu/

# Need to make version agnostic.
RUN \
  mkdir /usr/share/doc/R-3.5.0/html && \
  touch /usr/share/doc/R-3.5.0/html/R.css

EXPOSE 80
EXPOSE 443
EXPOSE 8004

CMD /usr/lib/rstudio-server/bin/rserver && apachectl -DFOREGROUND
#CMD ["/lib/systemd/systemd"]
