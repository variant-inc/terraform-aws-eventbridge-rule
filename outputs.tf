output "eventbridge_rule_name" {
  value = aws_cloudwatch_event_rule.rule.id
}