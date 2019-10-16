#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
NOCOLOR='\033[0m'
RED='\033[0;31m'
GREEN='\033[0;32m'
ORANGE='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
LIGHTGRAY='\033[0;37m'
DARKGRAY='\033[1;30m'
LIGHTRED='\033[1;31m'
LIGHTGREEN='\033[1;32m'
YELLOW='\033[1;33m'
LIGHTBLUE='\033[1;34m'
LIGHTPURPLE='\033[1;35m'
LIGHTCYAN='\033[1;36m'
WHITE='\033[1;37m'

VENOM="${VENOM:-`which venom`}"
VENOM_OPTS="${VENOM_OPTS:---log debug --output-dir ./results --strict --stop-on-failure}"

CDS_API_URL="${CDS_API_URL:-http://localhost:8081}"
CDS_UI_URL="${CDS_UI_URL:-http://localhost:4200}"
CDS_HATCHERY_URL="${CDS_HATCHERY_URL:-http://localhost:8086}"
CDS_HOOKS_URL="${CDS_HOOKS_URL:-http://localhost:8083}"
CDSCTL="${CDSCTL:-`which cdsctl`}"
CDSCTL_CONFIG="${CDSCTL_CONFIG:-.cdsrc}"
SMTP_MOCK_URL="${SMTP_MOCK_URL:-http://localhost:2024}"
AWS_DEFAULT_REGION="${AWS_DEFAULT_REGION:-us-east-1}"
S3_BUCKET="${S3_BUCKET:-cds-it}"
AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID:-$MINIO_ACCESS_KEY}"
AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY:-$MINIO_SECRET_KEY}"
AWS_ENDPOINT_URL=""
AWS_ENDPOINT_DISABLE_SSL=""
AWS_ENDPOINT_FORCE_PATH_STYLE=""

echo -e "Using venom using following variables:"
echo -e "  VENOM=${CYAN}${VENOM}${NOCOLOR}"
echo -e "  VENOM_OPTS=${CYAN}${VENOM_OPTS}${NOCOLOR}"
echo ""

echo -e "Running tests using following variables:"
echo -e "  CDS_API_URL=${CYAN}${CDS_API_URL}${NOCOLOR}"
echo -e "  CDS_UI_URL=${CYAN}${CDS_UI_URL}${NOCOLOR}"
echo -e "  CDS_HATCHERY_URL=${CYAN}${CDS_HATCHERY_URL}${NOCOLOR}"
echo -e "  CDSCTL=${CYAN}${CDSCTL}${NOCOLOR}"
echo -e "  CDSCTL_CONFIG=${CYAN}${CDSCTL_CONFIG}${NOCOLOR}"
echo ""

check_failure() {
    exit_status=$1
    if [ $exit_status -ne 0 ]; then
        echo -e "  ${LIGHTRED}FAILURE${RED}\n"
        cat $2
        echo -e ${NOCOLOR}
        exit $exit_status
    fi
}

smoke_tests() {
    echo "Running smoke tests:"
    for f in $(ls -1 00_*.yml); do
        CMD="${VENOM} run ${VENOM_OPTS} ${f} --var cdsctl=${CDSCTL} --var api.url=${CDS_API_URL} --var ui.url=${CDS_UI_URL}  --var smtpmock.url=${SMTP_MOCK_URL} --var hatchery.url=${CDS_HATCHERY_URL} --var hooks.url=${CDS_HOOKS_URL}"
        echo -e "  ${YELLOW}${f} ${DARKGRAY}[${CMD}]${NOCOLOR}"
        ${CMD} >${f}.output 2>&1
        check_failure $? ${f}.output
    done
}

initialization_tests() {
    echo "Running initialization tests:"
    CMD="${VENOM} run ${VENOM_OPTS} 01_signup.yml --var cdsctl=${CDSCTL} --var cdsctl.config=${CDSCTL_CONFIG}_admin --var api.url=${CDS_API_URL} --var username=cds.integration.tests.rw --var email=it-user-rw@localhost.local --var fullname='IT User RW' --var smtpmock.url=${SMTP_MOCK_URL}"
    echo -e "  ${YELLOW}01_signup.yml (admin) ${DARKGRAY}[${CMD}]${NOCOLOR}"
    ${CMD} >01_signup_admin.yml.output 2>&1
    check_failure $? 01_signup_admin.yml.output

    CMD="${VENOM} run ${VENOM_OPTS} 01_signup.yml --var cdsctl=${CDSCTL} --var cdsctl.config=${CDSCTL_CONFIG}_user --var api.url=${CDS_API_URL} --var username=cds.integration.tests.ro --var email=it-user-ro@localhost.local --var fullname='IT User RO' --var smtpmock.url=${SMTP_MOCK_URL}"
    echo -e "  ${YELLOW}01_signup.yml (user) ${DARKGRAY}[${CMD}]${NOCOLOR}"
    ${CMD} >01_signup_user.yml.output 2>&1

    check_failure $? 01_signup_user.yml.output
}

cli_tests() {
    echo "Running CLI tests:"
    for f in $(ls -1 02_cli*.yml); do
        CMD="${VENOM} run ${VENOM_OPTS} ${f} --var cdsctl=${CDSCTL} --var cdsctl.config=${CDSCTL_CONFIG}_admin --var api.url=${CDS_API_URL} --var ui.url=${CDS_UI_URL}  --var smtpmock.url=${SMTP_MOCK_URL}"
        echo -e "  ${YELLOW}${f} ${DARKGRAY}[${CMD}]${NOCOLOR}"
        ${CMD} >${f}.output 2>&1
        check_failure $? ${f}.output
    done
}

workflow_tests() {
    echo "Running Workflow tests:"
    for f in $(ls -1 03_*.yml); do
        CMD="${VENOM} run ${VENOM_OPTS} ${f} --var cdsctl=${CDSCTL} --var cdsctl.config=${CDSCTL_CONFIG}_admin --var api.url=${CDS_API_URL} --var ui.url=${CDS_UI_URL}  --var smtpmock.url=${SMTP_MOCK_URL}"
        echo -e "  ${YELLOW}${f} ${DARKGRAY}[${CMD}]${NOCOLOR}"
        ${CMD} >${f}.output 2>&1
        check_failure $? ${f}.output
    done
}

workflow_with_integration_tests() {
    echo "Running Workflow with Storage integration tests:"
    for f in $(ls -1 04_*.yml); do
        CMD="${VENOM} run ${VENOM_OPTS} ${f} --var cdsctl=${CDSCTL} --var cdsctl.config=${CDSCTL_CONFIG}_admin --var api.url=${CDS_API_URL} --var ui.url=${CDS_UI_URL}  --var smtpmock.url=${SMTP_MOCK_URL}"
        echo -e "  ${YELLOW}${f} ${DARKGRAY}[${CMD}]${NOCOLOR}"
        ${CMD} >${f}.output 2>&1
        check_failure $? ${f}.output
    done
}

rm -rf ./results
mkdir results

smoke_tests
initialization_tests
cli_tests
workflow_tests
workflow_with_integration_tests

