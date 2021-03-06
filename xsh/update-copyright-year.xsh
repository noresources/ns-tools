<?xml version="1.0" encoding="UTF-8"?>
<sh:program xmlns:prg="http://xsd.nore.fr/program" xmlns:sh="http://xsd.nore.fr/xsh" xmlns:xi="http://www.w3.org/2001/XInclude" interpreterType="bash">
	<sh:info>
		<xi:include href="update-copyright-year.xml" />
	</sh:info>
	<sh:functions>
		<xi:include href="../ns-xml/ns/xsh/lib/base/base.xsh" xpointer="xmlns(xsh=http://xsd.nore.fr/xsh)xpointer(//xsh:function)" />
		<xi:include href="../ns-xml/ns/xsh/lib/filesystem/filesystem.xsh" xpointer="xmlns(xsh=http://xsd.nore.fr/xsh)xpointer(//xsh:function)" />
		<xi:include href="../ns-xml/ns/xsh/lib/text/sed.xsh" xpointer="xmlns(xsh=http://xsd.nore.fr/xsh)xpointer(//xsh:function)" />
		<sh:function name="process_file">
			<sh:body>
				<sh:local name="_b">$(basename "${1}")</sh:local>
				<sh:local name="_postfixGroup" type="string">$(expr ${prefixPatternGroupCount} + 2)</sh:local>
<![CDATA[
if [ "${_b:0:1}" = '.' ]; then info "Skip ${1}"; return 0; fi

cols=50
ns_which -s tput && cols=$(expr $(tput cols) - 16) 
infof "%-${cols}.${cols}s" "${1}"
${preview} && info '' && return 0
 
cp -a "${1}" "${temporaryFile}"
# copyright xxxx-yyyy -> copyright xxxx
ns_sed_inplace -E 's,('${prefixPattern}'[0-9]{4})[[:space:]]*-[[:space:]]*[0-9]{4}([[:space:]]|$),\1\'${_postfixGroup}',g' "${temporaryFile}"
# copyright xxxx -> copyright xxxx-{year}
ns_sed_inplace -E 's,('${prefixPattern}'[0-9]{4})([[:space:]]|$),\1'"${yearRangeSeparator}${year}"'\'${_postfixGroup}',g' "${temporaryFile}"
# copyright {year}-{year} -> copyright {year}
ns_sed_inplace -E 's,('"${prefixPattern}${year}"')'"${yearRangeSeparator}${year}"'([[:space:]]|$),\1\'${_postfixGroup}',g' "${temporaryFile}"

if ${ascii}
then
	ns_sed_inplace -E 's,'${prefixPattern}',\1(c)\'${asciiPatternGroupIndex}',g' "${temporaryFile}"
fi

if diff -q "${1}" "${temporaryFile}" 1>/dev/null 2>&1
then
	info ': not changed'	
else
	info ': changed'
	mv "${temporaryFile}" "${1}"
fi
]]></sh:body>
		</sh:function>
		<sh:function name="process_folder">
			<sh:body>
				<sh:local name="_b">$(basename "${1}")</sh:local>
			<![CDATA[
if [ "${_b:0:1}" = '.' ]; then info "Skip ${1}"; return 0; fi
info "${1}"
while read file
do
	[ -z "${file}" ] && continue
	process_file "${file}"
done << EOF]]></sh:body><sh:body indent="no"><![CDATA[
$(find "${1}" -mindepth 1 -maxdepth 1 -type f "${findFilePatterns[@]}")
EOF]]></sh:body><sh:body><![CDATA[
while read directory
do
	[ -z "${directory}" ] && continue
	process_folder "${directory}"
done << EOF]]></sh:body><sh:body indent="no"><![CDATA[
$(find "${1}" -mindepth 1 -maxdepth 1 -type d)
EOF]]></sh:body>
		</sh:function>
		<sh:function name="on_exit">
			<sh:body>rm -f "${temporaryFile}"</sh:body>
		</sh:function>
		<sh:function name="info">
			<sh:body><![CDATA[${verbose} && echo "${@}"; return 0]]></sh:body>
		</sh:function>
		<sh:function name="infof">
			<sh:body><![CDATA[${verbose} && printf "${@}"; return 0]]></sh:body>
		</sh:function>
	</sh:functions>
	<sh:code>
		<!-- Include shell script code -->
		<xi:include href="update-copyright-year.body.sh" parse="text" />
	</sh:code>
</sh:program>
