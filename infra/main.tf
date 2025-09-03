resource "aws_ecr_repository" "fencoder_repo" {
	name = "fencoder-repo"
	image_tag_mutability = "MUTABLE"
	image_scanning_configuration {
		scan_on_push = true
	}
}
