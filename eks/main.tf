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

