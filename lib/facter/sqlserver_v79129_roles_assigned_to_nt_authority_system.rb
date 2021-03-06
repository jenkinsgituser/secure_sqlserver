# sqlserver_v79129_roles_assigned_to_nt_authority_system.#!/usr/bin/env ruby -wKU
#
# The 'sqlserver_roles_assigned_to_nt_authority_system' fact returns an array list
# of all server roles assigned to the 'NT AUTHORITY\SYSTEM' user.
# Currently, only returning 'server roles'.
#
# Consider modifying to include all types of roles: 'server roles', 'database roles', and 'application roles'.
#
# Default server roles:
# ['bulkadmin', 'dbcreator', 'diskadmin', 'processadmin', 'public', 'securityadmin', 'serveradmin', 'setupadmin', 'sysadmin']
#
# @return   An array of strings representing roles assigned to the 'NT AUTHORITY\SYSTEM' user.
# @example  ['public', 'sysadmin']
#           ['bulkadmin', 'dbcreator', 'diskadmin', 'processadmin', 'public', 'securityadmin', 'serveradmin', 'setupadmin', 'sysadmin']
#
# Spare code:
# -----------
# config = { admin_login_type: 'WINDOWS_LOGIN', instance_name: 'MSSQLSERVER', database: 'MSSQLSERVER', admin_user: '', admin_pass: '', host: 'localhost' } # lint:ignore:140chars
# config = { admin_login_type: 'WINDOWS_LOGIN', database: 'MSSQLSERVER', host: 'localhost' }
#
require 'sqlserver_client'

Facter.add('sqlserver_v79129_roles_assigned_to_nt_authority_system') do
  confine operatingsystem: :windows
  setcode do

    sql = "SELECT sp1.name as role
             FROM sys.server_role_members srm
        LEFT JOIN sys.server_principals sp1
               ON srm.role_principal_id = sp1.principal_id
  LEFT OUTER JOIN sys.server_principals sp2
               ON srm.member_principal_id = sp2.principal_id
            WHERE sp1.type = 'R'
              AND sp2.name = 'NT AUTHORITY\\SYSTEM'"
              #AND sp2.name = 'JEFF-WIN-SQLSVR\\Administrator'"

    Puppet.debug "sqlserver_v79129_roles_assigned_to_nt_authority_system.rb sql...\n#{sql}"

    client = SqlServerClient.new
    client.open
    client.column(sql)
    resultset = client.data
    client.close unless client.nil? || client.closed?
    resultset
  end
end
