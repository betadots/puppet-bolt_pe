# bolt_pe

This modules delivers the Open Source Bolt terraform plans and tasks to be available on Puppet Enterprise.

## Table of Contents

1. [Description](#description)
1. [Setup - The basics of getting started with bolt_pe](#setup)
    * [Setup requirements](#setup-requirements)
    * [Beginning with bolt_pe](#beginning-with-bolt_pe)
1. [Usage - Configuration options and additional functionality](#usage)

## Description

On Puppet Enterprise the terraform tasks and plans ar enot available.
These are only available within Bolt Open Source.

This module just delivers the terraform tasks and plans and places them under a new namespace: bolt_pe::

## Setup

### Setup Requirements

This module needs the [puppetlabs-ruby_task_helper](https://forge.puppet.com/modules/puppetlabs/ruby_task_helper)  module.

### Beginning with bolt_pe

Bolt_pe has no Puppet classes.
It only consits of task and plans.

## Usage

Add this module and the ruby_task_helper module to your Puppet Enterprise Server.
This can be achieved by adding the modules to your control-repo Puppetfile.

Afterwards you should see the tasks in Puppet Enterprise console.


