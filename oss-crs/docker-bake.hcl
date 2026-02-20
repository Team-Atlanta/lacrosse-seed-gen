variable "BASE_IMAGES_DIR" {
  default = "libs/oss-fuzz/infra/base-images"
}

variable "REGISTRY" {
  default = "ghcr.io/team-atlanta"
}

variable "VERSION" {
  default = "latest"
}

# When true (default): Pull cached images from registry, build only if cache miss
# When false: Build everything from scratch locally
variable "USE_PREBUILT" {
  default = false
}

# Helper function to generate tags
function "tags" {
  params = [name]
  result = [
    "${REGISTRY}/${name}:${VERSION}",
    "${REGISTRY}/${name}:latest",
    "${name}:latest"
  ]
}

group "default" {
  targets = ["lacrosse-seedgen-base"]
}

target "lacrosse-seedgen-base" {
  context    = "."
  dockerfile = "oss-crs/dockerfiles/base.Dockerfile"
  tags       = tags("lacrosse-seedgen-base")
}
