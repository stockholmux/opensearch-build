FROM amazonlinux:2

# Replace shell with bash so we can source files
RUN rm /bin/sh && ln -s /bin/bash /bin/sh

# Add AdoptOpenJDK Repo
RUN echo -e "[AdoptOpenJDK]\nname=AdoptOpenJDK\nbaseurl=http://adoptopenjdk.jfrog.io/adoptopenjdk/rpm/centos/7/\$basearch\nenabled=1\ngpgcheck=1\ngpgkey=https://adoptopenjdk.jfrog.io/adoptopenjdk/api/gpg/key/public" > /etc/yum.repos.d/adoptopenjdk.repo

# Add normal dependencies
RUN yum update -y && \
    yum install -y adoptopenjdk-14-hotspot curl python git tar net-tools procps-ng

# Add Dashboards dependencies
RUN yum install -y xorg-x11-server-Xvfb gtk2-devel gtk3-devel libnotify-devel GConf2 nss libXScrnSaver alsa-lib

# Add Notebook dependencies
RUN yum install -y libnss3.so xorg-x11-fonts-100dpi xorg-x11-fonts-75dpi xorg-x11-utils xorg-x11-fonts-cyrillic xorg-x11-fonts-Type1 xorg-x11-fonts-misc fontconfig freetype && yum clean all

# Add Yarn dependencies
RUN yum groupinstall -y "Development Tools"

# Remove yum cache
RUN yum clean all && rm -rf /var/cache/yum/*

# Setup Shared Memory
RUN  chmod -R 777 /dev/shm

# Must have values for ulimits on the server
# sudo sysctl -w vm.max_map_count=262144
# ulimit -n 65535
# Docker /etc/sysconfig/docker has to have nofiles to 65535
# OPTIONS="--default-ulimit nofile=65535:65535"

# Create user group
RUN groupadd -g 1000 opensearch && \
    useradd -u 1000 -g 1000 -d /usr/share/opensearch opensearch && \
    mkdir -p /usr/share/opensearch && \
    chown -R 1000:1000 /usr/share/opensearch

# Change User
USER 1000
WORKDIR /usr/share/opensearch

# Hard code node version and yarn version for now
# nvm environment variables
ENV NVM_DIR /usr/share/opensearch/.nvm
ENV NODE_VERSION 10.23.1
# install nvm
# https://github.com/creationix/nvm#install-script
RUN curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.31.2/install.sh | bash
# install node and npm
RUN source $NVM_DIR/nvm.sh \
    && nvm install $NODE_VERSION \
    && nvm alias default $NODE_VERSION \
    && nvm use default
# add node and npm to path so the commands are available
ENV NODE_PATH $NVM_DIR/v$NODE_VERSION/lib/node_modules
ENV PATH $NVM_DIR/versions/node/v$NODE_VERSION/bin:$PATH
# install yarn
RUN npm install -g yarn@^1.22.1
# confirm installation
RUN node -v
RUN npm -v
RUN yarn -v
