#!/bin/bash

docker build -q -t kelvineducation/stack-deploy:test . || exit $?

has_failures=0

deploy() {
  local stack_file="${1}"
  local stack_name="${2}"

  STACK_FILE="${stack_file}" \
    STACK_NAME="${stack_name}" \
    docker-compose -f tests/stack-deploy.yml run --rm stack-deploy >/dev/null

  return $?
}

run_test() {
  local timestamp=$(date +%s)
  local test_name="${1}"
  local stack_name="test-${test_name}-${timestamp}"

  local expected_exit=$(sed -E '/^Exit code:/s/^.*([0-9]+)$/\1/' "tests/${test_name}.expected.txt")

  echo -n "Running '${test_name}'... "

  local setup_stack="${test_name}.setup.yml"
  local setup_exit=0
  if [ -f "${setup_stack}" ]; then
    deploy "${setup_stack}" "${stack_name}"
    setup_exit=$?

    if [ $setup_exit -ne 0 ]; then
      echo "setup failed. Setup stack deploy exited with code ${setup_exit}."
      has_failures=1
      return
    fi
  fi

  deploy "${test_name}.stack.yml" "${stack_name}"
  local actual_exit="$?"

  if [ $actual_exit -ne $expected_exit ]; then
    echo "failed. Exited with exit code ${actual_exit} (expected ${expected_exit})."
    has_failures=1
  else
    echo "succeeded"
  fi

  docker stack rm "${stack_name}" >/dev/null
}

run_test "works"
run_test "update-works"
run_test "initially-broken"
run_test "becomes-broken"


[ $has_failures -eq 0 ] \
  && echo "All tests passed successfully" \
  || echo "One or more tests failed"

exit $has_failures
