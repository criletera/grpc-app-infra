module "networking" {
    source = "./networking"
    vpc_parameters = {
        grpc_app_vpc = {
            cidr_block = "10.0.0.0/16"
        }
    }
    subnet_parameters = {
        grpc_app_public_subnet_1 = {
            cidr_block = "10.0.1.0/24"
            az_name = "us-east-1a"
            vpc_name   = "grpc_app_vpc"
        }
        grpc_app_public_subnet_2 = {
            cidr_block = "10.0.2.0/24"
            vpc_name   = "grpc_app_vpc"
            az_name = "us-east-1b"
        }
        grpc_app_private_subnet_1 = {
            cidr_block = "10.0.4.0/24"
            vpc_name   = "grpc_app_vpc"
            az_name = "us-east-1a"
        }
        grpc_app_private_subnet_2 = {
            cidr_block = "10.0.5.0/24"
            vpc_name   = "grpc_app_vpc"
            az_name = "us-east-1b"
        }
    }
    igw_parameters = {
        grpc_app_igw = {
            vpc_name = "grpc_app_vpc"
        }
    }
    nat_parameters = {
        grpc_app_nat = {
            subnet_name = "grpc_app_public_subnet_1"
        }
    }
    rt_parameters = {
        grpc_app_public_rt = {
            vpc_name = "grpc_app_vpc"
            routes = [{
                cidr_block = "0.0.0.0/0"
                gateway_id = "grpc_app_igw"
            }]
        }
        grpc_app_private_rt = {
            vpc_name = "grpc_app_vpc"
            routes = [{
                cidr_block = "0.0.0.0/0"
                use_igw = false
                gateway_id = "grpc_app_nat"
            }]
        }
    }
    rt_association_parameters = {
        assoc1 = {
            subnet_name = "grpc_app_public_subnet_1"
            rt_name     = "grpc_app_public_rt"
        }
        assoc2 = {
            subnet_name = "grpc_app_public_subnet_2"
            rt_name     = "grpc_app_public_rt"
        }
        assoc3 = {
            subnet_name = "grpc_app_private_subnet_1"
            rt_name     = "grpc_app_private_rt"
        }
        assoc4 = {
            subnet_name = "grpc_app_private_subnet_2"
            rt_name     = "grpc_app_private_rt"
        }
    }
}

module "eks" {
    source = "./eks"
    iam_role_parameters = {
        grpc_cluster_iam_role = {
            path = "/"
            assume_role_policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
  {
   "Effect": "Allow",
   "Principal": {
    "Service": "eks.amazonaws.com"
   },
   "Action": "sts:AssumeRole"
  }
 ]
}
EOF
        }
        grpc_worker_nodes_iam_role = {
            path = "/"
            assume_role_policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
  {
   "Effect": "Allow",
   "Principal": {
    "Service": "ec2.amazonaws.com"
   },
   "Action": "sts:AssumeRole"
  }
 ]
}
EOF
        }
    }
    iam_role_policy_attachment_parameters = {
        eks_cluster_policy = {
            policy_arn  = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
            role_name   = "grpc_cluster_iam_role"
        }
        ec2_ecr_eks_ro = {
            policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
            role_name   = "grpc_cluster_iam_role"
        }
        eks_worker_node = {
            policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
            role_name   = "grpc_worker_nodes_iam_role"
        }
        eks_cni = {
            policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
            role_name   = "grpc_worker_nodes_iam_role"
        }
        ec2_instance_profile_ecr = {
            policy_arn = "arn:aws:iam::aws:policy/EC2InstanceProfileForImageBuilderECRContainerBuilds"
            role_name   = "grpc_worker_nodes_iam_role"
        }
        ec2_ecr_ro = {
            policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
            role_name   = "grpc_worker_nodes_iam_role"
        }
    }
    eks_cluster_parameters = {
        grpc_app_cluster = {
            subnet_ids = [
                module.networking.subnets.grpc_app_private_subnet_1.id,
                module.networking.subnets.grpc_app_private_subnet_2.id
            ]
            role_name = "grpc_cluster_iam_role"
            endpoint_private_access = true
        }
    }
    eks_cluster_node_group_parameters = {
        grpc_app_worker_nodes = {
            cluster_name = "grpc_app_cluster"
            node_role_name = "grpc_worker_nodes_iam_role"
            subnet_ids = [
                module.networking.subnets.grpc_app_private_subnet_1.id,
                module.networking.subnets.grpc_app_private_subnet_2.id
            ]
            instance_types = [
                "t2.micro"
            ]
            desired_size = 2
            max_size = 2
            min_size = 1
        }
    }
    alb_target_group_parameters = {
        grpc_app_target_group = {
            target_group_name = "grpc-alb-tg"
            port = 30728
            protocol = "HTTP"
            vpc_id = module.networking.vpcs["grpc_app_vpc"].id
            slow_start = 0
            load_balancing_algorithm_type = "round_robin"
            stickiness_enabled = false
            stickiness_type = "lb_cookie"
            health_check_enabled = true
            health_check_port = 30728
            health_check_interval = 30
            health_check_protocol = "HTTP"
            health_check_path = "/"
            health_check_matcher = "200"
            health_check_healthy_threshold = 3
            health_check_unhealthy_threshold = 3
        }
    }
    alb_tg_attachment_parameters = {
        grpc_app_tg_attachment = {
            target_group_name = "grpc_app_target_group"
            port = 30728
        }
    }
    alb_parameters = {
        grpc_lb = {
            lb_name     = "grpc-alb"
            internal    = false
            load_balancer_type  = "application"
            subnet_ids          = [
                module.networking.subnets.grpc_app_public_subnet_1.id,
                module.networking.subnets.grpc_app_public_subnet_2.id
            ]
        }
    }
    alb_listener_parameters = {
        grpc_lb_listener = {
            lb_name = "grpc_lb"
            port = 8000
            protocol = "HTTP"
            target_group_name = "grpc_app_target_group"
        }
    }
}

