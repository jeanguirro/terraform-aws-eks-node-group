
locals {
  # "amazon-eks-gpu-node-",
  arch_label_map = {
    "AL2_x86_64" : "",
    "AL2_x86_64_GPU" : "-gpu",
    "AL2_ARM_64" : "-arm64",
  }

  # Kubernetes version priority (first one to be set wins)
  # 1. prefix of var.ami_release_version
  # 2. var.kubernetes_version
  # 3. data.eks_cluster.this.kubernetes_version
  need_cluster_kubernetes_version = local.enabled ? local.need_ami_id && length(concat(var.ami_release_version, var.kubernetes_version)) == 0 : false

  ami_kubernetes_version = local.need_ami_id ? (local.need_cluster_kubernetes_version ? data.aws_eks_cluster.this[0].version :
    regex("^(\\d+\\.\\d+)", coalesce(try(var.ami_release_version[0], null), try(var.kubernetes_version[0], null)))[0]
  ) : ""

  ami_version_regex = local.need_ami_id ? (length(var.ami_release_version) == 1 ?
    replace(var.ami_release_version[0], "/^(\\d+\\.\\d+)\\.\\d+-(\\d+)$/", "$1-v$2") :
    "${local.ami_kubernetes_version}-*"
  ) : ""

  ami_regex = local.need_ami_id ? format("amazon-eks%s-node-%s", local.arch_label_map[var.ami_type], local.ami_version_regex) : ""
}

data "aws_ami" "selected" {
  count = local.enabled && local.need_ami_id ? 1 : 0

  most_recent = true
  name_regex  = local.ami_regex

  owners = ["amazon"]
}

