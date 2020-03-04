resource "aws_key_pair" "auth" {
  key_name   = "my_key"
  public_key = "${file(var.public_key_path)}"
}

resource "aws_security_group" "web" {
  name        = "web_security_group"
  description = "Used in the terraform"
  vpc_id      = "${aws_vpc.default.id}"

  # SSH access from anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.office_ip}/32"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["${var.office_ip}/32"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_security_group" "default" {
  name        = "db_security_group"
  description = "Used in the terraform"
  vpc_id      = "${aws_vpc.default.id}"

  # SSH access from anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  # HTTP access from the VPC
  ingress {
    from_port   = 8086 
    to_port     = 8086
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  ingress {
    from_port   = 8088
    to_port     = 8088
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "db" {
  instance_type = "t2.micro"
  ami = "ami-02a599eb01e3b3c5b"
  key_name = "${aws_key_pair.auth.id}"
  vpc_security_group_ids = ["${aws_security_group.default.id}"]
  subnet_id = "${aws_subnet.private.id}"
  user_data = "${file("scripts/provisiondb.sh")}"
}

resource "aws_instance" "web" {
  instance_type = "t2.micro"
  ami = "ami-02a599eb01e3b3c5b"
  key_name = "${aws_key_pair.auth.id}"
  vpc_security_group_ids = ["${aws_security_group.web.id}"]
  subnet_id = "${aws_subnet.public.id}"
  user_data = "${file("scripts/provisionweb.sh")}"
}

resource "aws_route53_record" "db" {
  zone_id = "${aws_route53_zone.private.zone_id}"
  name    = "influxdb.k6test.internal"
  type    = "CNAME"
  ttl     = "300"
  records = ["${aws_instance.db.private_dns}"]
}

output "grafana_host" {
  value = "${aws_instance.web.public_dns}"
}
