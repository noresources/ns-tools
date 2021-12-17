<?xml version="1.0" encoding="UTF-8"?>
<xsh:program xmlns:prg="http://xsd.nore.fr/program" xmlns:xsh="http://xsd.nore.fr/xsh" xmlns:xi="http://www.w3.org/2001/XInclude" interpreterType="bash">
  <xsh:info>
    <xi:include href="make-sprite.xml"/>
  </xsh:info>
  <xsh:functions>
    <xi:include href="../ns-xml/ns/xsh/lib/base/base.xsh" xpointer="xmlns(xsh=http://xsd.nore.fr/xsh) xpointer(//xsh:function)"/>
    <xi:include href="../ns-xml/ns/xsh/lib/filesystem/filesystem.xsh" xpointer="xmlns(xsh=http://xsd.nore.fr/xsh) xpointer(//xsh:function)"/>
  </xsh:functions>
  <xsh:code>
    <!-- Include shell script code -->
    <xi:include href="make-sprite.body.sh" parse="text"/>
  </xsh:code>
</xsh:program>
