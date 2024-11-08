FROM python:3.12-alpine3.20
LABEL MAINTAINER="Manny Carreiro"
RUN apk update && \
     apk add jq curl && pip install PYYaml --root-user-action=ignore && \
     mkdir -p /opt/secret_fetch/env_files_dir && \
     adduser -D vault && \
     chown vault:vault -R /opt/secret_fetch
COPY scripts/secret_fetch.sh /opt/secret_fetch/ 
WORKDIR /opt/secret_fetch
CMD ["/bin/sh", "-C", "./secret_fetch.sh"]
