FROM alpine:3.19

RUN apk update \
 && apk add --no-cache gcc libc-dev curl-dev curl lua-dev luarocks5.1 \
 && ln -s /usr/bin/luarocks-5.1 /usr/bin/luarocks \
 && luarocks install lua-curl 0.3.11

COPY entrypoint.sh /usr/bin/entrypoint.sh
COPY upload.lua /usr/bin/upload.lua

ENTRYPOINT ["/usr/bin/entrypoint.sh"]