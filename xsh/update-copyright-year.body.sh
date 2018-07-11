# Global variables
scriptFilePath="$(ns_realpath "${0}")"
scriptPath="$(dirname "${scriptFilePath}")"
scriptName="$(basename "${scriptFilePath}")"

# Option parsing
if ! parse "${@}"
then
	if ${displayHelp}
	then
		usage "${parser_subcommand}"
		exit 0
	fi
	
	parse_displayerrors
	exit 1
fi

if ${displayHelp}
then
	usage "${parser_subcommand}"
	exit 0
fi

# Main code

trap on_exit EXIT

year="$(date +'%Y')"
temporaryFile="$(ns_mktemp ucy)"

if [ ${prefixPatternGroupCount} -lt 0 ]
then
	p="${prefixPattern}"
	p="$(sed -E 's,\\\\,,g;s,\\\(,,g;s,[^(],,g' <<< "${p}")"
	prefixPatternGroupCount=$(echo -n "${p}" | wc -c)
fi

if [ ${asciiPatternGroupIndex} -lt 0 ]
then
	p="${prefixPattern}"
	p="$(sed -E 's,\\\\,,g;s,\\\(,,g;s,[^(@],,g;s,(.*)@.*,\1,g' <<< "${p}")"
	asciiPatternGroupIndex=$(echo -n "${p}" | wc -c)
fi

prefixPattern="$( sed 's,[[:space:]],[[:space:]],g' <<< "${prefixPattern}")"

if ${preview}
then
	printf "%-30.30s : %s\n" 'prefix pattern' "${prefixPattern}"
	printf "%-30.30s : %s\n" 'prefix group count' ${prefixPatternGroupCount}
	printf "%-30.30s : %s\n" 'ascii pattern group' ${asciiPatternGroupIndex}
	#exit 0
fi

for path in "${parser_values[@]}"
do
	if [ -f "${path}" ]
	then
		process_file "${path}"
	elif ${recursive}
	then
		while read file
		do
			process_file "${file}"
		done << EOF
$(find "${path}" -type f)
EOF
	else
		ns_error "Unable to process ${path}. Use --recursive option to process folders"
	fi
done