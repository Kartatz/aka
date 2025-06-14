#!/bin/bash

set -eu

declare -ra targets=(
	'alpha-unknown-linux-gnu'
	'aarch64-unknown-linux-gnu'
	'arm-unknown-linux-gnueabi'
	'arm-unknown-linux-gnueabihf'
	'hppa-unknown-linux-gnu'
	'i386-unknown-linux-gnu'
	'mips64el-unknown-linux-gnuabi64'
	'mips-unknown-linux-gnu'
	'mipsel-unknown-linux-gnu'
	'powerpc64le-unknown-linux-gnu'
	'powerpc-unknown-linux-gnu'
	's390-unknown-linux-gnu'
	's390x-unknown-linux-gnu'
	'sparc-unknown-linux-gnu'
	'x86_64-unknown-linux-gnu'
	'ia64-unknown-linux-gnu'
)

declare -ra hosts=(
	'i386-unknown-linux-gnu'
	'x86_64-unknown-linux-gnu'
	'aarch64-unknown-linux-gnu'
	'arm-unknown-linux-gnueabihf'
)

declare -ra glibc_versions=(
	'2.39'
	'2.31'
	'2.28'
	'2.24'
	'2.19'
	'2.17'
	'2.13'
	'2.11'
	'2.7'
	'2.3'
	''
)

declare -r base_url='https://github.com/AmanoTeam/obggcc/releases/latest/download/'

declare -r tarballs='/tmp/tarballs'
declare -r tarball='/tmp/chunk.tar.xz'

declare -r toolchain_directory='/tmp/obggcc'
declare -r name="$(basename "${toolchain_directory}")"

[ -d "${tarballs}" ] || mkdir "${tarballs}"
[ -d "${toolchain_directory}" ] || mkdir "${toolchain_directory}"

cd "$(dirname "${toolchain_directory}")"

for host in "${hosts[@]}"; do
	url="${base_url}${host}.tar.xz"
	
	rm --recursive --force "${toolchain_directory}/"*
	
	echo "- Downloading from '${url}'"
	
	curl \
		--url "${url}" \
		--retry '30' \
		--retry-all-errors \
		--retry-delay '0' \
		--retry-max-time '0' \
		--location \
		--silent \
		--output "${tarball}"
	
	tar \
		--directory="$(dirname "${toolchain_directory}")" \
		--extract \
		--file="${tarball}"
	
	for target in "${targets[@]}"; do
		for glibc_version in "${glibc_versions[@]}"; do
			if ! [ -d "${toolchain_directory}/${target}${glibc_version}" ]; then
				continue
			fi
			
			files=''
			
			while read file; do
				files+="${file} "
			done <<< "$(find "${name}" -type 'f' -o -type 'l' -regex ".*${target}${glibc_version}[-/\.].*" | sort --unique)"
			
			if [ -z "${glibc_version}" ]; then
				[ -d "${name}/lib" ] && files+="${name}/lib "
				[ -d "${name}/lib64" ] && files+="${name}/lib64 "
			fi
			
			declare destination="${tarballs}/${host}-${target}${glibc_version}.tar.xz"
			
			echo "- Saving to '${destination}'"
			
			tar \
				--directory="$(dirname "${toolchain_directory}")" \
				--create \
				--file=- \
				${files} | \
				xz \
					--threads='0' \
					--compress \
					--extreme \
					-9 > "${tarballs}/${host}-${target}${glibc_version}.tar.xz"
		done
	done
done

