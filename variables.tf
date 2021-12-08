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

variable "create_role" {
  description = "Specifies should role be created with module or will there be external one provided."
  type        = bool
  default     = true
}

variable "policy" {
  description = "List of additional policies for EB rule access."
  type        = list(any)
  default     = []
}

variable "role" {
  description = "Custom role ARN used for target invocations."
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