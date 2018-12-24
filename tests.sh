#!/bin/bash

docker build -q -t kelvineducation/stack-deploy:test . || exit $?

has_failures=0

run_test() {
  local timestamp=$(date +%s)
  local test_name="${1}"
  local stack_name="test-${test_name}-${timestamp}"

  local expected_exit=$(sed -E '/^Exit code: ([0-9]+)/c \1' "tests/${test_name}.expected.txt")

  echo -n "Running ${test_name}... "

  STACK_FILE="${test_name}.stack.yml" \
    STACK_NAME="${stack_name}" \
    docker-compose -f tests/stack-deploy.yml run --rm stack-deploy >/dev/null

  local actual_exit="$?"

  if [ $actual_exit -ne $expected_exit ]; then
    echo "failed. Exited with exit code ${actual_exit} (expected ${expected_exit})."
    has_failures=1
  else
    echo "succeeded"
  fi

  docker stack rm "${stack_name}" >/dev/null
}

run_test "initially-broken"

[ $has_failures -eq 0 ] \
  && echo "All tests passed successfully" \
  || echo "One or more tests failed"

exit $has_failures
