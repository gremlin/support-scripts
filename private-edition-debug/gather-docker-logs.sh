#! /usr/bin/env bash

set -eou pipefail

tmpdir="$(mktemp -d)"
debug_dir="${tmpdir}/gremlin-debug"

mkdir "${debug_dir}"

pushd /etc/gremlin

for i in $(docker ps --format "{{.Names}}"); do
    echo "Fetching log for container $i"
    docker logs $i > "${debug_dir}/$i.log" 2>&1
done

docker compose stop

echo "Copying cron logs and database to ${debug_dir}"
cp database-data/shared-local-instance.db "${debug_dir}/shared-local-instance.db"
cp /var/log/cron "${debug_dir}/cron.log"

pushd "${tmpdir}"
tar czf /tmp/gremlin-debug.tar.gz gremlin-debug
popd

docker compose start
popd
