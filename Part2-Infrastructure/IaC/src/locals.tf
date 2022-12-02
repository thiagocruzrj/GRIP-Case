locals {
  resource_suffix       = "${var.product_name}-${var.environment}-${var.instance}"
  resource_suffix_short = "${var.product_name}${var.environment}${var.instance}"
}
