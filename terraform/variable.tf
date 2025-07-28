variable "subnets" {
  description = "List of subnet IDs for the ECS service"
  type        = list(string)
  default     = ["subnet-05192e7512b4559fb", "subnet-0be296a1eb9bbb28e"] # Replace with your subnet IDs
}

variable "vpc_id" {
  description = "VPC ID for the ECS service"
  type        = string
  default     = "vpc-03a31b876ced80f4f" # Replace with your VPC ID
}