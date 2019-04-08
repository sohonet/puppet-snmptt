class snmptt::service() {

  # Not tested on RedHat or CentOS. Keep original init script
  case $facts['os']['family'] {
    'RedHat': {
      service { 'snmptt':
        ensure    => $snmptt::service_enable,
        enable    => $snmptt::service_enable,
        hasstatus => false,
        pattern   => '/usr/sbin/snmptt',
      }
    }
    default: {
      file { '/etc/init.d/snmptt':
        ensure => absent
      }
      file { '/etc/systemd/system/snmptt.service':
        ensure => present,
        source => 'puppet:///modules/snmptt/snmptt.service',
      }
      ~> exec { 'snmptt systemd reload':
        command     => '/bin/systemctl daemon-reload',
        refreshonly => true,
      }
      -> service { 'snmptt':
        ensure => $snmptt::service_enable,
        enable => $snmptt::service_enable,
      }
    }
  }

}