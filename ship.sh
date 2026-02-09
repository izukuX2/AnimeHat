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
    if [ -z "$TAG_PART" ]; then
        # Currently on stable, bump patch
        NEW_PATCH=$((PATCH + 1))
    elif [ "$CHANNEL" == "$TAG_NAME" ]; then
        # Already on same pre-release channel, bump tag number
        NEW_TAG_NUM=$((TAG_NUM + 1))
        # Keep same semver base unless user manually asked for more (handled by major/minor)
    else
        # Switching pre-release channels or from pre-release to stable
        # For pre-release to stable, we keep the semver base (e.g. 4.0.4-beta.2 -> 4.0.4)
        # For channel switch (alpha -> beta), we keep semver base and reset tag num
        NEW_TAG_NUM=1
    fi
fi

# 4. Channel Transition Logic
if [ "$CHANNEL" == "stable" ]; then
    NEW_TAG_NAME=""
else
    NEW_TAG_NAME=$CHANNEL
    if [ "$NEW_TAG_NAME" != "$TAG_NAME" ]; then
        # Reset tag number on channel change or start
        NEW_TAG_NUM=1
    elif [ "$TAG_NUM" -eq 0 ] && [ "$BUMP" == "none" ]; then
        # Starting pre-release from stable without a bump (e.g. 4.0.3 -> 4.0.3-beta.1)
        # Note: Usually you want 4.0.4-beta.1, but this allows for manual control
        NEW_TAG_NUM=1
    elif [ "$NEW_TAG_NUM" -eq 0 ]; then
        # Automatic increment if not already set by bump logic
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

# 5. Summary and Confirmation
echo -e "\n${CYAN}📋 Shipment Summary:${NC}"
echo -e "   From: ${YELLOW}$CURRENT_VERSION${NC}"
echo -e "   To:   ${GREEN}$FINAL_VERSION${NC}"
echo -e "   Channel: ${CYAN}$CHANNEL${NC}"
echo -e "   Message: $MESSAGE"

echo -en "\n${YELLOW}Proceed with shipment? [y/N]: ${NC}"
read -n 1 PROCEED
echo ""
if [[ ! "$PROCEED" =~ ^[Yy]$ ]]; then
    echo -e "${RED}Aborted.${NC}"
    exit 0
fi

# 6. Update Files
sed -i "s/^version: .*/version: $FINAL_VERSION/" $PUBSPEC

DATE=$(date +%Y-%m-%d)
TEMP_CHANGELOG="CHANGELOG.tmp"
echo "## [$FINAL_VERSION] - $DATE" > $TEMP_CHANGELOG
echo "- $MESSAGE" >> $TEMP_CHANGELOG
echo "" >> $TEMP_CHANGELOG
cat $CHANGELOG >> $TEMP_CHANGELOG
mv $TEMP_CHANGELOG $CHANGELOG

# 7. Git Operations
TRIGGER_RELEASE="n"
if [ "$CHANNEL" == "stable" ]; then
    echo -e "\n${YELLOW}🚀 Create automated GitHub Release (APK)? [y/N]: ${NC}"
    read -n 1 TRIGGER_RELEASE
    echo ""
fi

echo -e "\n${CYAN}📦 Committing and Pushing...${NC}"
git add .
git commit -m "chore(release): $FINAL_VERSION [skip ci]" -m "$MESSAGE"

if [[ "$TRIGGER_RELEASE" =~ ^[Yy]$ ]]; then
    echo -e "${GREEN}🏷️ Creating Release Tag: v$FINAL_VERSION${NC}"
    git tag "v$FINAL_VERSION"
    git push origin main
    git push origin "v$FINAL_VERSION"
else
    git push origin main
fi

# 8. Website Update (Optional)
WEBSITE_DIR="/home/izukux2/Development/website"
WEBSITE_PKY="$WEBSITE_DIR/website/package.json"

if [ -f "$WEBSITE_PKY" ]; then
    # Extract correct repo URL from package.json (specifically from the repository block)
    CORRECT_URL=$(grep -A 2 '"repository":' "$WEBSITE_PKY" | grep '"url":' | sed -E 's/.*"url": "git\+(.*)".*/\1/')
    
    cd "$WEBSITE_DIR"
    CURRENT_REMOTE=$(git remote get-url origin 2>/dev/null)
    
    if [[ "$CURRENT_REMOTE" != "$CORRECT_URL" ]] && [ -n "$CORRECT_URL" ]; then
        echo -e "\n${YELLOW}⚠️  Warning: Website remote mismatch detected!${NC}"
        echo -e "   Current: $CURRENT_REMOTE"
        echo -e "   Target:  $CORRECT_URL"
        echo -n "   Fix remote URL? [y/N]: "
        read -n 1 FIX_REMOTE
        echo ""
        if [[ "$FIX_REMOTE" =~ ^[Yy]$ ]]; then
            git remote set-url origin "$CORRECT_URL"
            echo -e "${GREEN}✅ Remote updated!${NC}"
        fi
    fi
    cd - > /dev/null

    echo -e "\n${CYAN}🌐 Detected Website Directory. Trigger website rebuild? [y/N]: ${NC}"
    read -n 1 UPDATE_WEBSITE
    echo ""
    if [[ "$UPDATE_WEBSITE" =~ ^[Yy]$ ]]; then
        echo -e "${CYAN}🔄 Triggering website rebuild...${NC}"
        cd "$WEBSITE_DIR"
        git commit --allow-empty -m "build: trigger rebuild for AnimeHat v$FINAL_VERSION"
        git push origin main
        cd - > /dev/null
        echo -e "${GREEN}✅ Website rebuild triggered!${NC}"
    fi
fi

echo -e "\n${GREEN}✅ Shipment Complete!${NC}"
