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
# [*net_snmp_perl_enable*]
#   Enable the use of the Perl module from the UCD-SNMP / NET-SNMP package.
#   Default: false
#
# [*description_mode*]
#   allows you to use the $D substitution variable to include the
#   description text from the SNMPTT.CONF or MIB files.
#   Default: false
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
  Enum['present', 'absent'] $ensure = 'present',
  Boolean $service_enable           = true,
  Boolean $multiple_event           = true,
  Boolean $dns_enable               = false,
  Boolean $strip_domain             = false,
  Array $strip_domain_list          = [],
  Boolean $log_enable               = true,
  Boolean $log_system_enable        = false,
  Boolean $unknown_trap_log_enable  = false,
  Boolean $syslog_enable            = true,
  Boolean $enable_mysql             = false,
  String $mysql_host                = 'localhost',
  Integer $mysql_port               = 3306,
  String $mysql_dbname              = 'snmptt',
  String $mysql_username            = 'snmpttuser',
  String $mysql_password            = 'UNSET',
  Array $trap_files                 = ['/etc/snmp/snmptt.conf'],
  Boolean $net_snmp_perl_enable     = false,
  Boolean $description_mode         = false,
) {

  $real_multiple_event          = bool2num($multiple_event)
  $real_dns_enable              = bool2num($dns_enable)
  $real_strip_domain            = bool2num($strip_domain)
  $real_log_enable              = bool2num($log_enable)
  $real_log_system_enable       = bool2num($log_system_enable)
  $real_unknown_trap_log_enable = bool2num($unknown_trap_log_enable)
  $real_syslog_enable           = bool2num($syslog_enable)
  $real_net_snmp_perl_enable    = bool2num($net_snmp_perl_enable)
  $real_description_mode        = bool2num($description_mode)

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
