FROM alpine:3.8

RUN apk add --no-cache docker \
  && rm /usr/bin/docker?*

RUN echo '{}' >/auth.json

COPY stack-deploy.sh /stack-deploy.sh

CMD ["/stack-deploy.sh"]
