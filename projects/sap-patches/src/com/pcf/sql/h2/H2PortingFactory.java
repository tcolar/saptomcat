/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package com.pcf.sql.h2;

import com.pcf.sql.mysql.*;
import com.sap.sql.jdbc.basic.BasicDbPortingServices;
import com.sap.sql.jdbc.basic.DbPortingFactory;
import com.sap.sql.jdbc.basic.SQLExceptionAnalyzer;
import java.sql.Connection;
import java.sql.SQLException;

/**
 * Implementation to allow SAP to use H2
 * @author thibautc
 */
public class H2PortingFactory implements DbPortingFactory
{

    public boolean isJdbcDriverSupported(Connection connection) throws SQLException
    {
        String driverName = connection.getMetaData().getDriverName();
        return driverName.toUpperCase().startsWith("H2"); 
    }

    public Connection createPortedConnection(Connection connection) throws SQLException
    {
        return connection;
    }

    public BasicDbPortingServices createDbPortingServices(Connection connection) throws SQLException
    {
        return new H2PortingServices(connection);
    }

    public SQLExceptionAnalyzer createSQLExceptionAnalyzer(Connection connection) throws SQLException
    {
        return new H2ExceptionAnalyzer(connection);
    }

    
}
