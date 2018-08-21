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
	infof "%-30.30s : %s\n" 'prefix pattern' "${prefixPattern}"
	infof "%-30.30s : %s\n" 'prefix group count' ${prefixPatternGroupCount}
	infof "%-30.30s : %s\n" 'ascii pattern group' ${asciiPatternGroupIndex}
fi

unset findFilePatterns
if [ ${#filePatterns[*]} -gt 0 ]
then
	for p in "${filePatterns[@]}"
	do
		if [ ${#findFilePatterns[*]} -gt 0 ]
		then
			findFilePatterns=("${findFilePatterns[@]}" -o)
		fi
		
		findFilePatterns=("${findFilePatterns[@]}" -name "${p}")
	done

	if [ ${#filePatterns[*]} -gt 1 ]
	then
		findFilePatterns=('(' "${findFilePatterns[@]}" ')')
	fi
fi

for path in "${parser_values[@]}"
do
	path="$(ns_realpath "${path}")"
	if [ -f "${path}" ]
	then
		process_file "${path}"
	elif [ -d "${path}" ] && ${recursive}
	then
		process_folder "${path}"
	fi
done
