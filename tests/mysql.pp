class { 'snmptt':
  unknown_trap_log_enable => true,
  syslog_enable           => false,
  enable_mysql            => true,
  mysql_password          => 'somethingideclared',
}
