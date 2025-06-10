resource "aws_efs_file_system" "app_efs" {
  creation_token   = "app-efs"
  performance_mode = "generalPurpose"
  tags = {
    Name = "app-efs"
  }
}

resource "aws_efs_mount_target" "app_efs_mount_1" {
  file_system_id  = aws_efs_file_system.app_efs.id
  subnet_id       = "subnet-05f355a2bead09d0b" # Replace with your subnet ID
  security_groups = [aws_security_group.ecs-service_sg.id]
}

resource "aws_efs_mount_target" "app_efs_mount_2" {
  file_system_id  = aws_efs_file_system.app_efs.id
  subnet_id       = "subnet-0b1aafe5c16c81bc9" # Replace with your subnet ID
  security_groups = [aws_security_group.ecs-service_sg.id]

}