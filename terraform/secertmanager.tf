resource "aws_secretsmanager_secret" "app_secret" {
  name        = "ecs-secert"
  description = "Secret for storing app credentials"
}

resource "aws_secretsmanager_secret_version" "app_secret_version" {
  secret_id = aws_secretsmanager_secret.app_secret.id
  secret_string = jsonencode({
    username = "admin"
    password = "mypassword"
  })
}
