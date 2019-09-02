
/*
 | -- Round robin card dealing distribution of private subnets
 | -- across availability zones is done here.
 | --
 | -- The modulus functionality is silently implemented by
 | -- "element" which rotates back to the first zone if the
 | -- subnet count exceeds the zone count.
*/
resource aws_subnet private {

    count = var.in_num_private_subnets

    cidr_block        = cidrsubnet( var.in_vpc_cidr, var.in_subnets_max, var.in_subnet_offset + count.index )
    availability_zone = element( data.aws_availability_zones.with.names, count.index )
    vpc_id            = var.in_vpc_id

    map_public_ip_on_launch = false

    tags = merge(
        {
            Name = "subnet-${ var.in_ecosystem }-${ var.in_timestamp }-${ format( "%02d", var.in_subnet_offset + count.index + 1 ) }-az${ element( split( "-", element( data.aws_availability_zones.with.names, count.index ) ), 2 ) }-x"
            Desc = "Private subnet no.${ var.in_subnet_offset + count.index + 1 } within availability zone ${ element( split( "-", element( data.aws_availability_zones.with.names, count.index ) ), 2 ) } ${ var.in_description }"
        },
        var.in_mandated_tags
    )

}


/*
 | -- Round robin card dealing distribution of public subnets
 | -- across availability zones is done here.
 | --
 | -- The modulus functionality is silently implemented by
 | -- "element" which rotates back to the first zone if the
 | -- subnet count exceeds the zone count.
*/
resource aws_subnet public {

    count = var.in_num_public_subnets

    cidr_block        = cidrsubnet( var.in_vpc_cidr, var.in_subnets_max, var.in_subnet_offset + var.in_num_private_subnets + count.index )
    availability_zone = element( data.aws_availability_zones.with.names, count.index )
    vpc_id            = var.in_vpc_id

    map_public_ip_on_launch = true

    tags = merge(
        {
            Name = "subnet-${ var.in_ecosystem }-${ var.in_timestamp }-${ format( "%02d", var.in_subnet_offset + var.in_num_private_subnets + count.index + 1 ) }-az${ element( split( "-", element( data.aws_availability_zones.with.names, count.index ) ), 2 ) }-o"
            Desc = "Public subnet no.${ var.in_subnet_offset + var.in_num_private_subnets + count.index + 1 } within availability zone ${ element( split( "-", element( data.aws_availability_zones.with.names, count.index ) ), 2 ) } ${ var.in_description }"
        },
        var.in_mandated_tags
    )
}


/*
 | --
 | -- This NAT (network address translator) gateway lives
 | -- to route traffic from the private subnet in its availability
 | -- zone to external networks and the internet at large.
 | --
 | -- IMPORTANT - DO NOT LET TERRAFORM BRING UP EC2 INSTANCES INSIDE PRIVATE
 | -- SUBNETS BEFORE (SLOW TO CREATE) NAT GATEWAYS ARE UP AND RUNNING.
 | -- (see comment against definition of resource.aws_route.private).
 | --
 | -- It does this from within a public subnet and requires
 | -- an internet gateway and an elastic IP address.
 | --
 | -- It uses the elastic IP address to wrap outgoing traffic
 | -- from the private subnet and then unwraps the returning
 | -- response sending it back to the originating private service.
 | --
 | -- Every availability zone (and public/private subnet
 | -- pairing) will have its own NAT gateway and hence
 | -- its own elastic IP address.
 | --
*/
resource aws_nat_gateway this {

    count = var.in_num_private_subnets * var.in_create_private_gateway

    allocation_id = element( aws_eip.nat_gw_ip.*.id, count.index )
    subnet_id     = element( aws_subnet.public.*.id, count.index )
#####    depends_on    = [ "aws_internet_gateway.this" ]


    tags = merge(
        {
            Name = "nat-gateway-${ var.in_ecosystem }-${ var.in_timestamp }"
            Desc = "This NAT gateway in public subnet ${ element( aws_subnet.public.*.id, count.index ) } for ${ var.in_ecosystem } ${ var.in_description }"
        },
        var.in_mandated_tags
    )
}


