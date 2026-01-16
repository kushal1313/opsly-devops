locals {
  max_subnet_length = max(
    length(var.Private_App_Subnets),
    length(var.Private_DB_Subnets),
    length(var.firewall_protected_subnets),
    length(var.public_subnets),
  )
  nat_gateway_count = var.single_nat_gateway ? 1 : var.one_nat_gateway_per_az ? length(var.azs) : local.max_subnet_length

  vpc_id = element(
    concat(
      aws_vpc.this.*.id,
    ),
    0,
  )
}

################################################################################
# VPC Module
################################################################################

resource "aws_vpc" "this" {
  count = var.create_vpc ? 1 : 0

  cidr_block                       = var.cidr
  instance_tenancy                 = var.instance_tenancy
  enable_dns_hostnames             = var.enable_dns_hostnames
  enable_dns_support               = var.enable_dns_support
  # enable_classiclink               = var.enable_classiclink
  # enable_classiclink_dns_support   = var.enable_classiclink_dns_support
  assign_generated_ipv6_cidr_block = var.enable_ipv6

  tags = merge(
    var.mandatory_tags,
    var.custom_tags,
  )

}

################################################################################
# Internet Gateway
################################################################################

resource "aws_internet_gateway" "this" {
  count = var.create_vpc && var.create_igw && length(var.public_subnets) > 0 ? 1 : 0

  vpc_id = var.use_existing_vpc ? var.vpc_id : local.vpc_id

  tags = merge(
    var.mandatory_tags,
    var.custom_tags,
  )
}

################################################################################
# Publiс routes
################################################################################

resource "aws_route_table" "public" {
  count = var.create_vpc && length(var.public_subnets) > 0 ? 1 : 0

  vpc_id = var.use_existing_vpc ? var.vpc_id : local.vpc_id

  tags = merge(
    var.mandatory_tags,
    var.custom_tags,
  )
}

resource "aws_route" "public_internet_gateway" {
  count = var.create_vpc && var.create_igw && length(var.public_subnets) > 0 ? 1 : 0

  route_table_id         = aws_route_table.public[0].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this[0].id

  timeouts {
    create = "5m"
  }
}

################################################################################
# Internet Gateway Routes for Firewall-Protected Route Tables (All AZs)
################################################################################

resource "aws_route" "firewall_internet_gateway" {
  count = var.create_vpc && var.create_igw && length(var.firewall_protected_subnets) > 0 ? length(aws_route_table.firewall-protected-rt) : 0

  route_table_id         = element(aws_route_table.firewall-protected-rt[*].id, count.index)
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this[0].id

  timeouts {
    create = "5m"
  }
}
################################################################################
# Private routes
# There are as many routing tables as the number of NAT gateways
################################################################################

resource "aws_route_table" "private-rt" {
  count = var.create_vpc && local.max_subnet_length > 0 ? local.nat_gateway_count : 0

  vpc_id = var.use_existing_vpc ? var.vpc_id : local.vpc_id


  tags = merge(
    var.mandatory_tags,
    var.custom_tags,
  )
}


################################################################################
# Database routes
################################################################################

resource "aws_route_table" "private-db-rt" {
  count = var.create_vpc && var.create_database_subnet_route_table && length(var.Private_DB_Subnets) > 0 ? var.single_nat_gateway || var.create_database_internet_gateway_route ? 1 : length(var.Private_DB_Subnets) : 0

  vpc_id = var.use_existing_vpc ? var.vpc_id : local.vpc_id

  tags = merge(
    var.mandatory_tags,
    var.custom_tags,
  )
}

resource "aws_route" "database_nat_gateway" {
  count = var.create_vpc && var.create_database_subnet_route_table && length(var.Private_DB_Subnets) > 0 && false == var.create_database_internet_gateway_route && var.create_database_nat_gateway_route && var.enable_nat_gateway && !var.firewall_associated_nat ? var.single_nat_gateway ? 1 : length(var.Private_DB_Subnets) : 0

  route_table_id         = element(aws_route_table.private-db-rt.*.id, count.index)
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = element(aws_nat_gateway.this.*.id, count.index)

  timeouts {
    create = "5m"
  }
}

