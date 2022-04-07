# join nodes to Kubernetes cluster
#
# @param targets Nodes to join
# @param control_plane Node that controls the workers
#
# @see https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/#join-nodes
plan nest::kubernetes::join_node (
  TargetSpec $targets,
  TargetSpec $control_plane,
) {
  run_command('systemctl start crio', $targets, 'Start CRI-O', {
    _run_as => 'root',
  })

  run_command('systemctl stop kubelet', $targets, 'Stop kubelet', {
    _run_as => 'root',
  })

  $kubeadm_token_cmd = 'kubeadm token create --print-join-command'
  $kubeadm_join_cmd = run_command($kubeadm_token_cmd, get_targets($control_plane)[0], 'Get kubeadm join command', {
    _run_as => 'root',
  }).first.value['stdout'].chomp

  run_command($kubeadm_join_cmd, $targets, 'Join node to Kubernetes cluster', {
    _run_as => 'root',
  })

  $wait_for_calico_cmd = 'kubectl rollout status daemonset calico-node -n kube-system --timeout=1h'
  run_command($wait_for_calico_cmd, get_targets($control_plane)[0], 'Wait for Calico to be ready', {
    _env_vars => { 'KUBECONFIG' => '/etc/kubernetes/admin.conf' },
    _run_as   => 'root',
  })
}