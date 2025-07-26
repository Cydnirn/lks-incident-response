# EC2 Instance
resource "aws_instance" "instance" {
  ami                    = var.ami
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = var.security_group_ids
  subnet_id              = var.subnet_id
  iam_instance_profile   = var.iam_instance_profile
  source_dest_check      = var.source_dest_check

  root_block_device {
    volume_size = var.root_volume_size
    volume_type = var.root_volume_type
    encrypted   = var.root_volume_encrypted
  }

  user_data = var.user_data != null ? base64encode(var.user_data) : null

  tags = merge(
    {
      Name = "${var.project_name}-${var.instance_name}"
    },
    var.tags
  )
}

# Elastic IP (optional)
resource "aws_eip" "instance_eip" {
  count  = var.create_eip ? 1 : 0
  domain = "vpc"
  
  tags = merge(
    {
      Name = "${var.project_name}-${var.instance_name}-eip"
    },
    var.tags
  )
}

# Associate Elastic IP with Instance
resource "aws_eip_association" "instance_eip_assoc" {
  count         = var.create_eip ? 1 : 0
  instance_id   = aws_instance.instance.id
  allocation_id = aws_eip.instance_eip[0].id
} 