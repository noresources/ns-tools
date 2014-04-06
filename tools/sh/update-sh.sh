#!/bin/bash
################################################################################
# A shell script to generate other shell scripts...
# Rebuild shell scripts built using ns-xml program schema
################################################################################

scriptPath="$(dirname "${0}")"

error()
{
	echo "${@}" 1>&2
	exit 1
}

usage()
{
	echo "$(basename ${0})"
}

nsxmlPath="${scriptPath}/../../ns-xml"
cwd="$(pwd)"
cd "${nsxmlPath}"
nsxmlPath="$(pwd)"
cd "${cwd}"

shBuilder="${nsxmlPath}/ns/sh/build-shellscript.sh"
xulBuilder="${nsxmlPath}/ns/sh/build-xulapp.sh"

[ -x "${shBuilder}" ] || error "Error: ${shBuilder} not found. Please provide ns-xml project location as first command line argument"
scriptPath="$(dirname "${0}")"
cd "${scriptPath}"
scriptPath="$(pwd)"

nstoolsPath="${scriptPath}/../.."
cd "${nstoolsPath}"
nstoolsPath="$(pwd)"
cd "${cwd}"

resourceBasePath="${nstoolsPath}/xsh"

while read f
do
	b="$(basename "${f}")"
	subTree="${f#${resourceBasePath}/}"
	subTree="${subTree%${b}}"
	subTree="${subTree%/}"
	
	# Skip lib path
	subTreeBase="$(echo "${subTree}" | cut -f 1 -d"/")"
	[ "${subTreeBase}" = "lib" ] && continue
			
	scriptOutputPath="${nstoolsPath}/sh"
	[ -z ${subTree} ] ||scriptOutputPath="${scriptPath}/${subTree}"
	
	mkdir -p "${scriptOutputPath}"
	if ! ${shBuilder} -x "${f%xsh}xml" -s "${f}" -o "${scriptOutputPath}/${b%xsh}sh"
	then
		echo "Failed to build Shell ${f%xsh}"
		exit 1
	fi
done << EOF
$(find "${resourceBasePath}" -mindepth 1 -name "*.xsh")
EOF

