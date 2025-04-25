#!/bin/bash

set -euxo pipefail

pushd "$(dirname $0)/test-simulator"
swift build -c release
BIN_PATH="$(swift build -c release --show-bin-path)"

popd
exec "$BIN_PATH/test-simulator" "$@"
