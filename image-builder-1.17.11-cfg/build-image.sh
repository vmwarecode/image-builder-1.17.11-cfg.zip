#!/bin/bash

set -o errexit
set -o pipefail
set -o xtrace

git checkout master
git checkout 11242d88d8772fd743fe235b54e755e2f80860e9

az cloud set --name AzureCloud
az login --service-principal --username $AZURE_CLIENT_ID --password $AZURE_CLIENT_SECRET --tenant $AZURE_TENANT_ID
az account set --subscription $AZURE_SUBSCRIPTION_ID

export TKG_GOSS_DIR="${PWD}/goss"
rm -rf ${TKG_GOSS_DIR}
mkdir -p ${TKG_GOSS_DIR}
cp -r -f ${PWD}/packer/goss/* ${TKG_GOSS_DIR}

# Add TKG serverspecs to GOSS files
# shellcheck source=./apply_goss.sh
source "./apply-goss.sh"
apply_goss "${TKG_GOSS_DIR}"

rm -f ./goss-args.json
cp "${TKG_GOSS_DIR}/goss-args.json" ./

PACKER_VAR_FILES="goss-args.json kubernetes.json osstp.json" PACKER_FLAGS="" make build-azure-sig-ubuntu-1804

rm -f ./goss-spec.yaml
cp -f /tmp/goss-spec.yaml .
