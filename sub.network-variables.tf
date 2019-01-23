
################ ################################################### ########
################ The key environment specific data source variables. ########
################ ################################################### ########


/*
 | --
 | -- The existing Amazon VPC (virtual private cloud) container within whose
 | -- auspices we will create subnets and other network infrastructure.
 | --
*/
data aws_vpc existing
{
    id = "${ var.in_vpc_id }"
}


/*
 | --
 | -- The (2 or 3) availability zones that exist within this VPC's region.
 | --
*/
data aws_availability_zones with
{
}


################ ############################################## ########
################ Module [[[sub-network]]] Input Variables List. ########
################ ############################################## ########

variable in_vpc_id
{
    description = "The ID of the existing VPC in which to create the subnet network."
}


variable in_vpc_cidr
{
    description = "The CIDr block defining the range of IP addresses allocated to this VPC."
}


variable in_subnets_max
{
    description = "Two to the power of in_subnets_max is the ma number of subnets carvable from the VPC."
}


variable in_subnets_exist_count
{
    description = "The number of subnets already carved out of the existing VPC to skip over."
}


variable in_num_private_subnets
{
    description = "The number of private subnets to create (defaults to 3 if not specified)."
    default     = "3"
}


variable in_num_public_subnets
{
    description = "The number of public subnets to create (defaults to 3 if not specified)."
    default     = "3"
}


variable in_create_public_gateway
{
    description = "An internet gateway and route is created unless this variable is supplied as false."
    default     = true
}


variable in_create_private_gateway
{
    description = "If private subnets exist an EIP, a NAT gateway, route and subnet association are created unless this variable is supplied as false."
    default     = true
}


variable in_ecosystem_name
{
    description = "Creational stamp binding all infrastructure components created on behalf of this ecosystem instance."
}


variable in_tag_timestamp
{
    description = "A timestamp for resource tags in the format ymmdd-hhmm like 80911-1435"
}


variable in_tag_description
{
    description = "Ubiquitous note detailing who, when, where and why for every infrastructure component."
}
