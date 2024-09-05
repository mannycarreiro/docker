FROM alpine:latest
LABEL MAINTAINER="Manny Carreiro"
RUN apk update && \
apk install jq curl && \
mkdir -p /opt/secret_fetch/envfiles_output && \
mkdir -p /opt/secret_fetch/env_files && \
adduser -D vault && \
chown vault:vault -R /opt/secret_fetch
CMD [ "/bin/sh" ]
ENTRYPOINT [ "/opt/secret_fetch/secret_fetch.sh" ]
