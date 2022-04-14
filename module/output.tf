output "awsec2publicip"{
    value = aws_instance.ec2.public_ip
}
output "awsec2privateip"{
   value = aws_instance.ec2.private_ip
}