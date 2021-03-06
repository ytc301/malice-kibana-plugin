FROM gliderlabs/alpine:3.4

MAINTAINER blacktop, https://github.com/blacktop

ARG VERSION=5.1.2

ENV LANG=C.UTF-8
ENV JAVA_HOME=/usr/lib/jvm/default-jvm/jre
ENV PATH=${PATH}:${JAVA_HOME}/bin

RUN apk-install openjdk8-jre nodejs git bash

RUN adduser -S kibana -h /home/kibana -s /bin/bash -G root -u 1000 -D \
  && touch /home/kibana/.bashrc \
  && chown kibana /home/kibana/.bashrc

RUN apk-install -t .build-deps wget ca-certificates tar \
  && wget -q https://raw.githubusercontent.com/creationix/nvm/v0.32.1/install.sh -O /tmp/install.sh \
  && chown kibana /tmp/install.sh && chmod +x /tmp/install.sh \
  && su kibana bash -c "/tmp/install.sh" \
  && echo "Installing Kibana $VERSION ======================" \
  && git clone -b v${VERSION} https://github.com/elastic/kibana.git /usr/share/kibana \
  && cd /usr/share/kibana \
  && chown -R kibana /usr/share/kibana \
  && su kibana bash -c 'source /home/kibana/.bashrc \
    && nvm install "$(cat .node-version)" \
    && echo "nvm use --delete-prefix $(cat .node-version)" >> /home/kibana/.bashrc' \
  && npm install elasticdump -g \
  && rm -rf /tmp/* \
  && apk del --purge .build-deps

USER kibana

COPY config/kibana.dev.yml /usr/share/kibana/config/kibana.dev.yml

VOLUME /usr/share/plugin

WORKDIR /usr/share/kibana

# Install kibana node_modules
RUN bash -c 'source /home/kibana/.bashrc \
    && npm config set registry https://registry.npmjs.org/ \
    && npm install --unsafe-perm' \
  && rm -rf /tmp/*

ENV PATH /usr/share/kibana/bin:$PATH

EXPOSE 5601

CMD ["npm","run","elasticsearch"]
