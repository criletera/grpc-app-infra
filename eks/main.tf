resource "aws_iam_role" "this" {
    for_each                = var.iam_role_parameters
    name                    = each.key
    path                    = each.value.path
    assume_role_policy      = each.value.assume_role_policy
    tags = merge(each.value.tags, {
        Name : each.key
    })
}

resource "aws_iam_role_policy_attachment" "this" {
    for_each    = var.iam_role_policy_attachment_parameters
    policy_arn  = each.value.policy_arn
    role        = each.value.role_name
    depends_on = [ aws_iam_role.this ]
}

resource "aws_eks_cluster" "this" {
    for_each = var.eks_cluster_parameters
    name = each.key
    role_arn = aws_iam_role.this[each.value.role_name].arn
    vpc_config {
        subnet_ids = each.value.subnet_ids
        endpoint_private_access = each.value.endpoint_private_access
    }
    depends_on = [ aws_iam_role.this ]
}

resource "aws_eks_node_group" "this" {
    for_each = var.eks_cluster_node_group_parameters
    cluster_name = each.value.cluster_name
    node_group_name = each.key
    node_role_arn = aws_iam_role.this[each.value.node_role_name].arn
    subnet_ids = each.value.subnet_ids
    instance_types = each.value.instance_types
    scaling_config {
        desired_size = each.value.desired_size
        max_size = each.value.max_size
        min_size = each.value.min_size
    }
    depends_on = [ aws_eks_cluster.this ]
}

data "aws_instances" "eks_worker_nodes" {
    filter {
        name   = "tag:aws:eks:cluster-name"
        values = [ "grpc_app_cluster" ]
    }
    # depends_on = [ 
    #     aws_eks_cluster.this,
    #     aws_eks_node_group.this,
    # ]
}

resource "aws_lb_target_group" "this" {
    for_each = var.alb_target_group_parameters
    name       = each.value.target_group_name
    port       = each.value.port
    protocol   = each.value.protocol
    vpc_id     = each.value.vpc_id
    slow_start = each.value.slow_start

    load_balancing_algorithm_type = each.value.load_balancing_algorithm_type
    
    stickiness {
        enabled = each.value.stickiness_enabled
        type    = each.value.stickiness_type
    }

    health_check {
        enabled             = each.value.health_check_enabled
        port                = each.value.health_check_port
        interval            = each.value.health_check_interval
        protocol            = each.value.health_check_protocol
        path                = each.value.health_check_path
        matcher             = each.value.health_check_matcher
        healthy_threshold   = each.value.health_check_healthy_threshold
        unhealthy_threshold = each.value.health_check_unhealthy_threshold
    }
    depends_on = [ aws_eks_node_group.this ]
}

resource "aws_lb_target_group_attachment" "this" {
    count = length(data.aws_instances.eks_worker_nodes.ids)
    target_group_arn    = aws_lb_target_group.this[var.alb_tg_attachment_parameters["grpc_app_tg_attachment"].target_group_name].arn
    target_id           = data.aws_instances.eks_worker_nodes.ids[count.index]
    port                = var.alb_tg_attachment_parameters["grpc_app_tg_attachment"].port
    depends_on          = [ data.aws_instances.eks_worker_nodes ]
}

resource "aws_lb" "this" {
    for_each = var.alb_parameters
    name                = each.value.lb_name
    internal            = each.value.internal
    load_balancer_type  = each.value.load_balancer_type
    subnets             = each.value.subnet_ids
    depends_on          = [ 
                            aws_lb_target_group.this,
                            aws_lb_target_group_attachment.this
                        ]
}

resource "aws_lb_listener" "this" {
    for_each = var.alb_listener_parameters
    load_balancer_arn = aws_lb.this[each.value.lb_name].arn
    port              = each.value.port
    protocol          = each.value.protocol

    default_action {
        type             = "forward"
        target_group_arn = aws_lb_target_group.this[each.value.target_group_name].arn
    }
    depends_on = [ aws_lb.this ]
}