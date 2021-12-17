#!/usr/bin/env ksh
# ####################################
# Copyright © 2012 by Renaud Guillard (dev@nore.fr)
# Distributed under the terms of the MIT License, see LICENSE
# Author: Renaud Guillard
# Version: 2.0
# 
# Documentation builder
#
# Program help
function usage
{
cat << 'EOFUSAGE'
create-gource-video: Documentation builder
Usage: 
  create-gource-video [-r <path>] -c <path> [--help] [Output file]
  Options:
    -r, --root: Project root path  
      Default value: .
    -c, --configuration: Gource configuration folder
    --help: Display program usage
  Positional arguments:
    1. Output file
EOFUSAGE
}

# Program parameter parsing
parser_program_author="Renaud Guillard"
parser_program_version="2.0"
if [ -r /proc/$$/exe ]
then
	parser_shell="$(readlink /proc/$$/exe | sed "s/.*\/\([a-z]*\)[0-9]*/\1/g")"
else
	parser_shell="$(basename "$(ps -p $$ -o command= | cut -f 1 -d' ')")"
fi

parser_input=("${@}")
parser_itemcount=${#parser_input[*]}
parser_startindex=0
parser_index=0
parser_subindex=0
parser_item=''
parser_option=''
parser_optiontail=''
parser_subcommand=''
parser_subcommand_expected=false
PARSER_OK=0
PARSER_ERROR=1
PARSER_SC_OK=0
PARSER_SC_ERROR=1
PARSER_SC_UNKNOWN=2
PARSER_SC_SKIP=3
[ "${parser_shell}" = 'zsh' ] && parser_startindex=1
parser_itemcount=$(expr ${parser_startindex} + ${parser_itemcount})
parser_index=${parser_startindex}


parser_required[$(expr ${#parser_required[*]} + ${parser_startindex})]="G_2_configuration:--configuration:"

displayHelp=false
rootPath=
configurationFolder=

function parse_addwarning
{
	typeset var message="${1}"
	typeset var m="[${parser_option}:${parser_index}:${parser_subindex}] ${message}"
	parser_warnings[$(expr ${#parser_warnings[*]} + ${parser_startindex})]="${m}"
}
function parse_adderror
{
	typeset var message="${1}"
	typeset var m="[${parser_option}:${parser_index}:${parser_subindex}] ${message}"
	parser_errors[$(expr ${#parser_errors[*]} + ${parser_startindex})]="${m}"
}
function parse_addfatalerror
{
	typeset var message="${1}"
	typeset var m="[${parser_option}:${parser_index}:${parser_subindex}] ${message}"
	parser_errors[$(expr ${#parser_errors[*]} + ${parser_startindex})]="${m}"
	parser_aborted=true
}

function parse_displayerrors
{
	for error in "${parser_errors[@]}"
	do
		echo -e "\t- ${error}"
	done
}


function parse_pathaccesscheck
{
	typeset var file="${1}"
	[ ! -a "${file}" ] && return 0
	
	typeset var accessString="${2}"
	while [ ! -z "${accessString}" ]
	do
		[ -${accessString:0:1} ${file} ] || return 1;
		accessString=${accessString:1}
	done
	return 0
}
function parse_addrequiredoption
{
	typeset var id="${1}"
	typeset var tail="${2}"
	typeset var o=
	for o in "${parser_required[@]}"
	do
		typeset var idPart="$(echo "${o}" | cut -f 1 -d":")"
		[ "${id}" = "${idPart}" ] && return 0
	done
	parser_required[$(expr ${#parser_required[*]} + ${parser_startindex})]="${id}:${tail}"
}
function parse_setoptionpresence
{
	parse_isoptionpresent "${1}" && return 0
	
	case "${1}" in
	
	esac
	case "${1}" in
	
	esac
	parser_present[$(expr ${#parser_present[*]} + ${parser_startindex})]="${1}"
	return 0
}
function parse_isoptionpresent
{
	typeset var _e_found=false
	typeset var _e=
	for _e in "${parser_present[@]}"
	do
		if [ "${_e}" = "${1}" ]
		then
			_e_found=true; break
		fi
	done
	if ${_e_found}
	then
		return 0
	else
		return 1
	fi
}
function parse_checkrequired
{
	[ ${#parser_required[*]} -eq 0 ] && return 0
	typeset var c=0
	for o in "${parser_required[@]}"
	do
		typeset var idPart="$(echo "${o}" | cut -f 1 -d":")"
		typeset var _e_found=false
		typeset var _e=
		for _e in "${parser_present[@]}"
		do
			if [ "${_e}" = "${idPart}" ]
			then
				_e_found=true; break
			fi
		done
		if ! (${_e_found})
		then
			typeset var displayPart="$(echo "${o}" | cut -f 2 -d":")"
			parser_errors[$(expr ${#parser_errors[*]} + ${parser_startindex})]="Missing required option ${displayPart}"
			c=$(expr ${c} + 1)
		fi
	done
	return ${c}
}
function parse_setdefaultoptions
{
	local parser_set_default=false
	
	parser_set_default=true
	parse_isoptionpresent G_1_root && parser_set_default=false
	if ${parser_set_default}
	then
		rootPath='.'
		parse_setoptionpresence G_1_root
	fi
}
function parse_checkminmax
{
	typeset var errorCount=0
	return ${errorCount}
}
function parse_numberlesserequalcheck
{
	typeset var hasBC=false
	which bc 1>/dev/null 2>&1 && hasBC=true
	if ${hasBC}
	then
		[ "$(echo "${1} <= ${2}" | bc)" = "0" ] && return 1
	else
		typeset var a_int="$(echo "${1}" | cut -f 1 -d".")"
		typeset var a_dec="$(echo "${1}" | cut -f 2 -d".")"
		[ "${a_dec}" = "${1}" ] && a_dec="0"
		typeset var b_int="$(echo "${2}" | cut -f 1 -d".")"
		typeset var b_dec="$(echo "${2}" | cut -f 2 -d".")"
		[ "${b_dec}" = "${2}" ] && b_dec="0"
		[ ${a_int} -lt ${b_int} ] && return 0
		[ ${a_int} -gt ${b_int} ] && return 1
		([ ${a_int} -ge 0 ] && [ ${a_dec} -gt ${b_dec} ]) && return 1
		([ ${a_int} -lt 0 ] && [ ${b_dec} -gt ${a_dec} ]) && return 1
	fi
	return 0
}
function parse_enumcheck
{
	typeset var ref="${1}"
	shift 1
	while [ $# -gt 0 ]
	do
		[ "${ref}" = "${1}" ] && return 0
		shift
	done
	return 1
}
function parse_addvalue
{
	typeset var position=${#parser_values[*]}
	typeset var value=
	if [ $# -gt 0 ] && [ ! -z "${1}" ]; then value="${1}"; else return ${PARSER_ERROR}; fi
	shift
	if [ -z "${parser_subcommand}" ]
	then
		case "${position}" in
		0)
			;;
		*)
			;;
		
		esac
	else
		case "${parser_subcommand}" in
		*)
			return ${PARSER_ERROR}
			;;
		
		esac
	fi
	parser_values[$(expr ${#parser_values[*]} + ${parser_startindex})]="${value}"
}
function parse_process_subcommand_option
{
	parser_item="${parser_input[${parser_index}]}"
	if [ -z "${parser_item}" ] || [ "${parser_item:0:1}" != "-" ] || [ "${parser_item}" = '--' ]
	then
		return ${PARSER_SC_SKIP}
	fi
	
	return ${PARSER_SC_SKIP}
}
function parse_process_option
{
	if [ ! -z "${parser_subcommand}" ] && [ "${parser_item}" != '--' ]
	then
		parse_process_subcommand_option && return ${PARSER_OK}
		[ ${parser_index} -ge ${parser_itemcount} ] && return ${PARSER_OK}
	fi
	
	parser_item="${parser_input[${parser_index}]}"
	
	[ -z "${parser_item}" ] && return ${PARSER_OK}
	
	if [ "${parser_item}" = '--' ]
	then
		for a in {$(expr ${parser_index} + 1)..$(expr ${parser_itemcount} - 1)}
		do
			parse_addvalue "${parser_input[${a}]}"
		done
		parser_index=${parser_itemcount}
		return ${PARSER_OK}
	elif [ "${parser_item}" = "-" ]
	then
		return ${PARSER_OK}
	elif [ "${parser_item:0:2}" = "\-" ]
	then
		parse_addvalue "${parser_item:1}"
	elif [ "${parser_item:0:2}" = '--' ] 
	then
		parser_option="${parser_item:2}"
		parser_optionhastail=false
		if echo "${parser_option}" | grep '=' 1>/dev/null 2>&1
		then
			parser_optionhastail=true
			parser_optiontail="$(echo "${parser_option}" | cut -f 2- -d"=")"
			parser_option="$(echo "${parser_option}" | cut -f 1 -d"=")"
		fi
		
		case "${parser_option}" in
		root)
			if ${parser_optionhastail}
			then
				parser_item=${parser_optiontail}
			else
				parser_index=$(expr ${parser_index} + 1)
				if [ ${parser_index} -ge ${parser_itemcount} ]
				then
					parse_adderror "End of input reached - Argument expected"
					return ${PARSER_ERROR}
				fi
				
				parser_item="${parser_input[${parser_index}]}"
				if [ "${parser_item}" = '--' ]
				then
					parse_adderror "End of option marker found - Argument expected"
					parser_index=$(expr ${parser_index} - 1)
					return ${PARSER_ERROR}
				fi
			fi
			
			parser_subindex=0
			parser_optiontail=''
			parser_optionhastail=false
			[ "${parser_item:0:2}" = "\-" ] && parser_item="${parser_item:1}"
			if [ ! -e "${parser_item}" ]
			then
				parse_adderror "Invalid path \"${parser_item}\" for option \"${parser_option}\""
				return ${PARSER_ERROR}
			fi
			
			if [ -a "${parser_item}" ] && ! ([ -d "${parser_item}" ])
			then
				parse_adderror "Invalid patn type for option \"${parser_option}\""
				return ${PARSER_ERROR}
			fi
			
			! parse_setoptionpresence G_1_root && return ${PARSER_ERROR}
			
			rootPath="${parser_item}"
			
			;;
		configuration)
			if ${parser_optionhastail}
			then
				parser_item=${parser_optiontail}
			else
				parser_index=$(expr ${parser_index} + 1)
				if [ ${parser_index} -ge ${parser_itemcount} ]
				then
					parse_adderror "End of input reached - Argument expected"
					return ${PARSER_ERROR}
				fi
				
				parser_item="${parser_input[${parser_index}]}"
				if [ "${parser_item}" = '--' ]
				then
					parse_adderror "End of option marker found - Argument expected"
					parser_index=$(expr ${parser_index} - 1)
					return ${PARSER_ERROR}
				fi
			fi
			
			parser_subindex=0
			parser_optiontail=''
			parser_optionhastail=false
			[ "${parser_item:0:2}" = "\-" ] && parser_item="${parser_item:1}"
			if [ ! -e "${parser_item}" ]
			then
				parse_adderror "Invalid path \"${parser_item}\" for option \"${parser_option}\""
				return ${PARSER_ERROR}
			fi
			
			if ! parse_pathaccesscheck "${parser_item}" "r"
			then
				parse_adderror "Invalid path permissions for \"${parser_item}\", r privilege(s) expected for option \"${parser_option}\""
				return ${PARSER_ERROR}
			fi
			
			if [ -a "${parser_item}" ] && ! ([ -d "${parser_item}" ])
			then
				parse_adderror "Invalid patn type for option \"${parser_option}\""
				return ${PARSER_ERROR}
			fi
			
			! parse_setoptionpresence G_2_configuration && return ${PARSER_ERROR}
			
			configurationFolder="${parser_item}"
			
			;;
		help)
			! parse_setoptionpresence G_3_help && return ${PARSER_ERROR}
			
			if ${parser_optionhastail} && [ ! -z "${parser_optiontail}" ]
			then
				parse_adderror "Option --${parser_option} does not allow an argument"
				parser_optiontail=''
				return ${PARSER_ERROR}
			fi
			displayHelp=true
			
			;;
		*)
			parse_addfatalerror "Unknown option \"${parser_option}\""
			return ${PARSER_ERROR}
			;;
		
		esac
	elif [ "${parser_item:0:1}" = "-" ] && [ ${#parser_item} -gt 1 ]
	then
		parser_optiontail="${parser_item:$(expr ${parser_subindex} + 2)}"
		parser_option="${parser_item:$(expr ${parser_subindex} + 1):1}"
		if [ -z "${parser_option}" ]
		then
			parser_subindex=0
			return ${PARSER_SC_OK}
		fi
		
		case "${parser_option}" in
		r)
			if [ ! -z "${parser_optiontail}" ]
			then
				parser_item=${parser_optiontail}
			else
				parser_index=$(expr ${parser_index} + 1)
				if [ ${parser_index} -ge ${parser_itemcount} ]
				then
					parse_adderror "End of input reached - Argument expected"
					return ${PARSER_ERROR}
				fi
				
				parser_item="${parser_input[${parser_index}]}"
				if [ "${parser_item}" = '--' ]
				then
					parse_adderror "End of option marker found - Argument expected"
					parser_index=$(expr ${parser_index} - 1)
					return ${PARSER_ERROR}
				fi
			fi
			
			parser_subindex=0
			parser_optiontail=''
			parser_optionhastail=false
			[ "${parser_item:0:2}" = "\-" ] && parser_item="${parser_item:1}"
			if [ ! -e "${parser_item}" ]
			then
				parse_adderror "Invalid path \"${parser_item}\" for option \"${parser_option}\""
				return ${PARSER_ERROR}
			fi
			
			if [ -a "${parser_item}" ] && ! ([ -d "${parser_item}" ])
			then
				parse_adderror "Invalid patn type for option \"${parser_option}\""
				return ${PARSER_ERROR}
			fi
			
			! parse_setoptionpresence G_1_root && return ${PARSER_ERROR}
			
			rootPath="${parser_item}"
			
			;;
		c)
			if [ ! -z "${parser_optiontail}" ]
			then
				parser_item=${parser_optiontail}
			else
				parser_index=$(expr ${parser_index} + 1)
				if [ ${parser_index} -ge ${parser_itemcount} ]
				then
					parse_adderror "End of input reached - Argument expected"
					return ${PARSER_ERROR}
				fi
				
				parser_item="${parser_input[${parser_index}]}"
				if [ "${parser_item}" = '--' ]
				then
					parse_adderror "End of option marker found - Argument expected"
					parser_index=$(expr ${parser_index} - 1)
					return ${PARSER_ERROR}
				fi
			fi
			
			parser_subindex=0
			parser_optiontail=''
			parser_optionhastail=false
			[ "${parser_item:0:2}" = "\-" ] && parser_item="${parser_item:1}"
			if [ ! -e "${parser_item}" ]
			then
				parse_adderror "Invalid path \"${parser_item}\" for option \"${parser_option}\""
				return ${PARSER_ERROR}
			fi
			
			if ! parse_pathaccesscheck "${parser_item}" "r"
			then
				parse_adderror "Invalid path permissions for \"${parser_item}\", r privilege(s) expected for option \"${parser_option}\""
				return ${PARSER_ERROR}
			fi
			
			if [ -a "${parser_item}" ] && ! ([ -d "${parser_item}" ])
			then
				parse_adderror "Invalid patn type for option \"${parser_option}\""
				return ${PARSER_ERROR}
			fi
			
			! parse_setoptionpresence G_2_configuration && return ${PARSER_ERROR}
			
			configurationFolder="${parser_item}"
			
			;;
		*)
			parse_addfatalerror "Unknown option \"${parser_option}\""
			return ${PARSER_ERROR}
			;;
		
		esac
	elif ${parser_subcommand_expected} && [ -z "${parser_subcommand}" ] && [ ${#parser_values[*]} -eq 0 ]
	then
		case "${parser_item}" in
		*)
			parse_addvalue "${parser_item}"
			;;
		
		esac
	else
		parse_addvalue "${parser_item}"
	fi
	return ${PARSER_OK}
}
function parse
{
	parser_aborted=false
	parser_isfirstpositionalargument=true
	while [ ${parser_index} -lt ${parser_itemcount} ] && ! ${parser_aborted}
	do
		parse_process_option
		if [ -z "${parser_optiontail}" ]
		then
			parser_index=$(expr ${parser_index} + 1)
			parser_subindex=0
		else
			parser_subindex=$(expr ${parser_subindex} + 1)
		fi
	done
	
	if ! ${parser_aborted}
	then
		parse_setdefaultoptions
		parse_checkrequired
		parse_checkminmax
	fi
	
	
	
	
	
	typeset var parser_errorcount=${#parser_errors[*]}
	return ${parser_errorcount}
}

function ns_isdir
{
	typeset var inputPath=
	if [ $# -gt 0 ]
	then
		inputPath="${1}"
		shift
	fi
	[ ! -z "${inputPath}" ] && [ -d "${inputPath}" ]
}
function ns_issymlink
{
	typeset var inputPath=
	if [ $# -gt 0 ]
	then
		inputPath="${1}"
		shift
	fi
	[ ! -z "${inputPath}" ] && [ -L "${inputPath}" ]
}
function ns_realpath
{
	typeset var __ns_realpath_in=
	if [ $# -gt 0 ]
	then
		__ns_realpath_in="${1}"
		shift
	fi
	typeset var __ns_realpath_rl=
	typeset var __ns_realpath_cwd="$(pwd)"
	[ -d "${__ns_realpath_in}" ] && cd "${__ns_realpath_in}" && __ns_realpath_in="."
	while [ -h "${__ns_realpath_in}" ]
	do
		__ns_realpath_rl="$(readlink "${__ns_realpath_in}")"
		if [ "${__ns_realpath_rl#/}" = "${__ns_realpath_rl}" ]
		then
			__ns_realpath_in="$(dirname "${__ns_realpath_in}")/${__ns_realpath_rl}"
		else
			__ns_realpath_in="${__ns_realpath_rl}"
		fi
	done
	
	if [ -d "${__ns_realpath_in}" ]
	then
		__ns_realpath_in="$(cd -P "$(dirname "${__ns_realpath_in}")" && pwd)"
	else
		__ns_realpath_in="$(cd -P "$(dirname "${__ns_realpath_in}")" && pwd)/$(basename "${__ns_realpath_in}")"
	fi
	
	cd "${__ns_realpath_cwd}" 1>/dev/null 2>&1
	echo "${__ns_realpath_in}"
}
function ns_relativepath
{
	typeset var from=
	if [ $# -gt 0 ]
	then
		from="${1}"
		shift
	fi
	typeset var base=
	if [ $# -gt 0 ]
	then
		base="${1}"
		shift
	else
		base="."
	fi
	[ -r "${from}" ] || return 1
	[ -r "${base}" ] || return 2
	[ ! -d "${base}" ] && base="$(dirname "${base}")"  
	[ -d "${base}" ] || return 3
	from="$(ns_realpath "${from}")"
	base="$(ns_realpath "${base}")"
	c=0
	sub="${base}"
	newsub=''
	while [ "${from:0:${#sub}}" != "${sub}" ]
	do
		newsub="$(dirname "${sub}")"
		[ "${newsub}" == "${sub}" ] && return 4
		sub="${newsub}"
		c="$(expr ${c} + 1)"
	done
	res='.'
	for ((i=0;${i}<${c};i++))
	do
		res="${res}/.."
	done
	res="${res}${from#${sub}}"
	res="${res#./}"
	[ -z "${res}" ] && res='.'
	echo "${res}"
}
function ns_mktemp
{
	typeset var __ns_mktemp_template=
	if [ $# -gt 0 ]
	then
		__ns_mktemp_template="${1}"
		shift
	else
		__ns_mktemp_template="$(date +%s)-XXXX"
	fi
	typeset var __ns_mktemp_xcount=
	if which 'mktemp' 1>/dev/null 2>&1
	then
		# Auto-fix template
		__ns_mktemp_xcount=0
		which 'grep' 1>/dev/null 2>&1 \
		&& which 'wc' 1>/dev/null 2>&1 \
		&& __ns_mktemp_xcount=$(grep -o X <<< "${__ns_mktemp_template}" | wc -c)
		while [ ${__ns_mktemp_xcount} -lt 3 ]
		do
			__ns_mktemp_template="${__ns_mktemp_template}X"
			__ns_mktemp_xcount=$(expr ${__ns_mktemp_xcount} + 1)
		done
		mktemp -t "${__ns_mktemp_template}" 2>/dev/null
	else
	typeset var __ns_mktemp_root=
	# Fallback to a manual solution
		for __ns_mktemp_root in "${TMPDIR}" "${TMP}" '/var/tmp' '/tmp'
		do
			[ -d "${__ns_mktemp_root}" ] && break
		done
		[ -d "${__ns_mktemp_root}" ] || return 1
	typeset var __ns_mktemp="/${__ns_mktemp_root}/${__ns_mktemp_template}.$(date +%s)-${RANDOM}"
	touch "${__ns_mktemp}" 1>/dev/null 2>&1 && echo "${__ns_mktemp}"
	fi
}
function ns_mktempdir
{
	typeset var __ns_mktemp_template=
	if [ $# -gt 0 ]
	then
		__ns_mktemp_template="${1}"
		shift
	else
		__ns_mktemp_template="$(date +%s)-XXXX"
	fi
	typeset var __ns_mktemp_xcount=
	if which 'mktemp' 1>/dev/null 2>&1
	then
		# Auto-fix template
		__ns_mktemp_xcount=0
		which 'grep' 1>/dev/null 2>&1 \
		&& which 'wc' 1>/dev/null 2>&1 \
		&& __ns_mktemp_xcount=$(grep -o X <<< "${__ns_mktemp_template}" | wc -c)
		
		while [ ${__ns_mktemp_xcount} -lt 3 ]
		do
			__ns_mktemp_template="${__ns_mktemp_template}X"
			__ns_mktemp_xcount=$(expr ${__ns_mktemp_xcount} + 1)
		done
		mktemp -d -t "${__ns_mktemp_template}" 2>/dev/null
	else
	typeset var __ns_mktemp_root=
	# Fallback to a manual solution
		for __ns_mktemp_root in "${TMPDIR}" "${TMP}" '/var/tmp' '/tmp'
		do
			[ -d "${__ns_mktemp_root}" ] && break
		done
		[ -d "${__ns_mktemp_root}" ] || return 1
	typeset var __ns_mktempdir="/${__ns_mktemp_root}/${__ns_mktemp_template}.$(date +%s)-${RANDOM}"
	mkdir -p "${__ns_mktempdir}" 1>/dev/null 2>&1 && echo "${__ns_mktempdir}"
	fi
}
function ns_which
{
	typeset var result=1
	if [ "$(uname -s)" = 'Darwin' ]
	then
		which "${@}" && result=0
	else
	typeset var silent="false"
	typeset var args=
	while [ ${#} -gt 0 ]
		do
			if [ "${1}" = '-s' ]
			then 
				silent=true
			else
				[ -z "${args}" ] \
					&& args="${1}" \
					|| args=("${args[@]}" "${1}")
			fi
			shift
		done
		
		if ${silent}
		then
			which "${args[@]}" 1>/dev/null 2>&1 && result=0
		else
			which "${args[@]}" && result=0
		fi
	fi
	return ${result}
}
scriptFilePath="$(ns_realpath "${0}")"
scriptPath="$(dirname "${scriptFilePath}")"
cwd="$(pwd)"

if ! parse "${@}"
then
	if ${displayHelp}
	then
		usage
		exit 0
	fi
	
	parse_displayerrors
	exit 1
fi

if ${displayHelp}
then
	usage
	exit 0
fi

for x in gource avconv
do
	if ! which ${x} 1>/dev/null 2>&1
	then
		echo "${x} not found"
		exit 1
	fi
done

# Absolute paths
configurationFolder="$(ns_realpath "${configurationFolder}")"
rootPath="$(ns_realpath "${rootPath}")"

userPicturePath="${configurationFolder}"

# User picture aliases
aliasesFile="${configurationFolder}/aliases.cfg"
if [ -f "${aliasesFile}" ]
then
	userPicturePath=$(ns_mktempdir "$(basename "${0}")")
	while read png
	do
		ln -sf "${png}" "${userPicturePath}/$(basename "${png}")"
		#cp -f "${png}" "${userPicturePath}/$(basename "${png}")"
	done << EOF
$(find "${configurationFolder}" -name "*.png") 
EOF
	
	while read line
	do
		name="$(echo ${line} | cut -f 1 -d"=")"
		png="$(echo ${line} | cut -f 2 -d"=")"
		echo "${name}" | grep -q "/" || echo ln -sf "${png}.png" "${userPicturePath}/${name}.png"
	done < "${aliasesFile}"
fi

# Default options
gourceArgs=( \
	--output-framerate 30 \
	--user-image-dir "${configurationFolder}" \
)

defaultPictureFile="${configurationFolder}/default.png"
[ -f "${defaultPictureFile}" ] && gourceArgs=("${gourceArgs[@]}" --default-user-image "${defaultPictureFile}")

for vcs in bzr git hg svn CVS
do
	[ -d "${rootPath}/.${vcs}" ] && gourceArgs=("${gourceArgs[@]}" --log-format "${vcs}")
done

configurationFile="${configurationFolder}/gource.cfg"
[ -f "${configurationFile}" ] && gourceArgs=("${gourceArgs[@]}" --load-config "${configurationFile}")

# Forced options
gourceArgs=("${gourceArgs[@]}" --output-ppm-stream - "${rootPath}")

outputFile="${parser_values[${parser_startindex}]}"
[ -z "${outputFile}" ] \
	&& outputFile="$(pwd)/gource-$(date +%F).mp4" \
	|| outputFile="$(ns_realpath "${outputFile}")"

cd "${configurationFolder}" \
	&& gource "${gourceArgs[@]}" \
		| avconv -y -r 60 -f image2pipe -vcodec ppm -i - \
			-vcodec libx264 -preset ultrafast -crf 1 -threads 0 -bf 0 \
			"${outputFile}"
