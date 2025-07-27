# Dynamic Security Group Module
# This module creates security groups with dynamic rules based on input variables

locals {
  # Merge common tags with provided tags
  security_group_tags = merge(
    {
      Name = "${var.project_name}-${var.security_group_name}"
      Type = var.security_group_type
      Project = var.project_name
      Owner = "lks-team"
    },
    var.common_tags,
    var.tags
  )
}

# Create the security group
resource "aws_security_group" "dynamic_sg" {
  name = "${var.project_name}-${var.security_group_name}"
  description = var.description
  vpc_id      = var.vpc_id

  # Dynamic ingress rules
  dynamic "ingress" {
    for_each = var.ingress_rules
    content {
      description      = ingress.value.description
      from_port        = ingress.value.from_port
      to_port          = ingress.value.to_port
      protocol         = ingress.value.protocol
      cidr_blocks      = lookup(ingress.value, "cidr_blocks", null)
      security_groups  = lookup(ingress.value, "security_groups", null)
      self             = lookup(ingress.value, "self", null)
      ipv6_cidr_blocks = lookup(ingress.value, "ipv6_cidr_blocks", null)
    }
  }

  # Dynamic egress rules
  dynamic "egress" {
    for_each = var.egress_rules
    content {
      description      = egress.value.description
      from_port        = egress.value.from_port
      to_port          = egress.value.to_port
      protocol         = egress.value.protocol
      cidr_blocks      = lookup(egress.value, "cidr_blocks", null)
      security_groups  = lookup(egress.value, "security_groups", null)
      self             = lookup(egress.value, "self", null)
      ipv6_cidr_blocks = lookup(egress.value, "ipv6_cidr_blocks", null)
    }
  }

  tags = local.security_group_tags

  lifecycle {
    create_before_destroy = true
  }
} 