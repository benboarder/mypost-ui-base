FROM debian:stable-slim

LABEL name="mypost-ui-base" \
      maintainer="DDC <ddc@auspost.com.au>" \
      version="1.0" \
      description="The base docker container for MyPost Consumer UI builds"

ENV TZ="/usr/share/zoneinfo/Australia/Melbourne"
ENV LANG C.UTF-8
ENV NPM_CONFIG_LOGLEVEL warn

ARG DEBIAN_FRONTEND=noninteractive
ARG USER_HOME_DIR="/tmp"
ARG USER_ID=1000

ENV HOME "$USER_HOME_DIR"


# ----- core utils

RUN apt-get update -qqy \
  && apt-get -qqy install \
       dumb-init curl git-all gnupg wget zip ca-certificates \
       python-pip apt-transport-https ttf-wqy-zenhei xvfb \
  && rm -rf /var/lib/apt/lists/* /var/cache/apt/*


# ----- google chrome

RUN wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | apt-key add - \
  && echo "deb https://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google-chrome.list \
  && apt-get update -qqy \
  && apt-get -qqy install google-chrome-unstable \
  && rm /etc/apt/sources.list.d/google-chrome.list \
  && rm -rf /var/lib/apt/lists/* /var/cache/apt/*


# ----- node/npm

RUN groupadd --gid 1000 node \
  && useradd --uid 1000 --gid node --shell /bin/bash --create-home node

# gpg keys listed at https://github.com/nodejs/node#release-team
RUN set -ex \
  && for key in \
    94AE36675C464D64BAFA68DD7434390BDBE9B9C5 \
    FD3A5288F042B6850C66B31F09FE44734EB7990E \
    71DCFD284A79C3B38668286BC97EC7A07EDE3FC1 \
    DD8F2338BAE7501E3DD5AC78C273792F7D83545D \
    C4F0DFFF4E8C1A8236409D08E73BC641CC11F4C8 \
    B9AE9905FFD7803F25714661B63B535A4C206CA9 \
    56730D5401028683275BD23C23EFEFE93C4CFFFE \
    77984A986EBC2AA786BC0F66B01FBB92821C587A \
  ; do \
    gpg --keyserver hkp://pgp.mit.edu:80 --recv-keys "$key" || \
    gpg --keyserver hkp://keyserver.pgp.com:80 --recv-keys "$key" || \
    gpg --keyserver hkp://ipv4.pool.sks-keyservers.net --recv-keys "$key" || \
    gpg --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys "$key" ; \
  done

ENV NODE_VERSION 8.5.0

RUN ARCH= && dpkgArch="$(dpkg --print-architecture)" \
  && case "${dpkgArch##*-}" in \
    amd64) ARCH='x64';; \
    ppc64el) ARCH='ppc64le';; \
    s390x) ARCH='s390x';; \
    arm64) ARCH='arm64';; \
    armhf) ARCH='armv7l';; \
    i386) ARCH='x86';; \
    *) echo "unsupported architecture"; exit 1 ;; \
  esac \
  && curl -SLO "https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-linux-$ARCH.tar.xz" \
  && curl -SLO --compressed "https://nodejs.org/dist/v$NODE_VERSION/SHASUMS256.txt.asc" \
  && gpg --batch --decrypt --output SHASUMS256.txt SHASUMS256.txt.asc \
  && grep " node-v$NODE_VERSION-linux-$ARCH.tar.xz\$" SHASUMS256.txt | sha256sum -c - \
  && tar -xJf "node-v$NODE_VERSION-linux-$ARCH.tar.xz" -C /usr/local --strip-components=1 --no-same-owner \
  && rm "node-v$NODE_VERSION-linux-$ARCH.tar.xz" SHASUMS256.txt.asc SHASUMS256.txt \
  && ln -s /usr/local/bin/node /usr/local/bin/nodejs


# ----- user/group permissions

RUN groupadd -g 10101 bamboo \
  && useradd bamboo --shell /bin/bash --create-home -u 10101 -g 10101 \
  && usermod -a -G sudo bamboo \
  && chown -R bamboo /usr/local/lib /usr/local/include /usr/local/share /usr/local/bin \
  && echo 'ALL ALL = (ALL) NOPASSWD: ALL' >> /etc/sudoers \
  && echo 'bamboo:nopassword' | chpasswd

RUN mkdir /data && chown -R bamboo:bamboo /data

RUN pip install awscli --upgrade

USER bamboo

ENTRYPOINT ["/usr/bin/dumb-init", "--", \
            "/usr/bin/google-chrome-unstable", \
            "--disable-gpu", \
            "--headless", \
            "--disable-dev-shm-usage", \
            "--remote-debugging-address=0.0.0.0", \
            "--remote-debugging-port=9222", \
            "--user-data-dir=/data"]
