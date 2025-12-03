# Docker Build Configuration

This directory contains the Dockerfile and related configuration for building container images.

## Files

- **Dockerfile** - Multi-stage Docker build configuration
- **.dockerignore** - Specifies files to exclude from the Docker build context

## .dockerignore Location

The `.dockerignore` file is located in this `docker/` folder for better organization, keeping all Docker-related files together. 

However, Docker expects to find `.dockerignore` at the root of the build context. To solve this:
- The actual file lives here: `docker/.dockerignore`
- A symlink exists at the repository root: `.dockerignore -> docker/.dockerignore`

This approach allows Docker to find the file when building with the repository root as the build context, while keeping the file organized with the Dockerfile.

## Building the Image

The image is built using the repository root as the build context:

```bash
docker buildx build --file docker/Dockerfile --tag <image-name> .
```

The `.dockerignore` file (via symlink) controls which files are included in the build context.