resource "aws_route" "database_nat_gateway_firewall" {
  count = var.create_vpc && var.create_database_subnet_route_table && length(var.Private_DB_Subnets) > 0 && false == var.create_database_internet_gateway_route && var.create_database_nat_gateway_route && var.enable_nat_gateway && var.firewall_associated_nat ? (var.single_nat_gateway ? 1 : length(var.Private_DB_Subnets)) : 0

  route_table_id         = element(aws_route_table.private-db-rt.*.id, count.index)
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = element(aws_nat_gateway.nat_firewall.*.id, count.index)

  timeouts {
    create = "5m"
  }
}

resource "aws_route_table" "firewall-protected-rt" {
  count  = length(var.firewall_protected_subnets)
  vpc_id = var.use_existing_vpc ? var.vpc_id : local.vpc_id
  tags = merge(
    var.mandatory_tags,
    var.custom_tags,
  )
  lifecycle {
    ignore_changes = [tags.Name]
  }
}

################################################################################
# Public subnet
################################################################################

resource "aws_subnet" "public" {
  count = var.create_vpc && length(var.public_subnets) > 0 && (false == var.one_nat_gateway_per_az || length(var.public_subnets) >= length(var.azs)) ? length(var.public_subnets) : 0

  vpc_id                          = local.vpc_id
  cidr_block                      = element(concat(var.public_subnets, [""]), count.index)
  availability_zone               = length(regexall("^[a-z]{2}-", element(var.azs, count.index))) > 0 ? element(var.azs, count.index) : null
  availability_zone_id            = length(regexall("^[a-z]{2}-", element(var.azs, count.index))) == 0 ? element(var.azs, count.index) : null
  map_public_ip_on_launch         = var.map_public_ip_on_launch
  assign_ipv6_address_on_creation = var.public_subnet_assign_ipv6_address_on_creation == null ? var.assign_ipv6_address_on_creation : var.public_subnet_assign_ipv6_address_on_creation

  ipv6_cidr_block = var.enable_ipv6 && length(var.public_subnet_ipv6_prefixes) > 0 ? cidrsubnet(aws_vpc.this[0].ipv6_cidr_block, 8, var.public_subnet_ipv6_prefixes[count.index]) : null

  tags = merge(
    var.mandatory_tags,
    var.custom_tags,
  )
}

################################################################################
# Private subnet
################################################################################

resource "aws_subnet" "private" {
  count = var.create_vpc && length(var.Private_App_Subnets) > 0 ? length(var.Private_App_Subnets) : 0

  vpc_id                          = local.vpc_id
  cidr_block                      = var.Private_App_Subnets[count.index]
  availability_zone               = length(regexall("^[a-z]{2}-", element(var.azs, count.index))) > 0 ? element(var.azs, count.index) : null
  availability_zone_id            = length(regexall("^[a-z]{2}-", element(var.azs, count.index))) == 0 ? element(var.azs, count.index) : null
  assign_ipv6_address_on_creation = var.private_subnet_assign_ipv6_address_on_creation == null ? var.assign_ipv6_address_on_creation : var.private_subnet_assign_ipv6_address_on_creation

  ipv6_cidr_block = var.enable_ipv6 && length(var.private_subnet_ipv6_prefixes) > 0 ? cidrsubnet(aws_vpc.this[0].ipv6_cidr_block, 8, var.private_subnet_ipv6_prefixes[count.index]) : null

  tags = merge(
    var.mandatory_tags,
    var.custom_tags,
  )
}

################################################################################
# Firewall public subnets
################################################################################

