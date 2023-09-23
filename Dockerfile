FROM ubuntu:latest

RUN ["apt-get", "update"]
ARG DEBIAN_FRONTEND=noninteractive
RUN ["apt-get", "install", "-y", "gcc", "make", "autoconf", "automake", "libtool", "libpng-dev", "git", "imagemagick"]
RUN ["git", "clone", "https://chromium.googlesource.com/webm/libwebp"]

WORKDIR /libwebp 
RUN ["./autogen.sh"]
RUN ["./configure"]
RUN ["make"]
RUN ["make", "install"]
WORKDIR /

RUN ["ldconfig"]

RUN ["mkdir", "/work"]
ENV WORK_PATH=/work

COPY convert.sh convert.sh

ENTRYPOINT ["/convert.sh"]
