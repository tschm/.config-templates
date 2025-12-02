#!/bin/sh
# Version bump and tag creation script for releases
# - Three-step release process: bump, commit, push
# - Validates the version format using uv
# - Updates pyproject.toml with the new version using uv
# - Creates a git tag and pushes it to trigger the release workflow
#
# This script is POSIX-sh compatible and follows the style of other scripts
# in this repository. It uses uv to manage version updates.

set -e

UV_BIN=${UV_BIN:-./bin/uv}

BLUE="\033[36m"
RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
RESET="\033[0m"

# Parse command-line arguments
VERSION=""
BUMP=""
COMMAND=""
BRANCH=""
ALL_MODE=""

show_usage() {
  printf "Usage: %s [OPTIONS] [COMMAND]\n\n" "$0"
  printf "Commands:\n"
  printf "  (default)      Bump version (updates pyproject.toml only)\n"
  printf "  commit         Commit version changes and create tag\n"
  printf "  push           Push commit and tag to remote\n\n"
  printf "Options:\n"
  printf "  --bump TYPE    Bump version semantically (major, minor, patch, alpha, beta, rc, etc.)\n"
  printf "  --version VER  Set explicit version number\n"
  printf "  --branch REF   Branch or ref to tag (default: current default branch)\n"
  printf "  --all          Execute all steps with prompts between each\n"
  printf "  -h, --help     Show this help message\n\n"
  printf "Examples:\n"
  printf "  %s --bump patch              (bump patch version)\n" "$0"
  printf "  %s --bump minor              (bump minor version)\n" "$0"
  printf "  %s --version 1.2.3           (set version to 1.2.3)\n" "$0"
  printf "  %s commit                    (commit version changes and create tag)\n" "$0"
  printf "  %s push                      (push commit and tag to remote)\n" "$0"
  printf "  %s --bump minor --all        (do all steps with prompts)\n" "$0"
  printf "  %s --bump patch --branch main (bump on specific branch)\n" "$0"
}

while [ $# -gt 0 ]; do
  case "$1" in
    --bump)
      if [ -z "$2" ]; then
        printf "%b[ERROR] --bump requires a value%b\n" "$RED" "$RESET"
        show_usage
        exit 1
      fi
      BUMP="$2"
      shift 2
      ;;
    --version)
      if [ -z "$2" ]; then
        printf "%b[ERROR] --version requires a value%b\n" "$RED" "$RESET"
        show_usage
        exit 1
      fi
      VERSION="$2"
      shift 2
      ;;
    --branch)
      if [ -z "$2" ]; then
        printf "%b[ERROR] --branch requires a value%b\n" "$RED" "$RESET"
        show_usage
        exit 1
      fi
      BRANCH="$2"
      shift 2
      ;;
    --all)
      ALL_MODE="true"
      shift
      ;;
    -h|--help)
      show_usage
      exit 0
      ;;
    commit|push)
      if [ -n "$COMMAND" ]; then
        printf "%b[ERROR] Multiple commands provided%b\n" "$RED" "$RESET"
        show_usage
        exit 1
      fi
      COMMAND="$1"
      shift
      ;;
    -*)
      printf "%b[ERROR] Unknown option: %s%b\n" "$RED" "$1" "$RESET"
      show_usage
      exit 1
      ;;
    *)
      printf "%b[ERROR] Unknown argument: %s%b\n" "$RED" "$1" "$RESET"
      show_usage
      exit 1
      ;;
  esac
done

# Strip 'v' prefix if present in explicit version
if [ -n "$VERSION" ]; then
  VERSION=$(echo "$VERSION" | sed 's/^v//')
fi

# Check if pyproject.toml exists
if [ ! -f "pyproject.toml" ]; then
  printf "%b[ERROR] pyproject.toml not found in current directory%b\n" "$RED" "$RESET"
  exit 1
fi

# Check if uv is available
if [ ! -x "$UV_BIN" ]; then
  printf "%b[ERROR] uv not found at %s. Run 'make install-uv' first.%b\n" "$RED" "$UV_BIN" "$RESET"
  exit 1
fi

# Helper function to prompt user in ALL mode
prompt_continue() {
  if [ -n "$ALL_MODE" ]; then
    printf "\n%b[PROMPT] Continue to next step? [y/N] %b" "$YELLOW" "$RESET"
    read -r answer
    case "$answer" in
      [Yy]*)
        return 0
        ;;
      *)
        printf "%b[INFO] Aborted by user%b\n" "$YELLOW" "$RESET"
        exit 0
        ;;
    esac
  fi
}

