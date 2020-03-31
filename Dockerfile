FROM debian:10.3

ARG ASTERISK_VERSION=17.2.0
ARG BCG729_VERSION=1.0.4
ARG SPANDSP_VERSION=20180108

ENV ASTERISK_BUILD_DEPS='autoconf automake bison build-essential doxygen flex libasound2-dev \
            libcurl4-openssl-dev libedit-dev libical-dev libiksemel-dev \
            libjansson-dev libncurses5-dev libneon27-dev \
            libnewt-dev libogg-dev libresample1-dev libspandsp-dev libsqlite3-dev \
            libsrtp2-dev libssl-dev libtiff-dev libtool-bin libvorbis-dev \
            libxml2-dev linux-headers-amd64 python-dev subversion unixodbc-dev \
            uuid-dev'

#build tools
RUN apt-get update && \
    apt-get install --no-install-recommends -y curl gnupg ca-certificates $ASTERISK_BUILD_DEPS && \
    addgroup --gid 2600 asterisk && \
    adduser --uid 2600 --gid 2600 --gecos "Asterisk User" --disabled-password asterisk && \

#SpanDSP
    mkdir -p /usr/src/spandsp && \
    curl -kL http://sources.buildroot.net/spandsp/spandsp-${SPANDSP_VERSION}.tar.gz | tar xvfz - --strip 1 -C /usr/src/spandsp && \
    cd /usr/src/spandsp && \
    ./configure && \
    make && \
    make install && \

#compile Asterisk
    cd /usr/src && \
    mkdir -p asterisk && \
    curl -sSL http://downloads.asterisk.org/pub/telephony/asterisk/releases/asterisk-${ASTERISK_VERSION}.tar.gz | tar xvfz - --strip 1 -C /usr/src/asterisk && \
    cd /usr/src/asterisk/ && \
    make distclean && \
    contrib/scripts/get_mp3_source.sh && \
    ./configure --with-resample --with-pjproject-bundled --with-jansson-bundled --with-ssl=ssl --with-srtp && \
    make menuselect/menuselect menuselect-tree menuselect.makeopts && \
    menuselect/menuselect --disable BUILD_NATIVE \
                          --enable app_confbridge \
                          --enable app_fax \
                          --enable app_macro \
                          --enable codec_opus \
                          --enable codec_silk \
                          --enable format_mp3 \
                          --enable BETTER_BACKTRACES \
                          --disable MOH-OPSOUND-WAV \
                          --enable MOH-OPSOUND-GSM \
    make && \
    make install && \
    make install-headers && \
    make config && \
    ldconfig && \

#G729 Codec
    apt-get install -y git && \
    git clone https://github.com/BelledonneCommunications/bcg729 /usr/src/bcg729 && \
    cd /usr/src/bcg729 && \
    git checkout tags/$BCG729_VERSION && \
    ./autogen.sh && \
    ./configure --libdir=/lib && \
    make && \
    make install && \
    \
    mkdir -p /usr/src/asterisk-g72x && \
    curl https://bitbucket.org/arkadi/asterisk-g72x/get/master.tar.gz | tar xvfz - --strip 1 -C /usr/src/asterisk-g72x && \
    cd /usr/src/asterisk-g72x && \
    ./autogen.sh && \
    ./configure --with-bcg729 --enable-penryn && \
    make && \
    make install && \

# Cleanup 
    mkdir -p /var/run/fail2ban && \
    cd / && \
    rm -rf /usr/src/* /tmp/* /etc/cron* && \
    apt-get purge -y $ASTERISK_BUILD_DEPS libspandsp-dev && \
    apt-get -y autoremove && \
    apt-get clean && \
    apt-get install -y make && \
    rm -rf /var/lib/apt/lists/*


