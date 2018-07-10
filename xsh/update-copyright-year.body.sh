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


p='((C|c)opyright[[:space:]][[:space:]]*)(©|\(c\))([[:space:]][[:space:]]*)'
p="=(sed 's,\\,,g')"
echo "$p"

exit 0

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