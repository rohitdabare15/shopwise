output "jenkins_public_ip" {
  description = "Jenkins server public IP — open port 8080 in browser"
  value       = aws_instance.jenkins.public_ip
}

output "jenkins_public_dns" {
  value = aws_instance.jenkins.public_dns
}

output "jenkins_url" {
  value = "http://${aws_instance.jenkins.public_ip}:8080"
}
