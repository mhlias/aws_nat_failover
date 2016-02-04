#### Table of Contents

1. [Overview](#overview)
2. [Module Description - What the module does and why it is useful](#module-description)
3. [Setup - The basics of getting started with manage_ebs_crossaz](#setup)
    * [What manage_ebs_crossaz affects](#what-manage_ebs_crossaz-affects)
    * [Setup requirements](#setup-requirements)
    * [Beginning with manage_ebs_crossaz](#beginning-with-manage_ebs_crossaz)
4. [Usage - Configuration options and additional functionality](#usage)
5. [Reference - An under-the-hood peek at what the module is doing and how](#reference)
5. [Limitations - OS compatibility, etc.](#limitations)
6. [Development - Guide for contributing to the module](#development)

## Overview

A simple puppet module that installs a service to monitor a Bastion NAT instance in AWS and failover routing in case of outage.      

## Module Description

This module will install a systemd service and start it.
The service will find the ENI used with the Bastion NAT instance it runs in, in the current VPC and Availability Zone
tagged with the key:value provided. Will make sure the default route for the private subnet in this Availability Zone points to the ENI/instance. Then it will start monitoring the Bastion Nat instance in another availability zone and in case of failure it will failover the route of the instance monitored to each own until the failed instance is recreated by an autoscaling group action.

It is expected to have 3 Bastion NAT instances for HA, one in every Availability zone.
instance in AZ a will monitor instance in AZ b
instance in AZ b will monitor instance in AZ c
instance in AZ c will monitor instance in AZ a

Although NAT gateways are available as a service right now. Someone can still take advantage of using the bastion instances for more than NAT and also pay less than the cost of the NAT gateway service when the bastion instances are of t2.micro size.

## Setup

### What aws_nat_failover affects

* The module will install ruby, rubygems using yum and aws-sdk using ruby gems.
* A custom ruby daemon into /usr/local/sbin that will be executable for the root user.
* A service into systemd

### Setup Requirements

The module expects the Bastion NAT instances to use an ENI tagged with the key:value provided.
It also expects the routing table containing the default route for the private subnet to be tagged with eni_id:eni_id_value of the ENI it routes to. 
ICMP traffic on the private ip address of the ENI attached to the Bastion NAT instance is expected to be allowed between Bastion NAT instances.

The EC2 instance that will use the module needs to have the following actions allowed in its IAM role:
```
"Action": [
  "ec2:Describe*",
  "ec2:ReplaceRoute"
],
```



### Beginning with aws_nat_failover

## Usage

Simple example:
```
class { 'aws_nat_failover':
  region    => 'eu-west-1',
  tag_key   => 'Service',
  tag_value => 'bastion',
} 
```
## Reference

## Limitations

Currently only tested in CentOS 7.



## Development

To run tests, first bundle install:

```shell
$ bundle install
```

Then, for overall spec tests, including syntax, lint, and rspec, run:

```shell
$ bundle exec rake test
```

To run acceptance tests locally, we use vagrant; first set a few environment variables for the target system:

```shell
$ export BEAKER_set=vagrant-centos7
$ export BEAKER_destroy=no
```
Note: Setting `BEAKER_destroy=no` will allow you to login to the vagrant box that get's provisioned.

Then execute the acceptance tests:

```shell
$ bundle exec rake acceptance
```

In order to access the vagrant box that's been provisioner, there are two options:
Obtain the unique ID of the box using `vagrant global-status`, and then use `vagrant ssh [unique_id]`

Alternately, change to the directory of the Beaker generated Vagrantfile:
```
$ cd .vagrant/beaker_vagrant_files/$BEAKER_SET
```
and run `vagrant ssh` - if there are multiple boxes, you may need to use `vagrant ssh [box_name]`
