/*
This terraform file creates the needed ECR (container registry), and the policies, role that are needed
*/

resource "aws_ecr_repository" "repo1" {
  name = "alula_test"
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_partition" "current" {}

resource "aws_ecr_registry_policy" "repo1" {
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "testpolicy",
        Effect = "Allow",
        Principal = {
          "AWS" : "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:root"
        },
        Action = [
          "ecr:ReplicateImage"
        ],
        Resource = [
          "arn:${data.aws_partition.current.partition}:ecr:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:repository/*"
        ]
      }
    ]
  })
}

resource "aws_ecr_repository_policy" "repo1" {
  repository = aws_ecr_repository.repo1.name

  policy = <<EOF
{
    "Version": "2008-10-17",
    "Statement": [
        {
            "Sid": "new policy",
            "Effect": "Allow",
            "Principal": "*",
            "Action": [
                "ecr:GetDownloadUrlForLayer",
                "ecr:BatchGetImage",
                "ecr:BatchCheckLayerAvailability",
                "ecr:PutImage",
                "ecr:InitiateLayerUpload",
                "ecr:UploadLayerPart",
                "ecr:CompleteLayerUpload",
                "ecr:DescribeRepositories",
                "ecr:GetRepositoryPolicy",
                "ecr:ListImages",
                "ecr:DeleteRepository",
                "ecr:BatchDeleteImage",
                "ecr:SetRepositoryPolicy",
                "ecr:DeleteRepositoryPolicy"
            ]
        }
    ]
}
EOF
}

resource "aws_iam_role" "apprunner_ecr_role" {
   name = "apprunner_ecr_role"
   assume_role_policy = <<EOF
{
   "Version": "2012-10-17",
   "Statement": [
     {
       "Action": "sts:AssumeRole",
       "Principal": {
         "Service": [
           "build.apprunner.amazonaws.com",
           "tasks.apprunner.amazonaws.com"
         ]
       },
       "Effect": "Allow",
       "Sid": ""
     }
   ]
 } 
EOF 
}

resource "aws_iam_role_policy_attachment" "apprunner_ecr_role-attach" {
   role       = aws_iam_role.apprunner_ecr_role.name
   policy_arn = "arn:aws:iam::aws:policy/service-role/AWSAppRunnerServicePolicyForECRAccess"
}


/*
Here we are running local commands to sync the aluladevops/metor-tracker container 
into the created ECR registry
*/

resource "null_resource" "pull_alula_container" {
  provisioner "local-exec" {
    command = "docker pull aluladevops/meteor-tracker:latest"
  }
}

resource "null_resource" "ecr_docker_login" {
  provisioner "local-exec" {
    command = "aws --profile alula ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin ${data.aws_caller_identity.current.account_id}.dkr.ecr.us-east-1.amazonaws.com"
  }
  depends_on = [
      aws_ecr_repository.repo1
  ]
}

resource "null_resource" "re-tag_container" {
  provisioner "local-exec" {
    command = "docker tag aluladevops/meteor-tracker:latest ${data.aws_caller_identity.current.account_id}.dkr.ecr.us-east-1.amazonaws.com/alula_test:latest"
  }
  depends_on = [
      aws_ecr_repository.repo1
  ]
}

resource "null_resource" "push_container" {
  provisioner "local-exec" {
    command = "docker push ${data.aws_caller_identity.current.account_id}.dkr.ecr.us-east-1.amazonaws.com/alula_test:latest"
  }
  depends_on = [
      aws_ecr_repository.repo1
  ]
}