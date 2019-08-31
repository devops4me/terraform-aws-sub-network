

/*
 | --
 | -- This module creates a VPC and then allocates subnets in a round robin manner
 | -- to each availability zone. For example if 8 subnets are required in a region
 | -- that has 3 availability zones - 2 zones will hold 3 subnets and the 3rd two.
 | --
 | -- Whenever and wherever public subnets are specified, this module knows to create
 | -- an internet gateway and a route out to the net.
 | --
*/
module sub-network {

    source                 = "./.."
    in_vpc_cidr            = "10.88.0.0/16"
    in_num_public_subnets  = 2
    in_num_private_subnets = 0

    in_ecosystem_name  = local.in_ecosystem
    in_tag_timestamp   = local.in_timestamp
    in_tag_description = local.in_description
}


/*
 | --
 | -- You can do away with long repeating and hard to read security group
 | -- declarations in favour of a succinct one word security group rule
 | -- definition. This module understands the common traffic protocols like
 | -- ssh (22), https (443), sonarqube (9000), jenkins (8080) and so on.
 | --
*/
module security-group {

    source     = "github.com/devops4me/terraform-aws-security-group"
    in_ingress = [ "http", "https" ]
    in_vpc_id  = module.vpc-network.out_vpc_id

    in_ecosystem_name  = local.in_ecosystem
    in_tag_timestamp   = local.in_timestamp
    in_tag_description = local.in_description
}


locals{

    in_ecosystem = "elasticsearch"
    in_timestamp = "190828"
    in_description = "was created recently."

}


provider aws {
    assume_role {
        role_arn = var.in_role_arn
    }
}


variable in_role_arn {
    description = "The Role ARN to use when we assume role to implement the provisioning."
}
