variable "name" {
  description = "The name or the prefix of the rule."
  type        = string
}

variable "name_is_prefix" {
  description = "Specify if name is prefix or specific name."
  type        = bool
  default     = false
}

variable "description" {
  description = "The description of the rule."
  type        = string
  default     = ""
}

variable "event_bus_name" {
  description = "Name of the event bus"
  type        = string
  default     = "default"
}

variable "schedule_expression" {
  description = "The scheduling expression. For example, cron(0 20 * * ? *) or rate(5 minutes)."
  type        = string
  default     = ""
}

variable "event_pattern" {
  description = "Map which will be cast to JSON showing event pattern for matching events."
  type        = any
  default     = {}
}

variable "role_arn" {
  description = "ARN of the role that is used for target invocation."
  type        = string
  default     = ""
}

variable "is_enabled" {
  description = "Whether the rule should be enabled."
  type        = bool
  default     = false
}

variable "event_targets" {
  description = "Map of definitions for all event targets."
  type        = any
  default     = {}
}