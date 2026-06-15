#!/usr/bin/env bash
set -euo pipefail

REGISTRY="ghcr.io/chienbui09"
TAG="${1:-latest}"
TARGET="${2:-all}"  # serve | worker | all
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Ensure buildx builder with multi-platform support exists
if ! docker buildx inspect multiplatform-builder &>/dev/null; then
  docker buildx create --name multiplatform-builder --driver docker-container --bootstrap
fi
docker buildx use multiplatform-builder

build_serve() {
  local image="${REGISTRY}/fastchat-server:${TAG}"
  echo "Building and pushing ${image} (linux/amd64, linux/arm64)..."
  docker buildx build \
    --platform linux/amd64,linux/arm64 \
    --file "${SCRIPT_DIR}/Dockerfile.serve" \
    --tag "${image}" \
    --push \
    "${SCRIPT_DIR}"
  echo "Done: ${image}"
}

build_worker() {
  local image="${REGISTRY}/fastchat-model-worker:${TAG}"
  echo "Building and pushing ${image} (linux/amd64)..."
  docker buildx build \
    --platform linux/amd64 \
    --file "${SCRIPT_DIR}/Dockerfile.model-worker" \
    --tag "${image}" \
    --push \
    "${SCRIPT_DIR}"
  echo "Done: ${image}"
}

case "${TARGET}" in
  serve)  build_serve ;;
  worker) build_worker ;;
  all)    build_serve && build_worker ;;
  *)
    echo "Usage: $0 [TAG] [serve|worker|all]"
    exit 1
    ;;
esac
