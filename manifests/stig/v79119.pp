# This class manages DISA STIG vulnerability: V-79119
# SQL Server must limit the number of concurrent sessions to an organization-defined
# number per user for all accounts and/or account types.
#
class secure_sqlserver::stig::v79119 (
  Boolean $enforced = false,
  String  $instance = 'MSSQLSERVER',
) {
  if $enforced {
    # Make sure to use the renamed SA account here.
    $sa = 'sa'
    $trigger_name = 'STIG_TRIGGER_V79119_SESSIONLIMIT'
    $connection_limit = 1000
    $sql_check = "IF (SELECT COUNT(*) FROM master.sys.server_triggers WHERE name='${trigger_name}') = 0 THROW 50000, 'Missing STIG Trigger for V-79119.', 10"# lint:ignore:140chars
    $sql_trigger = "CREATE TRIGGER ${trigger_name}
      ON ALL SERVER WITH EXECUTE AS '${sa}'
      FOR LOGON
      AS
      BEGIN
      IF (SELECT COUNT(1)
      FROM sys.dm_exec_sessions
      WHERE is_user_process = 1
      And original_login_name = ORIGINAL_LOGIN()
      ) > ${connection_limit}
      BEGIN
      PRINT 'The login [' + ORIGINAL_LOGIN() + '] has exceeded the concurrent session limit.'
      ROLLBACK;
      END
      END;"

    sqlserver_tsql{ 'v79119-create-logon-trigger-to-limit-concurrent-sessions':
      instance => $instance,
      command  => $sql_trigger,
      onlyif   => $sql_check,
      require  => Sqlserver::Config[$instance],
    }
  }
}
