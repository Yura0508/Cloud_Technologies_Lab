module "this" {
  source  = "cloudposse/label/null"
  version = "0.25.0"
  attributes = var.attributes 
  context    = var.context
}

resource "aws_dynamodb_table" "this" {
  name         = module.this.id 
  billing_mode = "PAY_PER_REQUEST" 
  hash_key     = var.hash_key

  attribute {
    name = var.hash_key
    type = "S" 
  }

  tags = module.this.tags 
}

