# Global variables
scriptFilePath="$(ns_realpath "${0}")"
scriptPath="$(dirname "${scriptFilePath}")"
scriptName="$(basename "${scriptFilePath}")"

# Option parsing
if ! parse "${@}"
then
	${displayHelp} && usage "${parser_subcommand}" && exit 0
	${displayVersion} && echo "${parser_program_version}" && exit 0
	parse_displayerrors 1>&2
	exit 1
fi
${displayHelp} && usage "${parser_subcommand}" && exit 0
${displayVersion} && echo "${parser_program_version}" && exit 0
# Main code

for x in convert bc
do
	ns_which -s "${x}" || ns_error "${x} not found"
done

if [ -z "${inputFilenamePattern}" ]
then
	commonPart=''
	extension=''
	maxDigitCount=0
	minDigitCount=
	while read f
	do
		name="$(basename "${f}")"
		[ -z "${commonPart}" ] \
			&& extension="$(echo "${name}" | sed -E 's,.*\.(.*),\1,g')" \
			&& commonPart="${name%.${extension}}" \
			&& numberingPart="$(echo "${commonPart}" | grep -oE '[0-9]+$')" \
			&& maxDigitCount=${#numberingPart} \
			&& minDigitCount=${#numberingPart} \
			&& commonPart="${commonPart%${numberingPart}}" \
			&& continue
		
		name="${name%.${extension}}"
		numberingPart="$(echo "${name}" | grep -oE '[0-9]+$')" \
		digitCount=${#numberingPart}
		name="${name%${numberingPart}}"
		
		[ "${commonPart}" = "${name}" ] || continue
		
		[ ${digitCount} -lt ${minDigitCount} ] \
			&& minDigitCount=${digitCount}
		[ ${digitCount} -gt ${maxDigitCount} ] \
			&& maxDigitCount=${digitCount}
		
		
	done << EOF
$(find "${inputDirectory}" -mindepth 1 -maxdepth 1 -type f)
EOF

	inputFilenamePattern="${commonPart}"
	[ ${minDigitCount} -eq ${maxDigitCount} ] \
		&& inputFilenamePattern="${inputFilenamePattern}%0${maxDigitCount}d" \
		|| inputFilenamePattern="${inputFilenamePattern}%d"
		
	inputFilenamePattern="${inputFilenamePattern}.${extension}"
fi

number=${inputFirstNumber}
count=-1
[ -z "${inputLastNumber}" ] \
	&& count=-1 \
	|| count=$(expr ${inputLastNumber} - ${inputFirstNumber})

unset inputFiles
inputFiles=()

while [ ${count} -ne 0 ]
do
	inputFile="${inputDirectory}/$(printf "${inputFilenamePattern}" ${number})"
	
	[ ! -f "${inputFile}" ] \
		&& [ ${#inputFiles[@]} -gt 0 ] \
		&& break
	
	number=$(expr ${number} + 1)
	[ -f "${inputFile}" ] || continue 
	
	inputFiles=("${inputFiles[@]}" "${inputFile}")
	[ ${count} -gt 0 ] && count=$(expr ${count} '-' 1)
	
done

inputFileCount=${#inputFiles[@]}
extension="$(echo "$(basename "${inputFiles[${parser_startindex}]}")" | sed -E 's,.*\.(.*),\1,g')"
[ -z "${outputFilename}" ] \
	&& outputFilename="$(basename "${inputDirectory}").${extension}"

width="$(identify -format %w "${inputFiles[${parser_startindex}]}")"
height="$(identify -format %h "${inputFiles[${parser_startindex}]}")"

columnCount=$(expr ${inputFileCount} '/' 2)
columnCount=$(echo "scale=0; sqrt($inputFileCount)" | bc)
columnCount=$(expr ${columnCount} + 1)
rowCount=${columnCount}
[ $(expr ${columnCount} '*' ${rowCount}) -lt ${inputFileCount} ] \
	&& columnCount=$(expr ${columnCount} + 1)
[ $(expr ${columnCount} '*' ${rowCount}) -lt ${inputFileCount} ] \
	&& rowCount=$(expr ${rowCount} + 1)

# echo ${columnCount} x ${rowCount} tile of ${inputFileCount} images

if ${outputMetadata}
then
	cat > "${outputFilename%${extension}}json" << EOF
{
	"width": ${width},
	"height": ${height},
	"count": ${inputFileCount},
	"columns": ${columnCount},
	"rows": ${rowCount}
}
EOF
fi

offset=0
unset rowOutputFiles
rowOutputFiles=()
unset rowInputFiles
rowInputFiles=()

while [ ${offset} -lt ${inputFileCount} ]
do
	if [ $(expr ${offset} '%' ${columnCount}) -eq 0 ]
	then
		[ ! -z "${rowOutputFile}" ] \
			&& [ ${#rowInputFiles[@]} -gt 0 ] \
			&& convert \
				-background none \
				+append "${rowInputFiles[@]}" \
				"${rowOutputFile}" 
		
		unset rowInputFiles
		rowInputFiles=()
		rowOutputFile="$(ns_mktemp "$(basename "${0}")").${extension}"
		rowOutputFiles=("${rowOutputFiles[@]}" "${rowOutputFile}")
	fi
	
	index=$(expr ${offset} + ${parser_startindex})
	inputFile="${inputFiles[${index}]}"
	
	rowInputFiles=("${rowInputFiles[@]}" "${inputFile}")
	
	offset=$(expr ${offset} + 1)
done

[ ! -z "${rowOutputFile}" ] \
	&& [ ${#rowInputFiles[@]} -gt 0 ] \
	&& convert \
		-background none \
		+append "${rowInputFiles[@]}" \
		"${rowOutputFile}"

convert \
	-background none \
	-append "${rowOutputFiles[@]}" \
	"${outputFilename}" \
&& rm -f "${rowOutputFiles[@]}" 

