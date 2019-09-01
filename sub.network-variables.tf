
################ ################################################### ########
################ The key environment specific data source variables. ########
################ ################################################### ########


/*
 | --
 | -- The existing Amazon VPC (virtual private cloud) container within whose
 | -- auspices we will create subnets and other network infrastructure.
 | --
*/
data aws_vpc existing {
    id = var.in_vpc_id
}


/*
 | --
 | -- The (2 or 3) availability zones that exist within this VPC's region.
 | --
*/
data aws_availability_zones with {
}


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

variable in_net_gateway_id {
    description = "The internet gateway ID of the existing VPC."
}



##### ---> ######################### <--- #####
##### ---> ------------------------- <--- #####
##### ---> Optional Module Variables <--- #####
##### ---> ------------------------- <--- #####
##### ---> ######################### <--- #####


variable in_num_private_subnets {
    description = "The number of private subnets to create (defaults to 3 if not specified)."
    default     = 3
}


variable in_num_public_subnets {
    description = "The number of public subnets to create (defaults to 3 if not specified)."
    default     = 3
}


variable in_create_public_gateway {
    description = "An internet gateway and route is created unless this variable is supplied as false."
    default     = true
}


variable in_create_private_gateway {
    description = "If private subnets exist an EIP, a NAT gateway, route and subnet association are created unless this variable is supplied as false."
    default     = true
}



### ############################## ###
### [[variable]] in_mandatory_tags ###
### ############################## ###

variable in_mandatory_tags {

    description = "Optional tags unless your organization mandates that a set of given tags must be set."
    type        = map
    default     = { }
}


### ############ ###
### in_ecosystem ###
### ############ ###

variable in_ecosystem {
    description = "The name of the ecosystem (environment superclass) being created or changed."
    default = "ecosystem"
    type = string
}


### ############ ###
### in_timestamp ###
### ############ ###

variable in_timestamp {
    description = "The numerical timestamp denoting the time this eco instance was instantiated."
    type = string
}


### ############## ###
### in_description ###
### ############## ###

variable in_description {
    description = "The when and where description of this ecosystem creation."
    type = string
}
