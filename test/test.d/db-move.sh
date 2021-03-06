#!/bin/bash

curdir=$(readlink -e $(dirname $0))
. "${curdir}/../lib/common.inc"

testMoveSimplePackages() {
	local arches=('i686' 'x86_64')
	local pkgs=('pkg-simple-a' 'pkg-simple-b')
	local pkgbase
	local arch

	for pkgbase in ${pkgs[@]}; do
		for arch in ${arches[@]}; do
			releasePackage testing ${pkgbase} ${arch}
		done
	done

	"${curdir}"/../../db-update

	"${curdir}"/../../db-move testing extra all pkg-simple-a

	for arch in ${arches[@]}; do
		checkPackage extra pkg-simple-a-1-1-${arch}.pkg.tar.xz ${arch}
		checkRemovedPackage testing pkg-simple-a-1-1-${arch}.pkg.tar.xz ${arch}

		checkPackage testing pkg-simple-b-1-1-${arch}.pkg.tar.xz ${arch}
	done
}

testMoveMultiplePackages() {
	local arches=('i686' 'x86_64')
	local pkgs=('pkg-simple-a' 'pkg-simple-b')
	local pkgbase
	local arch

	for pkgbase in ${pkgs[@]}; do
		for arch in ${arches[@]}; do
			releasePackage testing ${pkgbase} ${arch}
		done
	done

	"${curdir}"/../../db-update

	"${curdir}"/../../db-move testing extra all pkg-simple-a pkg-simple-b

	for pkgbase in ${pkgs[@]}; do
		for arch in ${arches[@]}; do
			checkPackage extra ${pkgbase}-1-1-${arch}.pkg.tar.xz ${arch}
			checkRemovedPackage testing ${pkgbase}-1-1-${arch}.pkg.tar.xz ${arch}
		done
	done
}

testMoveEpochPackages() {
	local arches=('i686' 'x86_64')
	local pkgs=('pkg-simple-epoch')
	local pkgbase
	local arch

	for pkgbase in ${pkgs[@]}; do
		for arch in ${arches[@]}; do
			releasePackage testing ${pkgbase} ${arch}
		done
	done

	"${curdir}"/../../db-update

	"${curdir}"/../../db-move testing extra all pkg-simple-epoch

	for arch in ${arches[@]}; do
		checkPackage extra pkg-simple-epoch-1:1-1-${arch}.pkg.tar.xz ${arch}
		checkRemovedPackage testing pkg-simple-epoch-1:1-1-${arch}.pkg.tar.xz ${arch}
	done
}

testMoveAnyPackages() {
	local pkgs=('pkg-any-a' 'pkg-any-b')
	local pkgbase

	for pkgbase in ${pkgs[@]}; do
		releasePackage testing ${pkgbase} any
	done

	"${curdir}"/../../db-update
	"${curdir}"/../../db-move testing extra all pkg-any-a

	checkAnyPackage extra pkg-any-a-1-1-any.pkg.tar.xz
	checkRemovedAnyPackage testing pkg-any-a
	checkAnyPackage testing pkg-any-b-1-1-any.pkg.tar.xz
}

testMoveSplitPackages() {
	local arches=('i686' 'x86_64')
	local pkgs=('pkg-split-a' 'pkg-split-b')
	local pkg
	local pkgbase
	local arch

	for pkgbase in ${pkgs[@]}; do
		for arch in ${arches[@]}; do
			releasePackage testing ${pkgbase} ${arch}
		done
	done

	"${curdir}"/../../db-update
	"${curdir}"/../../db-move testing extra all pkg-split-a1 pkg-split-a2

	for arch in ${arches[@]}; do
		for pkg in "${pkgdir}/pkg-split-a"/*-1-1-${arch}${PKGEXT}; do
			checkPackage extra ${pkg##*/} ${arch}
		done
	done
	for arch in ${arches[@]}; do
		for pkg in "${pkgdir}/pkg-split-b"/*-1-1-${arch}${PKGEXT}; do
			checkPackage testing ${pkg##*/} ${arch}
		done
	done

	checkRemovedAnyPackage testing pkg-split-a
}

