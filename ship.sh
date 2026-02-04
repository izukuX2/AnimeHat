#!/bin/bash

# --- Styling ---
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${CYAN}🚀 AnimeHat Ship Tool${NC}"
echo "--------------------------"

# 1. Get current version
current_version=$(grep '^version: ' pubspec.yaml | sed 's/version: //')
echo -e "Current version: ${YELLOW}$current_version${NC}"

# 2. Ask for commit message
read -p "Enter commit message: " commit_message
if [ -z "$commit_message" ]; then
    echo -e "${RED}Error: Commit message cannot be empty.${NC}"
    exit 1
fi

# 3. Version Bumping
echo -e "\n${CYAN}Version Bumping Options:${NC}"
echo "1) No Change (Standard Push)"
echo "2) Patch (x.x.X) - Bug fixes"
echo "3) Minor (x.X.0) - New features"
echo "4) Major (X.0.0) - Breaking changes"
read -p "Select option [1-4]: " version_choice

version_changed=false
new_version=$current_version

if [ "$version_choice" != "1" ]; then
    # Parse version (format: major.minor.patch+build)
    base_version=$(echo $current_version | cut -d'+' -f1)
    build_number=$(echo $current_version | cut -d'+' -f2)
    
    major=$(echo $base_version | cut -d'.' -f1)
    minor=$(echo $base_version | cut -d'.' -f2)
    patch=$(echo $base_version | cut -d'.' -f3)

    case $version_choice in
        2) patch=$((patch + 1)) ;;
        3) minor=$((minor + 1)); patch=0 ;;
        4) major=$((major + 1)); minor=0; patch=0 ;;
    esac
    
    # Increment build number
    build_number=$((build_number + 1))
    
    new_version="$major.$minor.$patch+$build_number"
    echo -e "Bumping version to: ${GREEN}$new_version${NC}"
    
    # Update pubspec.yaml
    sed -i "s/version: $current_version/version: $new_version/" pubspec.yaml
    version_changed=true
fi

# 4. Summary & Confirmation
echo -e "\n${YELLOW}Summary:${NC}"
echo -e "Commit: $commit_message"
echo -e "Version: $new_version"
if [ "$version_changed" = true ]; then
    echo -e "GitHub Action: ${GREEN}WILL TRIGGER APK BUILD & RELEASE${NC}"
else
    echo -e "GitHub Action: ${YELLOW}CI ONLY (No APK build)${NC}"
fi

read -p "Confirm shipping? (y/n): " confirm
if [ "$confirm" != "y" ]; then
    # Revert version if it was changed
    if [ "$version_changed" = true ]; then
        sed -i "s/version: $new_version/version: $current_version/" pubspec.yaml
    fi
    echo "Shipment cancelled."
    exit 0
fi

# 5. Execution
echo -e "\n${CYAN}📦 Packing and Shipping...${NC}"

git add .
git commit -m "$commit_message"
git push origin main

echo -e "\n${GREEN}✅ Shipped!${NC}"
echo "Check your GitHub Actions at: https://github.com/izukuX2/AnimeHat/actions"
