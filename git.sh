#!/usr/bin/env bash

set -e -o pipefail

function subcommand_init() {
	mkdir -p .git/{objects,refs/{heads,tags}}
	>.git/HEAD echo "ref: refs/heads/main"
	echo "Initialized empty Git repository in $(realpath .git)"
}

function subcommand_cat_file() {
	if (( "$1" != "-p" )); then
		echo "pretty print mode is only supported one for now"
		exit 1
	fi

	shift
	if [ -z "$1" ]; then
		2>&1 echo "$(basename "$0"): error: expected hash"
		exit 2
	fi

	object_sha="$1"

	if (( ${#object_sha} != 40 )); then
		2>&1 echo "$(basename "$0"): error: invalid hash"
		exit 2
	fi

	object="$(mktemp)"
	zlib-flate -uncompress >"$object" <.git/objects/${object_sha:0:2}/${object_sha:2}

	type_and_size=$(head -qzn 1 "$object" | tr -d '\000')
	type=${type_and_size%% *}
	size=${type_and_size##* }

	case "$type" in
		blob)
			tail -qzn +2 "$object" | head --bytes=$size
			;;
		*)
			2>&1 echo "$(basename "$0"): error: object has unknown type $type"
			exit 2
		;;
	esac
}

case "$1" in
	init)
		subcommand_init
		;;
	cat-file)
		shift
		subcommand_cat_file "$@"
		;;
	"")
		2>&1 echo "$(basename "$0"): error: expected subcommand"
		exit 2
		;;
	*)
		2>&1 echo "$(basename "$0"): error: unkown subcommand: $1"
		exit 2
esac
