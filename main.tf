locals {
  attach_role_arns         = concat(local.ecs_target_arns, local.stepfunction_target_arns)
  ecs_target_arns          = [for k, v in var.event_targets : v.arn if contains(keys(v), "ecs_target")]
  stepfunction_target_arns = [for k, v in var.event_targets : v.arn if contains(split(":", v.arn), "stateMachine")]
  lambda_target_arns       = [for k, v in var.event_targets : v.arn if contains(split(":", v.arn), "lambda")]
  sns_target_arns          = [for k, v in var.event_targets : v.arn if contains(split(":", v.arn), "sns")]
}

resource "aws_cloudwatch_event_rule" "rule" {
  name           = var.name_is_prefix ? null : var.name
  name_prefix    = var.name_is_prefix ? var.name : null
  description    = var.description
  event_bus_name = length(var.event_bus_name) != 0 ? var.event_bus_name : "default"

  schedule_expression = length(var.schedule_expression) != 0 ? var.schedule_expression : null
  event_pattern = length(var.event_pattern) != 0 ? jsonencode(var.event_pattern) : null

  role_arn   = try(length(var.role_arn), "") != 0 ? var.role_arn : aws_iam_role.eventbridge_rule_role[0].arn
  is_enabled = var.is_enabled
}

resource "aws_cloudwatch_event_target" "target" {
  for_each = var.event_targets

  rule           = aws_cloudwatch_event_rule.rule.id
  target_id      = each.key
  arn            = lookup(each.value, "arn", null)
  event_bus_name = aws_cloudwatch_event_rule.rule.event_bus_name
  role_arn       = contains(local.attach_role_arns, lookup(each.value, "arn", null)) ? aws_cloudwatch_event_rule.rule.role_arn : null

  input      = jsonencode(lookup(each.value, "input", null))
  input_path = lookup(each.value, "input_path", null)
  dynamic "input_transformer" {
    for_each = lookup(each.value, "input_transformer", null) != null ? [
      each.value.input_transformer
    ] : []

    content {
      input_paths    = input_transformer.value.input_paths
      input_template = input_transformer.value.input_template
    }
  }

  dynamic "ecs_target" {
    for_each = lookup(each.value, "ecs_target", null) != null ? [
      each.value.ecs_target
    ] : []

    content {
      group               = lookup(ecs_target.value, "group", null)
      launch_type         = lookup(ecs_target.value, "launch_type", null)
      platform_version    = lookup(ecs_target.value, "platform_version", null)
      task_count          = lookup(ecs_target.value, "task_count", null)
      task_definition_arn = lookup(ecs_target.value, "task_definition_arn", null)

      dynamic "network_configuration" {
        for_each = lookup(ecs_target.value, "network_configuration", null) != null ? [
          ecs_target.value.network_configuration
        ] : []

        content {
          subnets          = lookup(network_configuration.value, "subnets", null)
          security_groups  = lookup(network_configuration.value, "security_groups", null)
          assign_public_ip = lookup(network_configuration.value, "assign_public_ip", null)
        }
      }
    }
  }


  dynamic "dead_letter_config" {
    for_each = lookup(each.value, "dead_letter_arn", null) != null ? [true] : []

    content {
      arn = each.value.dead_letter_arn
    }
  }

  dynamic "retry_policy" {
    for_each = lookup(each.value, "retry_policy", null) != null ? [
      each.value.retry_policy
    ] : []

    content {
      maximum_event_age_in_seconds = retry_policy.value.maximum_event_age_in_seconds
      maximum_retry_attempts       = retry_policy.value.maximum_retry_attempts
    }
  }
}

resource "aws_iam_role" "eventbridge_rule_role" {
  count = length(var.role_arn) == 0 ? 1 : 0
  name  = format("EventBridge-rule-%s", var.name)
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  dynamic "inline_policy" {
    for_each = length(local.ecs_target_arns) != 0 ? [true] : []
    content {
      name = "eb-rule-ecs-policy"
      policy = jsonencode({
        "Version" = "2012-10-17",
        "Statement" = [
          {
            "Sid"      = "ECSAccess"
            "Effect"   = "Allow"
            "Action"   = ["ecs:RunTask"]
            "Resource" = local.ecs_target_arns
          },
          {
            "Sid"      = "PassRole"
            "Effect"   = "Allow"
            "Action"   = ["iam:PassRole"]
            "Resource" = ["*"],
            "Condition" = {
              "StringLike" = {
                "iam:PassedToService" : "ecs-tasks.amazonaws.com"
              }
            }
          }
        ]
      })
    }
  }

  dynamic "inline_policy" {
    for_each = length(local.stepfunction_target_arns) != 0 ? [true] : []
    content {
      name = "eb-rule-stepfunction-policy"
      policy = jsonencode({
        "Version" = "2012-10-17",
        "Statement" = [
          {
            "Sid"      = "stepFunctionAccess"
            "Effect"   = "Allow"
            "Action"   = ["states:StartExecution"]
            "Resource" = local.stepfunction_target_arns
          }
        ]
      })
    }
  }

  dynamic "inline_policy" {
    for_each = length(local.lambda_target_arns) != 0 ? [true] : []
    content {
      name = "eb-rule-lambda-policy"
      policy = jsonencode({
        "Version" = "2012-10-17",
        "Statement" = [
          {
            "Sid"      = "lambdaAccess"
            "Effect"   = "Allow"
            "Action"   = ["lambda:InvokeFunction"]
            "Resource" = local.lambda_target_arns
          }
        ]
      })
    }
  }

  dynamic "inline_policy" {
    for_each = length(local.sns_target_arns) != 0 ? [true] : []
    content {
      name = "eb-rule-sns-policy"
      policy = jsonencode({
        "Version" = "2012-10-17",
        "Statement" = [
          {
            "Sid"      = "snsAccess"
            "Effect"   = "Allow"
            "Action"   = ["SNS:Publish"]
            "Resource" = local.sns_target_arns
          }
        ]
      })
    }
  }
}

