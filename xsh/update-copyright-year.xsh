<?xml version="1.0" encoding="UTF-8"?>
<sh:program xmlns:prg="http://xsd.nore.fr/program" xmlns:sh="http://xsd.nore.fr/xsh" xmlns:xi="http://www.w3.org/2001/XInclude" interpreterType="bash">
	<sh:info>
		<xi:include href="update-copyright-year.xml"/>
	</sh:info>
	<sh:functions>
		<xi:include href="../ns-xml/ns/xsh/lib/base/base.xsh" xpointer="xmlns(xsh=http://xsd.nore.fr/xsh)xpointer(//xsh:function)" />
		<xi:include href="../ns-xml/ns/xsh/lib/filesystem/filesystem.xsh" xpointer="xmlns(xsh=http://xsd.nore.fr/xsh)xpointer(//xsh:function)" />
		<xi:include href="../ns-xml/ns/xsh/lib/text/sed.xsh" xpointer="xmlns(xsh=http://xsd.nore.fr/xsh)xpointer(//xsh:function)" />
		<sh:function name="process_file">
			<sh:body>
			<sh:local name="prefixPattern">((C|c)opyright[[:space:]][[:space:]]*)(©|\(c\))([[:space:]][[:space:]]*)</sh:local>
<![CDATA[
cp -a "${1}" "${temporaryFile}"
ns_sed_inplace -E 's,('${prefixPattern}'[0-9]{4}-)[0-9]{4}([[:space:]]|$),\1'${year}'\6,g' "${temporaryFile}"
ns_sed_inplace -E 's,('${prefixPattern}'[0-9]{4})([[:space:]]|$),\1'-${year}'\6,g' "${temporaryFile}"
ns_sed_inplace -E 's,('${prefixPattern}${year}')-'${year}'([[:space:]]|$),\1\6,g' "${temporaryFile}"

if ${ascii}
then
	echo ascii
	ns_sed_inplace -E 's,'${prefixPattern}',\1(c)\4,g' "${temporaryFile}"
fi

diff -q "${1}" "${temporaryFile}" 1>/dev/null 2>&1 || mv "${temporaryFile}" "${1}"
]]></sh:body>
		</sh:function>
		<sh:function name="on_exit">
		<sh:body>rm -f "${temporaryFile}"</sh:body>
		</sh:function>
	</sh:functions>
	<sh:code>
		<!-- Include shell script code -->
		<xi:include href="update-copyright-year.body.sh" parse="text"/>
	</sh:code>
</sh:program>
