
#### Creating *new subnets* (and other network components) *within an existing VPC* is the primary function of this terraform module. This is in contrast to the [VPC Network terraform module](https://github.com/devops4me/terraform-aws-vpc-network) that does a similar job but *creates its own VPC* housing.


# Create Subnet Network in Existing VPC

Your **primary concern here** is to avoid a **subnet address overlap** scenario. The existing VPC will likely have subnets that have reserved and/or issued a certain number of IP addresses.

#### *We don't want the new stepping on the toes of the old.*

## Understanding how Subnets Carve the IP Address Space

To avoid the addressing overlap you need an understanding of

- the **VPC cidr block** (and integer) defining the entire VPC addresses range
- the **subnets max** integer that specifies the ***count of allocable addresses*** per subnet
- a **subnet offset** count that says these n subnets *have already been allocated* - skip them
- terraform's **cidrsubnet function** that does the addressing math

**You!** - know the subnets that have already been created and this module does not attempt to work things out for itself. It takes your inputs as read and gets on with the job of **carving out extra subnets** in an existing vpc.

## Module Inputs

The above 3 variables must be provided along with the **ID of the existing VPC**. The sensible defaults mantra that held sway when a fresh VPC was being created, ceases to apply.

That said, all other inputs and behaviour run along the same lines as in the **[VPC network](https://github.com/devops4me/terraform-aws-vpc-network)** sister module.





## Usage

    module vpc-network
    {
        source                 = "github.com/devops4me/terraform-aws-sub-network"
        in_vpc_cidr            = "10.245.0.0/16"
        in_num_private_subnets = 6
        in_num_public_subnets  = 3
        in_ecosystem           = "kubernetes-cluster"
    }

    output subnet_ids
    {
        value = "${ module.vpc-network.out_subnet_ids }"
    }

    output private_subnet_ids
    {
        value = "${ module.vpc-network.out_private_subnet_ids }"
    }

    output public_subnet_ids
    {
        value = "${ module.vpc-network.out_public_subnet_ids }"
    }


The most common usage is to specify the VPC Cidr, the number of public / private subnets and the class of ecosystem being built.

## [Examples and Tests](test-vpc.network)

**[This terraform module has runnable example integration tests](test-vpc.network)**. Read the instructions on how to clone the project and run the integration tests.


## Module Inputs

| Input Variable             | Type    | Description                                                   | Default        |
|:-------------------------- |:-------:|:------------------------------------------------------------- |:--------------:|
| **in_vpc_id**              | String  | The ID of the VPC to create subnet networks within.           | vpc-123456789  |
| **in_vpc_cidr**            | String  | The VPC's Cidr defining the range of available IP addresses   | 10.42.0.0/16   |
| **in_subnets_max**         | Integer | 2 to the power of this is the max number of carvable subnets  | 4 (16 subnets) |
| **in_subnets_exist_count** | Integer | This existing subnet count plus the number of subnets to create must not exceed the maximum number of carvable subnets in this vpc. | mandatory |
| **in_num_private_subnets** | Integer | Number of private subnets to create across availability zones | 3              |
| **in_num_public_subnets**  | Integer | Number of public subnets to create across availability zones. If one or more an internet gateway and route to the internet will be created regardless of the value of the in_create_gateway boolean variable. | 3 |
| **in_create_gateway**      | Boolean | If set to true an internet gateway and route will be created even when no public subnets are requested. | false |
| **in_ecosystem**           | String  | the class name of the ecosystem being built here              | eco-system     |

## subnets into availability zones | round robin

You can create **more or less subnets** than there are availability zones in the VPC's region. You can ask for **6 private subnets** in a **3 availability zone region**. The subnets are distributed into the availability zones like dealing a deck of cards.

Every permutation of subnets and availability zones is catered for so you can demand

- **less subnets** than availability zones (so some won't get any)
- a subnet count that is an **exact multiple** of the zone count (equality reigns)
- that **no subnets** (public and/or private) get created
- nothing - and each availability zone will get one public and one private subnet

---

## in_subnets_max | variable

This variable defines the maximum number of subnets that can be carved out of your VPC (you do not need to use them all). It then combines with the VPC Cidr to define the number of **addresses available in each subnet's** pool.

### 2<sup>32 - (in_vpc_cidr + in_subnets_max)</sup> = number of subnet addresses

A **vpc_cidr of 21 (eg 10.42.0.0/21)** and **subnets_max of 5** gives a pool of **2<sup>32-(21+5)</sup> = 64 addresses** in each subnet. (Note it is actually 2 less). We can carve out **2<sup>5</sup> = 32 subnets** as in_subnets_max is 5.

### Dividing VPC Addresses into Subnet Blocks

| vpc cidr  | subnets max | number of addresses per subnet                          | max subnets                 | vpc addresses total                  |
|:---------:|:-----------:|:------------------------------------------------------- |:--------------------------- |:------------------------------------ |
|  /16      |   6         | 2<sup>32-(16+6)</sup> = 2<sup>10</sup> = 1024 addresses | 2<sup>6</sup> = 64 subnets  | 2<sup>32-16</sup> = 65,536 addresses |
|  /16      |   4         | 2<sup>32-(16+4)</sup> = 2<sup>12</sup> = 4096 addresses | 2<sup>4</sup> = 16 subnets  | 2<sup>32-16</sup> = 65,536 addresses |
|  /20      |   8         | 2<sup>32-(20+8)</sup> = 2<sup>4</sup>  = 16 addresses   | 2<sup>8</sup> = 256 subnets | 2<sup>32-20</sup> = 4,096 addresses  |
|  /20      |   2         | 2<sup>32-(20+2)</sup> = 2<sup>10</sup> = 1024 addresses | 2<sup>2</sup> = 4 subnets   | 2<sup>32-20</sup> = 4,096 addresses  |

Check the below formula holds true for every row in the above table.

<pre><code>addresses per subnet * number of subnets = total available VPC addresses</code></pre>

---

## in_subnets_max | in_vpc_cidr

**How many addresses will each subnet contain** and **how many subnets can be carved out of the VPC's IP address pool**? These questions are answered by the vpc_cidr and the subnets_max variable.

The VPC Cidr default is 16 giving 65,536 total addresses and the subnets max default is 4 so **16 subnets** can be carved out with each subnet ready to issue 4,096 addresses.

Clearly the addresses per subnet multiplied by the number of subnets cannot exceed the available VPC address pool. To keep your powder dry, ensure **in_vpc_cidr plus in_subnets_max does not exceed 31**.

## number of subnets constraint

It is unlikely **in_num_private_subnets + in_num_public_subnets** will exceed the maximum number of subnets that can be carved out of the VPC. Usually it is a lot less but be prudent and ensure that **in_num_private_subnets + in_num_public_subnets < 2<sup>in_subnets_max</sup>**


## subnet cidr blocks | cidrsubnet function

You do not need to specify each subnet's CIDR block because they are calculated by passing the VPC Cidr (in_vpc_cidr), the Subnets Max (in_subnets_max) and the present subnet's index (count.index) into Terraform's **cidrsubnet function**.

The behaviour of Terraform's **cidrsubnet function** is involved but slightly outside the scope of this VPC/Subnet module document. Read **[Understanding the Terraform Cidr Subnet Function](http://www.devopswiki.co.uk/wiki/devops/terraform/terraform-cidrsubnet-function)** for a fuller coverage of cidrsubnet's behaviour.

## constraint | in_subnet_offset

It is unlikely **in_num_private_subnets + in_num_public_subnets** will exceed the maximum number of subnets that can be carved out of the VPC. Usually it is a lot less but be prudent and ensure that **in_num_private_subnets + in_num_public_subnets < 2<sup>in_subnets_max</sup>**


---
