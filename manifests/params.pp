# == Class aws_nat_failover::params
#
# This class is meant to be called from aws_nat_failover.
# It sets variables according to platform.
#
class aws_nat_failover::params {
  $region    = 'eu-west-1'
  $tag_key   = 'Service'
  $tag_value = 'bastion'
}
