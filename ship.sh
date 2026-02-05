#!/bin/bash

# --- Configuration ---
PUBSPEC="pubspec.yaml"
CHANGELOG="CHANGELOG.md"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}🚀 AnimeHat Ship Tool v3.1 (Multi-Channel)${NC}"

# 1. Argument Parsing
MESSAGE=""
CHANNEL="stable"
BUMP="none"

if [ $# -eq 0 ]; then
    # Interactive Mode
    echo -e "${CYAN}🚀 AnimeHat Ship Tool - Interactive Mode${NC}"
    echo -n "📝 Enter commit message: "
    read MESSAGE
    if [ -z "$MESSAGE" ]; then
        echo -e "${RED}Error: Message cannot be empty.${NC}"
        exit 1
    fi

    echo -e "\nSelect Release Channel:"
    echo "1. Release (Stable) - Default"
    echo "2. Beta"
    echo "3. Alpha"
    echo -n "Choice [1-3]: "
    read CH_CHOICE
    case $CH_CHOICE in
        2) CHANNEL="beta" ;;
        3) CHANNEL="alpha" ;;
        *) CHANNEL="stable" ;;
    esac

    echo -e "\nSelect Version Action:"
    echo "1. None (Default)"
    echo "2. Patch/Increment Pre-release"
    echo "3. Minor"
    echo "4. Major"
    echo -n "Choice [1-4]: "
    read B_CHOICE
    case $B_CHOICE in
        2) BUMP="patch" ;;
        3) BUMP="minor" ;;
        4) BUMP="major" ;;
        *) BUMP="none" ;;
    esac
else
    MESSAGE="$*"
fi

# 2. Extract current version
# Format: version: 1.0.0-beta.1+21
CURRENT_VERSION=$(grep "^version: " $PUBSPEC | sed 's/version: //')
echo -e "Current Version: ${YELLOW}$CURRENT_VERSION${NC}"

# Parse full version: BASE-TAG.NUM+BUILD
# Example: 4.0.3-beta.2+21
# Base: 4.0.3
# Tag: beta (optional)
# TagNum: 2 (optional)
# Build: 21

BASE_PART=$(echo $CURRENT_VERSION | cut -d'+' -f1)
BUILD_NUMBER=$(echo $CURRENT_VERSION | cut -d'+' -f2)

# Extract Semantic Base (X.Y.Z)
SEMVER=$(echo $BASE_PART | cut -d'-' -f1)
TAG_PART=$(echo $BASE_PART | cut -d'-' -s -f2) # empty if no tag

IFS='.' read -ra SEM_ADDR <<< "$SEMVER"
MAJOR=${SEM_ADDR[0]}
MINOR=${SEM_ADDR[1]}
PATCH=${SEM_ADDR[2]}

TAG_NAME=""
TAG_NUM=0
if [ -n "$TAG_PART" ]; then
    TAG_NAME=$(echo $TAG_PART | cut -d'.' -f1)
    TAG_NUM=$(echo $TAG_PART | cut -d'.' -f2)
fi

# 3. Version Bumping Logic
NEW_MAJOR=$MAJOR
NEW_MINOR=$MINOR
NEW_PATCH=$PATCH
NEW_TAG_NAME=""
NEW_TAG_NUM=0

if [ "$BUMP" == "major" ]; then
    NEW_MAJOR=$((MAJOR + 1))
    NEW_MINOR=0
    NEW_PATCH=0
elif [ "$BUMP" == "minor" ]; then
    NEW_MINOR=$((MINOR + 1))
    NEW_PATCH=0
elif [ "$BUMP" == "patch" ]; then
    if [ "$CHANNEL" == "stable" ] && [ -z "$TAG_PART" ]; then
        # Standard patch bump
        NEW_PATCH=$((PATCH + 1))
    elif [ "$CHANNEL" != "stable" ] && [ "$CHANNEL" == "$TAG_NAME" ]; then
        # Just incrementing the existing pre-release tag
        NEW_TAG_NUM=$((TAG_NUM + 1))
        NEW_TAG_NAME=$CHANNEL
    fi
    # If switching channels or going to stable, patch logic is handled below
fi

# 4. Channel Transition Logic
if [ "$CHANNEL" == "stable" ]; then
    # Stripping any tags
    NEW_TAG_NAME=""
else
    # We are in or moving to alpha/beta
    NEW_TAG_NAME=$CHANNEL
    if [ "$CHANNEL" != "$TAG_NAME" ]; then
        # Switching channel (e.g. stable->beta or alpha->beta)
        NEW_TAG_NUM=1
    elif [ "$BUMP" == "none" ] && [ -z "$TAG_PART" ]; then
         # Moving from stable to a tag without bumping semver
         NEW_TAG_NUM=1
    elif [ -z "$NEW_TAG_NUM" ] || [ "$NEW_TAG_NUM" -eq 0 ]; then
         # Fallback increment if we didn't handle it above
         NEW_TAG_NUM=$((TAG_NUM + 1))
    fi
fi

# Construct Final Base Version
NEW_BASE="$NEW_MAJOR.$NEW_MINOR.$NEW_PATCH"
if [ -n "$NEW_TAG_NAME" ]; then
    NEW_BASE="$NEW_BASE-$NEW_TAG_NAME.$NEW_TAG_NUM"
fi

NEW_BUILD=$((BUILD_NUMBER + 1))
FINAL_VERSION="$NEW_BASE+$NEW_BUILD"

if [ "$CHANNEL" == "stable" ]; then
    echo -e "${YELLOW}🌟 Preparing Full Release...${NC}"
fi

echo -e "New Version:     ${GREEN}$FINAL_VERSION${NC}"
echo -e "Channel:         ${CYAN}$CHANNEL${NC}"

# 5. Update Files
# Update pubspec.yaml
sed -i "s/^version: .*/version: $FINAL_VERSION/" $PUBSPEC

# Update CHANGELOG.md
DATE=$(date +%Y-%m-%d)
TEMP_CHANGELOG="CHANGELOG.tmp"
echo "## [$FINAL_VERSION] - $DATE" > $TEMP_CHANGELOG
echo "- $MESSAGE" >> $TEMP_CHANGELOG
echo "" >> $TEMP_CHANGELOG
cat $CHANGELOG >> $TEMP_CHANGELOG
mv $TEMP_CHANGELOG $CHANGELOG

# 6. Git Operations
TRIGGER_RELEASE="n"
if [ "$CHANNEL" == "stable" ] && [ "$FINAL_VERSION" != "$CURRENT_VERSION" ]; then
    echo -e "\n${YELLOW}🚀 Create automated GitHub Release (APK)? [y/N]: ${NC}"
    read -n 1 TRIGGER_RELEASE
    echo ""
fi

echo -e "\n${CYAN}📦 Committing and Pushing...${NC}"
git add .
git commit -m "$MESSAGE"

if [[ "$TRIGGER_RELEASE" =~ ^[Yy]$ ]]; then
    echo -e "${GREEN}🏷️ Creating Release Tag: v$FINAL_VERSION${NC}"
    git tag "v$FINAL_VERSION"
    git push origin main
    git push origin "v$FINAL_VERSION"
elif [ "$FINAL_VERSION" != "$CURRENT_VERSION" ]; then
    # Still version changed, but maybe not a formal release? 
    # Usually we tag anyway for history, but if user said no to release, 
    # we might just push the code.
    git push origin main
else
    git push origin main
fi

echo -e "\n${GREEN}✅ Shipment Complete!${NC}"
