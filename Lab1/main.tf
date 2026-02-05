
// Generate a random string for the suffix
resource "random_string" "suffix" {
    upper = false
    length = 6
    special = false
}

// Define anvironment prefix value
locals {
    environment_prefix = "${var.application_name}-${var.environment_name}-${random_string.suffix.result}"
}