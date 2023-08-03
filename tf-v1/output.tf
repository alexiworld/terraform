output "public_ip" {
    description = "The public IP address of the web server"
    sensitive = false
    value = aws_instance.example.public_ip
}