resource "aws_subnet" "firewall-subnet" {
  count = var.create_vpc && length(var.firewall_subnets) > 0 && (false == var.one_nat_gateway_per_az || length(var.public_subnets) >= length(var.azs)) ? length(var.firewall_subnets) : 0

  vpc_id                  = local.vpc_id
  cidr_block              = element(concat(var.firewall_subnets, [""]), count.index)
  availability_zone       = length(regexall("^[a-z]{2}-", element(var.azs, count.index))) > 0 ? element(var.azs, count.index) : null
  availability_zone_id    = length(regexall("^[a-z]{2}-", element(var.azs, count.index))) == 0 ? element(var.azs, count.index) : null
  map_public_ip_on_launch = var.map_public_ip_on_launch

  tags = merge(
    var.mandatory_tags,
    var.custom_tags,
  )
}

################################################################################
# Database subnet
################################################################################

resource "aws_subnet" "database" {
  count = var.create_vpc && length(var.Private_DB_Subnets) > 0 ? length(var.Private_DB_Subnets) : 0

  vpc_id               = local.vpc_id
  cidr_block           = var.Private_DB_Subnets[count.index]
  availability_zone    = length(regexall("^[a-z]{2}-", element(var.azs, count.index))) > 0 ? element(var.azs, count.index) : null
  availability_zone_id = length(regexall("^[a-z]{2}-", element(var.azs, count.index))) == 0 ? element(var.azs, count.index) : null

  tags = merge(
    var.mandatory_tags,
    var.custom_tags,
  )
}

resource "aws_db_subnet_group" "database" {
  count = var.create_vpc && length(var.Private_DB_Subnets) > 0 && var.create_database_subnet_group ? 1 : 0

  name        = lower(coalesce(var.database_subnet_group_name, var.name))
  description = "Database subnet group for ${var.name}"
  subnet_ids  = aws_subnet.database[*].id

  tags = merge(
    var.mandatory_tags,
    var.custom_tags,
  )
}

################################################################################
# # Firewall protected public subnets
################################################################################

resource "aws_subnet" "firewall_protected_subnets" {
  count = var.create_vpc && length(var.firewall_protected_subnets) > 0 ? length(var.firewall_protected_subnets) : 0

  vpc_id                  = local.vpc_id
  cidr_block              = var.firewall_protected_subnets[count.index]
  availability_zone       = length(regexall("^[a-z]{2}-", element(var.azs, count.index))) > 0 ? element(var.azs, count.index) : null
  availability_zone_id    = length(regexall("^[a-z]{2}-", element(var.azs, count.index))) == 0 ? element(var.azs, count.index) : null
  map_public_ip_on_launch = var.map_public_ip_on_launch_firewall
  tags = merge(
    var.mandatory_tags,
    var.custom_tags,
  )
}

################################################################################
# NAT Gateway
################################################################################

# Workaround for interpolation not being able to "short-circuit" the evaluation of the conditional branch that doesn't end up being used
# Source: https://github.com/hashicorp/terraform/issues/11566#issuecomment-289417805
#
# The logical expression would be
#
#    nat_gateway_ips = var.reuse_nat_ips ? var.external_nat_ip_ids : aws_eip.nat.*.id
#
# but then when count of aws_eip.nat.*.id is zero, this would throw a resource not found error on aws_eip.nat.*.id.
locals {
  nat_gateway_ips = split(
    ",",
    var.reuse_nat_ips ? join(",", var.external_nat_ip_ids) : join(",", aws_eip.nat.*.id),
  )
}

resource "aws_eip" "nat" {
  count = var.create_vpc && !var.reuse_nat_ips && (var.public_associated_nat || var.firewall_associated_nat) ? local.nat_gateway_count : 0

   domain = "vpc"

  tags = merge(
    var.mandatory_tags,
    var.custom_tags,
  )
}

