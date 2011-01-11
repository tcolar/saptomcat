// History:
//   Oct 7, 2010 tcolar Creation
//
using xml

**
** "Inject" webshop project with patched SAP code
**
class Installer
{
  const File scaFolder
  const File sapTomcatPrjFolder
  const File jcoFolder
  const File tomcatFolder
  const File projectFolder
  const Bool isB2C
  const File jcoJar 
  const File linuxLibFolder := File(`/usr/lib/`)
  const File winLibFolder := File(`/c:/windows/system32/`)
  const File tmpFolder := File(`tmp/`)
  File? scaFile

  **
  ** Main method
  **
  static Void main()
  {
    installer := Installer()
  }

  new make()
  {
    tmpFolder.delete
    tmpFolder.create
    tmpFolder.deleteOnExit

    /*scaFolder = File(ask("What folder contains the SAP SCA files ? (enter path)").toUri)
    jcoFolder = File(ask("What folder contains jco ? (enter path)").toUri)
    sapTomcatPrjFolder = File(ask("Where is the sap_tomcat project (from bitbucket)? (enter path)").toUri)
    tomcatFolder = File(ask("What folder contains vanilla tomcat ? (to be patched)").toUri)
    projectFolder = File(ask("What folder contains the b2c/b2b web IDE project ? (to be patched)").toUri)
    isB2C = ! ask("Do you want to extract B2C or B2B ? (b2c/b2b)").equalsIgnoreCase("b2b")*/

    // testing
    scaFolder = File(`./scas/`); jcoFolder = File(`./jco/`); projectFolder = File(`./b2c_mine/`);
    tomcatFolder = File(`./tomcat/`); isB2C = true; sapTomcatPrjFolder = File(`./saptomcat/`);

    jcoJar = jcoFolder + `sapjco.jar`

    scaFolder.listFiles.each |File f| {if(f.name.upper.startsWith("SAPSHRAPP")) scaFile = f }

    err := checks()
    if(err != null)
    {
      echo("Error: $err\n")
      Env.cur.exit(-1)
    }

    askAndRun("Run step 'patch Tomcat' ?") |->| {patchTomcat}

    askAndRun("Run step 'copy JCO' ?") |->| {copyJco}

    askAndRun("Extract the web project sources from the SCA ?") |->| {extractSca}

    askAndRun("Find and install libraries dependencies ?") |->|
    {
        jars := Dependencies(projectFolder.uri, scaFolder.uri).run
        echo("Copying $jars.size jars into sap_libs")
        jars.each
        {
            it.copyInto(tomcatFolder + `sap_libs/`,["overwrite":true])
        }
    }
    //copyPatchLibs
    echo("Done.")
  }

  /*** Copy select libraries to sap-patches folder
  ** Libs needed to build the patched files
  Void copyPatchLibs()
  {
  echo("Copying select libs to sap-patches folder")
  File(`webshop-b2b/lib/extra/server/bin/system/logging.jar`).copyTo(File(`sap-patches/lib/extra/server/bin/system/logging.jar`),["overwrite":true])
  File(`webshop-b2b/lib/references/library/com.sap.km.trex.client/trex.jc_api.jar`).copyTo(File(`sap-patches/lib/references/library/com.sap.km.trex.client/trex.jc_api.jar`),["overwrite":true])
  File(`webshop-b2b/lib/references/library/com.sap.security.api.sda/com.sap.security.api.jar`).copyTo(File(`sap-patches/lib/references/library/com.sap.security.api.sda/com.sap.security.api.jar`),["overwrite":true])
  }*/

