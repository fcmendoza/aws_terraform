# Thanks to https://stackoverflow.com/questions/53333888/creating-mutilple-load-balancers-target-groups-and-listeners-in-terraform

resource "aws_lb" "elb_ref" {
  name               = "los-gatos-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = ["${data.aws_security_group.lb_sg.id}"]
  subnets            = [ "subnet-0f6db19ae3cdc5cd6", "subnet-00c0d61053293b5fd" ] # these subnets aleready exists in the VPC.

  enable_deletion_protection = false

  # access_logs {
  #   bucket  = "dummy-lambdas-bucket"
  #   prefix  = "gatos-lb"
  #   enabled = true
  # }

  tags = {
    Environment = "production"
  }
}

data "aws_security_group" "lb_sg" {
  name = "gatos_alb_ports"
}

data "aws_alb_target_group" "lb_target_ref" { 
  name = "ecs-gatos-gatosbalancedservice"
}

# resource "aws_alb_target_group" "alb_targets" {
#   count     = "1"
#   name      = "${var.name}-${var.environment}"
#   port      = "80"
#   protocol  = "HTTP"
#   vpc_id    = "${var.vpc_id}"
#   health_check {
#     healthy_threshold   = 2
#     interval            = 15
#     path                = "/api/health"
#     timeout             = 10
#     unhealthy_threshold = 2
#   }
# }

resource "aws_alb_listener" "alb_listener_80" {
  count             = "1"
  load_balancer_arn = "${aws_lb.elb_ref.arn}"
  port              = "80"
  protocol          = "HTTP"
  #ssl_policy        = "ELBSecurityPolicy-2015-05"
  #certificate_arn   = "${var.ssl_certificate_arn}"
  default_action {
    target_group_arn = "${data.aws_alb_target_group.lb_target_ref.arn}"
    type = "forward"
  }
}

resource "aws_alb_listener" "alb_listener_8080" {
  count             = "1"
  load_balancer_arn = "${aws_lb.elb_ref.arn}"
  port              = "8080"
  protocol          = "HTTP"
  #ssl_policy        = "ELBSecurityPolicy-2015-05"
  #certificate_arn   = "${var.ssl_certificate_arn}"
  default_action {
    target_group_arn = "${data.aws_alb_target_group.lb_target_ref.arn}"
    type = "forward"
  }
}

# resource "aws_lb_target_group_attachment" "test" {
#   target_group_arn = "${data.aws_alb_target_group.lb_target_ref.arn}"
#   target_id        = "${element(var.instance_ids,count.index)}"
#   port             = 80
# }
