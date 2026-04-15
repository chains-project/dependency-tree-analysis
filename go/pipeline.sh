#!/bin/bash

## Parameters
TOTAL=500
METRIC='docker_downloads_count'


## Constants
PAGE_SIZE=100


## Main
rm -rf tmp/

echo "Evaluating dependency metrics of top ${TOTAL} Go packages, based on the metric '${METRIC}'"
echo "Using page size ${PAGE_SIZE}"

echo ''
echo '== COLLECTING PACKAGE NAMES =='
packages=''
pages=$(( (TOTAL + PAGE_SIZE - 1) / PAGE_SIZE ))
for ((page=1; page<=pages; page++)); do
	echo "Fetching page ${page} ..."

	response=$( \
		curl -sX 'GET' \
			"https://packages.ecosyste.ms/api/v1/registries/proxy.golang.org/package_names?page=${page}&per_page=${PAGE_SIZE}&sort=${METRIC}" \
			-H 'accept: application/json' \
	)

	tmp=$(echo "${response}" | jq -r '.[]')
	packages="${packages}${tmp}"
done

	echo "${packages}"
echo ''
echo '== DETERMINING TRANSITIVE COUNT =='
counts=''
while IFS= read -r package; do
	mkdir tmp/
	cd tmp/

  echo "Evaluating ${package} ..."
	go mod init example.com/m >/dev/null 2>&1
	go get "${package}" >/dev/null 2>&1

	tmp=$(go list -m all 2>/dev/null)
	transitive_count=$(echo "${tmp}" | awk 'NR > 2' | wc -l)
	counts="${counts}${transitive_count}
"

	echo "  got $(echo "$tmp" | awk 'NR == 2' | awk '{print $2}')"
	echo "  has ${transitive_count} dependencies"

	cd ..
	rm -rf tmp/
done <<<"${packages}"

echo ''
echo '== COMPUTING STATS =='
sum=0
count=0
while IFS= read -r n; do
  sum=$((sum + n))
  count=$((count + 1))
done <<<"${counts}"

echo ''
echo '== RESULTS =='
echo "$sum"
echo "avg: $((sum / count)) (=${sum}/${count})"
