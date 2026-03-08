terraform {
  backend "s3" {
    bucket         = "569260897730-terraform-tfstate" 
    key            = "terraform.tfstate"
    region         = "eu-central-1"
    dynamodb_table = "terraform-tfstate-lock"
    encrypt        = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "eu-central-1"
}



# --- DynamoDB Tables ---

module "courses_table" {
  source     = "./modules/dynamodb"
  attributes = ["courses"]
  context    = module.labels.context
}

module "authors_table" {
  source     = "./modules/dynamodb"
  attributes = ["authors"]
  context    = module.labels.context
}

# --- Lambda 1: Get All Authors ---

module "get_all_authors_iam" {
  source             = "./modules/iam"
  name               = "get-all-authors"
  dynamodb_table_arn = module.authors_table.table_arn
  dynamodb_actions   = ["dynamodb:Scan", "dynamodb:GetItem"]
  context            = module.labels.context
}

module "get_all_authors_lambda" {
  source              = "./modules/lambda"
  name                = "get-all-authors"
  source_dir          = "./builds/get-all-authors"
  role_arn            = module.get_all_authors_iam.role_arn
  dynamodb_table_name = module.authors_table.table_name
  context             = module.labels.context
}

# --- Lambda 2: Get Course (by ID) ---

module "get_course_iam" {
  source             = "./modules/iam"
  name               = "get-course"
  dynamodb_table_arn = module.courses_table.table_arn
  dynamodb_actions   = ["dynamodb:GetItem"]
  context            = module.labels.context
}

module "get_course_lambda" {
  source              = "./modules/lambda"
  name                = "get-course"
  source_dir          = "./builds/get-course"
  role_arn            = module.get_course_iam.role_arn
  dynamodb_table_name = module.courses_table.table_name
  context             = module.labels.context
}

# --- Lambda 3: Save Course ---

module "save_course_iam" {
  source             = "./modules/iam"
  name               = "save-course"
  dynamodb_table_arn = module.courses_table.table_arn
  dynamodb_actions   = ["dynamodb:PutItem"]
  context            = module.labels.context
}

module "save_course_lambda" {
  source              = "./modules/lambda"
  name                = "save-course"
  source_dir          = "./builds/save-course"
  role_arn            = module.save_course_iam.role_arn
  dynamodb_table_name = module.courses_table.table_name
  context             = module.labels.context
}

# --- Lambda 4: Delete Course ---

module "delete_course_iam" {
  source             = "./modules/iam"
  name               = "delete-course"
  dynamodb_table_arn = module.courses_table.table_arn
  dynamodb_actions   = ["dynamodb:DeleteItem"]
  context            = module.labels.context
}

module "delete_course_lambda" {
  source              = "./modules/lambda"
  name                = "delete-course"
  source_dir          = "./builds/delete-course"
  role_arn            = module.delete_course_iam.role_arn
  dynamodb_table_name = module.courses_table.table_name
  context             = module.labels.context
}

# --- Lambda 5: Get All Courses ---
module "get_all_courses_iam" {
  source             = "./modules/iam"
  name               = "get-all-courses"
  dynamodb_table_arn = module.courses_table.table_arn
  dynamodb_actions   = ["dynamodb:Scan"]
  context            = module.labels.context
}

module "get_all_courses_lambda" {
  source              = "./modules/lambda"
  name                = "get-all-courses"
  source_dir          = "./builds/get-all-courses"
  role_arn            = module.get_all_courses_iam.role_arn
  dynamodb_table_name = module.courses_table.table_name
  context             = module.labels.context
}

# --- Lambda 6: Update Course ---
module "update_course_iam" {
  source             = "./modules/iam"
  name               = "update-course"
  dynamodb_table_arn = module.courses_table.table_arn
  dynamodb_actions   = ["dynamodb:PutItem"]
  context            = module.labels.context
}

module "update_course_lambda" {
  source              = "./modules/lambda"
  name                = "update-course"
  source_dir          = "./builds/update-course"
  role_arn            = module.update_course_iam.role_arn
  dynamodb_table_name = module.courses_table.table_name
  context             = module.labels.context
}