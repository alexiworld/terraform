The tf-v5 example works. 

Creates VPC, Subnets, GW, AutoScale Group, Application Loadbalancer, VM(s).

Updates Route Table to allow internet traffic to reach the VM and get Hello, World back.

Resources:

https://www.youtube.com/watch?v=VJYA8mzmqFk (How to create "default-like" AWS VPC)
https://www.youtube.com/watch?v=6XSroskdCF0 (Terraform Basics)
https://github.com/antonputra/tutorials/tree/main/lessons/164
https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc.html
https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/default_route_table
https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route
https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association
https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/internet_gateway_attachment
https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table
https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance
https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group
https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/launch_configuration
https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group
https://developer.hashicorp.com/terraform/language/meta-arguments/depends_on
https://developer.hashicorp.com/terraform/language/data-sources