output "vpc_id" {
  description = "Created VPC ID"
  value       = aws_vpc.main.id
}

output "public_subnet_id" {
  value = aws_subnet.public.id
}

output "private_subnet_id" {
  value = aws_subnet.private.id
}

output "public_ec2_id" {
  value = aws_instance.public_ec2.id
}

output "public_ec2_ip" {
  value = aws_instance.public_ec2.public_ip
}

output "private_ec2_id" {
  value = aws_instance.private_ec2.id
}

output "private_ec2_ip" {
  value = aws_instance.private_ec2.private_ip
}

output "nat_gateway_id" {
  value = aws_nat_gateway.nat.id
}

output "nat_gateway_public_ip" {
  value = aws_eip.nat.public_ip
}
