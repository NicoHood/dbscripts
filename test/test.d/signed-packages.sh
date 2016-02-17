#!/bin/bash

curdir=$(readlink -e $(dirname $0))
. "${curdir}/../lib/common.inc"

testAddSignedPackage() {
	releasePackage extra 'pkg-simple-a' 'i686'
	"${curdir}"/../../db-update || fail "db-update failed!"
}

testAddUnsignedPackage() {
	releasePackage extra 'pkg-simple-a' 'i686'
	rm "${STAGING}"/extra/*.sig
	"${curdir}"/../../db-update >/dev/null 2>&1 && fail "db-update should fail when a signature is missing!"
}

testAddInvalidSignedPackage() {
	local p
	releasePackage extra 'pkg-simple-a' 'i686'
	for p in "${STAGING}"/extra/*${PKGEXT}; do
		unxz $p
		xz -0 ${p%%.xz}
	done
	"${curdir}"/../../db-update >/dev/null 2>&1 && fail "db-update should fail when a signature is invalid!"
}

testAddBrokenSignature() {
	local s
	releasePackage extra 'pkg-simple-a' 'i686'
	for s in "${STAGING}"/extra/*.sig; do
		echo 0 > $s
	done
	"${curdir}"/../../db-update >/dev/null 2>&1 && fail "db-update should fail when a signature is broken!"
}

. "${curdir}/../lib/shunit2"