resource "aws_nat_gateway" "this" {
  count = var.create_vpc && var.public_associated_nat ? local.nat_gateway_count : 0

  allocation_id = element(
    local.nat_gateway_ips,
    var.single_nat_gateway ? 0 : count.index,
  )
  subnet_id = element(
    aws_subnet.public.*.id,
    var.single_nat_gateway ? 0 : count.index,
  )

  tags = merge(
    var.mandatory_tags,
    var.custom_tags,
  )

  depends_on = [aws_internet_gateway.this]
}
resource "aws_nat_gateway" "nat_firewall" {
  count = var.create_vpc && var.firewall_associated_nat ? local.nat_gateway_count : 0

  allocation_id = element(
    local.nat_gateway_ips,
    var.single_nat_gateway ? 0 : count.index,
  )
  subnet_id = element(
    aws_subnet.firewall_protected_subnets.*.id,
    var.single_nat_gateway ? 0 : count.index,
  )

  tags = merge(
    var.mandatory_tags,
    var.custom_tags,
  )

  depends_on = [aws_internet_gateway.this]
}
resource "aws_route" "private_nat_gateway" {
  count = var.create_vpc && var.enable_nat_gateway  && !var.firewall_associated_nat ? local.nat_gateway_count : 0

  route_table_id         = element(aws_route_table.private-rt.*.id, count.index)
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = element(aws_nat_gateway.this.*.id, count.index)

  timeouts {
    create = "5m"
  }
}

resource "aws_route" "private_nat_gateway_firewall" {
  count = var.create_vpc && var.enable_nat_gateway && var.firewall_associated_nat ? local.nat_gateway_count : 0

  route_table_id         = element(aws_route_table.private-rt.*.id, count.index)
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = element(aws_nat_gateway.nat_firewall.*.id, count.index)

  timeouts {
    create = "5m"
  }
}


################################################################################
# Route table association
################################################################################

resource "aws_route_table_association" "private" {
  count = var.create_vpc && length(var.Private_App_Subnets) > 0 ? length(var.Private_App_Subnets) : 0

  subnet_id = element(aws_subnet.private.*.id, count.index)
  route_table_id = element(
    aws_route_table.private-rt.*.id,
    var.single_nat_gateway ? 0 : count.index,
  )
}

resource "aws_route_table_association" "database" {
  count = var.create_vpc && length(var.Private_DB_Subnets) > 0 ? length(var.Private_DB_Subnets) : 0

  subnet_id = element(aws_subnet.database[*].id, count.index)
  route_table_id = element(
    coalescelist(aws_route_table.private-db-rt[*].id, aws_route_table.private-rt[*].id),
    var.create_database_subnet_route_table ? var.single_nat_gateway || var.create_database_internet_gateway_route ? 0 : count.index : count.index,
  )
}


resource "aws_route_table_association" "public" {
  count = var.create_vpc && length(var.public_subnets) > 0 ? length(var.public_subnets) : 0

  subnet_id      = element(aws_subnet.public.*.id, count.index)
  route_table_id = aws_route_table.public[0].id
}
resource "aws_route_table_association" "firewall_subnets" {
  count = var.create_vpc && length(var.firewall_subnets) > 0 ? length(var.firewall_subnets) : 0

  subnet_id      = element(aws_subnet.public.*.id, count.index)
  route_table_id = aws_route_table.public[0].id
}

resource "aws_route_table_association" "firewall-protected-subnets" {
  count = length(var.firewall_protected_subnets)

  subnet_id      = element(aws_subnet.firewall_protected_subnets.*.id, count.index)
  route_table_id = element(aws_route_table.firewall-protected-rt.*.id, count.index)
}
################################################################################
# AWS VPC S3 Endpoint
################################################################################

resource "aws_vpc_endpoint" "s3" {
  count        = var.create_s3_endpoint ? 1 : 0
  vpc_id       = var.use_existing_vpc ? var.vpc_id : local.vpc_id
  service_name = "com.amazonaws.us-east-1.s3"
  tags = merge(
    var.mandatory_tags,
    var.custom_tags,
  )
}

################################################################################
# Route table association of AWS VPC S3 Endpoint with private route table
################################################################################

resource "aws_vpc_endpoint_route_table_association" "vpce-db-rta" {
  count           = var.create_s3_endpoint ? length(var.Private_DB_Subnets) : 0
  route_table_id  = element(aws_route_table.private-db-rt[*].id, count.index)
  vpc_endpoint_id = aws_vpc_endpoint.s3[0].id
}

