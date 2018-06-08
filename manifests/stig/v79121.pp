# This class manages DISA STIG vulnerability: V-79121
# *** RESTART REQ'D ***
# SQL Server must integrate with an organization-level authentication/access mechanism
# providing account management and automation for all users, groups, roles, and any other principals.
#
class secure_sqlserver::stig::v79121 (
  Boolean $enforced = false,
) {

  # this requires a restart to take effect...
  registry::value { 'v79121':
    key   => 'HKEY_LOCAL_MACHINE\Software\Microsoft\MSSQLServer\MSSQLServer',
    value => 'LoginMode',
    type  => 'dword',
    data  => '0x00000002',
  }

}