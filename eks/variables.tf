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

variable "alb_target_group_parameters" {
    description = "ALB target group parameters"
    type = map(object({
        target_group_name = string
        port = number
        protocol = string
        vpc_id = string
        slow_start = number
        load_balancing_algorithm_type = string

        stickiness_enabled = bool
        stickiness_type = string

        health_check_enabled = bool
        health_check_port = number
        health_check_interval = number
        health_check_protocol = string
        health_check_path = string
        health_check_matcher = string
        health_check_healthy_threshold = number
        health_check_unhealthy_threshold = number

        tags            = optional(map(string), {})
    }))
    default = {}
}

variable "alb_tg_attachment_parameters" {
    description = ""
    type = map(object({
        target_group_name    = string
        port                = number
        tags                = optional(map(string), {})
    }))
    default = {}
}

variable "alb_parameters" {
    description = ""
    type = map(object({
        lb_name             = string
        load_balancer_type  = string
        internal            = bool
        subnet_ids          = list(string)
        tags                = optional(map(string), {})
    })) 
    default = {}
}

variable "alb_listener_parameters" {
    description = ""
    type = map(object({
        lb_name             = string
        port                = number
        protocol            = string
        target_group_name   = string
        tags                = optional(map(string), {})
    })) 
    default = {}
}