
##### ---> ########################## <--- #####
##### ---> -------------------------- <--- #####
##### ---> Mandatory Module Variables <--- #####
##### ---> -------------------------- <--- #####
##### ---> ########################## <--- #####

variable in_vpc_id {
   description = "The ID of the existing VPC in which to create the subnet network."
}

variable in_vpc_cidr {
    description = "The CIDr block defining the range of IP addresses allocated to this VPC."
}

variable in_subnets_max {
    description = "Two to the power of in_subnets_max is the ma number of subnets carvable from the VPC."
}

variable in_subnet_offset {
    description = "The number of subnets already carved out of the existing VPC to skip over."
}

variable in_internet_gateway_id {
    description = "The internet gateway ID of the existing VPC."
}

### ################# ###
### in_ssh_public_key ###
### ################# ###

variable in_ssh_public_key {
    description = "The public key to use for EC2 instance communications."
}


##### ---> ######################### <--- #####
##### ---> ------------------------- <--- #####
##### ---> Optional Module Variables <--- #####
##### ---> ------------------------- <--- #####
##### ---> ######################### <--- #####

### ########### ###
### in_role_arn ###
### ########### ###

variable in_role_arn {
    description = "If using an IAM role as the AWS access mechanism place its ARN here."
    default = ""
}

### ############ ###
### in_timestamp ###
### ############ ###

variable in_timestamp {
    description = "The numerical resource instantiation timestamp to the nearest whole second."
    type        = string
}

### ############ ###
### in_ecosystem ###
### ############ ###

variable in_ecosystem {
    description = "The name of the ecosystem (environment superclass) being created or changed."
    default = "netex"
    type = string
}


### ############## ###
### in_description ###
### ############## ###

variable in_description {
    description = "The when and where description of this ecosystem creation."
    type = string
}


##### ---> ######################### <--- #####
##### ---> ------------------------- <--- #####
##### ---> Locally Defined Variables <--- #####
##### ---> ------------------------- <--- #####
##### ---> ######################### <--- #####

locals {
    the_timestamp = formatdate( "YYMMDDhhmmss", timestamp() )
    the_description = "was created on ${ timestamp() }."
}