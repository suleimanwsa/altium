provider "aws" {
  region = "eu-west-1"
}

########################################### Vpc and Subnets ########################################
# resource "aws_vpc" "main" {
#   cidr_block = "10.0.0.0/16"
# }
data "aws_vpc" "main" {
  default = true
}


resource "aws_subnet" "ec2_subnet" {
  vpc_id     = data.aws_vpc.main.id
  cidr_block = var.ec2_subnet
  map_public_ip_on_launch = true # for testing to check access to ec2 on https port directly
}

resource "aws_subnet" "mysql_subnet" {
  vpc_id     = data.aws_vpc.main.id
  cidr_block = var.mysql_subnet
}

resource "aws_subnet" "alb1_subnet" {
  vpc_id     = data.aws_vpc.main.id
  cidr_block = var.alb1_subnet
  availability_zone = "eu-west-1a"
}

resource "aws_subnet" "alb2_subnet" {
  vpc_id     = data.aws_vpc.main.id
  cidr_block = var.alb2_subnet
  availability_zone = "eu-west-1b"
}

########################################### CDE app ########################################
resource "aws_security_group" "ec2_sg" {
  name        = "ec2-security-group"
  description = "Allow traffic to EC2 instances"
  vpc_id      = data.aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = concat([aws_subnet.alb1_subnet.cidr_block, aws_subnet.alb2_subnet.cidr_block], var.ips_allowed_to_access_cde)
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = concat([aws_subnet.alb1_subnet.cidr_block, aws_subnet.alb2_subnet.cidr_block], var.ips_allowed_to_access_cde)
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  #Allow all outbound traffic to secureweb
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] # var.secureweb_ips
  }
}



resource "aws_launch_template" "template" {
  name_prefix     = "test"
  image_id        = "ami-0fa8fe6f147dc938b"
  instance_type   = "t2.micro"
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]

  user_data = filebase64("${path.module}/setup-http-server.sh")
}

resource "aws_autoscaling_group" "autoscale" {
  name                  = "cde-autoscaling-group"  
  desired_capacity      = 1
  max_size              = 4
  min_size              = 1
  vpc_zone_identifier   = [aws_subnet.ec2_subnet.id]


  launch_template {
    id      = aws_launch_template.template.id
    version = "$Latest"
  }

  lifecycle {
    create_before_destroy = true
  }
}







########################## mysql #############################

resource "aws_security_group" "mysql_sg" {
  name        = "mysql-security-group"
  description = "Allow traffic to mysql EC2 instances"
  vpc_id      = data.aws_vpc.main.id

  # Allow HTTP access (optional)
  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [aws_subnet.ec2_subnet.cidr_block] # allow app subnet to access DB only
  }
}


resource "aws_instance" "mysql_instance" {
  ami           = "ami-03cc8375791cb8bcf"
  subnet_id     = aws_subnet.mysql_subnet.id
  instance_type = "t2.micro"
  user_data = filebase64("${path.module}/mysql.sh")
  vpc_security_group_ids = [aws_security_group.mysql_sg.id]

}



######################################### ALB #####################################

resource "aws_lb" "cde" {
  name               = "cde-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.alb1_subnet.id, aws_subnet.alb2_subnet.id]
}

resource "aws_security_group" "alb_sg" {
  name        = "cde-alb-sg"
  description = "Security group for ALB"
  vpc_id      = data.aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [aws_subnet.ec2_subnet.cidr_block]
  }

}


resource "aws_lb_target_group" "cde" {
  name     = "cde"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.main.id

  health_check {
    path                = "/index.html"
    interval            = 30
    timeout             = 5
    healthy_threshold    = 2
    unhealthy_threshold  = 2
  }
}


resource "aws_autoscaling_attachment" "example" {
  autoscaling_group_name = aws_autoscaling_group.autoscale.name
  lb_target_group_arn    = aws_lb_target_group.cde.arn
}



resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.cde.arn
  port              = 443
  protocol          = "HTTP"


  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.cde.arn
  }
}