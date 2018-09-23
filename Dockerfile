FROM alpine:3.8

RUN apk add --no-cache docker

COPY stack-deploy.sh /stack-deploy.sh

CMD ["/stack-deploy.sh"]
