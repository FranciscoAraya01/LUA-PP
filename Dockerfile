FROM openresty/openresty:alpine-fat

# Instalar git y dependencias
RUN apk add --no-cache git curl

# Instalar lua-resty-http
RUN cd /tmp && \
    git clone https://github.com/ledgetech/lua-resty-http.git && \
    cp -r lua-resty-http/lib/resty/* /usr/local/openresty/lualib/resty/ && \
    rm -rf /tmp/lua-resty-http

# Verificar instalación
RUN ls -la /usr/local/openresty/lualib/resty/http.lua

WORKDIR /usr/local/openresty/nginx