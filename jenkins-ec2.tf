resource "aws_key_pair" "jenkins-key" {
  key_name   = "jenkins-key"
  public_key = file("jenkins-key.pub")
}

resource "aws_default_vpc" "default_vpc" {
    tags    = {
    Name  = "default vpc"
  }
}
data "aws_availability_zones" "available_zones" {}

resource "aws_default_subnet" "default_az1" {
  availability_zone = data.aws_availability_zones.available_zones.names[0]

  tags   = {
    Name = "default subnet"
  }
}

resource "aws_instance" "jenkins" {
  ami                    = "ami-007855ac798b5175e"
  key_name               = aws_key_pair.jenkins-key.id
  instance_type          = "t2.micro"
  subnet_id              = aws_default_subnet.default_az1.id
  vpc_security_group_ids = [aws_default_vpc.default_vpc.id]
  tags = {
    Name    = "jenkins"
    }

  provisioner "file" {
    source      = "jenkins_install.sh"
    destination = "/tmp/jenkins_install.sh"
  }
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/jenkins_install.sh",
      "sudo /tmp/jenkins_install.sh",
    ]
  }
  
  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("jenkins-key")
    host        = self.public_ip
  }
}
output "jenkins_url" {
  value     = join ("", ["http://", aws_instance.jenkins.public_dns, ":", "8080"])
}