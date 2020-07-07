resource "aws_codepipeline" "codepipeline" {
  count    = var.enabled ? 1 : 0
  name     = var.service_name
  role_arn = var.code_pipeline_role == "" ? aws_iam_role.code_pipeline_role[count.index].arn : data.aws_iam_role.code_pipeline[count.index].arn

  tags = merge(var.tags, {
    tf_module = basename(path.module)
  })

  artifact_store {
    location = var.artifact_bucket == "" ? module.s3_bucket.this_s3_bucket_id : data.aws_s3_bucket.codepipeline[count.index].bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "ECR"
      category         = "Source"
      owner            = "AWS"
      provider         = "ECR"
      version          = "1"
      output_artifacts = ["ecr_source"]

      configuration = {
        "ImageTag" : "production",
        "RepositoryName" : var.ecr_repository_name
      }
    }
  }

  stage {
    name = "Build"
    action {
      name             = "CodeBuild"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["ecr_source"]
      output_artifacts = ["build_source"]

      configuration = {
        "ProjectName" : aws_codebuild_project.this[count.index].name
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "ECS"
      input_artifacts = ["build_source"]
      version         = "1"

      configuration = {
        "ClusterName" : "k8",
        "ServiceName" : var.service_name
        "FileName" : "imagedefinitions.json"
      }
    }
  }
}
