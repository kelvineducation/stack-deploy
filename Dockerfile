FROM alpine:3.8

RUN apk add --no-cache docker bash \
  && rm /usr/bin/docker?*

RUN echo '{}' >/auth.json

COPY stack-deploy.sh /stack-deploy.sh

ENTRYPOINT ["/stack-deploy.sh"]
CMD ["deploy"]
