variable "test_id" {
  description = "Unique identifier for this test run (e.g., GitHub run ID or timestamp)"
  type        = string
}

variable "location" {
  description = "Azure region for test resources"
  type        = string
  default     = "eastus2"
}

variable "tags" {
  description = "Additional tags for test resources"
  type        = map(string)
  default     = {}
}