resource "aws_vpc_endpoint_route_table_association" "vpce-rta" {
  count = var.create_s3_endpoint ? length(var.Private_App_Subnets) : 0

  route_table_id  = element(aws_route_table.private-rt[*].id, count.index)
  vpc_endpoint_id = aws_vpc_endpoint.s3[0].id
}

################################################################################
# IGW Firewall route table and route table association
################################################################################

resource "aws_route_table" "igw-fw" {
  count  = var.create_vpc && var.internet_gateway_fw_routetable ? 1 : 0
  vpc_id = var.use_existing_vpc ? var.vpc_id : local.vpc_id
  tags = merge(
    var.mandatory_tags,
    var.custom_tags,
  )

}

resource "aws_route_table_association" "igw-fw-rta" {
  count = var.internet_gateway_fw_routetable ? length(var.public_subnets) : 0

  gateway_id     = aws_internet_gateway.this[0].id
  route_table_id = aws_route_table.igw-fw[0].id
}

################################################################################
# Default Network ACLs
################################################################################

resource "aws_default_network_acl" "this" {
  count = var.create_vpc && var.manage_default_network_acl ? 1 : 0

  default_network_acl_id = aws_vpc.this[0].default_network_acl_id

  subnet_ids = null
  dynamic "ingress" {
    for_each = var.default_network_acl_ingress
    content {
      action          = ingress.value.action
      cidr_block      = lookup(ingress.value, "cidr_block", null)
      from_port       = ingress.value.from_port
      icmp_code       = lookup(ingress.value, "icmp_code", null)
      icmp_type       = lookup(ingress.value, "icmp_type", null)
      ipv6_cidr_block = lookup(ingress.value, "ipv6_cidr_block", null)
      protocol        = ingress.value.protocol
      rule_no         = ingress.value.rule_no
      to_port         = ingress.value.to_port
    }
  }
  dynamic "egress" {
    for_each = var.default_network_acl_egress
    content {
      action          = egress.value.action
      cidr_block      = lookup(egress.value, "cidr_block", null)
      from_port       = egress.value.from_port
      icmp_code       = lookup(egress.value, "icmp_code", null)
      icmp_type       = lookup(egress.value, "icmp_type", null)
      ipv6_cidr_block = lookup(egress.value, "ipv6_cidr_block", null)
      protocol        = egress.value.protocol
      rule_no         = egress.value.rule_no
      to_port         = egress.value.to_port
    }
  }

  tags = merge(
    var.mandatory_tags,
    var.custom_tags,
  )

  lifecycle {
    ignore_changes = [subnet_ids]
  }
}

################################################################################
# Public Network ACLs
################################################################################

resource "aws_network_acl" "public" {
  count = var.create_vpc && var.public_dedicated_network_acl && length(var.public_subnets) > 0 ? 1 : 0

  vpc_id     = local.vpc_id
  subnet_ids = aws_subnet.public[*].id

  tags = merge(
    var.mandatory_tags,
    var.custom_tags,
  )
}

resource "aws_network_acl_rule" "public_inbound" {
  count = var.create_vpc && var.public_dedicated_network_acl && length(var.public_subnets) > 0 ? length(var.public_inbound_acl_rules) : 0

  network_acl_id = aws_network_acl.public[0].id

  egress          = false
  rule_number     = var.public_inbound_acl_rules[count.index]["rule_number"]
  rule_action     = var.public_inbound_acl_rules[count.index]["rule_action"]
  from_port       = lookup(var.public_inbound_acl_rules[count.index], "from_port", null)
  to_port         = lookup(var.public_inbound_acl_rules[count.index], "to_port", null)
  icmp_code       = lookup(var.public_inbound_acl_rules[count.index], "icmp_code", null)
  icmp_type       = lookup(var.public_inbound_acl_rules[count.index], "icmp_type", null)
  protocol        = var.public_inbound_acl_rules[count.index]["protocol"]
  cidr_block      = lookup(var.public_inbound_acl_rules[count.index], "cidr_block", null)
  ipv6_cidr_block = lookup(var.public_inbound_acl_rules[count.index], "ipv6_cidr_block", null)
}

