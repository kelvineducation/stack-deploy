#!/bin/sh

set -e

deploy_prefix="${STACK_NAME}-interim" docker stack deploy -c "${STACK_FILE}" "${STACK_NAME}"

docker secret ls --format "table {{.ID}}\t{{.Name}}" \
  | grep -E "\s+${STACK_NAME}-stable" \
  | awk '{print $1}' \
  | xargs -I {} docker secret rm {}
docker config ls --format "table {{.ID}}\t{{.Name}}" \
  | grep -E "\s+${STACK_NAME}-stable" \
  | awk '{print $1}' \
  | xargs -I {} docker config rm {}

deploy_prefix="${STACK_NAME}-stable" docker stack deploy -c "${STACK_FILE}" "${STACK_NAME}"

docker secret ls --format "table {{.ID}}\t{{.Name}}" \
  | grep -E "\s+${STACK_NAME}-interim" \
  | awk '{print $1}' \
  | xargs -I {} docker secret rm {}
docker config ls --format "table {{.ID}}\t{{.Name}}" \
  | grep -E "\s+${STACK_NAME}-interim" \
  | awk '{print $1}' \
  | xargs -I {} docker config rm {}