testMoveChangedSplitPackages() {
	local arches=('i686' 'x86_64')
	local pkgbase='pkg-split-a'
	local pkg
	local arch

	for arch in ${arches[@]}; do
		releasePackage extra ${pkgbase} ${arch}
	done

	"${curdir}"/../../db-update

	pushd "${TMP}/svn-packages-copy/${pkgbase}/trunk/" >/dev/null
	sed "s/pkgrel=1/pkgrel=2/g;s/pkgname=('pkg-split-a1' 'pkg-split-a2')/pkgname='pkg-split-a1'/g" -i PKGBUILD
	arch_svn commit -q -m"remove pkg-split-a2; pkgrel=2" >/dev/null
	popd >/dev/null

	for arch in ${arches[@]}; do
		releasePackage testing ${pkgbase} ${arch}
	done

	"${curdir}"/../../db-update
	"${curdir}"/../../db-move testing extra all pkg-split-a1

	for arch in ${arches[@]}; do
		checkPackage extra ${pkgbase}1-1-2-${arch}.pkg.tar.xz ${arch}
		checkRemovedPackage extra ${pkgbase}2 ${arch}
	done
}

testMoveChangedAnySplitPackages() {
	local arches=('i686' 'x86_64')
	local pkgbase='pkg-split-c'
	local arch

	for arch in ${arches[@]}; do
		releasePackage extra ${pkgbase} ${arch} ${pkgbase}1
	done
	releasePackage extra ${pkgbase} any ${pkgbase}2

	"${curdir}"/../../db-update

	pushd "${TMP}/svn-packages-copy/${pkgbase}/trunk/" >/dev/null
	sed "s/pkgrel=1/pkgrel=2/g;s/pkgname=('pkg-split-c1' 'pkg-split-c2')/pkgname='pkg-split-c1'/g" -i PKGBUILD
	arch_svn commit -q -m"remove pkg-split-c2; pkgrel=2" >/dev/null
	popd >/dev/null

	for arch in ${arches[@]}; do
		releasePackage testing ${pkgbase} ${arch} ${pkgbase}1
	done

	"${curdir}"/../../db-update
	"${curdir}"/../../db-move testing extra all ${pkgbase}1

	for arch in ${arches[@]}; do
		checkPackage extra ${pkgbase}1-1-2-${arch}.pkg.tar.xz ${arch}
	done
	checkRemovedAnyPackage extra ${pkgbase}2
}

testMoveDebugPackages() {
	local arches=('i686' 'x86_64')
	local pkgbase='pkg-debug-a'
	local pkgbase
	local arch

	for arch in ${arches[@]}; do
		releasePackage testing ${pkgbase} ${arch}
	done

	"${curdir}"/../../db-update

	"${curdir}"/../../db-move testing extra all ${pkgbase}

	for arch in ${arches[@]}; do
		checkPackage extra ${pkgbase}-1-1-${arch}.pkg.tar.xz ${arch}
		checkPackage extra-${DEBUGSUFFIX} ${pkgbase}-${DEBUGSUFFIX}-1-1-${arch}.pkg.tar.xz ${arch}
		checkRemovedPackage testing ${pkgbase} ${arch}
		checkRemovedPackage testing-${DEBUGSUFFIX} ${pkgbase}-${DEBUGSUFFIX} ${arch}
	done
}

testMoveChangedDebugSplitPackages() {
	local arches=('i686' 'x86_64')
	local pkgbase='pkg-debug-b'
	local arch

	for arch in ${arches[@]}; do
		releasePackage extra ${pkgbase} ${arch} ${pkgbase}1
	done
	releasePackage extra ${pkgbase} any ${pkgbase}2

	"${curdir}"/../../db-update

	pushd "${TMP}/svn-packages-copy/${pkgbase}/trunk/" >/dev/null
	sed "s/pkgrel=1/pkgrel=2/g;s/pkgname=('pkg-debug-b1' 'pkg-debug-b2')/pkgname='pkg-debug-b2'/g" -i PKGBUILD
	arch_svn commit -q -m"remove pkg-debug-b1; pkgrel=2" >/dev/null
	popd >/dev/null

	releasePackage testing ${pkgbase} any ${pkgbase}2

	"${curdir}"/../../db-update
	"${curdir}"/../../db-move testing extra all ${pkgbase}2

	for arch in ${arches[@]}; do
		checkRemovedPackage extra ${pkgbase}1 ${arch}
		checkRemovedPackage extra-${DEBUGSUFFIX} ${pkgbase}1-${DEBUGSUFFIX} ${arch}
	done
	checkAnyPackage extra ${pkgbase}2-1-2-any.pkg.tar.xz
}

. "${curdir}/../lib/shunit2"
