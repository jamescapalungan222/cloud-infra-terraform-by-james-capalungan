terraform {
    required_providers {
        aws = {
            source = "hashicorp/aws"
            version = "~> 5.0"
        }
    }
}

provider "aws" {
    region = "ap-southeast-2"
}
# Security Group for EC2 Instances

resource "aws_security_group" "web_sg" {
    name = "instances-security-group"
}

resource "aws_security_group_rule" "allow_http_inbound" {
    type = "ingress"
    security_group_id = aws_security_group.web_sg.id
    from_port = 8080
    to_port = 8080
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
}


# EC2 Instances

resource "aws_instance" "instance1" {
    ami = "ami-038013fbee7451346"
    instance_type = "t3.micro"
    security_groups = [aws_security_group.web_sg.name]
    user_data = <<-EOF
                #!/bin/bash
                echo "Hello, World from Web Server 1" > index.html
                python3 -m http.server 8080 &
                EOF
}

resource "aws_instance" "instance2" {
    ami = "ami-038013fbee7451346"
    instance_type = "t3.micro"
    security_groups = [aws_security_group.web_sg.name]
    user_data = <<-EOF
                #!/bin/bash
                echo "Hello, World from Web Server 2" > index.html
                python3 -m http.server 8080 &
                EOF
}

#S3 Bucket for Static Content

resource "aws_s3_bucket" "bucket" {
    bucket = "web-application-bucket-1"
    force_destroy = true
    versioning {
        enabled = true
    }

    server_side_encryption_configuration {
        rule {
            apply_server_side_encryption_by_default {
                sse_algorithm = "AES256"
            }
        }
    }
}
# VPC % Subnets (Default VPC only)

data "aws_vpc" "webapp-vpc" {
    default = true
}

data "aws_subnets" "webapp_subnets" {
    filter {
        name   = "vpc-id"
        values = [data.aws_vpc.webapp-vpc.id]
    }
}

# Application Load Balancer


resource "aws_lb_listener" "web_lb_listener" {
    load_balancer_arn = aws_lb.load_balancer.arn
    port = "80"
    protocol = "HTTP"

    default_action {
        type             = "forward"
        target_group_arn = aws_lb_target_group.web_target_group.arn
            }
    }

resource "aws_lb_target_group" "web_target_group" {
    name = "web-target-group"
    port = 8080
    protocol = "HTTP"
    vpc_id = data.aws_vpc.webapp-vpc.id

    health_check {
        path = "/"
        port = "8080"
        protocol = "HTTP"
        interval = 30
        timeout = 5
        healthy_threshold = 2
        unhealthy_threshold = 2
    }
}

resource "aws_lb_listener_rule" "web_lb_listener_rule" {
    listener_arn = aws_lb_listener.web_lb_listener.arn
    priority = 100

    action {
        type = "forward"
        target_group_arn = aws_lb_target_group.web_target_group.arn
    }

    condition {
        path_pattern {
            values = ["/"]
        }
    }
}

resource "aws_security_group" "alb"{
    name = "alb-security-group"
}
resource "aws_security_group_rule" "allow_http_inbound_alb" {
    type = "ingress"
    security_group_id = aws_security_group.alb.id
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "allow_alb_all_outbound" {
    type = "egress"
    security_group_id = aws_security_group.alb.id
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_lb" "load_balancer" {
    name               = "web-app-load-balancer"
    load_balancer_type = "application"
    security_groups    = [aws_security_group.alb.id]
    subnets            = data.aws_subnets.webapp_subnets.ids
}

## RDS Database Instance

resource "aws_db_instance" "db_instance" {
    allocated_storage = 20
    engine = "mysql"
    engine_version = "8.0"
    instance_class = "db.t4g.micro"
    username = "adminuser"
    password = "adminpassword"
    parameter_group_name = "default.mysql8.0"
    skip_final_snapshot = true
}