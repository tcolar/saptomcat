// To change this License template, choose Tools / Templates
// and edit Licenses / FanDefaultLicense.txt
//
// History:
//   Oct 8, 2010 tcolar Creation
//

**
** Dependencies
** Find dependencies(jars) needed by sap webshop project
**
class Dependencies
{
  const Uri root
  const Uri scas

  const Str:Uri pathMap := ["application.lst":`lib/references/application/`,
        "extra.lst":`lib/extras/server/`, // SISU Doc ommited 'server''
        "interface.lst":`lib/references/interface/`,
        "library.lst":`lib/references/library/ `,
        "services.lst":`lib/references/service/`,
        "war.lst":`war/`,
  ]

  new make(Uri webShopRoot, Uri scaFolder)
  {
    root = webShopRoot
    scas = scaFolder
  }

  Void run()
  {
    // cleanup previous runs extractions
    File(scas).listDirs.each
    {
      if(it.name.startsWith("__"))
          it.delete
    }
    echo("Finding dependencies")
    finder := SapJarFinder(File(scas))
    //finder.jars.each {echo("... $it")}
    File depsFolder := File(root) + `etc/dependencies/sap/`
    depsFolder.listFiles.each
    {
      processDep(finder.jars, it)
    }
  }

  Void copyDep(Str path, File dest)
  {
    Uri uri := path.toUri
    //echo("path: $uri")
    extracted := `./`
    uri.path.each
    {
      //echo("pathit: $extracted    $it")
      ext := it.toUri.ext
      if(ext!=null && ZipFinder.unzipExtensions.contains(ext.lower))
        {
        archive := extracted.plusSlash.plusName(it)
        //echo("ar: $archive")
        zip := Zip.open(File(archive))
        extracted = extracted.plusSlash.plusName("__${it}", true)
        if(! File(extracted).exists)
          {
          zip.contents.each |file, zuri|
          {
            File f := File(extracted + file.pathStr[1..-1].toUri)
            //echo("\tExtracting SCA contents: $uri -> $dest")
            file.copyTo(f,["overwrite":true])
          }
          zip.close
        }
      }
      else
        {
        extracted = extracted.plusSlash.plusName(it)
      }
    }
    //echo("Copying: $extracted to $dest")
    File(extracted).copyTo(dest,["overwrite":true])
  }

  Void processDep(Str[] allJars, File f)
  {
    dest := pathMap[f.name.lower]
    if(f.ext.lower.equals("lst") && dest!=null)
      {
      f.eachLine
      {
        sapName := it
        if(it.endsWith("/**/*.jar"))
          {
          idx := it.indexr("/",-10) + 1
          // sometimes SAP ends the name with .sda (usually not)
          sda := it[idx..-10]
          if(! sda.endsWith(".sda")) sda += ".sda"
          jars := allJars.findAll |Str jar -> Bool| {return jar.contains(sda)}
          if(jars.isEmpty)
          // Seems like SAP sometimes have the path with '_' instead of '~'
          jars = allJars.findAll |Str jar -> Bool| {return jar.contains(sda.replace("~","_"))}
          if(jars.isEmpty)
          // try yet another format
          jars = allJars.findAll |Str jar -> Bool| {return jar.contains(sda.replace(".sda","~dcia.zip"))}
          if(jars.isEmpty)
          echo("##### WARNING: NO SDA ENTRIES FOUND FOR: $sda #####")
          //else
          //  echo("Added $jars.size jars for $sda")
                  
          jars.each
          {
            //echo("jar: $it")
            jar := it[(it.indexr("/",-1)+1)..-1]
            name := sapName[idx..-10]+"/"
            File destFile := File(root+dest)+name.toUri+jar.toUri
            copyDep(it, destFile)
          }
            
        }
      }

    }
  }
}