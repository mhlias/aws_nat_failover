# == Class: aws_nat_failover
#
# Full description of class aws_nat_failover here.
#
# === Parameters
#
# [*sample_parameter*]
#   Explanation of what this parameter affects and what it defaults to.

class aws_nat_failover (

  $region    = $::aws_nat_failover::params::region,
  $tag_key   = $::aws_nat_failover::params::tag_key,
  $tag_value = $::aws_nat_failover::params::tag_value,

) inherits ::aws_nat_failover::params {

  # validate parameters here
  validate_string($region)
  validate_string($tag_key)
  validate_string($tag_value)

  class { '::aws_nat_failover::install': } ->
  class { '::aws_nat_failover::config':
    region    => $region,
    tag_key   => $tag_key,
    tag_value => $tag_value,
  } ~>
  class { '::aws_nat_failover::service': } ->
  Class['::aws_nat_failover']


}
