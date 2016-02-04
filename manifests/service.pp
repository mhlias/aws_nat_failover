# == Class aws_nat_failover::service
#
# This class is meant to be called from aws_nat_failover.
# It ensure the service is running.
#
class aws_nat_failover::service {

  service { 'aws_nat_failover':
    ensure     => running,
    enable     => true,
    hasstatus  => false,
    hasrestart => false,
  }
}
