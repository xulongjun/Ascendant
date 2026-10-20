variable "location" {
  type        = string
  description = "Azure region for the production resource group and Static Web App."

  validation {
    condition     = can(regex("^[a-z0-9]+$", var.location))
    error_message = "location must be an Azure region name such as westeurope."
  }
}

variable "name_suffix" {
  type        = string
  description = "4-8 character suffix that makes the Static Web App name globally unique. Supply it as TF_VAR_name_suffix. Do not commit a guessed suffix."

  validation {
    condition     = can(regex("^[a-z0-9]{4,8}$", var.name_suffix))
    error_message = "name_suffix must be 4-8 lowercase letters or digits."
  }
}
