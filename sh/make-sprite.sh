#!/usr/bin/env bash
# ####################################
# Copyright © 2021 by renaud
# Author: renaud
# Version: 1.0.0
# 
# make-sprite short description
#
# Program help
usage()
{
cat << 'EOFUSAGE'
make-sprite: make-sprite short description
Usage: 
  make-sprite [-i <path> -p <...> --from <number> --to <...>] [[-m] -o <...>] [--version] [--help]
  Options:
    Input
      -i, --input: Input directory
      -p, --pattern: Input filename pattern
      --from: First image number  
        Default value: 1
      --to: Last image number
    
    Output
      -o, --output: Output filename
      -m, --metadata, --json: Output metadata
        Create a JSON file alongside output image file containing sprite 
        informations
    
    --version: Display program version
    --help: Display program usage
EOFUSAGE
}

# Program parameter parsing
parser_program_author="renaud"
parser_program_version="1.0.0"
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



outputMetadata=false
displayVersion=false
displayHelp=false
inputDirectory=
inputFilenamePattern=
inputStartNumber=
inputLastNumber=
outputFilename=

parse_addwarning()
{
	local message="${1}"
	local m="[${parser_option}:${parser_index}:${parser_subindex}] ${message}"
	parser_warnings[$(expr ${#parser_warnings[*]} + ${parser_startindex})]="${m}"
}
parse_adderror()
{
	local message="${1}"
	local m="[${parser_option}:${parser_index}:${parser_subindex}] ${message}"
	parser_errors[$(expr ${#parser_errors[*]} + ${parser_startindex})]="${m}"
}
parse_addfatalerror()
{
	local message="${1}"
	local m="[${parser_option}:${parser_index}:${parser_subindex}] ${message}"
	parser_errors[$(expr ${#parser_errors[*]} + ${parser_startindex})]="${m}"
	parser_aborted=true
}

parse_displayerrors()
{
	for error in "${parser_errors[@]}"
	do
		echo -e "\t- ${error}"
	done
}


parse_pathaccesscheck()
{
	local file="${1}"
	[ ! -a "${file}" ] && return 0
	
	local accessString="${2}"
	while [ ! -z "${accessString}" ]
	do
		[ -${accessString:0:1} ${file} ] || return 1;
		accessString=${accessString:1}
	done
	return 0
}
parse_addrequiredoption()
{
	local id="${1}"
	local tail="${2}"
	local o=
	for o in "${parser_required[@]}"
	do
		local idPart="$(echo "${o}" | cut -f 1 -d":")"
		[ "${id}" = "${idPart}" ] && return 0
	done
	parser_required[$(expr ${#parser_required[*]} + ${parser_startindex})]="${id}:${tail}"
}
parse_setoptionpresence()
{
	parse_isoptionpresent "${1}" && return 0
	
	case "${1}" in
	G_1_g_1_input)
		;;
	G_1_g_2_pattern)
		;;
	G_1_g_3_from)
		;;
	G_1_g_4_to)
		;;
	G_2_g_1_output)
		;;
	G_2_g_2_metadata)
		;;
	
	esac
	case "${1}" in
	G_1_g)
		;;
	G_2_g)
		;;
	
	esac
	parser_present[$(expr ${#parser_present[*]} + ${parser_startindex})]="${1}"
	return 0
}
parse_isoptionpresent()
{
	local _e_found=false
	local _e=
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
parse_checkrequired()
{
	[ ${#parser_required[*]} -eq 0 ] && return 0
	local c=0
	for o in "${parser_required[@]}"
	do
		local idPart="$(echo "${o}" | cut -f 1 -d":")"
		local _e_found=false
		local _e=
		for _e in "${parser_present[@]}"
		do
			if [ "${_e}" = "${idPart}" ]
			then
				_e_found=true; break
			fi
		done
		if ! (${_e_found})
		then
			local displayPart="$(echo "${o}" | cut -f 2 -d":")"
			parser_errors[$(expr ${#parser_errors[*]} + ${parser_startindex})]="Missing required option ${displayPart}"
			c=$(expr ${c} + 1)
		fi
	done
	return ${c}
}
parse_setdefaultoptions()
{
	local parser_set_default=false
	
	parser_set_default=true
	parse_isoptionpresent G_1_g_3_from && parser_set_default=false
	if ${parser_set_default}
	then
		inputStartNumber='1'
		parse_setoptionpresence G_1_g_3_from
		parse_setoptionpresence G_1_g
	fi
}
parse_checkminmax()
{
	local errorCount=0
	return ${errorCount}
}
parse_numberlesserequalcheck()
{
	local hasBC=false
	which bc 1>/dev/null 2>&1 && hasBC=true
	if ${hasBC}
	then
		[ "$(echo "${1} <= ${2}" | bc)" = "0" ] && return 1
	else
		local a_int="$(echo "${1}" | cut -f 1 -d".")"
		local a_dec="$(echo "${1}" | cut -f 2 -d".")"
		[ "${a_dec}" = "${1}" ] && a_dec="0"
		local b_int="$(echo "${2}" | cut -f 1 -d".")"
		local b_dec="$(echo "${2}" | cut -f 2 -d".")"
		[ "${b_dec}" = "${2}" ] && b_dec="0"
		[ ${a_int} -lt ${b_int} ] && return 0
		[ ${a_int} -gt ${b_int} ] && return 1
		([ ${a_int} -ge 0 ] && [ ${a_dec} -gt ${b_dec} ]) && return 1
		([ ${a_int} -lt 0 ] && [ ${b_dec} -gt ${a_dec} ]) && return 1
	fi
	return 0
}
parse_enumcheck()
{
	local ref="${1}"
	shift 1
	while [ $# -gt 0 ]
	do
		[ "${ref}" = "${1}" ] && return 0
		shift
	done
	return 1
}
parse_addvalue()
{
	local position=${#parser_values[*]}
	local value=
	if [ $# -gt 0 ] && [ ! -z "${1}" ]; then value="${1}"; else return ${PARSER_ERROR}; fi
	shift
	if [ -z "${parser_subcommand}" ]
	then
		${parser_isfirstpositionalargument} && parser_errors[$(expr ${#parser_errors[*]} + ${parser_startindex})]='Program does not accept positional arguments'
		
		parser_isfirstpositionalargument=false
		return ${PARSER_ERROR}
	else
		case "${parser_subcommand}" in
		*)
			return ${PARSER_ERROR}
			;;
		
		esac
	fi
	parser_values[$(expr ${#parser_values[*]} + ${parser_startindex})]="${value}"
}
parse_process_subcommand_option()
{
	parser_item="${parser_input[${parser_index}]}"
	if [ -z "${parser_item}" ] || [ "${parser_item:0:1}" != "-" ] || [ "${parser_item}" = '--' ]
	then
		return ${PARSER_SC_SKIP}
	fi
	
	return ${PARSER_SC_SKIP}
}
parse_process_option()
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
		for ((a=$(expr ${parser_index} + 1);${a}<=$(expr ${parser_itemcount} - 1);a++))
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
		version)
			! parse_setoptionpresence G_3_version && return ${PARSER_ERROR}
			
			if ${parser_optionhastail} && [ ! -z "${parser_optiontail}" ]
			then
				parse_adderror "Option --${parser_option} does not allow an argument"
				parser_optiontail=''
				return ${PARSER_ERROR}
			fi
			displayVersion=true
			
			;;
		help)
			! parse_setoptionpresence G_4_help && return ${PARSER_ERROR}
			
			if ${parser_optionhastail} && [ ! -z "${parser_optiontail}" ]
			then
				parse_adderror "Option --${parser_option} does not allow an argument"
				parser_optiontail=''
				return ${PARSER_ERROR}
			fi
			displayHelp=true
			
			;;
		input)
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
			
			! parse_setoptionpresence G_1_g_1_input && return ${PARSER_ERROR}
			
			! parse_setoptionpresence G_1_g && return ${PARSER_ERROR}
			
			inputDirectory="${parser_item}"
			
			;;
		pattern)
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
			! parse_setoptionpresence G_1_g_2_pattern && return ${PARSER_ERROR}
			
			! parse_setoptionpresence G_1_g && return ${PARSER_ERROR}
			
			inputFilenamePattern="${parser_item}"
			
			;;
		from)
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
			if ! echo -n "${parser_item}" | grep -E "\-?[0-9]+(\.[0-9]+)*" 1>/dev/null 2>&1
			then
				parse_adderror "Invalid value \"${parser_item}\" for option \"${parser_option}\". Number expected"
				return ${PARSER_ERROR}
			else
				if ! parse_numberlesserequalcheck 0 ${parser_item}
				then
					parse_adderror "Invalid value \"${parser_item}\" for option \"${parser_option}\". Number expected"
					return ${PARSER_ERROR}
				fi
			fi
			
			! parse_setoptionpresence G_1_g_3_from && return ${PARSER_ERROR}
			
			! parse_setoptionpresence G_1_g && return ${PARSER_ERROR}
			
			inputStartNumber="${parser_item}"
			
			;;
		to)
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
			! parse_setoptionpresence G_1_g_4_to && return ${PARSER_ERROR}
			
			! parse_setoptionpresence G_1_g && return ${PARSER_ERROR}
			
			inputLastNumber="${parser_item}"
			
			;;
		output)
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
			! parse_setoptionpresence G_2_g_1_output && return ${PARSER_ERROR}
			
			! parse_setoptionpresence G_2_g && return ${PARSER_ERROR}
			
			outputFilename="${parser_item}"
			
			;;
		metadata | json)
			! parse_setoptionpresence G_2_g_2_metadata && return ${PARSER_ERROR}
			
			! parse_setoptionpresence G_2_g && return ${PARSER_ERROR}
			
			if ${parser_optionhastail} && [ ! -z "${parser_optiontail}" ]
			then
				parse_adderror "Option --${parser_option} does not allow an argument"
				parser_optiontail=''
				return ${PARSER_ERROR}
			fi
			outputMetadata=true
			
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
		i)
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
			
			! parse_setoptionpresence G_1_g_1_input && return ${PARSER_ERROR}
			
			! parse_setoptionpresence G_1_g && return ${PARSER_ERROR}
			
			inputDirectory="${parser_item}"
			
			;;
		p)
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
			! parse_setoptionpresence G_1_g_2_pattern && return ${PARSER_ERROR}
			
			! parse_setoptionpresence G_1_g && return ${PARSER_ERROR}
			
			inputFilenamePattern="${parser_item}"
			
			;;
		o)
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
			! parse_setoptionpresence G_2_g_1_output && return ${PARSER_ERROR}
			
			! parse_setoptionpresence G_2_g && return ${PARSER_ERROR}
			
			outputFilename="${parser_item}"
			
			;;
		m)
			! parse_setoptionpresence G_2_g_2_metadata && return ${PARSER_ERROR}
			
			! parse_setoptionpresence G_2_g && return ${PARSER_ERROR}
			
			outputMetadata=true
			
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
parse()
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
	
	
	[ "${parser_option_G_1_g:0:1}" = '@' ] && parser_option_G_1_g=''
	parser_option_G_1_g=''
	[ "${parser_option_G_2_g:0:1}" = '@' ] && parser_option_G_2_g=''
	parser_option_G_2_g=''
	
	
	
	local parser_errorcount=${#parser_errors[*]}
	return ${parser_errorcount}
}

ns_print_error()
{
	local shell="$(readlink /proc/$$/exe | sed "s/.*\/\([a-z]*\)[0-9]*/\1/g")"
	local errorColor="${NSXML_ERROR_COLOR}"
	local useColor=false
	for s in bash zsh ash
	do
		if [ "${shell}" = "${s}" ]
		then
			useColor=true
			break
		fi
	done
	if ${useColor} 
	then
		[ -z "${errorColor}" ] && errorColor="31" 
		echo -e "\e[${errorColor}m${@}\e[0m"  1>&2
	else
		echo "${@}" 1>&2
	fi
}
ns_error()
{
	local errno=
	if [ $# -gt 0 ]
	then
		errno=${1}
		shift
	else
		errno=1
	fi
	local message="${@}"
	if [ -z "${errno##*[!0-9]*}" ]
	then
		message="${errno} ${message}"
		errno=1
	fi
	ns_print_error "${message}"
	exit ${errno}
}
nsxml_installpath()
{
	local subpath="share/ns"
	for prefix in \
		"${@}" \
		"${NSXML_PATH}" \
		"${HOME}/.local/${subpath}" \
		"${HOME}/${subpath}" \
		/usr/${subpath} \
		/usr/loca/${subpath}l \
		/opt/${subpath} \
		/opt/local/${subpath}
	do
		if [ ! -z "${prefix}" ] \
			&& [ -d "${prefix}" ] \
			&& [ -r "${prefix}/ns-xml.plist" ]
		then
			echo -n "${prefix}"
			return 0
		fi
	done
	
	ns_print_error "nsxml_installpath: Path not found"
	return 1
}
ns_isdir()
{
	local inputPath=
	if [ $# -gt 0 ]
	then
		inputPath="${1}"
		shift
	fi
	[ ! -z "${inputPath}" ] && [ -d "${inputPath}" ]
}
ns_issymlink()
{
	local inputPath=
	if [ $# -gt 0 ]
	then
		inputPath="${1}"
		shift
	fi
	[ ! -z "${inputPath}" ] && [ -L "${inputPath}" ]
}
ns_realpath()
{
	local __ns_realpath_in=
	if [ $# -gt 0 ]
	then
		__ns_realpath_in="${1}"
		shift
	fi
	local __ns_realpath_rl=
	local __ns_realpath_cwd="$(pwd)"
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
ns_relativepath()
{
	local from=
	if [ $# -gt 0 ]
	then
		from="${1}"
		shift
	fi
	local base=
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
ns_mktemp()
{
	local __ns_mktemp_template=
	if [ $# -gt 0 ]
	then
		__ns_mktemp_template="${1}"
		shift
	else
		__ns_mktemp_template="$(date +%s)-XXXX"
	fi
	local __ns_mktemp_xcount=
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
	local __ns_mktemp_root=
	# Fallback to a manual solution
		for __ns_mktemp_root in "${TMPDIR}" "${TMP}" '/var/tmp' '/tmp'
		do
			[ -d "${__ns_mktemp_root}" ] && break
		done
		[ -d "${__ns_mktemp_root}" ] || return 1
	local __ns_mktemp="/${__ns_mktemp_root}/${__ns_mktemp_template}.$(date +%s)-${RANDOM}"
	touch "${__ns_mktemp}" 1>/dev/null 2>&1 && echo "${__ns_mktemp}"
	fi
}
ns_mktempdir()
{
	local __ns_mktemp_template=
	if [ $# -gt 0 ]
	then
		__ns_mktemp_template="${1}"
		shift
	else
		__ns_mktemp_template="$(date +%s)-XXXX"
	fi
	local __ns_mktemp_xcount=
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
	local __ns_mktemp_root=
	# Fallback to a manual solution
		for __ns_mktemp_root in "${TMPDIR}" "${TMP}" '/var/tmp' '/tmp'
		do
			[ -d "${__ns_mktemp_root}" ] && break
		done
		[ -d "${__ns_mktemp_root}" ] || return 1
	local __ns_mktempdir="/${__ns_mktemp_root}/${__ns_mktemp_template}.$(date +%s)-${RANDOM}"
	mkdir -p "${__ns_mktempdir}" 1>/dev/null 2>&1 && echo "${__ns_mktempdir}"
	fi
}
ns_which()
{
	local result=1
	if [ "$(uname -s)" = 'Darwin' ]
	then
		which "${@}" && result=0
	else
	local silent="false"
	local args=
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
