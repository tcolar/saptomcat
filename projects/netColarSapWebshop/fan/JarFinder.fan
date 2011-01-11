
**
** Generic helper to try to find a specific class/resource given a folder of jars/sca's etc...
** Pretty useful to find a solution(jar) for a ClassNotFoundException
**
class ArchiveFinder
{
  ** Find a file within jars/sca's (and print out it's path if found)
  ** For example : something.class
  static Void findFile(File archiveFolder, Str fileName)
  {
    Func func := |File file, Str path|
    {
      Zip zip := Zip.read(file.in)
      File? f
      while ((f = zip.readNext()) != null)
      {
        if(fileName.lower.equals(f.name.lower))
          echo("Found : $path -> $f.pathStr")
      }
      zip.close
    }
    finder := ArchiveLookup {findFunc = func; listExtensions = null}
    finder.scan(archiveFolder)
  }

  ** Search recursively in a folder of java libraries (jars, sca's etc..) for a given resource
  ** Example of use:
  ** fan netColarSapWebshop::ClassFinder  /home/thibautc/java_libs/  AuctionBusinessObjectManager.class
  static Void main(Str[] args)
  {
    if(args.size < 2)
      echo("expecting two args")
    else
      findFile(File(Uri(args[0])), args[1])
  }
}

**
** Dump all the files found in an archive (recursively)
**
class ZipDumper
{
  Void main()
  {
    args := Env.cur.args
    if(args.size==0)
    {
      echo("Need a folder uri as an argument.")
      Env.cur.exit(-1)
    }
    File dir := File(args[0].toUri)
    ArchiveLookup{listExtensions = null}.scan(dir)
  }
}

** Generic zip lookup class
** Recursively dig through zipped archives (zip within zips)
** And return files of interest
** By default search jar files
class ArchiveLookup
{
  // which files are 'zips'
  Str[] unzipExtensions := ["sca","sda","ppa","zip","war"]
  // which files to list (files we are looking for) - Null means all
  Str[]? listExtensions:= ["jar"]
  // Replace to do something more useful with results
  Func findFunc := |File f, Str path ->Void| {echo("$path")}

  Void scan(File f, Str path:="")
  {
    fl:="${path}/${f.pathStr}"
    if(f.isDir)
    {
      f.list.each {scan(it, path)}
    }
    else
    {
      ext := f.ext?.lower
      if(ext!=null && (listExtensions==null || listExtensions.contains(ext)))
        findFunc.call(f, fl)

      if(ext!=null && unzipExtensions.contains(ext))
      {
        Zip zip := Zip.read(f.in)
        File? file
        while ((file = zip.readNext()) != null)
        {
          scan(file, "${path}${f.pathStr}")
        }
        zip.close
      }
    }
  }

  // testing: prints found items in given folder
  Void main()
  {
    args := Env.cur.args
    if(args.size==0)
    {
      echo("Need a folder uri as an argument.")
      Env.cur.exit(-1)
    }
    File dir := File(args[0].toUri)
    scan(dir)
  }
}
