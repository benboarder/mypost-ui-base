FROM debian:stable-slim

LABEL name="mypost-ui-base" \
      maintainer="DDC <ddc@auspost.com.au>" \
      version="1.0" \
      description="The base docker container for MyPost Consumer automated testing"

ENV TZ="/usr/share/zoneinfo/Australia/Melbourne"
ENV LANG C.UTF-8

ARG DEBIAN_FRONTEND=noninteractive
ARG USER_HOME_DIR="/tmp"
ARG USER_ID=1000

ENV HOME "$USER_HOME_DIR"

RUN apt-get update -qqy \
  && apt-get -qqy install \
       dumb-init curl git-all gnupg wget zip ca-certificates \
       python-pip apt-transport-https ttf-wqy-zenhei xvfb \
  && rm -rf /var/lib/apt/lists/* /var/cache/apt/*

RUN wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | apt-key add - \
  && echo "deb https://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google-chrome.list \
  && apt-get update -qqy \
  && apt-get -qqy install google-chrome-unstable \
  && rm /etc/apt/sources.list.d/google-chrome.list \
  && rm -rf /var/lib/apt/lists/* /var/cache/apt/*

RUN groupadd -g 10101 bamboo \
  && useradd bamboo --shell /bin/bash --create-home -u 10101 -g 10101 \
  && usermod -a -G sudo bamboo \
  && chown -R bamboo /usr/local/lib /usr/local/include /usr/local/share /usr/local/bin \
  && echo 'ALL ALL = (ALL) NOPASSWD: ALL' >> /etc/sudoers \
  && echo 'bamboo:nopassword' | chpasswd \
  && (cd "$USER_HOME_DIR"; su bamboo -c "npm i -g @angular/cli@$NG_CLI_VERSION; npm i -g yarn; npm i -g gyp node-gyp; npm cache clean --force")

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
