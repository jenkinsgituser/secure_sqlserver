# secure_database.pp
#
# This class calls all classes that secure a MS SQL Server 2016 database.
#
# The table below displays which vulnerabilites are addressed,
# which are delayed until version 2, and which ones had to be omitted
# because the requirements were vague or too broad.
#
#         Version 1 |	Version 2	| Omitted |
# ------------------+-----------+---------+
# V-79061	    X     |           |         |
# V-79065		        |     X     |         |
# V-79067	    X     |           |         |
# V-79069	    X     |           |         |
# V-79071	    X     |           |         |
# V-79073	    X     |           |         |
# V-79075	    X     |           |         |
# V-79077	    X     |           |         |
# V-79079	   	      |     X     |         |
# V-79081	    X     |           |         |
# V-79083	    X     |           |         |
# V-79085	    X     |           |         |
# V-79087	    X     |           |         |
# V-79089	    X     |           |         |
# V-79091	          |           |    X    |
# V-79093			      |           |    X    |
# V-79095			      |           |    X    |
# V-79097			      |           |    X    |
# V-79099			      |           |    X    |
# V-79101			      |           |    X    |
# V-79103			      |           |    X    |
# V-79105		        |     X     |         |
# V-79107		        |     X     |         |
# V-79109	    X     |           |         |
# V-79111	    X     |           |         |
# V-79113	    X     |           |         |
# V-79115	    X     |           |         |
# V-79117		        |           |    X    | (Duplicate of V-79115)
#
define secure_sqlserver::secure_database (
  Array         $approved_shared_accounts,
  Array         $approved_sql_login_users,
  String        $audit_filepath,
  Hash          $audit_maintainer_username,
  Hash          $backup_plan,
  Hash          $backup_recovery_model_settings,
  Hash          $certificate_backup,
  String        $db_master_key_encryption_password,
  Hash          $new_database_owner,
  Hash          $schema_owners,
  Hash          $temporal_tables,
  Hash          $transparent_data_encryption,
  String[1,128] $database,
  String[1,16]  $instance = 'MSSQLSERVER',
) {
  # Database-level Vulnerabilities...

  # Calling define types over classes,
  # since the module must invoke each vulnerability more than once
  # (once for every database in an instance).

  $prefix = "${instance}\\${database}"

  notify { "${prefix}_secure_database_output" :
    message  => "Applying DoD hardening to instance\\database: ${prefix}",
    loglevel => info,
  }

  ::secure_sqlserver::stig::v79061 { "${prefix}-v79061":
    approved_sql_login_users => $approved_sql_login_users,
    database                 => $database,
    instance                 => $instance,
    enforced                 => lookup('secure_sqlserver::stig::v79061::enforced'),
  }

  ::secure_sqlserver::stig::v79067 { "${prefix}-v79067":
    approved_shared_accounts => $approved_shared_accounts,
    database                 => $database,
    instance                 => $instance,
    enforced                 => lookup('secure_sqlserver::stig::v79067::enforced'),
  }

  ::secure_sqlserver::stig::v79069 { "${prefix}-v79069":
    temporal_tables => $temporal_tables,
    database        => $database,
    instance        => $instance,
    enforced        => lookup('secure_sqlserver::stig::v79069::enforced'),
  }

  ::secure_sqlserver::stig::v79071 { "${prefix}-v79071":
    database => $database,
    instance => $instance,
    enforced => lookup('secure_sqlserver::stig::v79071::enforced'),
  }

  ::secure_sqlserver::stig::v79073 { "${prefix}-v79073":
    audit_maintainer_username => $audit_maintainer_username,
    database                  => $database,
    instance                  => $instance,
    enforced                  => lookup('secure_sqlserver::stig::v79073::enforced'),
  }

  ::secure_sqlserver::stig::v79075 { "${prefix}-v79075":
    database => $database,
    instance => $instance,
    enforced => lookup('secure_sqlserver::stig::v79075::enforced'),
  }

  ::secure_sqlserver::stig::v79077 { "${prefix}-v79077":
    schema_owners => $schema_owners,
    database      => $database,
    instance      => $instance,
    enforced      => lookup('secure_sqlserver::stig::v79077::enforced'),
  }

  ::secure_sqlserver::stig::v79081 { "${prefix}-v79081":
    database => $database,
    instance => $instance,
    enforced => lookup('secure_sqlserver::stig::v79081::enforced'),
    }

  ::secure_sqlserver::stig::v79083 { "${prefix}-v79083":
    backup_plan                    => $backup_plan,
    backup_recovery_model_settings => $backup_recovery_model_settings,
    database                       => $database,
    instance                       => $instance,
    enforced                       => lookup('secure_sqlserver::stig::v79083::enforced'),
  }

  ::secure_sqlserver::stig::v79085 { "${prefix}-v79085":
    db_master_key_encryption_password => $db_master_key_encryption_password,
    database                          => $database,
    instance                          => $instance,
    enforced                          => lookup('secure_sqlserver::stig::v79085::enforced'),
  }

  ::secure_sqlserver::stig::v79087 { "${prefix}-v79087":
    audit_filepath => $audit_filepath,
    database       => $database,
    instance       => $instance,
    enforced       => lookup('secure_sqlserver::stig::v79087::enforced'),
  }

  ::secure_sqlserver::stig::v79089 { "${prefix}-v79089":
    certificate_backup => $certificate_backup,
    database           => $database,
    instance           => $instance,
    enforced           => lookup('secure_sqlserver::stig::v79089::enforced'),
  }

  ::secure_sqlserver::stig::v79111 { "${prefix}-v79111":
    new_database_owner => $new_database_owner,
    database           => $database,
    instance           => $instance,
    enforced           => lookup('secure_sqlserver::stig::v79111::enforced'),
  }

  ::secure_sqlserver::stig::v79113 { "${prefix}-v79113":
    transparent_data_encryption => $transparent_data_encryption,
    database                    => $database,
    instance                    => $instance,
    enforced                    => lookup('secure_sqlserver::stig::v79113::enforced'),
  }
}
