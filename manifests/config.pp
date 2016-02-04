# == Class aws_nat_failover::config
#
# This class is called from aws_nat_failover for service config.
#
class aws_nat_failover::config (

  $region        = $::aws_nat_failover::params::region,
  $tag_key       = $::aws_nat_failover::params::tag_key,
  $tag_value     = $::aws_nat_failover::params::tag_value,

) inherits ::aws_nat_failover::params {

  file { "/usr/lib/systemd/system/aws_nat_failover.service":
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('aws_nat_failover/aws_nat_failover.service.erb')
  }


}
