// To change this License template, choose Tools / Templates
// and edit Licenses / FanDefaultLicense.txt
//
// History:
//   28-Dec-2010 thibautc Creation
//
using xml

**
** SapCrmDicToSql
** Takes a SAPCRMDIC SCA and try to find the DB table schemas (in gdbtable format) ...
** ... and try to convert that into a standrad SQL script.
**
** Note: gdbtable is an undocumented SAP format, so this conversion is a hack and only the minimum required
** was implemented and this might break/need to be uopdated with further SAPCRMDIC releases
** Made to work on MySQL, might need modifs for other db's
**
** Example: fan netColarSapWebshop::SapCrmDicToSql /tmp/SAPCRMDIC12_0-10002941.SCA > dic.sql
**
class SapCrmDicToSql
{
  Void processDic(Str dic)
  {
    file := File(Uri(dic))

    func := |File f, Str path -> Void|
    {
      processGdbTable(f)
    }

    // Find all gdbtbale files and process them
    ZipFinder
    {
      it.listExtensions = ["gdbtable"]
      it.findFunc = func
    }.scan(file)
  }

  Void processGdbTable(File f)
  {
    root := XParser(f.in).parseDoc(true).root
    if(root.name == "Dbtable")
    {
      tableName := root.get("name");
      [Int:GdbTableMeta] columns := [:] {ordered = true}

      Str? pkey := root.elem("primary-key", false)?.elem("columns", false)?.elem("column", false)?.text?.toStr

      root.elems.each |elem, int|
      {
        if(elem.name == "columns")
        {
          elem.elems.each |elem2, int2|
          {
            if(elem2.name == "column")
            {
              pos := elem2.elem("position").text.toStr
              type := elem2.elem("java-sql-type").text.toStr
              if (type.equalsIgnoreCase("varchar"))
              {
                  type += "("+elem2.elem("length").text.toStr+")"
              }
              // no clob in mysql
              if (type.equalsIgnoreCase("clob"))
              {
                  type = "LONGTEXT"
              }
              // no longvarchar in mysql
              if (type.equalsIgnoreCase("longvarchar"))
              {
                  type = "LONGTEXT"
              }

              meta := GdbTableMeta
              {
                name = elem2.get("name")
                it.type = type
                it.notNull = elem2.elem("is-not-null").text.toStr.equalsIgnoreCase("true")
                it.isPkey = pkey!=null && name.equalsIgnoreCase(pkey)
              }
              columns.add(Int(pos), meta)
            }
          }
        }
      }
      
      Str cols := ""
      columns.each
      {
        if( ! cols.isEmpty)
          cols += ", "
        cols += "`$it.name` $it.type"
        if(it.notNull)
            cols += " NOT NULL"
        if(it.isPkey)
            cols += " PRIMARY KEY"
      }
      echo("CREATE TABLE $tableName ($cols);")

    }

  }

  Void main()
  {
    args := Env.cur.args
    if(args.size==0)
    {
      echo("Need the path to the CRM Dictionary SDA file as an argument")
      Env.cur.exit(-1)
    }
    processDic(args[0])
  }

}

class GdbTableMeta
{
  Str name := ""
  Str type := ""
  Bool isPkey := false
  Bool notNull := false
}
