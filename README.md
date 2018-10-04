# stack-deploy
Docker image for deploying Stack updates with Swarm config and secret changes

Release the app in the current directory to localhost's Docker swarm using 'perch' as  the stack name and /app/docker-stack.yml as the stack configuration.
```
docker run --rm \
  -v "${PWD}:/app" \
  -v "/var/run/docker.sock:/var/run/docker.sock" \
  -v "${HOME}/.docker/config.json:/auth.json" \
  -e "STACK_NAME=perch" \
  -e "STACK_FILE=/app/docker-stack.yml" \
  kelvineducation/stack-deploy
```

stack-deploy makes a few environment variables available to your docker-stack.yml:
 - `deploy_prefix`: every secret and config name should prepended with this variable so that when the secret or config is changed, stack-deploy can swap in the updated secrets and configs.  Swarm Mode does not natively support updating secrets or configs in place, so stack-deploy supplements this functionality by temporarily releasing the secrets and configs with an interim name, deleting the secrets and configs with the original name, and then re-releasing the updated secrets and configs with the updated name.
 - `time_suffix`: every volume name should be prepended with this variable so that when a deploy is made that should trigger changes to a volume, a new volume will be created.  Docker only copies to volumes from containers when first creating a volume, so stack-deploy supplements this functionality by providing this variable to force a new volume name.  Additionally, you can set the following label on volumes to have the unused volumes periodically pruned: `education.kelvin.prune=stack-deploy`