# Function: Bump version
do_bump() {
  # Validate that either version or bump was provided
  if [ -z "$VERSION" ] && [ -z "$BUMP" ]; then
    printf "%b[ERROR] No version or bump type specified for bump command%b\n" "$RED" "$RESET"
    printf "Use --bump TYPE or --version VER\n"
    show_usage
    exit 1
  fi

  if [ -n "$VERSION" ] && [ -n "$BUMP" ]; then
    printf "%b[ERROR] Cannot specify both --version and --bump%b\n" "$RED" "$RESET"
    show_usage
    exit 1
  fi

  # Determine target branch and default branch
  DEFAULT_BRANCH=$(git remote show origin | grep 'HEAD branch' | cut -d' ' -f5)
  if [ -z "$DEFAULT_BRANCH" ]; then
    printf "%b[ERROR] Could not determine default branch from remote%b\n" "$RED" "$RESET"
    exit 1
  fi

  if [ -z "$BRANCH" ]; then
    BRANCH="$DEFAULT_BRANCH"
    printf "%b[INFO] Using default branch: %s%b\n" "$BLUE" "$BRANCH" "$RESET"
  else
    printf "%b[INFO] Using specified branch: %s%b\n" "$BLUE" "$BRANCH" "$RESET"
    if [ "$BRANCH" != "$DEFAULT_BRANCH" ]; then
      printf "%b[WARN] Target branch '%s' differs from default branch '%s'%b\n" "$YELLOW" "$BRANCH" "$DEFAULT_BRANCH" "$RESET"
      printf "%b[WARN] Releases are typically created from the default branch.%b\n" "$YELLOW" "$RESET"
      if [ -z "$ALL_MODE" ]; then
        printf "Continue with branch '%s'? [y/N] " "$BRANCH"
        read -r answer
        case "$answer" in
          [Yy]*)
            ;;
          *)
            printf "%b[INFO] Aborted by user%b\n" "$YELLOW" "$RESET"
            exit 1
            ;;
        esac
      fi
    fi
  fi

  # Verify branch exists
  if ! git rev-parse --verify "origin/$BRANCH" >/dev/null 2>&1; then
    printf "%b[ERROR] Branch 'origin/%s' does not exist%b\n" "$RED" "$BRANCH" "$RESET"
    exit 1
  fi

  # Check for ambiguous tag/branch names
  if git rev-parse --verify "refs/tags/$BRANCH" >/dev/null 2>&1; then
    printf "%b[WARN] A tag named '%s' exists, which conflicts with the branch name.%b\n" "$YELLOW" "$BRANCH" "$RESET"
    printf "%b[WARN] This creates ambiguity for git commands. We will use explicit refspecs to handle this.%b\n" "$YELLOW" "$RESET"
  fi

  # Get current version
  CURRENT_VERSION=$("$UV_BIN" version --short 2>/dev/null || echo "unknown")
  printf "%b[INFO] Current version: %s%b\n" "$BLUE" "$CURRENT_VERSION" "$RESET"

  # Determine the new version using uv version with --dry-run first
  if [ -n "$BUMP" ]; then
    printf "%b[INFO] Bumping version using: %s%b\n" "$BLUE" "$BUMP" "$RESET"
    NEW_VERSION=$("$UV_BIN" version --bump "$BUMP" --dry-run --short 2>/dev/null)
    if [ $? -ne 0 ] || [ -z "$NEW_VERSION" ]; then
      printf "%b[ERROR] Failed to calculate new version with bump type: %s%b\n" "$RED" "$BUMP" "$RESET"
      exit 1
    fi
  else
    # Validate the version format by having uv try it with --dry-run
    if ! "$UV_BIN" version "$VERSION" --dry-run >/dev/null 2>&1; then
      printf "%b[ERROR] Invalid version format: %s%b\n" "$RED" "$VERSION" "$RESET"
      printf "uv rejected this version. Please use a valid semantic version.\n"
      exit 1
    fi
    NEW_VERSION="$VERSION"
  fi

  printf "%b[INFO] New version will be: %s%b\n" "$BLUE" "$NEW_VERSION" "$RESET"

  TAG="v$NEW_VERSION"

  # Check if tag already exists
  if git rev-parse "$TAG" >/dev/null 2>&1; then
    printf "%b[ERROR] Tag '%s' already exists locally%b\n" "$RED" "$TAG" "$RESET"
    exit 1
  fi

  if git ls-remote --exit-code --tags origin "refs/tags/$TAG" >/dev/null 2>&1; then
    printf "%b[ERROR] Tag '%s' already exists on remote%b\n" "$RED" "$TAG" "$RESET"
    exit 1
  fi

  # Check for uncommitted changes (excluding pyproject.toml and uv.lock which we'll update)
  UNCOMMITTED=$(git status --porcelain | grep -v "^ M pyproject.toml" | grep -v "^ M uv.lock" || true)
  if [ -n "$UNCOMMITTED" ]; then
    printf "%b[ERROR] You have uncommitted changes:%b\n" "$RED" "$RESET"
    echo "$UNCOMMITTED"
    printf "\n%b[ERROR] Please commit or stash your changes before releasing.%b\n" "$RED" "$RESET"
    exit 1
  fi

  # Checkout and update the target branch
  printf "%b[INFO] Checking out branch %s...%b\n" "$BLUE" "$BRANCH" "$RESET"
  git fetch origin
  git checkout "$BRANCH"
  git pull origin "$BRANCH"

  # Update version in pyproject.toml using uv
  printf "%b[INFO] Updating version in pyproject.toml...%b\n" "$BLUE" "$RESET"
  if [ -n "$BUMP" ]; then
    if ! "$UV_BIN" version --bump "$BUMP" >/dev/null 2>&1; then
      printf "%b[ERROR] Failed to bump version using 'uv version --bump %s'%b\n" "$RED" "$BUMP" "$RESET"
      exit 1
    fi
  else
    if ! "$UV_BIN" version "$NEW_VERSION" >/dev/null 2>&1; then
      printf "%b[ERROR] Failed to set version using 'uv version %s'%b\n" "$RED" "$NEW_VERSION" "$RESET"
      exit 1
    fi
  fi

  # Verify the update
  UPDATED_VERSION=$("$UV_BIN" version --short 2>/dev/null)
  if [ "$UPDATED_VERSION" != "$NEW_VERSION" ]; then
    printf "%b[ERROR] Version update failed. Expected %s but got %s%b\n" "$RED" "$NEW_VERSION" "$UPDATED_VERSION" "$RESET"
    exit 1
  fi

  printf "%b[SUCCESS] Version bumped to %s in pyproject.toml%b\n" "$GREEN" "$NEW_VERSION" "$RESET"
  printf "%b[INFO] Next step: Run 'make release commit' to commit changes and create tag%b\n" "$BLUE" "$RESET"
}

