# get all node groups and print to stdout
plan bolt_pe::get_node_groups (
  Enum['All Nodes', 'Production Environment'] $node_group,
) {
  out::message(bolt_pe::get_targets_from_node_groups($node_group))
}
