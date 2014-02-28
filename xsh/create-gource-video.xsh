<?xml version="1.0" encoding="UTF-8"?>
<!-- Copyright © 2011-2012 by Renaud Guillard (dev@nore.fr) -->
<!-- Distributed under the terms of the MIT License, see LICENSE -->
<xsh:program interpreterType="ksh" xmlns:prg="http://xsd.nore.fr/program" xmlns:xsh="http://xsd.nore.fr/xsh" xmlns:xi="http://www.w3.org/2001/XInclude">
	<xsh:info>
		<xi:include href="create-gource-video.xml" />
	</xsh:info>
	<xsh:functions>
		<xi:include href="../ns-xml/ns/xsh/lib/filesystem/filesystem.xsh" xpointer="xmlns(xsh=http://xsd.nore.fr/xsh)xpointer(//xsh:function)" />
	</xsh:functions>
	<xsh:code><![CDATA[
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
		ln -sf "${png}.png" "${userPicturePath}/${name}.png"
		#cp -f "${userPicturePath}/${png}.png" "${userPicturePath}/${name}.png"
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
]]></xsh:code>
</xsh:program>
