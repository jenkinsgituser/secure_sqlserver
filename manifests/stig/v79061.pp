# This class manages DISA STIG vulnerability: V-79061
# SQL Server databases must integrate with an organization-level authentication/access mechanism
# providing account management and automation for all users, groups, roles, and any other principals.
#
# Similar to v79121
#
# *** RESTART REQ'D ***
#
class secure_sqlserver::stig::v79061 (
  Boolean       $enforced = false,
  String[1,16]  $instance = 'MSSQLSERVER',
  String        $database,
) {

  if $enforced {

    # Disable Contained Databases...
    if !$facts['sqlserver_enabled_contained_databases'] {
      ::secure_sqlserver::log { "Contained databases is enabled.  This is a finding per vulnerability V-79061.":
        loglevel => warning,
      }
    }

    if $facts['sqlserver_authentication_mode'] != 'Windows Authentication' {
      # Use Windows Authentication...
      # set login mode to Windows authentication (not SQL Server authentication)
      # this requires a restart to take effect...
      registry::value { 'v79061':
        key   => 'HKEY_LOCAL_MACHINE\Software\Microsoft\MSSQLServer\MSSQLServer',
        value => 'LoginMode',
        type  => 'dword',
        data  => '0x00000002',
      }
      # reboot
    }

    $facts['sqlserver_sql_authenticated_users'].each |String $sql_login| {
      unless $sql_login in ['dbo', 'public', 'sa'] {
        $sql_dcl = "USE ${database}; DROP USER '${sql_login}';"

        ::secure_sqlserver::log { "v79061_sql_dcl = \n${sql_dcl}": }

        sqlserver_tsql{ "drop_user_${database}_${username}":
          instance => $instance,
          command  => $sql_dcl,
          require  => Sqlserver::Config[$instance],
        }
      }
    }

  }

}