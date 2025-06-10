resource "aws_ecr_repository" "secertmanager_ecr_repo" {
  name                 = "secertmanager-ecr-repo"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}