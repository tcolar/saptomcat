/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package com.pcf.sql.h2;

import com.pcf.sql.mysql.*;
import com.sap.sql.jdbc.basic.AbstractSQLExceptionAnalyzer;
import java.sql.Connection;
import java.sql.SQLException;

/**
 * Implementation to allow SAP to use H2
 * @author thibautc
 */
class H2ExceptionAnalyzer extends AbstractSQLExceptionAnalyzer
{

    public H2ExceptionAnalyzer(Connection connection)
    {
        super(connection);
        this.vendorName = "H2";
    }

    public int getCategory(SQLException sqle)
    {
        return ILLEGAL_CATEGORY;
    }
}
