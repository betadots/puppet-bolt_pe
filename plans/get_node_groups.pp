# get all node groups and print to stdout
plan bolt_pe::get_node_groups (
  Enum['All Nodes', 'Production Environment'] $node_group,
  String $puppet_server,
) {
  $targets = run_task('bolt_pe::get_targets_from_node_groups', $puppet_server, 'node_group' => $node_group)
  $targets.each |$target| {
    # ...
  }
}
