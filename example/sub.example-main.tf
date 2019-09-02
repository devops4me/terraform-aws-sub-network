
### ---> ###################### <--- ### || < ####### > || ###
### ---> ---------------------- <--- ### || < ------- > || ###
### ---> Instance Layer Modules <--- ### || < Layer I > || ###
### ---> ---------------------- <--- ### || < ------- > || ###
### ---> ###################### <--- ### || < ####### > || ###

module ec2-instance {

    source                  = "github.com/devops4me/terraform-aws-ec2-instance-cluster"

    in_node_count           = 1
    in_iam_instance_profile = module.ec2-instance-profile.out_ec2_instance_profile
    in_ssh_public_key       = var.in_ssh_public_key

    in_ami_id               = data.aws_ami.ubuntu-1804.id
    in_subnet_ids           = [ element ( module.sub-network.out_public_subnet_ids, 0 ) ]
    in_security_group_ids   = [ module.security-group.out_security_group_id ]

    in_ecosystem_name       = var.in_ecosystem
    in_tag_timestamp        = var.in_timestamp
    in_tag_description      = var.in_description
}

module ec2-instance-profile {

    source = "github.com/devops4me/terraform-aws-ec2-instance-profile"

    in_ec2_policy_stmts = data.template_file.ec2_policy_stmts.rendered
    in_ecosystem_name   = var.in_ecosystem
    in_tag_timestamp    = var.in_timestamp
}

data template_file ec2_policy_stmts {
    template = file( "${path.module}/ec2-policies.json" )
}


### ---> ##################### <--- ### || < ####### > || ###
### ---> --------------------- <--- ### || < ------- > || ###
### ---> Network Layer Modules <--- ### || < Layer N > || ###
### ---> --------------------- <--- ### || < ------- > || ###
### ---> ##################### <--- ### || < ####### > || ###

module sub-network {

    source = "./.."

    in_vpc_id         = var.in_vpc_id
    in_vpc_cidr       = var.in_vpc_cidr
    in_net_gateway_id = var.in_gateway_id
    in_subnets_max    = var.in_subnets_max
    in_subnet_offset  = var.in_subnet_offset

    in_num_public_subnets  = 1
    in_num_private_subnets = 0

    in_ecosystem   = var.in_ecosystem
    in_timestamp   = var.in_timestamp
    in_description = var.in_description
}

module security-group {

    source      = "github.com/devops4me/terraform-aws-security-group"
    in_ingress  = [ "http", "https", "ssh" ]
    in_vpc_id   = var.in_vpc_id

    in_ecosystem_name  = var.in_ecosystem
    in_tag_timestamp   = var.in_timestamp
    in_tag_description = var.in_description
}


/*
 | --
 | -- If you are using an IAM role as the AWS access mechanism then
 | -- pass it as in_role_arn commonly through an environment variable
 | -- named TF_VAR_in_role_arn in addition to the usual AWS access
 | -- key, secret key and default region parameters.
 | --
*/
provider aws {
    dynamic assume_role {
        for_each = length( var.in_role_arn ) > 0 ? [ var.in_role_arn ] : [] 
        content {
            role_arn = assume_role.value
	}
    }
}


/*
 | --
 | -- Use the AMI data filter to find the ID of the Ubuntu 18.04 image
 | -- within the region that we are currently in.
 | --
*/
data aws_ami ubuntu-1804 {

    most_recent = true

    filter {
        name   = "name"
        values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
    }

    filter {
        name   = "virtualization-type"
        values = [ "hvm" ]
    }

    owners = [ "099720109477" ]
}
