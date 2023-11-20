variable "iam_role_parameters" {
    description = "IAM role parameters for EKS"
    type = map(object({
        path                = string
        assume_role_policy  = string
        tags                = optional(map(string), {})
    }))
    default = {}
}

variable "iam_role_policy_attachment_parameters" {
    description = "IAM role policy attachment for EKS"
    type = map(object({
        policy_arn  = string
        role_name   = string
        tags        = optional(map(string), {})
    }))
    default = {}
}

variable "eks_cluster_parameters" {
    description = "EKS cluster parameters"
    type = map(object({
        subnet_ids              = list(string)
        role_name               = string
        endpoint_private_access = bool
        tags                    = optional(map(string), {})
    }))
    default = {}
}

variable "eks_cluster_node_group_parameters" {
    description = "EKS cluster node group parameters"
    type = map(object({
        cluster_name    = string
        node_role_name  = string
        subnet_ids      = list(string)
        instance_types  = list(string)
        desired_size    = number
        max_size        = number
        min_size        = number
        tags            = optional(map(string), {})
    }))
    default = {}
}

