/*
This terraform file launches 2 containers inside aws apprunner
*/

resource "aws_apprunner_service" "meteor-tracker-api" {
  service_name = "meteor-tracker-api"

  source_configuration {
    authentication_configuration {
      access_role_arn = aws_iam_role.apprunner_ecr_role.arn
    }
    image_repository {
      image_configuration {
        port = "9001"
        runtime_environment_variables = tomap(
            {"API_PORT" =  "9001", 
            "DATABASE_URL" = "postgresql://mtapp:test123_abcd@${aws_db_instance.alula_db.endpoint}/mtapp?schema=public",
            "NODE_ENV" = "production"}
          )
        start_command = "start:api"
      }
      image_identifier      = "${aws_ecr_repository.repo1.repository_url}:latest"
      image_repository_type = "ECR"
    }
  
  }

  tags = {
    Name = "meteor-tracker-api-apprunner-service"
  }

  depends_on = [
    aws_db_instance.alula_db,
    aws_ecr_repository.repo1,
    aws_iam_role_policy_attachment.apprunner_ecr_role-attach,
    aws_nat_gateway.nat1,
    null_resource.push_container
  ]
}

output "meteor-tracker-api_service_url" {
  value = aws_apprunner_service.meteor-tracker-api.service_url
}

resource "aws_apprunner_service" "meteor-tracker" {
  service_name = "meteor-tracker"

  source_configuration {
    authentication_configuration {
      access_role_arn = aws_iam_role.apprunner_ecr_role.arn
    }
    image_repository {
      image_configuration {
        port = "9000"
        runtime_environment_variables = tomap(
            {"API_URL" = "https://${aws_apprunner_service.meteor-tracker-api.service_url}",
            "PORT" = "9000",
            "NODE_ENV" = "production"}
          )
        start_command = "start:app"
      }
      image_identifier      = "${aws_ecr_repository.repo1.repository_url}:latest"
      image_repository_type = "ECR"
    }
  }

  tags = {
    Name = "meteor-tracker-apprunner-service"
  }

  depends_on = [
    aws_apprunner_service.meteor-tracker-api
  ]
}

output "meteor-tracker_service_url" {
  value = aws_apprunner_service.meteor-tracker.service_url
}