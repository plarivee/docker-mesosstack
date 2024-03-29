FROM mesos/mesos-centos
# mesos ports
EXPOSE 8080
EXPOSE 5050
EXPOSE 5151
# consul ports
EXPOSE 8500
# marathon services ports
EXPOSE 3000:3200

RUN yum install -y java-1.8.0-openjdk iptables iproute lsof wget java-1.8.0-openjdk-devel unzip

# Prepare systemd environment.
ENV container docker

RUN (cd /lib/systemd/system/sysinit.target.wants/; for i in *; do [ $i == systemd-tmpfiles-setup.service ] || rm -f $i; done); \
    rm -f /lib/systemd/system/multi-user.target.wants/*; \
    rm -f /etc/systemd/system/*.wants/*; \
    rm -f /lib/systemd/system/local-fs.target.wants/*; \
    rm -f /lib/systemd/system/sockets.target.wants/*udev*; \
    rm -f /lib/systemd/system/sockets.target.wants/*initctl*; \
    rm -f /lib/systemd/system/basic.target.wants/*; \
    rm -f /lib/systemd/system/anaconda.target.wants/*; \
    ln -vf /lib/systemd/system/multi-user.target /lib/systemd/system/default.target

RUN for service in\
    console-getty.service\
    dbus.service\
    dbus.socket\
    dev-hugepages.mount\
    getty.target\
    sys-fs-fuse-connections.mount\
    systemd-logind.service\
    systemd-remount-fs.service\
    systemd-vconsole-setup.service\
    ; do systemctl mask $service; done

# Prepare Docker environment.
ARG DOCKER_URL=https://download.docker.com/linux/static/stable/x86_64/docker-17.12.0-ce.tgz

RUN mkdir -p /etc/docker && \
    touch /etc/docker/env && \
    curl -s $DOCKER_URL -o /docker.tgz && \
    tar -xzvf /docker.tgz -C /usr/local/bin --strip 1 && \
    rm -f /docker.tgz

RUN groupadd docker

COPY docker/docker.service /usr/lib/systemd/system/docker.service
COPY docker/docker_env.sh /etc/docker/env.sh
COPY docker/docker_daemon.json /etc/docker/daemon.json

# Prepare Mesos environment.
RUN chmod +x /usr/bin/mesos-init-wrapper && \
    rm -f /etc/mesos-master/work_dir && \
    rm -f /etc/mesos-slave/work_dir && \
    mkdir -p /etc/mesos/resource_providers && \
    mkdir -p /etc/mesos/cni && \
    mkdir -p /usr/libexec/mesos/cni

COPY mesos/master_environment /etc/default/mesos-master
COPY mesos/agent_environment /etc/default/mesos-agent
COPY mesos/modules /etc/mesos/modules

# Prepare CNI environment.
ARG CNI_PLUGINS_URL=https://github.com/containernetworking/plugins/releases/download/v0.7.4/cni-plugins-amd64-v0.7.4.tgz

RUN curl -sL $CNI_PLUGINS_URL -o /cni-plugins.tgz && \
    tar xzvf /cni-plugins.tgz -C /usr/libexec/mesos/cni && \
    rm -f /cni-plugins.tgz

COPY mesos/ucr-default-bridge.json /etc/mesos/cni/

# Prepare Marathon environment.
ARG MARATHON_URL=https://downloads.mesosphere.com/marathon/releases/1.6.322/marathon-1.6.322-2bf46b341.tgz
ARG MARATHON_INSTALL_DIR=/usr/local/marathon

RUN mkdir -p $MARATHON_INSTALL_DIR && \
    curl -s $MARATHON_URL -o /marathon.tgz && \
    tar -xzvf /marathon.tgz -C $MARATHON_INSTALL_DIR --strip 1 && \
    rm -f /marathon.tgz

COPY marathon/marathon.sh $MARATHON_INSTALL_DIR/bin/
COPY marathon/marathon.service /usr/lib/systemd/system/marathon.service

# Install consul
ARG CONSUL_URL=https://releases.hashicorp.com/consul/1.6.1/consul_1.6.1_linux_amd64.zip
ARG CONSUL_INSTALL_DIR=/usr/local/consul

RUN curl -s $CONSUL_URL -o /consul.zip && \
    unzip /consul.zip -d $CONSUL_INSTALL_DIR && \
    rm -f /consul.zip

COPY consul/consul.service /etc/systemd/system/consul.service

# Install marathon-consul
ARG MARATHON_CONSUL_URL=https://github.com/allegro/marathon-consul/releases/download/1.5.1/marathon-consul_1.5.1_linux_amd64.tar.gz
ARG MARATHON_CONSUL_INSTALL_DIR=/usr/local/marathon-consul

RUN curl -L -s $MARATHON_CONSUL_URL -o /marathon-consul.tar.gz && \
    mkdir -p $MARATHON_CONSUL_INSTALL_DIR && \
    tar -xzvf /marathon-consul.tar.gz -C $MARATHON_CONSUL_INSTALL_DIR --strip 1 && \
    rm -f /marathon-consul.tar.gz

COPY marathon-consul/marathon-consul.service /etc/systemd/system/marathon-consul.service

RUN systemctl enable docker mesos-slave mesos-master marathon consul marathon-consul

# Prepare entrypoint.
COPY entrypoint.sh /

CMD ["/entrypoint.sh"]

STOPSIGNAL SIGRTMIN+3
