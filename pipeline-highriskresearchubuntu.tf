# Ubuntu 20.04 High-Risk CIS Research Image

locals {
  highriskresearch_image_name = "highriskresearch-ubuntu-linux"
  highriskresearch_ami_name   = "highriskresearchubuntu"
}

resource "aws_imagebuilder_image_pipeline" "highriskresearchubuntu" {
  name        = local.highriskresearch_image_name
  description = "Ubuntu 20.04 Linux High-Risk Research"
  status      = "ENABLED"

  image_recipe_arn                 = aws_imagebuilder_image_recipe.highriskresearchubuntu.arn
  infrastructure_configuration_arn = aws_imagebuilder_infrastructure_configuration.highriskresearchubuntu.arn
  distribution_configuration_arn   = aws_imagebuilder_distribution_configuration.highriskresearchubuntu.arn

  # schedule {
  #   # run every Sunday at 9 AM
  #   schedule_expression = "cron(0 9 ? * sun)"
  #   timezone = "America/New_York"
  #   pipeline_execution_start_condition = "EXPRESSION_MATCH_AND_DEPENDENCY_UPDATES_AVAILABLE"
  # }

  image_tests_configuration {
    image_tests_enabled = true
    timeout_minutes     = 60
  }
}

resource "aws_imagebuilder_image_recipe" "highriskresearchubuntu" {
  name              = local.highriskresearch_image_name
  description       = "Recipe High-Risk Research Ubuntu 20.04"
  version           = "0.1.0"
  working_directory = "/var/tmp"

  # CIS Image hard-coded for US-east-1 for Ubuntu 20.04 - will update with data source instead
  parent_image = data.aws_ami.highriskresearch.id

  block_device_mapping {
    device_name = "/dev/sda1"
    ebs {
      volume_size           = 100
      volume_type           = "gp3"
      delete_on_termination = true
    }
  }

  component {
    component_arn = data.aws_imagebuilder_component.cloudwatch_agent_linux_ubuntu.arn
  }

  component {
    component_arn = data.aws_imagebuilder_component.update_linux_ubuntu.arn
  }

  component {
    component_arn = data.aws_imagebuilder_component.go-linux-ubuntu.arn
  }

  component {
    component_arn = aws_imagebuilder_component.miniconda3.arn
  }

  component {
    component_arn = aws_imagebuilder_component.pythonbotopip.arn
  }

  component {
    component_arn = aws_imagebuilder_component.highriskcorecomponent.arn
  }

  systems_manager_agent {
    uninstall_after_build = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

data "aws_ami" "highriskresearch" {
  owners      = ["679593333241"]
  most_recent = true

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "name"
    values = ["CIS Ubuntu Linux 20.04 LTS Benchmark*"]
  }
}

resource "aws_imagebuilder_component" "miniconda3" {
  name     = "miniconda3"
  platform = "Linux"
  uri      = "s3://${var.ib_bucket}/components/miniconda3.yml"
  version  = "1.0.2"
}

resource "aws_imagebuilder_component" "highriskcorecomponent" {
  name     = "highriskcorecomponent"
  platform = "Linux"
  uri      = "s3://${var.ib_bucket}/components/highriskcorecomponent.yml"
  version  = "1.0.1"
}

resource "aws_imagebuilder_component" "pythonbotopip" {
  name     = "pythonbotopip_high"
  platform = "Linux"
  uri      = "s3://${var.ib_bucket}/components/pythonbotopip.yml"
  version  = "1.0.2"
}

data "aws_imagebuilder_component" "cloudwatch_agent_linux_ubuntu" {
  arn = "arn:aws:imagebuilder:${data.aws_region.current.name}:aws:component/amazon-cloudwatch-agent-linux/x.x.x"
}

data "aws_imagebuilder_component" "update_linux_ubuntu" {
  arn = "arn:aws:imagebuilder:${data.aws_region.current.name}:aws:component/update-linux/x.x.x"
}

data "aws_imagebuilder_component" "go-linux-ubuntu" {
  arn = "arn:aws:imagebuilder:${data.aws_region.current.name}:aws:component/go-linux/x.x.x"
}

resource "aws_imagebuilder_infrastructure_configuration" "highriskresearchubuntu" {
  name                          = local.highriskresearch_image_name
  instance_types                = ["t3.medium", "t3.large"]
  instance_profile_name         = aws_iam_instance_profile.imagebuilder.name
  security_group_ids            = [data.aws_security_group.default.id]
  subnet_id                     = data.aws_subnet.default.id
  terminate_instance_on_failure = true

  # logging {
  #   s3_logs {
  #     s3_bucket_name = var.aws_s3_log_bucket
  #     s3_key_prefix  = "image-builder"
  #   }
  # }
}

resource "aws_imagebuilder_distribution_configuration" "highriskresearchubuntu" {
  name = local.highriskresearch_image_name

  distribution {
    region     = data.aws_region.current.name



    ami_distribution_configuration {
      name        = "${local.highriskresearch_ami_name}-{{ imagebuilder:buildDate }}"
      description = "Ubuntu 20.04 High-Risk Research Distribution"
      kms_key_id = data.aws_kms_key.image_builder.arn

      ami_tags = {
        CostCenter  = "CloudEng"
        Application = "Spinup ImageBuilder"
      }

      # share with these AWS accounts
      # target_account_ids = ["1234567890"]
    }
  }
}
