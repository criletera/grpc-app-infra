output "networking" {
    value = {
        vpcs = module.networking.vpcs
        subnets = module.networking.subnets
    }
}
