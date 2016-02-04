# == Class aws_nat_failover::install
#
# This class is called from aws_nat_failover for install.
#
class aws_nat_failover::install {

  package { 'ruby':
    ensure   => installed,
    provider => 'yum',
  }->
  package { 'rubygems':
    ensure   => installed,
    provider => 'yum',
  }->
  package { 'aws-sdk':
    ensure   => installed,
    provider => 'gem',
  }->
  file { '/usr/local/sbin/monitor_bastion':
    source => 'puppet:///modules/aws_nat_failover/monitor_bastion.rb',
    ensure => 'file',
    owner  => 'root',
    mode   => '0700',
  }
  
}
