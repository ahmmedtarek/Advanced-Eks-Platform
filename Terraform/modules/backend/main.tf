#to create a backend for the tfstate we need to create an enabled versioning - encryption s3 bucket

resource "aws_s3_bucket" "backend-bucket"{
    bucket = "backend-bucket-tf-11"
    versioning {
        enabled = true
    }
    server_side_encryption_configuration {
            rule {
                apply_server_side_encryption_by_default {
                    sse_algorithm     = "AES256"
            }
        }
    }
}

#then we create an aws_dynamodb_table

resource "aws_dynamodb_table" "state-lock"{
    name = "state-lock"
    billing_mode = "PAY_PER_REQUEST"
    hash_key = "LockID"
    attribute {
        name = "LockID"
        type = "S"
    }
}