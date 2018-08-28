# sqlserver_encryption_is_master_key_encrypted_by_server.rb
#
# @return   true/false
#
# Dependencies:
# v79087
#
require 'sqlserver_client'

Facter.add('sqlserver_encryption_is_master_key_encrypted_by_server') do
  confine operatingsystem: :windows
  setcode do

    # Note:
    # The query below assumes that the [sa] account is not used as the owner of application databases,
    # in keeping with other STIG guidance. If this is not the case, modify the query accordingly.
    # I don't want to exclude the [sa] account so I removed the condition:
    # "AND owner_sid <> 1"
    sql = "SELECT name FROM [master].sys.databases WHERE is_master_key_encrypted_by_server = 1 AND state = 0"

    Puppet.debug "sqlserver_encryption_is_master_key_encrypted_by_server.rb sql...\n#{sql}"

    client = SqlServerClient.new
    client.open
    client.column(sql)
    resultset = client.data
    client.close unless client.nil? || client.closed?
    resultset

  end
end