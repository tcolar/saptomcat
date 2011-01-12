// To change this License template, choose Tools / Templates
// and edit Licenses / FanDefaultLicense.txt
//
// History:
//   12-Jan-2011 thibautc Creation
//

**
** PatchBuilder
**
class PatchBuilder
{
  const Uri scas
  const Uri patches
  const Uri tmp
  const Uri project
  const Uri tomcat
  const Bool needSql

  new make(Installer inst, Bool needSql)
  {
    scas = inst.scaFolder.uri
    patches =  inst.sapPatches.uri
    tmp = inst.tmpFolder.uri
    project = inst.projectFolder.uri
    tomcat = inst.tomcatFolder.uri
    this.needSql = needSql
  }

  Void run()
  {
    srcFolder := File(patches + `src/`)
    srcFolder.walk |file|
    {
      if(file.ext!=null && file.ext.equalsIgnoreCase("txt"))
      {
        Uri uri := file.uri
        if( needSql ||  ! uri.pathStr.contains("com/sap/sql/"))
        {
          javaFile := uri[0..-2] + (uri.basename + ".java").toUri
          javaRelPath := javaFile.relTo(srcFolder.uri)
          found := copyJavaSource(javaRelPath, File(javaFile))
        }
      }
    }
  }

  Bool copyJavaSource(Uri path, File javaFile)
  {
    // First in b2c/b2b sources
    srcPath := project + `src-ref/` + path
    f := File(srcPath)
    if(f.exists)
    {
      f.copyTo(javaFile, ["overwrite":true])
      return true
    }
        
    // Otherwise try to find it in the jars
    pathStr := path.pathStr
    libsFolder := File(tomcat + `sap_libs/`)
    found := false
    libsFolder.listFiles.each |jar|
    {
      if(jar.ext.equalsIgnoreCase("jar"))
      {
        zip := Zip.open(jar)
        zip.contents.each |file, uri|
        {
          if(uri.pathStr.endsWith(pathStr))
          {
            file.copyTo(javaFile, ["overwrite":true])
            found = true
            return // exit the "each""
          }
        }
        zip.close
      }
    }

    // If not found, try to find which jar to decompile:
    classFound := false
    classPathStr := (path[0..-2] + (path.basename + ".class").toUri).pathStr
    libsFolder.listFiles.each |jar|
    {
      if(jar.ext.equalsIgnoreCase("jar"))
      {
        zip := Zip.open(jar)
        zip.contents.each |file, uri|
        {
          if(uri.pathStr.endsWith(classPathStr))
          {
            classFound = true
            echo("WARNING: Source for $path was not found, however the compiled class was found in $jar, you should try decompiling it and saving it under $javaFile.pathStr
                   Hint: 'jd-gui $jar'")
          }
        }
        zip.close
      }
    }
    if(!classFound)
    {
      echo("ERROR: Neither the source not the class was found for $path ... Maybe it's in a different SCA ?
              You can try running 'fan netColarSapWebshop::ArchiveFinder someFolderWithScas ${path.basename}.class' to locate it.")
    }
    return found
  }
}