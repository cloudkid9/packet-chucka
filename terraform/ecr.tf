resource "aws_ecr_repository" "repo" {
  name                 = "k6test"
  image_tag_mutability = "MUTABLE"

}

output "ecr_repo_url" {
  value = "${aws_ecr_repository.repo.repository_url}"
}