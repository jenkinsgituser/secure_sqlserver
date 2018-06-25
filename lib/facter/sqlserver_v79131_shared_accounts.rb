# sqlserver_v79131_shared_accounts.rb
# SQL Server must protect against a user falsely repudiating by ensuring only
# clearly unique Active Directory user accounts can connect to the instance.
#
# Design and implementation also must ensure that applications pass
# individual user identification to the DBMS, even where the application connects
# to the DBMS with a standard, shared account.
#
# If the computer account of a remote computer is granted access to SQL Server,
# any service or scheduled task running as NT AUTHORITY\SYSTEM or NT AUTHORITY\NETWORK SERVICE
# can log into the instance and perform actions. These actions cannot be
# traced back to a specific user or process.
#
# Type Description
# ---- ------------------------
# C    CERTIFICATE_MAPPED_LOGIN
# R    SERVER_ROLE
# S    SQL_LOGIN
# U    WINDOWS_LOGIN
# G    GROUP
#
# @return   An array of strings representing shared accounts.
# @example  ['some_user$','another_user$']
#
require 'sqlserver_client'

Facter.add('sqlserver_v79131_shared_accounts') do
  confine operatingsystem: :windows
  setcode do

    sql = "SELECT name
          FROM sys.server_principals
          WHERE type in ('U','G')
          AND name LIKE '%$'"



    Puppet.debug "sqlserver_roles_assigned_to_nt_authority_system.rb sql...\n#{sql}"

    client = SqlServerClient.new
    client.open
    client.simple_array(sql)
    # An ADO Recordset's GetRows method returns an array
    # of columns, so we'll use the transpose method to
    # convert it to an array of rows
    resultset = client.data
    client.close unless client.nil? || client.closed?
    resultset
  end
end
