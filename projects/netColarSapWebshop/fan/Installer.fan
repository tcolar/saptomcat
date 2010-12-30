// History:
//   Oct 7, 2010 tcolar Creation
//

**
** "Inject" webshop project with patched SAP code
**
class Installer
{
  //TODO: make webshop-b2b a variable
  // TODO: make b2c an option
  const Uri sdaZipEntry := `/DEPLOYARCHIVES/crm~b2b.sda`;

  const File resFolder := File(`sap_resources/`)
  const File patchesFolder := File(`sap-patches/`)
  const File jcoFolder  := resFolder + `jco/`
  const File jettyFolder := File(`webshop-b2b/jetty-6.1.25/`)
  const File jcoJar  := jcoFolder + `sapjco.jar`
  const File linuxLibFolder := File(`/usr/lib/`)
  const File winLibFolder := File(`/c:/windows/system32/`)
  const File wsLibs := File(`webshop-b2b/lib/local/sapjco/`)
  const File srcFolder := File(`webshop-b2b/etc/src/sap.com/b2b/`)
  const File loggingLibs := File(`jco-logging/lib/`)
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
    resFolder.listFiles.each |File f| {if(f.name.upper.startsWith("SAPSHRAPP")) scaFile=f }
    err := checks()
    if(err != null)
      {
      echo("Error: $err\n")
      echo(infos)
      Env.cur.exit(-1)
    }
    //doJco
    doSca
    Dependencies(`webshop-b2b/`, resFolder.uri).run
    copyPatchLibs
    echo("Done.")
  }

  ** Copy select libraries to sap-patches folder
  ** Libs needed to build the patched files
  Void copyPatchLibs()
  {
    echo("Copying select libs to sap-patches folder")
    File(`webshop-b2b/lib/extra/server/bin/system/logging.jar`).copyTo(File(`sap-patches/lib/extra/server/bin/system/logging.jar`),["overwrite":true])
    File(`webshop-b2b/lib/references/library/com.sap.km.trex.client/trex.jc_api.jar`).copyTo(File(`sap-patches/lib/references/library/com.sap.km.trex.client/trex.jc_api.jar`),["overwrite":true])
    File(`webshop-b2b/lib/references/library/com.sap.security.api.sda/com.sap.security.api.jar`).copyTo(File(`sap-patches/lib/references/library/com.sap.security.api.sda/com.sap.security.api.jar`),["overwrite":true])
  }

  ** Copy jco libs
  Void doJco()
  {
    Str os := Env.cur.os
    if(os.equalsIgnoreCase("win32"))
      {
      File jcoLib := jcoFolder + `sapjcorfc.dll`
      File rfcLib := jcoFolder + `librfc32.dll`
      //ask("\tCopy $jcoLib to $winLibFolder Y/N ?") |->| {jcoLib.copyInto(winLibFolder, ["overwrite":true])}
      //ask("\tCopy $rfcLib to $winLibFolder Y/N ?") |->| {rfcLib.copyInto(winLibFolder, ["overwrite":true])}
    }
    else if(os.equalsIgnoreCase("linux"))
      {
      File jcoLib := jcoFolder + `libsapjcorfc.so`
      File rfcLib := jcoFolder + `librfccm.so`
      //ask("\tCopy $jcoLib to $linuxLibFolder Y/N ?") |->| {jcoLib.copyInto(linuxLibFolder, ["overwrite":true])}
      //ask("\tCopy $rfcLib to $linuxLibFolder Y/N ?") |->| {rfcLib.copyInto(linuxLibFolder, ["overwrite":true])}
    }
    else
    echo("Unexpected OS: $os - Not copying Jco native libs")

    //ask("\tCopy $jcoJar to $wsLibs Y/N ?") |->| {jcoJar.copyInto(wsLibs, ["overwrite":true])}
    //ask("\tCopy $jcoJar to $loggingLibs Y/N ?") |->| {jcoJar.copyInto(loggingLibs, ["overwrite":true])}
  }

  ** Extract the SCA (SAPSHRAPP.SCA)
  ** Get the B2B sda out of it and extract b2b libs & classes out of it
  ** Copy them into project folder.
  Void doSca()
  {
    echo("Extracting SDA from SCA")
    // extract /DEPLOYARCHIVES/crm~b2b.sca
    File scaCopy := tmpFolder + scaFile.name.toUri
    scaZip := Zip.open(scaFile)
    sdaFile := scaZip.contents[sdaZipEntry]
    // zip.contents wants physical file, so extract it first
    sdaFile.copyTo(scaCopy)
    scaZip.close

    // extract content of crm~b2b.sca
    sdaZip := Zip.open(scaCopy)
    sdaZip.contents.each |file, uri|
    {
      File dest := srcFolder + file.pathStr[1..-1].toUri
      //echo("\tExtracting SCA contents: $uri -> $dest")
      file.copyTo(dest,["overwrite":true])
    }
    sdaZip.close

    echo("Extracting B2B war")
    warFile := srcFolder + `sap.com~crm~isa~web~b2b.war`
    warZip := Zip.open(warFile)
    warZip.contents.each |file, uri|
    {
      File dest := File(`webshop-b2b/war/`) + file.pathStr[1..-1].toUri
      //echo("\tExtracting war contents: $uri -> $dest")
      file.copyTo(dest,["overwrite":true])
    }
    warZip.close

    echo("Copying config files to deploy folder")
    File deployFolder := File(`webshop-b2b/deploy/war/`)
    File(`webshop-b2b/war/WEB-INF/xcm/customer/configuration/config-data.xml`).copyTo(deployFolder+`WEB-INF/xcm/customer/configuration/config-data.xml`,["overwrite":true])
    File(`webshop-b2b/war/WEB-INF/xcm/customer/configuration/scenario-config.xml`).copyTo(deployFolder+`WEB-INF/xcm/customer/configuration/scenario-config.xml`,["overwrite":true])
    File(`webshop-b2b/war/WEB-INF/xcm/sap/system/bootstrap-config.xml`).copyTo(deployFolder+`WEB-INF/xcm/sap/system/bootstrap-config.xml`,["overwrite":true])

    echo("Copying properties files")
    File(`webshop-b2b/WEB-INF/classes`).list.each{ it.copyInto(File(`webshop-b2b/src-properties`),["overwrite":true])}
    File(`webshop-b2b/WEB-INF/classes`).delete

    echo("Copying META-INF to deploy folder")
    File(`webshop-b2b/etc/src/sap.com/b2b/META-INF/`).copyInto(deployFolder,["overwrite":true])

    echo("Copying web.xml to jetty")
    File webXml := jettyFolder + `config/sap-b2b-web.xml`
    File(`webshop-b2b/war/WEB-INF/web.xml`).copyTo(webXml,["overwrite":true])
  }

  ** Ask a question to the user (yes/no), execute 'func' if answer is yes.
  Void ask(Str question, Func func)
  {
    echo(question)
    input := Env.cur.in.readChar
    if(input == 'y' || input == 'Y')
    func.call
  }

  ** check needed SAP resources are available
  Str? checks()
  {
    if( ! jcoFolder.exists )
    return "Could not find JCO at: $jcoFolder.pathStr"
    if( ! jcoJar.exists )
    return "Could not find JCO jar at: $jcoJar.pathStr"
    if( scaFile == null)
    return "Could not find SAPSHRAPP SCA in $resFolder"
    return null
  }

  const Str infos := """Infos: TBD"""
}