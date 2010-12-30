/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package com.pcf.sql.mysql;

import com.sap.sql.jdbc.basic.AbstractSQLExceptionAnalyzer;
import java.sql.Connection;
import java.sql.SQLException;

/**
 * Implementation to allow SAP to use MySql
 * @author thibautc
 */
class MysqlExceptionAnalyzer extends AbstractSQLExceptionAnalyzer
{

    public MysqlExceptionAnalyzer(Connection connection)
    {
        super(connection);
        this.vendorName = "MYSQL";
    }

    public int getCategory(SQLException sqle)
    {
        return ILLEGAL_CATEGORY;
    }
}
