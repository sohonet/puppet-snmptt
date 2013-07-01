# == Define: snmptt::setting
#
# Set the various ini directives in the SNMPTT file.
#
# === Parameters
#
# [*ensure*]
#   Present or absent
#
# [*section*]
#   Ini section in which to apply the setting = value pair. Accepted
#   values are General, DaemonMode, Logging, SQL, Exec and Debugging.
#
# [*sname*]
#   Setting name.
#
# [*svalue*]
#   Setting value.
#
# === Examples
#
# See the tests folder.
#
# === Authors
#
# Scott Barr <gsbarr@gmail.com>
#
define snmptt::setting (
  $ensure   = 'present',
  $section  = undef,
  $sname    = undef,
  $svalue   = undef,
) {
  require snmptt

  validate_re($ensure, '^(present|absent)$',
  'ensure parameter must have a value of: present or absent')

  validate_re($section, '^(General|DaemonMode|Logging|SQL|Exec|Debugging|TrapFiles)$',
  "Section '${section}' is not recognised as a valid value for the snmptt.ini file.")

  if $svalue == undef {
    fail('svalue parameter requires a value')
  }

  $sanitized_name = regsubst($name, '[^a-zA-Z0-9\-_]', '_', 'G')

  $real_sname = $sname ? {
    undef   => $name,
    default => $sname,
  }

  #ini_setting { "snmptt_ini_${sanitized_name}":
  #  ensure  => $ensure,
  #  path    => '/etc/snmp/snmptt.ini',
  #  section => $section,
  #  setting => $real_sname,
  #  value   => $svalue,
  #}
  snmptt_config { "snmptt_ini_${sanitized_name}":
    ensure  => $ensure,
    section => $section,
    setting => $real_sname,
    value   => $svalue,
  }
}
