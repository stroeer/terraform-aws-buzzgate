resource "aws_alb_target_group" "public" {
  deregistration_delay = 5
  name                 = "${var.service_name}-public"
  port                 = var.container_port
  protocol             = "HTTP"
  tags                 = local.default_tags
  target_type          = "ip"
  vpc_id               = data.aws_vpc.selected.id

  health_check {
    healthy_threshold   = 2
    interval            = 30
    path                = var.health_check_endpoint
    port                = var.container_port
    protocol            = "HTTP"
    unhealthy_threshold = 10
  }
}

resource "aws_alb_target_group" "private" {
  deregistration_delay = 5
  name                 = "${var.service_name}-private"
  port                 = var.container_port
  protocol             = "HTTP"
  tags                 = local.default_tags
  target_type          = "ip"
  vpc_id               = data.aws_vpc.selected.id

  health_check {
    path                = var.health_check_endpoint
    port                = var.container_port
    protocol            = "HTTP"
    interval            = 30
    healthy_threshold   = 2
    unhealthy_threshold = 10
  }
}

data "aws_lb" "public" {
  name = "public"
}

data "aws_lb_listener" "public" {
  load_balancer_arn = data.aws_lb.public.arn
  port              = 443
}

data "aws_lb_listener" "public_80" {
  load_balancer_arn = data.aws_lb.public.arn
  port              = 80
}

resource "aws_alb_listener_rule" "public" {
  listener_arn = data.aws_lb_listener.public.arn
  priority     = var.alb_listener_priority

  action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.public.arn
  }

  condition {
    host_header {
      values = [trimsuffix("${var.service_name}.${data.aws_route53_zone.external.name}", ".")]
    }
  }
}

resource "aws_alb_listener_rule" "public_80" {
  listener_arn = data.aws_lb_listener.public_80.arn
  priority     = var.alb_listener_priority

  action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.public.arn
  }

  condition {
    host_header {
      values = [trimsuffix("${var.service_name}.${data.aws_route53_zone.external.name}", ".")]
    }
  }

  condition {
    http_header {
      http_header_name = "X-Do-Not-Redirect"
      values           = ["true"]
    }
  }
}

data "aws_lb" "private" {
  name = "private"
}

data "aws_lb_listener" "private" {
  load_balancer_arn = data.aws_lb.private.arn
  port              = 80
}

resource "aws_alb_listener_rule" "private" {
  listener_arn = data.aws_lb_listener.private.arn
  priority     = var.alb_listener_priority

  action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.private.arn
  }

  condition {
    host_header {
      values = [trimsuffix("${var.service_name}.${data.aws_route53_zone.internal.name}", ".")]
    }
  }
}
