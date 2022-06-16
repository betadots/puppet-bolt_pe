plan bolt_pe::terraform_apply(
  Optional[String[1]] $dir = undef,
  Optional[String[1]] $state = undef,
  Optional[String[1]] $state_out = undef,
  Optional[Variant[String[1], Array[String[1]]]] $target = undef,
  Optional[Hash] $var = undef,
  Optional[Variant[String[1], Array[String[1]]]] $var_file = undef,
  Optional[Boolean] $return_output = false,
  TargetSpec $terraform_host,
) {
  $apply_opts = {
    'dir' => $dir,
    'state' => $state,
    'state_out' => $state_out,
    'target' => $target,
    'var' => $var,
    'var_file' => $var_file,
  }

  $apply_logs = run_task('bolt_pe::terraform_apply', $terraform_host, $apply_opts)

  unless $return_output {
    return $apply_logs
  }

  $output_opts = {
    'dir' => $dir,
    'state' => $state,
  }

  $output = run_task('bolt_pe::terraform_output', $terraform_host, $output_opts)
  return $output[0].value
}
