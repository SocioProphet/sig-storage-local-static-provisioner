#!/bin/bash

# Copyright 2018 The Kubernetes Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

if [ -z "$ROOT" ]; then
	echo "error: ROOT should be initialized"
	exit 1
fi

OS=$(go env GOOS)
ARCH=$(go env GOARCH)
OUTPUT=${ROOT}/_output
OUTPUT_BIN=${OUTPUT}/${OS}/${ARCH}
HELM_VERSION=2.7.2
DEP_VERSION=0.5.0
DEP_BIN=$OUTPUT_BIN/dep
HELM_BIN=$OUTPUT_BIN/helm
MISSPELL_VERSION=0.3.4
MISSPELL_BIN=$OUTPUT_BIN/misspell

test -d "$OUTPUT_BIN" || mkdir -p "$OUTPUT_BIN"

function hack::verify_helm() {
    if test -x "$HELM_BIN"; then
        local v=$($HELM_BIN version --short --client | grep -o -P '\d+.\d+.\d+')
        [[ "$v" == "$HELM_VERSION" ]]
        return
    fi
    return 1
}

function hack::install_helm() {
    if hack::verify_helm; then
        return 0
    fi
    local OS=$(uname | tr A-Z a-z)
    local ARCH=amd64
    local HELM_URL=http://storage.googleapis.com/kubernetes-helm/helm-v${HELM_VERSION}-${OS}-${ARCH}.tar.gz
    curl -s "$HELM_URL" | tar --strip-components 1 -C $OUTPUT_BIN -zxf - ${OS}-${ARCH}/helm
}

function hack::verify_dep() {
    if test -x "$DEP_BIN"; then
        local v=$($DEP_BIN version | awk -F: '/^\s+version\s+:/ { print $2 }' | sed -r 's/^\s+v//g')
        [[ "$v" == "$DEP_VERSION" ]]
        return
    fi
    return 1
}

function hack::install_dep() {
    if hack::verify_dep; then
        return 0
    fi
    platform=$(uname -s | tr A-Z a-z)
    echo "Installing dep v$DEP_VERSION..."
    tmpfile=$(mktemp)
    trap "test -f $tmpfile && rm $tmpfile" RETURN
    wget https://github.com/golang/dep/releases/download/v$DEP_VERSION/dep-${platform}-amd64 -O $tmpfile
    mv $tmpfile $DEP_BIN
    chmod +x $DEP_BIN
}

function hack::verify_misspell() {
    if test -x "$MISSPELL_BIN"; then
        [[ "$($MISSPELL_BIN -v)" == "$MISSPELL_VERSION" ]]
        return
    fi
    return 1
}

function hack::install_misspell() {
    if hack::verify_misspell; then
        return 0
    fi
    echo "Install misspell $MISSPELL_VERSION..."
    local TARURL=https://github.com/client9/misspell/releases/download/v${MISSPELL_VERSION}/misspell_${MISSPELL_VERSION}_linux_64bit.tar.gz
    wget -q $TARURL -O - | tar -zxf - -C "$OUTPUT_BIN"
}
