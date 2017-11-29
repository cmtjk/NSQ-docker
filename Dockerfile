FROM arm32v7/debian:stable-slim

EXPOSE 4150 4151 4160 4161 4170 4171

COPY build/ /usr/local/bin/

ARG BUILD_DATE
ARG VCS_REF
ARG VERSION
ARG VCS_URL
LABEL org.label-schema.schema-version="1.0" \
      org.label-schema.vendor="https://github.com/r3r57" \
      org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.version=$VERSION \
      org.label-schema.vcs-ref=$VCS_REF \
      org.label-schema.vcs-url=$VCS_URL