# Function: Commit version changes and create tag
do_commit() {
  # Check for uncommitted version changes (either pyproject.toml or uv.lock should have changes)
  if git diff --quiet pyproject.toml 2>/dev/null && git diff --quiet uv.lock 2>/dev/null; then
    printf "%b[ERROR] No uncommitted changes found in pyproject.toml or uv.lock%b\n" "$RED" "$RESET"
    printf "Run the bump command first: make release BUMP=<type>\n"
    exit 1
  fi

  # Get the new version from pyproject.toml
  NEW_VERSION=$("$UV_BIN" version --short 2>/dev/null)
  if [ -z "$NEW_VERSION" ]; then
    printf "%b[ERROR] Could not determine version from pyproject.toml%b\n" "$RED" "$RESET"
    exit 1
  fi

  TAG="v$NEW_VERSION"

  # Check if tag already exists
  if git rev-parse "$TAG" >/dev/null 2>&1; then
    printf "%b[ERROR] Tag '%s' already exists locally%b\n" "$RED" "$TAG" "$RESET"
    exit 1
  fi

  if git ls-remote --exit-code --tags origin "refs/tags/$TAG" >/dev/null 2>&1; then
    printf "%b[ERROR] Tag '%s' already exists on remote%b\n" "$RED" "$TAG" "$RESET"
    exit 1
  fi

  # Check for other uncommitted changes
  UNCOMMITTED=$(git status --porcelain | grep -v "^ M pyproject.toml" | grep -v "^ M uv.lock" || true)
  if [ -n "$UNCOMMITTED" ]; then
    printf "%b[ERROR] You have uncommitted changes beyond pyproject.toml and uv.lock:%b\n" "$RED" "$RESET"
    echo "$UNCOMMITTED"
    printf "\n%b[ERROR] Please commit or stash your changes before committing the release.%b\n" "$RED" "$RESET"
    exit 1
  fi

  # Commit the version change
  printf "%b[INFO] Committing version change to %s...%b\n" "$BLUE" "$NEW_VERSION" "$RESET"
  git add pyproject.toml
  git add uv.lock 2>/dev/null || true  # In case uv modifies the lock file
  git commit -m "chore: bump version to $NEW_VERSION"

  # Create the tag
  printf "%b[INFO] Creating tag %s...%b\n" "$BLUE" "$TAG" "$RESET"
  git tag -a "$TAG" -m "Release $TAG"

  printf "%b[SUCCESS] Version committed and tag %s created locally%b\n" "$GREEN" "$TAG" "$RESET"
  printf "%b[INFO] Next step: Run 'make release push' to push to remote%b\n" "$BLUE" "$RESET"
}

