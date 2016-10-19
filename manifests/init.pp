# == Class: snmptt
#
# Installs snmptt and can optionally be configured to enable mysql support.
#
# === Parameters
#
# [*ensure*]
#   Present or absent.
#
# [*service_enable*]
#   Boolean. If true will run SNMPTT in daemon mode. See standard vs. embedded
#   handlers at http://snmptt.sourceforge.net/docs/snmptt.shtml
#
# [*strip_domain*]
# Set to 1 to have SNMPTT strip the domain name from the host name passed to it.  For
# example, server01.domain.com would be changed to server01.
# Set to 2 to have SNMPTT strip the domain name from the host name passed to it
# based on the list of domains in strip_domain_list
#
# [*strip_domain_list*]
# Array. List of domain names that should be stripped when strip_domain is set to 2.
#
# [*enable_mysql*]
# Boolean. Set to true to enable mysql support in SNMPTT. This will also create
# a mysql database with the correct permissions and schema.
#
# [*mysql_host*]
# Mysql server hostname (Defaults to localhost).
#
# [*mysql_port*]
# Defaults to 3306.
#
# [*mysql_dbname*]
# Defaults to snmptt.
#
# [*mysql_username*]
# Defaults to snmpttuser.
#
# [*mysql_password*]
# If not value is set a random password
# will be generated.
#
# [*trap_files*]
# Array of snmptt.conf files. The COMPLETE path and filename.
# Example: ['/etc/snmp/snmptt.conf', '/etc/snmp/snmptt.conf.device']
#
# === Examples
#
# See tests folder.
#
# === Authors
#
# Scott Barr <gsbarr@gmail.com>
#
class snmptt (
  $ensure                  = 'present',
  $service_enable          = true,
  $multiple_event          = true,
  $dns_enable              = false,
  $strip_domain            = false,
  $strip_domain_list       = [],
  $log_enable              = true,
  $log_system_enable       = false,
  $unknown_trap_log_enable = false,
  $syslog_enable           = true,
  $enable_mysql            = false,
  $mysql_host              = 'localhost',
  $mysql_port              = '3306',
  $mysql_dbname            = 'snmptt',
  $mysql_username          = 'snmpttuser',
  $mysql_password          = 'UNSET',
  $trap_files              = ['/etc/snmp/snmptt.conf'],
) {
  validate_re($ensure, '^(present|absent)$',
  'ensure parameter must have a value of: present or absent')

  validate_bool($enable_mysql)
  validate_bool($service_enable)

  $real_multiple_event          = bool2num($multiple_event)
  $real_dns_enable              = bool2num($dns_enable)
  $real_strip_domain            = bool2num($strip_domain)
  $real_log_enable              = bool2num($log_enable)
  $real_log_system_enable       = bool2num($log_system_enable)
  $real_unknown_trap_log_enable = bool2num($unknown_trap_log_enable)
  $real_syslog_enable           = bool2num($syslog_enable)

  package { 'snmptt':
    ensure => $ensure,
  }

  File {
    ensure  => $ensure,
    require => Package['snmptt'],
  }

  if $enable_mysql {
    $real_mysql_password = $mysql_password ? {
      'UNSET' => sha1("${::uniqueid}hjny89%_ewd"),
      default => $mysql_password,
    }

    file { '/etc/snmp/snmptt.sql':
      content => template('snmptt/sql_schema.erb'),
    }

    mysql::db { $mysql_dbname:
      ensure   => $ensure,
      user     => $mysql_username,
      password => $real_mysql_password,
      host     => $mysql_host,
      grant    => ['SELECT','INSERT','UPDATE','DELETE','LOCK TABLES'],
    }
    exec { 'snmptt_dbimport':
      command   => "mysql --defaults-file=${::root_home}/.my.cnf ${mysql_dbname} < /etc/snmp/snmptt.sql",
      unless    => "mysql --defaults-file=${::root_home}/.my.cnf ${mysql_dbname} -Be \"SHOW TABLES LIKE 'snmptt'\" | grep '^snmptt'",
      logoutput => true,
      path      => '/usr/bin:/bin:/usr/local/bin',
      require   => [ Mysql::Db[$mysql_dbname], File['/etc/snmp/snmptt.sql'] ],
      notify    => Service['snmptt'],
    }
  }
  else {
    $real_mysql_password = ''
  }

  file { '/etc/snmp/snmptt.ini':
    content => template('snmptt/snmptt_ini.erb'),
    notify  => Service['snmptt'],
  }

  service { 'snmptt':
    ensure    => $service_enable,
    enable    => $service_enable,
    hasstatus => false,
    pattern   => '/usr/sbin/snmptt',
  }
}
