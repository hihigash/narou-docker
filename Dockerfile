FROM ubuntu:24.10
ENV LANG=ja_JP.UTF-8
ENV AOZORA_EPUB3_FILE=AozoraEpub3-1.1.0b46.zip
ENV KINDLEGEN_FILE=kindlegen_linux_2.6_i386_v2_9.tar.gz
ENV NAROU_VERSION=3.9.1
ENV RUBY_VERSION=3.3.1
WORKDIR /opt/narou

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    openjdk-8-jre-headless \
    ruby \
    ruby-dev \
    build-essential \
    wget \
    unzip \
    git \
    libssl-dev \
    libreadline-dev \
    zlib1g-dev \
    libffi-dev \
    libyaml-dev \
    language-pack-ja && \
    rm -rf /var/lib/apt/lists/* && \
    update-locale LANG=ja_JP.UTF-8

RUN git clone https://github.com/rbenv/rbenv.git ~/.rbenv && \
    echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc && \
    echo 'eval "$(rbenv init -)"' >> ~/.bashrc

ENV PATH=/root/.rbenv/shims:/root/.rbenv/bin:$PATH

RUN git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build && \
    ~/.rbenv/bin/rbenv install ${RUBY_VERSION} && \
    ~/.rbenv/bin/rbenv global ${RUBY_VERSION} && \
    ~/.rbenv/bin/rbenv rehash && \
    ~/.rbenv/shims/gem install narou -v ${NAROU_VERSION} --no-document && \
    ~/.rbenv/shims/gem install erubi -v 1.13 --no-document && \
    ~/.rbenv/bin/rbenv rehash && \
    sed -ie "s/tilt\/erubis/tilt\/erubi/g" ~/.rbenv/versions/${RUBY_VERSION}/lib/ruby/gems/3.3.0/gems/narou-${NAROU_VERSION}/lib/web/appserver.rb

COPY ${AOZORA_EPUB3_FILE} /tmp

RUN unzip /tmp/${AOZORA_EPUB3_FILE} -d /opt/AozoraEpub3 && \
    rm /tmp/${AOZORA_EPUB3_FILE}

RUN wget https://archive.org/download/kindlegen_linux_2_6_i386_v2_9/${KINDLEGEN_FILE} && \
    mkdir -p /opt/kindlegen && \
    tar zxf ${KINDLEGEN_FILE} -C /opt/kindlegen && \
    ln -s /opt/kindlegen/kindlegen /opt/AozoraEpub3 && \
    rm ${KINDLEGEN_FILE}

RUN (echo ; cat $HOME/.rbenv/versions/3.3.1/lib/ruby/gems/3.3.0/gems/narou-${NAROU_VERSION}/preset/custom_chuki_tag.txt) >> /opt/AozoraEpub3/chuki_tag.txt
COPY init.sh /usr/local/bin

ENTRYPOINT ["init.sh"]
CMD ["narou", "web", "-p", "8000", "-n"]
