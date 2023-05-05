#!/bin/bash
#
# executes terraform from cloudbuld trigger with gitgub credentials
# for safety, it's uploaded into terraform-cache/.trigger_scripts and downloaded into repostory_directory/.trigger_scripts on each run

set -o errexit   # exit on error
set -o nounset   # fail if var undefined
set -o noclobber # don't overwrite exists files via >
set -o pipefail  # fails if pipes (|) fails
# set -o xtrace  # debug

ACTIONS=()
DIRS=""
ROOT="."
GOOGLE_IMPERSONATE_SERVICE_ACCOUNT=""

while getopts "a:d:r:s:" c
do
  case $c in
    a) ACTIONS+=("${OPTARG}") ;;
    d) DIRS="${OPTARG}" ;;
    r) ROOT="${OPTARG}" ;;
    s) GOOGLE_IMPERSONATE_SERVICE_ACCOUNT="${OPTARG}" ;;
    *)
      echo "Invalid flag ${OPTARG}"
      exit 1
      ;;
  esac
done

# running actions inside folders
ROOT=$(realpath "${ROOT}")
ROOT_DIR="$(dirname "$ROOT" )"

# login as sa
export GOOGLE_IMPERSONATE_SERVICE_ACCOUNT
export GITHUB_OWNER="inventcorp"


# Read DIRS from a space-separated string to list
IFS=' ' read -r -a DIRS <<< "${DIRS}"

echo "load terraform"
# shellcheck source=/dev/null
source "${ROOT}/../.env.terraform_version"
TERRAFORM_LOCAL_BINARY=${ROOT_DIR}/.bin/terraform-${TERRAFORM_VER}

if [ ! -d "${ROOT_DIR}/.bin" ]; then
    mkdir "${ROOT_DIR}/.bin"
fi

if [ ! -d "${ROOT_DIR}/.terraform/plugin-cache-${TERRAFORM_VER}" ]; then
    mkdir -p "${ROOT_DIR}/.terraform/plugin-cache-${TERRAFORM_VER}"
fi

if [ ! -e "${TERRAFORM_LOCAL_BINARY}" ]; then
    echo "[*] download TERRAFORM binary ..."
    wget "https://releases.hashicorp.com/terraform/${TERRAFORM_VER}/terraform_${TERRAFORM_VER}_linux_amd64.zip" --quiet -O "${ROOT_DIR}/terraform_${TERRAFORM_VER}_linux_amd64.zip"
    unzip "${ROOT_DIR}/terraform_${TERRAFORM_VER}_linux_amd64.zip" -d "${ROOT_DIR}/.bin/"
    mv "${ROOT_DIR}/.bin/terraform" "${TERRAFORM_LOCAL_BINARY}"
    chmod +x "${TERRAFORM_LOCAL_BINARY}"
    rm "${ROOT_DIR}/terraform_${TERRAFORM_VER}_linux_amd64.zip"
fi

export TF_PLUGIN_CACHE_DIR=${ROOT_DIR}/.terraform/plugin-cache-${TERRAFORM_VER}
export TF_PLUGIN_CACHE_MAY_BREAK_DEPENDENCY_LOCK_FILE=1
export TF_IN_AUTOMATION=1

"${TERRAFORM_LOCAL_BINARY}" version

echo ""
for mod in "${DIRS[@]}"
do
    echo "-----------------------------"
    echo "Processing ${ROOT}/${mod}"
    echo "-----------------------------"
    echo ""
    cd "${ROOT}"/"${mod}"
    for action in "${ACTIONS[@]}"
    do
      # Convert action string to array as it can have multiple arguments.
      IFS=' ' read -r -a args <<< "${action}"
      echo "-----------------------------"
      echo "Running ./terraform" "${args[@]}"
      echo "-----------------------------"
      "${TERRAFORM_LOCAL_BINARY}" "${args[@]}"
      echo ""
    done
done

