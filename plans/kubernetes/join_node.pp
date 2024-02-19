# Join nodes to Kubernetes cluster
#
# @param targets Nodes to join
# @param control_plane Node that controls the workers
# @param taints List of taints to start the nodes with
#
# @see https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/#join-nodes
plan nest::kubernetes::join_node (
  TargetSpec $targets,
  TargetSpec $control_plane,
  Variant[Nest::KubernetesTaint, Array[Nest::KubernetesTaint]] $taints = [],
) {
  $taints_list = [$taints].flatten

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

  if $kubeadm_join_cmd =~ /join (\S+)/ {
    $api_server = $1
  } else {
    $api_server = undef
  }

  if $kubeadm_join_cmd =~ /--token (\S+)/ {
    $token = $1
  } else {
    $token = undef
  }

  if $kubeadm_join_cmd =~ /--discovery-token-ca-cert-hash (\S+)/ {
    $ca_cert_hash = $1
  } else {
    $ca_cert_hash = undef
  }

  $kubeadm_config = epp('nest/kubernetes/kubeadm-join-config.yaml.epp', {
    api_server   => $api_server,
    token        => $token,
    ca_cert_hash => $ca_cert_hash,
    taints       => $taints_list,
  })
  write_file($kubeadm_config, '/root/kubeadm-config.yaml', $targets, {
    _run_as => 'root',
  })

  run_command('kubeadm join --config=/root/kubeadm-config.yaml', $targets, 'Join node to Kubernetes cluster', {
    _run_as => 'root',
  })

  parallelize(get_targets($targets)) |$target| {
    $taints_list.each |$taint| {
      if $taint =~ /^(\w+)(=(\w+))?/ {
        $key = $1
        $value = $3
        $label_cmd = "kubectl label nodes ${target.name} ${key}=${value}"
        run_command($label_cmd, 'localhost', "Label node ${target.name} with ${key}=${value}")
      }
    }
  }

  run_command('rm -f /root/kubeadm-config.yaml', $targets, 'Remove kubeadm config file', {
    _run_as => 'root',
  })

  run_plan('nest::kubernetes::wait', {
    kind      => daemonset,
    name      => 'calico-node',
    namespace => 'calico-system',
  })
}
