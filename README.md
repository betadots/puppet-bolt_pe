# bolt_pe

This modules delivers extensions to be used with Puppet Enterprise.

## Table of Contents

1. [Description](#description)
1. [Setup - The basics of getting started with bolt_pe](#setup)
    * [Setup requirements](#setup-requirements)
    * [Beginning with bolt_pe](#beginning-with-bolt_pe)
1. [Usage - Configuration options and additional functionality](#usage)

## Description

### Tasks and Plans

#### Terraform

On Puppet Enterprise the terraform tasks and plans are not available.
These are only available within Bolt Open Source.

This module delivers the terraform tasks and plans and places them under a new namespace: bolt_pe

#### Get Targets from Node Groups

On Puppet Enterprise on can group servers into node groups.
This module provides a task which will read an exusting node group and return the nodes from the provided node group.

Usage is straight forward like an other Puppet Task:

    plan foo (
      Enum['All Nodes', 'Production Environment'] $node_group,
      String $puppet_server,
    ) {
      $targets = run_task('bolt_pe::get_targets_from_node_groups', $puppet_server, 'node_group' => $node_group)
      $targets.each |$target| {
        # ...
      }
    }

## Setup

### Setup Requirements

This module needs the [puppetlabs-ruby_task_helper](https://forge.puppet.com/modules/puppetlabs/ruby_task_helper)  module.

### Beginning with bolt_pe

Bolt_pe has no Puppet classes.
It only consists of tasks, plans and functions.

## Usage

Add this module and the ruby_task_helper module to your Puppet Enterprise Server.
This can be achieved by adding the modules to your control-repo Puppetfile.

Afterwards you should see the tasks in Puppet Enterprise console.