resource "aws_network_acl_rule" "public_outbound" {
  count = var.create_vpc && var.public_dedicated_network_acl && length(var.public_subnets) > 0 ? length(var.public_outbound_acl_rules) : 0

  network_acl_id = aws_network_acl.public[0].id

  egress          = true
  rule_number     = var.public_outbound_acl_rules[count.index]["rule_number"]
  rule_action     = var.public_outbound_acl_rules[count.index]["rule_action"]
  from_port       = lookup(var.public_outbound_acl_rules[count.index], "from_port", null)
  to_port         = lookup(var.public_outbound_acl_rules[count.index], "to_port", null)
  icmp_code       = lookup(var.public_outbound_acl_rules[count.index], "icmp_code", null)
  icmp_type       = lookup(var.public_outbound_acl_rules[count.index], "icmp_type", null)
  protocol        = var.public_outbound_acl_rules[count.index]["protocol"]
  cidr_block      = lookup(var.public_outbound_acl_rules[count.index], "cidr_block", null)
  ipv6_cidr_block = lookup(var.public_outbound_acl_rules[count.index], "ipv6_cidr_block", null)
}

################################################################################
# Private Network ACLs
################################################################################

resource "aws_network_acl" "private" {
  count = var.create_vpc && var.private_dedicated_network_acl && length(var.Private_App_Subnets) > 0 ? 1 : 0

  vpc_id     = local.vpc_id
  subnet_ids = aws_subnet.private[*].id

  tags = merge(
    var.mandatory_tags,
    var.custom_tags,
  )
}

resource "aws_network_acl_rule" "private_inbound" {
  count = var.create_vpc && var.private_dedicated_network_acl && length(var.Private_App_Subnets) > 0 ? length(var.private_inbound_acl_rules) : 0

  network_acl_id = aws_network_acl.private[0].id

  egress          = false
  rule_number     = var.private_inbound_acl_rules[count.index]["rule_number"]
  rule_action     = var.private_inbound_acl_rules[count.index]["rule_action"]
  from_port       = lookup(var.private_inbound_acl_rules[count.index], "from_port", null)
  to_port         = lookup(var.private_inbound_acl_rules[count.index], "to_port", null)
  icmp_code       = lookup(var.private_inbound_acl_rules[count.index], "icmp_code", null)
  icmp_type       = lookup(var.private_inbound_acl_rules[count.index], "icmp_type", null)
  protocol        = var.private_inbound_acl_rules[count.index]["protocol"]
  cidr_block      = lookup(var.private_inbound_acl_rules[count.index], "cidr_block", null)
  ipv6_cidr_block = lookup(var.private_inbound_acl_rules[count.index], "ipv6_cidr_block", null)
}

resource "aws_network_acl_rule" "private_outbound" {
  count = var.create_vpc && var.private_dedicated_network_acl && length(var.Private_App_Subnets) > 0 ? length(var.private_outbound_acl_rules) : 0

  network_acl_id = aws_network_acl.private[0].id

  egress          = true
  rule_number     = var.private_outbound_acl_rules[count.index]["rule_number"]
  rule_action     = var.private_outbound_acl_rules[count.index]["rule_action"]
  from_port       = lookup(var.private_outbound_acl_rules[count.index], "from_port", null)
  to_port         = lookup(var.private_outbound_acl_rules[count.index], "to_port", null)
  icmp_code       = lookup(var.private_outbound_acl_rules[count.index], "icmp_code", null)
  icmp_type       = lookup(var.private_outbound_acl_rules[count.index], "icmp_type", null)
  protocol        = var.private_outbound_acl_rules[count.index]["protocol"]
  cidr_block      = lookup(var.private_outbound_acl_rules[count.index], "cidr_block", null)
  ipv6_cidr_block = lookup(var.private_outbound_acl_rules[count.index], "ipv6_cidr_block", null)
}
