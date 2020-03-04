
resource "aws_security_group" "batch_sg" {
  name = "aws_batch_compute_environment_security_group"
  vpc_id = "${aws_vpc.default.id}"
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_batch_compute_environment" "test_batch" {
  compute_environment_name = "test_k6"

  compute_resources {
    instance_role = "${aws_iam_instance_profile.ecs_instance_role.arn}"

    instance_type = [
      "c5.large",
    ]

    max_vcpus = 4
    min_vcpus = 0

    security_group_ids = [
      "${aws_security_group.batch_sg.id}",
    ]

    subnets = [
      "${aws_subnet.public.id}",
    ]

    type = "EC2"
  }

  service_role = "${aws_iam_role.aws_batch_service_role.arn}"
  type         = "MANAGED"
  depends_on   = ["aws_iam_role_policy_attachment.aws_batch_service_role"]
}

resource "aws_batch_job_queue" "test_queue" {
  name                 = "k6-test-batch-job-queue"
  state                = "ENABLED"
  priority             = 1
  compute_environments = ["${aws_batch_compute_environment.test_batch.arn}"]
}

resource "aws_batch_job_definition" "test" {
  name = "k6_test_batch_job_definition"
  type = "container"
  
# TODO: update with variable for record
  container_properties = <<CONTAINER_PROPERTIES
{
    "command": ["run", "script.js"],
    "image": "${aws_ecr_repository.repo.repository_url}:latest",
    "memory": 52,
    "vcpus": 1,
    "environment": [
      { "name": "K6_OUT", "value": "influxdb=http://influxdb.k6test.internal:8086/k6" }
    ],
    "ulimits": []
}
CONTAINER_PROPERTIES
}