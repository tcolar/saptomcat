// To change this License template, choose Tools / Templates
// and edit Licenses / FanDefaultLicense.txt
//
// History:
//   Oct 7, 2010  tcolar  Creation
//
using build

**
** Build: netColarSapWebshop
**
class Build : BuildPod
{
  new make()
  {
    podName = "netColarSapWebshop"
	summary = "netColarSapWebshop"
    depends = ["sys 1.0", "xml 1.0"]
    srcDirs = [`fan/`, `test/`]
  }
}
