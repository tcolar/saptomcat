/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package com.pcf.sql.mysql;

import com.sap.sql.jdbc.basic.BasicDbPortingServices;
import com.sap.sql.jdbc.basic.DbPortingFactory;
import com.sap.sql.jdbc.basic.SQLExceptionAnalyzer;
import java.sql.Connection;
import java.sql.SQLException;

/**
 * Implementation to allow SAP to use MySql
 * @author thibautc
 */
public class MysqlPortingFactory implements DbPortingFactory
{

    public boolean isJdbcDriverSupported(Connection connection) throws SQLException
    {
        String driverName = connection.getMetaData().getDriverName();
        return driverName.toUpperCase().startsWith("MYSQL"); //MySql-AB-JDBC....
    }

    public Connection createPortedConnection(Connection connection) throws SQLException
    {
        return connection;
    }

    public BasicDbPortingServices createDbPortingServices(Connection connection) throws SQLException
    {
        return new MysqlPortingServices(connection);
    }

    public SQLExceptionAnalyzer createSQLExceptionAnalyzer(Connection connection) throws SQLException
    {
        return new MysqlExceptionAnalyzer(connection);
    }

    
}
