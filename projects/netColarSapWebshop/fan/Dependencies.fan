// To change this License template, choose Tools / Templates
// and edit Licenses / FanDefaultLicense.txt
//
// History:
//   Oct 8, 2010 tcolar Creation
//
using xml

**
** Dependencies
** Find dependencies(jars) needed by sap web project
**
class Dependencies
{
  const Uri root
  const Uri scas
  ** pattern for Sap manifest library name
  static const Regex sdaName := Regex.fromStr("keyname:(.*)")

  new make(Uri webProjectRoot, Uri scaFolder)
  {
    root = webProjectRoot
    scas = scaFolder
  }

  **
  ** Run the deopendency search
  ** Return a list of library (jars) found
  **
  File[] run()
  {
    jars := File[,]

    scasFolder := File(scas);

    extractor := SapScaExtractor(scasFolder)

    Str:File[] sapLibs := indexSapLibs(scasFolder)

    File appJ2ee := File(root) + `META-INF/application-j2ee-engine.xml`
    Str xml := appJ2ee.readAllStr

    root := XParser(xml.in).parseDoc(true).root
    root.elems.each
    {
      if(it.name.equalsIgnoreCase("reference"))
      {
        target := it.elem("reference-target", false)
        if(target != null)
        {
          name := normalizeSdaName(target.text.writeToStr)
          if( ! sapLibs.containsKey(name))
          {
              echo("No SCA contained an entry for $name")
          }
          else
          {
              sapLibs[name].each |file|
              {
                  jars.add(file)
              }
          }
        }
      }
    }
    return jars
  }

  **
  ** Find the SAP_MANIFEST.MF files and store the sap name (like tc~sec~securestorage~service)
  ** along with the jars provided with it
  Str:File[] indexSapLibs(File scasFolder)
  {
    echo("Indexing Sap Libraries")

    Str:File[] sdaLibs := [:]

    scasFolder.walk |File file|
    {
      if(file.name.equalsIgnoreCase("SAP_MANIFEST.MF") && file.parent.name.equals("META-INF"))
      {
        Str? name
        if(file.exists)
        {
          file.eachLine
          {
            matcher := sdaName.matcher(it)
            if(matcher.matches)
            {
              name = normalizeSdaName(matcher.group(1))
              //echo("** $name")
            }
          }
        }
        if(name != null)
        {
          File[] jars := [,]
          folder := file.parent.parent
          folder.walk |f|
          {
            if(!f.isDir && f.pathStr.endsWith(".jar"))
              jars.add(f)
          }
          sdaLibs.set(name, jars)
        }
      }
    }

    return sdaLibs
  }

  ** SAP Sda names are all over the places, so trying to normalize
  Str normalizeSdaName(Str name)
  {
    return name.trim.replace("/","_").replace("~","_")
  }
}

**
** Recursively extracts SAP Sca's to temporary folder
** Including sub-archives
**
class SapScaExtractor
{
  static const Str[] unzipExtensions := ["sda","ppa","zip","war","ear","rar"]

  new make(File scasFolder)
  {
    File tmpFolder := scasFolder+`tmp/`;
    tmpFolder.delete
    tmpFolder.create
    tmpFolder.deleteOnExit

    echo("Extracting SCA archives ... please wait.")
    scasFolder.walk |file|
    {
        //echo(file)
        if(!file.isDir && file.ext!=null && file.ext.equalsIgnoreCase("sca"))
        {
            extract(file, tmpFolder.createDir(file.name))
        }
    }
  }

  **
  ** Extract an archive and recurse into sub-archives
  **
  Void extract(File archive, File destFolder)
  {
    zip := Zip.open(archive)
    zip.contents.each |file, uri|
    {
        Uri path := file.pathStr[1..-1].toUri;
        Str name := file.uri.name

        if(!file.isDir && file.ext!=null && unzipExtensions.contains(file.ext.lower))
        {
            File dest := destFolder + path
            file.copyTo(dest,["overwrite":true])
            // process sub archive
            File dir := dest.parent.createDir("__${name}")
            extract(dest, dir)
        }
        else
        {
            // "regular" file
            File dest := destFolder + path
            file.copyTo(dest,["overwrite":true])
        }
    }
    zip.close
  }

}

