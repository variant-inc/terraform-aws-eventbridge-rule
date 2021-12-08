# Terraform EventBridge Rule module

- [Terraform EventBridge Rule module](#terraform-eventbridge-rule-module)
  - [Input Variables](#input-variables)
  - [Variable definitions](#variable-definitions)
    - [name](#name)
    - [name_is_prefix](#name_is_prefix)
    - [description](#description)
    - [event_bus_name](#event_bus_name)
    - [schedule_expression](#schedule_expression)
    - [event_pattern](#event_pattern)
    - [create_role](#create_role)
    - [policy](#policy)
    - [role](#role)
    - [is_enabled](#is_enabled)
    - [event_targets](#event_targets)
  - [Examples](#examples)
    - [`main.tf`](#maintf)
    - [`terraform.tfvars.json`](#terraformtfvarsjson)
    - [`provider.tf`](#providertf)
    - [`variables.tf`](#variablestf)
    - [`outputs.tf`](#outputstf)

## Input Variables
| Name     | Type    | Default   | Example     | Notes   |
| -------- | ------- | --------- | ----------- | ------- |
| name | string |  | "ebrule-test" |  |
| name_is_prefix | bool | false | true |  |
| description | string | "" | "test eventbridge rule" |  |
| event_bus_name | string | "default" | "test-custom-eventubus" |  |
| schedule_expression | string | "" | rate(5 minutes) | <https://docs.aws.amazon.com/AmazonCloudWatch/latest/events/ScheduledEvents.html> |
| event_pattern | any | {} | ```{ "detail-type": [ "AWS Console Sign In via CloudTrail" ]}``` | |
| create_role | bool | true | false |  |
| policy | list(any) | [] | `see below` |  |
| role | string | "" | "arn:aws:iam::319244236588:role/test-eb-rule-role" |  |
| is_enabled | bool | false | true |  |
| event_targets | any | {} | `see below` |  |

## Variable definitions

### name
Sets name for EventBridge rule.
```json
"name": "<EB rule name>"
```

### name_is_prefix
Specifies if name is just a prefix.
If `true` AWS generates suffix for unique name, otherwise it is using name from `name` variable.
```json
"name_is_prefix": <true or false>
```

Default:
```json
"name_is_prefix": false
```

### description
Description for EB rule.
```json
"description": "<description of EB rule>"
```

Default:
```json
"description": ""
```

### event_bus_name
Name of custom event bus for which we want to define the rule.
`default` is name of AWS default eventbus.
```json
"event_bus_name": "<name of the custom event bus>"
```

Default:
```json
"event_bus_name": "default"
```

### schedule_expression
In case we're using scheduled triggering. Supports cron and rate expressions.
cron: `"cron(5,35 14 * * ? *)"`
rate: `rate(5 minutes)`
<https://docs.aws.amazon.com/AmazonCloudWatch/latest/events/ScheduledEvents.html>
> :warning: can't be used together with `event_pattern`
```json
"schedule_expression": "<cron or rate expression>"
```

Default:
```json
"schedule_expression": ""
```
### event_pattern
In case we want to use event patterns instead of scheduled expression.
<https://docs.aws.amazon.com/eventbridge/latest/userguide/eb-events.html>
> :warning: can't be used together with `schedule_expression`

```json
"event_pattern": {<map that will be cast to JSON>}
```

Default:
```json
"event_pattern": {}
```
### create_role
Specifies if IAM role for the EB rule target invocation will be created in module or externally.
`true` - created with module
`false` - created externally
```json
"create_role": <true or false>
```

Default:
```json
"create_role": true
```

### policy
Additional inline policy statements for EB rule role.
Effective only if `create_role` is set to `true`.
```json
"policy": [<list of inline policies>]
```

Default:
```json
"policy": []
```

### role
ARN of externally created role. Use in case of `create_role` is set to `false`.
```json
"role": "<role ARN>"
```

Default:
```json
"role": ""
```

### is_enabled
Specifies if EB rule is enabled or disabled.
```json
"is_enabled": <true or false>
```

Default:
```json
"is_enabled": false
```

### event_targets
Specifies event targets that will be used wit this EB rule.
Current support only for:
* Lambda
* Step function
* ECS task - [special config requirements](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_target#ecs_target)
* SNS

Each has these basic atributes:
* **arn** - ARN of the target resource
* **input** - specifying fixed JSON that will be sent to the target, conflicts with `input_path` and `input_transformer`
* **input_path** - use if we don't want to use fixed JSON in input, conflicts with `input` and `input_transformer`
* **input_transformer** - gives input to target based on on event data, conflicts with `input` and `input_path`
* **retry policy** - if you need to change default one(24h, 185x) - [configuration](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_target#retry_policy)
* **dead_letter_config** - if we need to use deadletter SQS queue for failed events - [configuration](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_target#dead_letter_config)

```json
"event_targets": <map of all event targets and their configuration>
```

Default:
```json
"event_targets": {}
```

## Examples
### `main.tf`
```terraform
module "eventbridge_rule" {
  source = "github.com/variant-inc/terraform-aws-eventbridge-rule?ref=v1"

  name           = var.name
  name_is_prefix = var.name_is_prefix
  description    = var.description

  event_bus_name      = var.event_bus_name
  schedule_expression = var.schedule_expression
  event_pattern       = var.event_pattern
  is_enabled          = var.is_enabled
  event_targets       = var.event_targets

  create_role = var.create_role
  policy      = var.policy
  role        = var.role
}
```

### `terraform.tfvars.json`
```json
{
  "name": "test-eb-rule",
  "name_is_prefix": false,
  "description": "test EB rule",
  "schedule_expression": "rate(5 minutes)",
  "create_role": false,
  "role": "arn:aws:iam::319244236588:role/test-eb-rule-role",
  "is_enabled": false,
  "event_targets": {
    "target-lambda-test": {
      "arn": "arn:aws:lambda:us-east-1:319244236588:function:eb-test-lambda",
      "dead_letter_arn": "arn:aws:sqs:us-east-1:319244236588:test-dlq",
      "retry_policy": {
        "maximum_event_age_in_seconds": 300,
        "maximum_retry_attempts": 5
      },
      "input": {
        "event": "test-event-input"
      }
    },
    "target-sns-test": {
      "arn": "arn:aws:sns:us-east-1:319244236588:test-sns",
      "input": {
        "event": "test-event-input"
      }
    },
    "target-stepfunction-test": {
      "arn": "arn:aws:states:us-east-1:319244236588:stateMachine:test-statemachine",
      "input": {
        "event": "test-event-input"
      }
    },
    "target-ecs-test": {
      "arn": "arn:aws:ecs:us-east-1:319244236588:cluster/test-ecs-cluster",
      "input": {
        "event": "test-event-input"
      },
      "ecs_target": {
        "task_definition_arn": "arn:aws:ecs:us-east-1:319244236588:task-definition/test-ecs-task:1"
      }
    }
  }
}
```

Basic
```json
{
  "name": "test-eb-rule",
  "schedule_expression": "rate(5 minutes)",
  "is_enabled": false,
  "event_targets": {
    "target-lambda-test": {
      "arn": "arn:aws:lambda:us-east-1:319244236588:function:eb-test-lambda",
      "input": {
        "event": "test-event-input"
      }
    }
  }
}
```

### `provider.tf`
```terraform
provider "aws" {
  region = "us-east-1"
  default_tags {
    tags = {
      team : "DataOps",
      purpose : "eventbridge_rule_test",
      owner : "Luka"
    }
  }
}
```

### `variables.tf`
copy ones from module

### `outputs.tf`
```terraform
output "eventbridge_rule_name" {
  value       = module.eventbridge_rule.eventbridge_rule_name
  description = "Name of the EventBridge Rule"
}
```