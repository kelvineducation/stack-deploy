# stack-deploy
Docker image for deploying Stack updates with Swarm config and secret changes

Release the app in the current directory to localhost's Docker swarm using 'perch' as  the stack name and /app/docker-stack.yml as the stack configuration.
```
docker run --rm \
  -v "${PWD}:/app" \
  -v "/var/run/docker.sock:/var/run/docker.sock" \
  -e "STACK_NAME=perch"
  -e "STACK_FILE=/app/docker-stack.yml"
  kelvineducation/stack-deploy
```
