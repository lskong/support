FROM alpine

EXPOSE 8443 19200

RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.tuna.tsinghua.edu.cn/g' /etc/apk/repositories

VOLUME ["/var/stdiscosrv"]

RUN apk add --no-cache ca-certificates su-exec

COPY ./stdiscosrv /bin/stdiscosrv
COPY ./entrypoint.sh /bin/entrypoint.sh
COPY ./start.sh /var/stdiscosrv/start.sh

ENV PUID=1000 PGID=1000 HOME=/var/strelaysrv

HEALTHCHECK --interval=1m --timeout=10s \
  CMD nc -z localhost 8443 || exit 1

WORKDIR /var/stdiscosrv
ENTRYPOINT ["/bin/entrypoint.sh", "/var/stdiscosrv/start.sh"]
