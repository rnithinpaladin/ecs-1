# Service Discovery Namespace
resource "aws_service_discovery_private_dns_namespace" "service_ns" {
  name        = "service.local"
  description = "Service discovery namespace"
  vpc         = var.vpc_id
}

# Cloud Map Service for Service B
resource "aws_service_discovery_service" "backend_discovery" {
  name         = "backend"
  namespace_id = aws_service_discovery_private_dns_namespace.service_ns.id

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.service_ns.id
    dns_records {
      ttl  = 10
      type = "A"
    }
    routing_policy = "MULTIVALUE"
  }

  health_check_custom_config {
    failure_threshold = 1
  }
}