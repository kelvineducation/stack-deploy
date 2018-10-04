#!/bin/sh

set -e

if [ "${HOME}" == "" ]; then
  echo "\$HOME is empty. Docker registry credentials will be unavailable." >&2
elif [ "${HOME}" == "/" ]; then
  echo "\$HOME is '/'. Docker registry credentials will be unavailable." >&2
elif [ ! -f "${HOME}/.docker/config.json" ]; then
  mkdir "${HOME}/.docker"
  ln -sfn /auth.json "${HOME}/.docker/config.json"
fi

if [ -f .env ]; then
  export $(grep -v '^\s*#' .env | grep '=' | xargs -0)
fi

deploy_prefix="${STACK_NAME}-interim" docker stack deploy --with-registry-auth -c "${STACK_FILE}" "${STACK_NAME}"

docker secret ls --format "table {{.ID}}\t{{.Name}}" \
  | grep -E "\s+${STACK_NAME}-stable" \
  | awk '{print $1}' \
  | xargs -I {} docker secret rm {}
docker config ls --format "table {{.ID}}\t{{.Name}}" \
  | grep -E "\s+${STACK_NAME}-stable" \
  | awk '{print $1}' \
  | xargs -I {} docker config rm {}

deploy_prefix="${STACK_NAME}-stable" docker stack deploy --with-registry-auth -c "${STACK_FILE}" "${STACK_NAME}"

docker secret ls --format "table {{.ID}}\t{{.Name}}" \
  | grep -E "\s+${STACK_NAME}-interim" \
  | awk '{print $1}' \
  | xargs -I {} docker secret rm {}
docker config ls --format "table {{.ID}}\t{{.Name}}" \
  | grep -E "\s+${STACK_NAME}-interim" \
  | awk '{print $1}' \
  | xargs -I {} docker config rm {}