/*
 | --
 | -- Almost all services make outgoing (egress) connections to the internet
 | -- regardless whether those services are in public or private subnets. So
 | -- an internet gateway and route are always created unless the variable
 | -- in_create_public_gateway is passed in and set to false.
 | --
 | -- This route through the internet gateway is created against the VPC's
 | -- default route table. The destination is set as 0.0.0.0/0 (everywhere).
 | --
*/
resource aws_route public {

    count  = var.in_create_public_gateway

    route_table_id         = data.aws_vpc.existing.main_route_table_id
    destination_cidr_block = "0.0.0.0/0"
    gateway_id             = var.in_internet_gateway_id
}


/*
 | --
 | -- These routes go into the newly created private route tables and
 | -- are designed to allow network interfaces (in the private subnets)
 | -- to initiate connections to the internet via its corresponding nat gateway
 | -- in a sister public subnet in the same availability zone.
 | --
 | -- IMPORTANT - DO NOT LET TERRAFORM BRING UP EC2 INSTANCES INSIDE PRIVATE
 | -- SUBNETS BEFORE (SLOW TO CREATE) NAT GATEWAYS ARE UP AND RUNNING.
 | --
 | -- Suppose systemd on bootup wants to get a rabbitmq docker image as
 | -- specified by a service unit file. Terraform will quickly bring up ec2
 | -- instances and then proceed to slowly create NAT gateways. To avoid
 | -- these types of bootup errors we must declare explicit dependencies to
 | -- delay ec2 creation until the private gateways and routes are ready.
 | --
*/
resource aws_route private {

    count = var.in_num_private_subnets * var.in_create_private_gateway

    route_table_id = element( aws_route_table.private.*.id, count.index )
    nat_gateway_id = element( aws_nat_gateway.this.*.id, count.index )

    destination_cidr_block = "0.0.0.0/0"
}


/*
 | --
 | -- This elastic IP address is presented to the NAT
 | -- (network address translator) and is only required
 | -- (like the NAT) when private subnets need to connect
 | -- externally to a publicly addressable endpoint.
 | --
 | -- Every availability zone (and public/private subnet
 | -- pairing) will have its own NAT gateway and hence
 | -- its own elastic IP address.
 | --
 | -- This elastic IP is created if at least 1 private subnet
 | -- exists and in_create_private_gateway is true.
 | --
*/
resource aws_eip nat_gw_ip {

    count = var.in_num_private_subnets * var.in_create_private_gateway

    vpc        = true
#####    depends_on = [ "aws_internet_gateway.this" ]


    tags = merge(
        {
            Name = "elastic-ip-${ var.in_ecosystem }-${ var.in_timestamp }"
            Desc = "This elastic IP in public subnet ${ element( aws_subnet.public.*.id, count.index ) } for ${ var.in_ecosystem } ${ var.in_description }"
        },
        var.in_mandated_tags
    )
}


/*
 | --
 | -- These route tables are required for holding private routes
 | -- so that private network interfaces (in the private subnets)
 | -- can initiate connections to the internet.
 | --
*/
resource aws_route_table private {

    count = var.in_num_private_subnets * var.in_create_private_gateway
    vpc_id = var.in_vpc_id

    tags = merge(
        {
            Name = "route-table-${ var.in_ecosystem }-${ var.in_timestamp }"
            Desc = "This route table associated with private subnet ${ element( aws_subnet.private.*.id, count.index ) } for ${ var.in_ecosystem } ${ var.in_description }"
        },
        var.in_mandated_tags
    )

}


/*
 | --
 | -- These route table associations per each availability zone binds
 | --
 | --   a) the route inside the route table that ...
 | --   b) goes to the NAT gateway inside the public subnet with ...
 | --   c) the private subnet that has ...
 | --   d) private interfaces that need to connect to the internet
 | --
*/
resource aws_route_table_association private {

    count = var.in_num_private_subnets * var.in_create_private_gateway

    subnet_id      = element( aws_subnet.private.*.id, count.index )
    route_table_id = element( aws_route_table.private.*.id, count.index )
}