# Function: Push commit and tag to remote
do_push() {
  # Get the current version
  NEW_VERSION=$("$UV_BIN" version --short 2>/dev/null)
  if [ -z "$NEW_VERSION" ]; then
    printf "%b[ERROR] Could not determine version from pyproject.toml%b\n" "$RED" "$RESET"
    exit 1
  fi

  TAG="v$NEW_VERSION"

  # Verify tag exists locally
  if ! git rev-parse "$TAG" >/dev/null 2>&1; then
    printf "%b[ERROR] Tag '%s' does not exist locally%b\n" "$RED" "$TAG" "$RESET"
    printf "Run the commit command first: make release commit\n"
    exit 1
  fi

  # Check if tag already exists on remote
  if git ls-remote --exit-code --tags origin "refs/tags/$TAG" >/dev/null 2>&1; then
    printf "%b[ERROR] Tag '%s' already exists on remote%b\n" "$RED" "$TAG" "$RESET"
    exit 1
  fi

  # Determine current branch
  CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
  if [ -z "$CURRENT_BRANCH" ]; then
    printf "%b[ERROR] Could not determine current branch%b\n" "$RED" "$RESET"
    exit 1
  fi

  # Check if there are unpushed commits
  UNPUSHED=$(git log "origin/$CURRENT_BRANCH..$CURRENT_BRANCH" --oneline 2>/dev/null || true)
  if [ -z "$UNPUSHED" ]; then
    printf "%b[WARN] No unpushed commits found on branch %s%b\n" "$YELLOW" "$CURRENT_BRANCH" "$RESET"
    printf "Make sure you've run 'make release commit' first\n"
  fi

  # Push the commit
  printf "%b[INFO] Pushing commit to %s...%b\n" "$BLUE" "$CURRENT_BRANCH" "$RESET"
  git push origin "refs/heads/$CURRENT_BRANCH"

  # Push the tag
  printf "%b[INFO] Pushing tag %s to origin...%b\n" "$BLUE" "$TAG" "$RESET"
  git push origin "refs/tags/$TAG"

  REPO_URL=$(git remote get-url origin | sed 's/.*github.com[:/]\(.*\)\.git/\1/')
  printf "\n%b[SUCCESS] Release tag %s pushed to remote!%b\n" "$GREEN" "$TAG" "$RESET"
  printf "%b[INFO] The release workflow will now be triggered automatically.%b\n" "$BLUE" "$RESET"
  printf "%b[INFO] Monitor progress at: https://github.com/%s/actions%b\n" "$BLUE" "$REPO_URL" "$RESET"
}

# Main execution logic
if [ -n "$ALL_MODE" ]; then
  # Execute all steps with prompts
  printf "%b[INFO] Running in ALL mode - will prompt between steps%b\n" "$BLUE" "$RESET"
  
  printf "\n%b=== STEP 1: Bump Version ===%b\n" "$BLUE" "$RESET"
  do_bump
  prompt_continue
  
  printf "\n%b=== STEP 2: Commit and Tag ===%b\n" "$BLUE" "$RESET"
  do_commit
  prompt_continue
  
  printf "\n%b=== STEP 3: Push to Remote ===%b\n" "$BLUE" "$RESET"
  do_push
  
  printf "\n%b[SUCCESS] All release steps completed!%b\n" "$GREEN" "$RESET"
else
  # Execute specific command
  case "$COMMAND" in
    commit)
      do_commit
      ;;
    push)
      do_push
      ;;
    "")
      # Default: bump version
      do_bump
      ;;
    *)
      printf "%b[ERROR] Unknown command: %s%b\n" "$RED" "$COMMAND" "$RESET"
      show_usage
      exit 1
      ;;
  esac
fi
