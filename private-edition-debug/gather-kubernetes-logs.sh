#! /usr/bin/env bash

set -eou pipefail

tmpdir="$(mktemp -d)"
debug_dir="${tmpdir}/gremlin-debug"

mkdir "${debug_dir}"

pushd ${tmpdir}

for namespace in $(kubectl get namespaces | grep "gremlin" | awk ' {{ print $1 }}'); do
    echo "checking namespace $namespace"
    for pod in $(kubectl get pods -n "$namespace" | tail -n +2 | awk 'NR > 1 {{ print $1 }}'); do
      kubectl logs -n $namespace $pod > "${debug_dir}/$pod.log"
    done
done


echo "Copying database to ${debug_dir}"
#cp database-data/shared-local-instance.db "${debug_dir}/shared-local-instance.db"

tar czf /tmp/gremlin-debug.tar.gz gremlin-debug

popd
