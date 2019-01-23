
#### Creating *new subnets* (and other network components) *within an existing VPC* is the primary function of this terraform module. This is in contrast to the [VPC Network terraform module](https://github.com/devops4me/terraform-aws-vpc-network) that does a similar job but *creates its own VPC* housing.


# Create Subnet Network in Existing VPC

Your **primary concern here** is to avoid a **subnet address overlap** scenario. The existing VPC will likely have subnets that have reserved and/or issued a certain number of IP addresses.

#### *We don't want the new stepping on the toes of the old.*

## Understanding how Subnets Carve the IP Address Space

To avoid the addressing overlap you need an understanding of

- the **VPC cidr block** (and integer) defining the entire VPC addresses range
- the **subnet-max** integer that specifies the ***count of allocable addresses*** per subnet
- a **subnet-offset** count that says these n subnets *have already been allocated* - skip them
- terraform's **cidrsubnet function** that does the addressing math

You know the subnets that have already been created and this module does not attempt to work things out for itself. It takes your inputs as read and gets on with the job of carving out the requeted number of subnets.

## Module Inputs

The above 3 variables must be provided along with the **ID of the existing VPC**. The sensible defaults mantra that held sway when a fresh VPC was being created, ceases to apply.

That said, all other inputs and behaviour run along the same lines as in the **[VPC network](https://github.com/devops4me/terraform-aws-vpc-network)** sister module.