  **
  ** Patch vanilla tomcat distribution (config files)
  ** - create folders
  ** - add sap_libs/*.jar to the common loader in catalina.porperties
  ** - copy and register our custom clasloader in context.xml
  ** - create trex config in trexjavaclient.properties
  ** - create a user in tomcat-users.xml
  ** - update logging.properties log config
  Void patchTomcat()
  {
    f := tomcatFolder+`patched.txt`
    if(f.exists)
    {
      echo("*** Warning: It seems the tomcat patches where alreday applied to $tomcatFolder.pathStr , skipping!\nIf you want to run it again, please remove $f.pathStr")
      return
    }
    f.create

    jar := sapTomcatPrjFolder+`projects/J2eeSapUtils/dist/J2eeSapUtils.jar`
    dest := tomcatFolder + `lib/J2eeSapUtils.jar`;
    jar.copyInto(tomcatFolder, ["overwrite":true])

    sapLibs := tomcatFolder + `sap_libs/`;
    sapLocalLibs := tomcatFolder + `sap_local_libs/`;
    sapDb := sapTomcatPrjFolder + `db/`;
    
    sapLibs.create
    sapLocalLibs.create
    sapDb.create

    catalinaProps := tomcatFolder + `conf/catalina.properties`
    buf := Buf()
    buf.printLine("Holla!!!!")
    catalinaProps.eachLine |Str line|
    {
      if(line.trim.startsWith("common.loader") &&
            ! line .trim.endsWith("sap_libs/*.jar"))
      {
        line = line + ",\${catalina.home}/sap_libs/*.jar";
      }
      buf.printLine(line)
    }
    catalinaProps.out.writeBuf(buf.flip).close

    contextXml := tomcatFolder + `conf/context.xml`
    Str xml := contextXml.readAllStr
    root := XParser(xml.in).parseDoc(true).root
    XElem loader := XElem("Loader")
    loader.addAttr("className", "org.apache.catalina.loader.WebappLoader")
    loader.addAttr("loaderClass", "net.colar.j2eeSapUtils.TomcatClassLoader")
    root.add(loader)
    contextOut := contextXml.out
    root.doc.write(contextOut)
    contextOut.close

    trexHost := ask("Enter TREX server host name:")
    trexPort := ask("Enter TREX server port number (ex: 30301):")

    trexProps := sapLibs + `trexjavaclient.properties`
    trexOut := trexProps.out()
    trexOut.printLine("nameserver.backupserverlist = tcpip://${trexHost}:${trexPort}")
    trexOut.printLine("nameserver.address = tcpip://${trexHost}:${trexPort}")
    trexOut.close

    tomcatUser := ask("Create a tomcat user. User Name? (ex: admin)")
    tomcatPass := ask("Tomcat user Password? (ex: admin)")
    usersXml := tomcatFolder + `conf/tomcat-users.xml`
    Str uXml := usersXml.readAllStr
    usersRoot := XParser(uXml.in).parseDoc(true).root
    XElem user := XElem("user")
    user.addAttr("password", "$tomcatPass")
    user.addAttr("username", "$tomcatUser")
    user.addAttr("roles", "manager,admin")
    usersRoot.add(user)
    out := usersXml.out
    usersRoot.doc.write(out)
    out.close

    logProps := tomcatFolder + `conf/logging.properties`
    logOut := logProps.out(true)
    logOut.printLine("").printLine("")
    logOut.printLine("log4j.logger.com.sap.isa.core.util.MiscUtil=INFO")
    logOut.printLine("log4j.logger.com.sap.isa.core.xcm=INFO")
    logOut.printLine("log4j.logger.com.sap.isa.catalog.actions=INFO")
    logOut.printLine("log4j.logger.com.sap.isa.isacore.action=INFO")
    logOut.printLine("log4j.logger.com.sap.isa.user.action=INFO")
    logOut.printLine("log4j.logger.org.apache.commons=INFO")
    logOut.printLine("log4j.logger.org.apache.jasper=INFO")
    logOut.printLine("log4j.logger.org.apache.struts=INFO")
    logOut.close

    // TODO: sap_libs sap_local_libs

  }

  ** Copy jco libs
  Void copyJco()
  {
    Str os := Env.cur.os
    if(os.equalsIgnoreCase("win32"))
    {
      File jcoLib := jcoFolder + `sapjcorfc.dll`
      File rfcLib := jcoFolder + `librfc32.dll`
      echo("*** Please copy as root/admin $jcoLib to $winLibFolder")
      echo("*** Please copy as root/admin $rfcLib to $winLibFolder")
      ask("Press enter once done")
    }
    else if(os.equalsIgnoreCase("linux"))
    {
      File jcoLib := jcoFolder + `libsapjcorfc.so`
      File rfcLib := jcoFolder + `librfccm.so`
      echo("*** Please copy as root/admin $jcoLib to $linuxLibFolder")
      echo("*** Please copy as root/admin $rfcLib to $linuxLibFolder")
      ask("Press enter once done")
    }
    else
      echo("*** Unexpected OS: $os - Not copying Jco native libs, copy them manually to the system library folder")

    jcoJar.copyInto(tomcatFolder + `sap_libs/`,["overwrite":true])
  }

  ** Extract the SCA (SAPSHRAPP.SCA)
  ** Get the B2B or B2C sda out of it and extract sources, libs & classes out of it
  ** Copy them into project folder.
  Void extractSca()
  {
    webFolder := projectFolder + `web/`;

    echo("Extracting SDA from SCA")
    // extract /DEPLOYARCHIVES/crm~b2b.sca
    File scaCopy := tmpFolder + scaFile.name.toUri
    scaZip := Zip.open(scaFile)

    sdaZipEntry := isB2C ? `/DEPLOYARCHIVES/crm~b2c.sda` : `/DEPLOYARCHIVES/crm~b2b.sda`

    sdaFile := scaZip.contents[sdaZipEntry]
    // zip.contents wants physical file, so extract it first
    sdaFile.copyTo(scaCopy, ["overwrite":true])
    scaZip.close

    // extract content of crm~b2b.sca
    echo("Extracting sca to  to $tmpFolder.pathStr")
    extractTo(scaCopy, tmpFolder)

    echo("Extracting war to $webFolder.pathStr")
    warFile := tmpFolder + (isB2C ? `sap.com~crm~isa~web~b2c.war` : `sap.com~crm~isa~web~b2b.war`)
    extractTo(warFile, webFolder)

    echo("Copying META-INF to $projectFolder.pathStr")
    metaFolder := tmpFolder + `META-INF/`;
    metaFolder.copyInto(projectFolder, ["overwrite":true])

    File srcFolder := projectFolder + `src-ref/`;
    srcFolder.create
    echo("Extracting reference Java sources to $srcFolder.pathStr")
    srcFile := tmpFolder + `src.zip`;
    extractTo(srcFile, srcFolder)
  }

  ** Ask a question to the user (yes/no), execute 'func' if answer is yes.
  Void askAndRun(Str question, Func func)
  {
    input := ask(question)
    if(input.lower.startsWith("y"))
      func.call
    else
      echo("---Skipping step---")
  }

  ** Ask a question to the user, call func with answer
  Str ask(Str question)
  {
    echo(question)
    input := Env.cur.in.readLine
    return input
  }

  ** check needed SAP resources are available
  Str? checks()
  {
    if( ! jcoFolder.exists )
      return "Could not find JCO at: $jcoFolder.pathStr"
    if( ! jcoJar.exists )
      return "Could not find JCO jar at: $jcoJar.pathStr"
    if( scaFile == null)
      return "Could not find SAPSHRAPP SCA in $scaFolder"
    return null
  }

  Void extractTo(File archive, File destFolder)
  {
    zip := Zip.open(archive)
    zip.contents.each |file, uri|
    {
      File dest := destFolder + file.pathStr[1..-1].toUri
      file.copyTo(dest,["overwrite":true])
    }
    zip.close
  }
}