FROM alpine:3.11.5

EXPOSE 5060/udp 5060/tcp 5160/udp 10000-20000/udp

RUN apk add --update --no-cache \
      asterisk \
      asterisk-sample-config && \
      rm -rf /usr/lib/asterisk/modules/*pjsip* && \
      asterisk -U asterisk && \
      sleep 5 && \
      pkill -9 asterisk && \
      pkill -9 astcanary && \
      sleep 2 && \
      rm -rf /var/run/asterisk/* && \
      mkdir -p /var/spool/asterisk/fax && \
      chown -R asterisk: /var/spool/asterisk/fax && \
      truncate -s 0 /var/log/asterisk/messages \
                 /var/log/asterisk/queue_log && \
      rm -rf /var/cache/apk/* \
           /tmp/* \
           /var/tmp/*

RUN apk add --no-cache asterisk-srtp asterisk-cdr-mysql

