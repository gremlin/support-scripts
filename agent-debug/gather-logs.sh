#! /usr/bin/env bash

set -eou pipefail

tmpdir="$(mktemp -d)"
debug_dir="${tmpdir}/gremlin-agent-debug"

mkdir "${debug_dir}"

for i in $(kubectl -n gremlin get pods --selector=app.kubernetes.io/name=chao --output jsonpath="{.items[*].metadata.name}"); do
    echo "Fetching logs for ${i}"
    kubectl -n gremlin logs "${i}" > "${debug_dir}/pod-${i}.log"
done

for i in $(kubectl -n gremlin get pods --selector=app.kubernetes.io/name=gremlin --output jsonpath="{.items[*].metadata.name}"); do
    echo "Fetching logs for ${i}"
    kubectl -n gremlin exec -it "${i}" -- gremlin check daemon > "${debug_dir}/pod-daemon-check-${i}.log" 2>&1
    kubectl -n gremlin logs "${i}" > "${debug_dir}/pod-daemon-${i}.log"
done

pushd "${tmpdir}"
tar czf gremlin-agent-debug.tar.gz gremlin-agent-debug
popd

echo "Debug tarball is located at ${tmpdir}/gremlin-agent-debug.tar.gz"
