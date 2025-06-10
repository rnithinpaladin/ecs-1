variable "subnets" {
    description = "List of subnet IDs for the ECS service"
    type        = list(string)
    default     = ["subnet-05f355a2bead09d0b", "subnet-0b1aafe5c16c81bc9"] # Replace with your subnet IDs
}

variable "vpc_id" {
    description = "VPC ID for the ECS service"
    type        = string
    default     = "vpc-0a04a9d926ee85fa4" # Replace with your VPC ID
  
}