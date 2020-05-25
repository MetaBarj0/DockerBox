FROM alpine:3.11

RUN apk add git \
            autoconf \
            automake \
            gcc \
            musl-dev \
            libtool \
            zlib-dev \
            util-linux-dev \
            libtirpc-dev \
            openssl-dev \
            linux-virt-dev \
            make \
            musl-libintl \
            linux-headers

WORKDIR /root

COPY entrypoint.sh source.sh build.sh install.sh ./

RUN chmod +x entrypoint.sh source.sh build.sh install.sh

VOLUME [ "/root/source", "/root/build", "/root/install" ]

ENTRYPOINT [ "/root/entrypoint.sh" ]