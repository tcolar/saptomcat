/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package net.colar.j2eeSapUtils;

import java.io.File;
import java.util.Properties;
import java.util.Vector;
import java.util.jar.JarFile;
import org.apache.catalina.LifecycleException;
import org.apache.catalina.loader.WebappClassLoader;

/**
 * Adds custom patched jars in sap_local_libs such as they take precedence over the ones in WEB-INF/lib of webapp
 * @author thibautc
 */
public class TomcatClassLoader extends WebappClassLoader {
    File patchedLibFolder;

    public TomcatClassLoader(ClassLoader parent) {
        super(parent);
        Properties props=System.getProperties();
        String catHome = props.getProperty("catalina.home");
        if(catHome == null)
        {
            throw(new RuntimeException("catalina.home property not found - Not running tomcat ???"));
        }
            else
        {
            patchedLibFolder = new File(props.getProperty("catalina.home")+File.separator+"sap_libs_local");
            System.err.println("Tomcat CL(p) started: ");
            initPatchLoader();
        }
    }

    private void initPatchLoader() {
        Vector v = new Vector();
        File[] files = patchedLibFolder.listFiles();
        for (int i = 0; i != files.length; i++) {
            File f = files[i];
            if (f.isFile() && f.getName().endsWith(".jar")) {
                try {
                    addJar(f.getAbsolutePath(), new JarFile(f), f);
                } catch (Exception e) {
                    e.printStackTrace();
                }
            }
        }
    }

    @Override
    public Class loadClass(String name) throws ClassNotFoundException {
        Class clazz =null;
        try
        {
            clazz = super.loadClass(name);
        }catch(ClassNotFoundException e)
        {
            throw(e);
        }
        return clazz;
    }


    @Override
    public void start() throws LifecycleException {
        super.start();
    }

    @Override
    public void setWorkDir(File workDir) {
        super.setWorkDir(workDir);
    }

    void addJar(String jar, JarFile jarFile, File file) {
        int i;

        if ((jarPath != null) && (jar.startsWith(jarPath))) {

            String jarName = jar.substring(jarPath.length());
            while (jarName.startsWith("/")) {
                jarName = jarName.substring(1);
            }

            String[] result = new String[jarNames.length + 1];
            for (i = 0; i < jarNames.length; i++) {
                result[i] = jarNames[i];
            }
            result[jarNames.length] = jarName;
            jarNames = result;

        }
            // Register the JAR for tracking
            long lastModified = file.lastModified();

            String[] result = new String[paths.length + 1];
            for (i = 0; i < paths.length; i++) {
                result[i] = paths[i];
            }
            result[paths.length] = jar;
            paths = result;

            long[] result3 = new long[lastModifiedDates.length + 1];
            for (i = 0; i < lastModifiedDates.length; i++) {
                result3[i] = lastModifiedDates[i];
            }
            result3[lastModifiedDates.length] = lastModified;
            lastModifiedDates = result3;

        JarFile[] result2 = new JarFile[jarFiles.length + 1];
        for (i = 0; i < jarFiles.length; i++) {
            result2[i] = jarFiles[i];
        }
        result2[jarFiles.length] = jarFile;
        jarFiles = result2;

        // Add the file to the list
        File[] result4 = new File[jarRealFiles.length + 1];
        for (i = 0; i < jarRealFiles.length; i++) {
            result4[i] = jarRealFiles[i];
        }
        result4[jarRealFiles.length] = file;
        jarRealFiles = result4;
    }

}
