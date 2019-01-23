
#### Creating *new subnets* (and other network components) *within an existing VPC* is the primary function of this terraform module. This is in contrast to the [VPC Network terraform module](https://github.com/devops4me/terraform-aws-vpc-network) that does a similar job but *creates its own VPC* housing.


# Create Subnet Network in Existing VPC

Your **primary concern here** is to avoid a **subnet address overlap** scenario. The existing VPC will likely have subnets that have reserved and/or issued a certain number of IP addresses.

#### *We don't want the new stepping on the toes of the old.*

## Understanding how Subnets Carve the IP Address Space

To avoid the addressing overlap you need an understanding of

- the **VPC cidr block** (like 10.42.0.0/20) defines the entire VPC **allocable address range**
- the **VPC cidr integer** comes after the Cidr Block slash so is 20 if the cidr block is 10.42.0.0/20
- the **subnets max** integer specifies maximum number of carvable subnets. A **formula** for deriving it from the ***number of allocable addresses per subnet*** and the **VPC Cidr integer** is given below.
- a **subnet offset** count that says these n subnets *have already been allocated* - skip them
- terraform's **cidrsubnet function** that does the addressing math

**You!** - know the subnets that have already been created and this module does not attempt to work things out for itself. It takes your inputs as read and gets on with the job of **carving out extra subnets** in an existing vpc.

## Module Inputs

The above 3 variables must be provided along with the **ID of the existing VPC**. The sensible defaults mantra that held sway when a fresh VPC was being created, ceases to apply.

That said, all other inputs and behaviour run along the same lines as in the **[VPC network](https://github.com/devops4me/terraform-aws-vpc-network)** sister module.

---

## Usage

    module sub-network
    {
        source                  = "github.com/devops4me/terraform-aws-sub-network"

        in_vpc_id               = "${ local.the_vpc_id }"
        in_vpc_cidr             = "${ local.the_vpc_cidr }"
        in_subnets_max          = "${ local.the_subnets_max }"
        in_num_existing_subnets = "${ local.the_num_existing_subnets }"

        in_num_public_subnets   = 2
        in_num_private_subnets  = 0
    }

---

## Module Inputs

| Input Variable             | Type    | Description                                                   | Default        |
|:-------------------------- |:-------:|:------------------------------------------------------------- |:--------------:|
| **in_vpc_id**              | String  | The ID of the VPC to create subnet networks within.           | vpc-123456789  |
| **in_vpc_cidr**            | String  | The VPC's Cidr defining the range of available IP addresses   | 10.42.0.0/16   |
| **in_subnets_max**         | Integer | 2 to the power of this integer is the **maximum number** of carvable subnets. **How do we reverse engineer this value?** See the section below this table. | 4 (16 subnets) |
| **in_num_existing_subnets** | Integer | This number of existing subnets plus the number of subnets to create must not exceed the maximum number of carvable subnets in this vpc. It is fine for the value to exceed the actual number of existing subnets as long as there is sufficient headroom for the new subnets. | mandatory |
| **in_num_private_subnets** | Integer | Number of private subnets to create across availability zones | 3              |
| **in_num_public_subnets**  | Integer | Number of public subnets to create across availability zones. If one or more an internet gateway and route to the internet will be created regardless of the value of the in_create_gateway boolean variable. | 3 |
| **in_create_gateway**      | Boolean | If set to true an internet gateway and route will be created even when no public subnets are requested. | false |
| **in_ecosystem**           | String  | the class name of the ecosystem being built here              | eco-system     |


## subnets_max | How to Reverse Engineer its Value?

A subnet_max of 8 means you can have a maximum of **2<sup>8</sup>** (256) subnets. 4 means your VPC can hold at most 16 subnets.When creating a network within an existing VPC you need to reverse engineer and provide the correct subnet max value to avoid overlap.

To reverse engineer this value go to the AWS Console and

- note the **trailing Cidr integer** on the IPV4 Cidr column **on the VPC page** *( 20 if the cidr block is 10.42.0.0/20 )*
- note the Available IPv4 column **on the subnet page** against your VPC.
- increase the available IPv4 count until you arrive at the next power of 2

The subnet_address_power is the integer power of 2 that you got after increasing the available ipv4 count.

| IPv4 Count | Next 2 Power | 2<sup>subnet address power</sup> | subnet address power | VPC Cidr Block | VPC Cidr Int | Formula    | Subnet Max |
|:----------:|:------------:|:-------------------------------- |:--------------------:|:--------------:|:------------:|:-----------|:----------:|
|  250       |   256        | **2<sup>8</sup>**                | 8                    | 10.222.0.0/16  |  16          | 32-(16+8)  |  8         |
|  4087      |   4096       | **2<sup>12</sup>**               | 12                   | 10.111.0.0/16  |  16          | 32-(16+12) |  4         |


### Simple Formula

### `subnet_max = 32 - ( vpc_cidr_int + subnet_address_power )`

A **common error** is to read the IPV4 Cidr from the subnets screen - don't! Read it from the VPC screen otherwise you are getting the Subnet's Cidr block which is **not the same as the VPC's Cidr** block.

---

## subnets max | addresses per subnet

The subnet max can combine with the VPC Cidr to define the number of **addresses available in each subnet's** pool.

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

## subnet cidr blocks | cidrsubnet function

You do not need to specify each subnet's CIDR block because they are calculated by passing the VPC Cidr (in_vpc_cidr), the Subnets Max (in_subnets_max) and the present subnet's index (count.index) into Terraform's **cidrsubnet function**.

The behaviour of Terraform's **cidrsubnet function** is involved but slightly outside the scope of this VPC/Subnet module document. Read **[Understanding the Terraform Cidr Subnet Function](http://www.devopswiki.co.uk/wiki/devops/terraform/terraform-cidrsubnet-function)** for a fuller coverage of cidrsubnet's behaviour.

---
