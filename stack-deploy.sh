#!/bin/bash

set -e
set -u

if [ "${1:-deploy}" != "deploy" ]; then
  exec "${@}"
fi

detach=0
debug=0
for opt in "${@}"; do
  case "${opt}" in
    --detach)
      detach=1
      ;;

    --debug)
      debug=1
      ;;
  esac
done

[ $debug -eq 1 ] && set -x

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

export time_prefix="${STACK_NAME}-$(date +%s)"

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

docker volume prune --force --filter 'label=education.kelvin.prune=stack-deploy'

[ $detach -eq 1 ] && exit

echo -n "Waiting for deploy to complete... "

service_count=$(docker stack services -q "${STACK_NAME}" | wc -l)
service_ids=($(docker stack services -q "${STACK_NAME}"))

failed_count=0
completed_count=0
while [ $completed_count -lt $service_count ]; do
  failed_count=0
  completed_count=0

  statuses=($(docker service inspect --format '{{if .UpdateStatus}}{{.UpdateStatus.State}}{{end}}' "${service_ids[@]}"))
  for status in "${statuses[@]}"; do
    case "${status}" in
      *paused | rollback_completed)
        failed_count=$((failed_count + 1))
        completed_count=$((completed_count + 1))
        ;;

      completed)
        completed_count=$((completed_count + 1))
        ;;
    esac
  done

  usleep 500000
done

if [ $failed_count -ne 0 ]; then
  echo "failed"
  echo "One or more services failed to deploy"
  exit 1
fi

echo "completed"

# possible swarm service status keys:
# https://github.com/moby/moby/blob/8e610b2b55bfd1bfa9436ab110d311f5e8a74dcb/api/types/swarm/service.go#L43
# - updating
# - paused
# - completed
# - rollback_started
# - rollback_paused
# - rollback_completed
