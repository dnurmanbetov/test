#!/usr/bin/env bash

# Helper script that checks for delete changes in terraform plans.
# Expects that the following command was previously run:
# $ terraform plan -out=plan.tfplan
#
# Requirements:
#  * terraform
#  * jq
#
# Can optionally pass in a path to an allowlist file. It will be passed as an
# argument to `grep -Evf` to ignore certain resources for deletion. The
# patterns will be matched against the resource address.
# See https://en.wikipedia.org/wiki/Regular_expression#POSIX_extended
#
# WARNING: this script runs with owner credentials for all projects
# for safety, it's uploaded into terraform-cache/.trigger_scripts and downloaded into repostory_directory/.trigger_scripts on each run

set -o errexit   # exit on error
set -o nounset   # fail if var undefined
set -o noclobber # don't overwrite exists files via >
set -o pipefail  # fails if pipes (|) fails
# set -o xtrace  # debug

# obtain directory with current script
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
CURR_DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
# it runs from repository/.trigger_scripts/run.sh
ROOT_DIR="$(dirname "$CURR_DIR" )"

# Look for an allowlist of which resources are allowed to be deleted.
# Make sure it exists, is readable, and isn't empty.
allowlist="${1}"
allowlist_path=
if [[ -s "${allowlist}" && -r "${allowlist}" ]]; then
  allowlist_path="$(pwd)/${allowlist}"
  cat <<EOF
Using allowlist from ${allowlist_path}:
$(cat "${allowlist_path}")

EOF
fi

echo "load terraform"
# shellcheck source=/dev/null
source "${CURR_DIR}/../.env.terraform_version"
TERRAFORM_LOCAL_BINARY=${ROOT_DIR}/.bin/terraform-${TERRAFORM_VER}

if [ ! -d "${ROOT_DIR}/.bin" ]; then
    mkdir "${ROOT_DIR}/.bin"
fi

if [ ! -d "${ROOT_DIR}/.terraform/plugin-cache-${TERRAFORM_VER}" ]; then
    mkdir -p "${ROOT_DIR}/.terraform/plugin-cache-${TERRAFORM_VER}"
fi

if [ ! -e "${TERRAFORM_LOCAL_BINARY}" ]; then
    echo "[*] download TERRAFORM binary ..."
    "wget https://releases.hashicorp.com/terraform/${TERRAFORM_VER}/terraform_${TERRAFORM_VER}_linux_amd64.zip" --quiet -O "${ROOT_DIR}/terraform_${TERRAFORM_VER}_linux_amd64.zip"
    unzip "${ROOT_DIR}/terraform_${TERRAFORM_VER}_linux_amd64.zip" -d "${ROOT_DIR}/.bin/"
    mv "${ROOT_DIR}/.bin/terraform" "${TERRAFORM_LOCAL_BINARY}"
    chmod +x "${TERRAFORM_LOCAL_BINARY}"
    rm "${ROOT_DIR}/terraform_${TERRAFORM_VER}_linux_amd64.zip"
fi

export TF_PLUGIN_CACHE_DIR=${ROOT_DIR}/.terraform/plugin-cache-${TERRAFORM_VER}
export TF_PLUGIN_CACHE_MAY_BREAK_DEPENDENCY_LOCK_FILE=1

"${TERRAFORM_LOCAL_BINARY}" version

echo -e 'Checking for resource deletions...\n'

# Parse every plan
found_deletes="false"
for planfile in $(find "$(pwd)" -name 'plan.tfplan'); do
  plandir="$(dirname ${planfile})"
  pushd "${plandir}" &>/dev/null

  if [ ! -f "terraform" ]; then
    echo "Error : ./terraform not found in ${CURR_DIR}, ignoring"
    continue
  fi

  delchanges="$(${TERRAFORM_LOCAL_BINARY} show -json $(basename ${planfile}) | jq -rM '.resource_changes[]? | select(.change.actions | index("delete")) | .address')"

  # Filter through the allowlist, if configured.
  # Removes any matching resources, so they are no longer considered.
  if [[ -n "${allowlist_path}" ]]; then
    delchanges="$(echo "${delchanges}" | grep -Evf "${allowlist_path}")"
  fi

  if ! [[ -z "${delchanges}" ]]; then
    cat >&2 <<EOF
Warning: Found changes intending to delete the following resources in module ${plandir}:
$(printf '\t%s\n' ${delchanges[@]})

EOF
    found_deletes="true"

    # Don't fail early, show all deletions found.
  fi

  popd &>/dev/null
done

if [[ "${found_deletes}" == 'true' ]]; then
  echo >&2 'Destructive changes should be reviewed carefully by a human operator before being applied by automation.'
else
  echo >&2 'No resource deletion found.'
fi
