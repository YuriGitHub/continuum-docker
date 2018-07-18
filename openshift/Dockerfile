# FROM ubuntu:16.04
FROM registry.access.redhat.com/rhel7

### Required Atomic/OpenShift Labels - https://github.com/projectatomic/ContainerApplicationGenericLabels
LABEL name="Continuum" \
      maintainer="dfreeman@collab.net" \
      vendor="CollabNet VersionOne" \
      version="18.2" \
      release="18.2" \
      summary="Continuum summary TODO" \
      description="Continuum description TODO"

### add licenses to this directory
COPY licenses /licenses

### Add necessary Red Hat repos here
RUN REPOLIST=rhel-7-server-rpms,rhel-7-server-optional-rpms \
### Add your package needs here
    INSTALL_PKGS="sudo" && \
    yum -y update-minimal --disablerepo "*" --enablerepo rhel-7-server-rpms --setopt=tsflags=nodocs \
      --security --sec-severity=Important --sec-severity=Critical && \
    yum -y install --disablerepo "*" --enablerepo ${REPOLIST} --setopt=tsflags=nodocs ${INSTALL_PKGS} && \
    yum clean all

# RUN apt-get update && apt-get install -y \
#     build-essential \
#     cron \
#     curl \
#     libffi-dev \
#     libkrb5-dev \
#     libldap2-dev \
#     libsasl2-dev \
#     libssl-dev \
#     python \
#     sudo

ARG INSTALLER=""
ENV MY_CTM_INSTALLER=$INSTALLER

RUN set -xe && \
    cd /tmp && \
    # Download installer
    curl -o install.sh $INSTALLER && \
    chmod +x install.sh && \
    # Installation wasn't successful until source line was removed
    sed -i '/source ${WHICHPROFILE}/d' install.sh && \
    # -s silent, -m skip data initialization, -p skip starting services
    ./install.sh -m -p -s

ENV APP=/opt/continuum/current
WORKDIR $APP

ADD run.sh /run.sh
RUN chmod +x /*.sh

# RUN groupadd --gid 999 ctmgroup && \
#     useradd --uid 999 --gid ctmgroup --create-home --groups 0 ctmuser

RUN groupadd ctmgroup && \
    useradd --create-home --groups root,ctmgroup ctmuser

RUN chgrp -R root /etc/continuum && \
    chmod -R g+w /etc/continuum

RUN chgrp -R root /var/continuum && \
    chmod -R g+w /var/continuum

# RUN chgrp -R 0 /opt/continuum && \
#     chmod -R g+w /opt/continuum

RUN chgrp -R root /opt/continuum && \
    chmod -R 777 /opt/continuum

RUN chmod g+w /etc/passwd

# RUN chown -R ctmuser:root /home/ctmuser
RUN chmod 777 /home/ctmuser

# RUN cp /root/.profile /home/ctmuser/.profile

RUN echo "export CONTINUUM_HOME=/opt/continuum/current" >> /home/ctmuser/.profile
RUN echo "export PATH=\$PATH:\$CONTINUUM_HOME/common/bin:/opt/continuum/python/bin" >> /home/ctmuser/.profile

ADD ./entrypoint.sh $APP
RUN chmod +x $APP/entrypoint.sh

# ui and messagehub
EXPOSE 8080 8083

# HEALTHCHECK --start-period=3s --interval=10s --timeout=1s --retries=3 \
#     CMD curl --fail http://localhost:8080/ || exit 1

USER ctmgroup:ctmuser
ENV HOME /home/ctmuser

ENTRYPOINT ["/opt/continuum/current/entrypoint.sh"]
CMD ["/run.sh"]
