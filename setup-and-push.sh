#!/bin/bash

# Color codes for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}"
echo "╔══════════════════════════════════════════════════════════╗"
echo "║     React Native Call Keeper - Setup & Push Script      ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Get current directory
PACKAGE_DIR="/Users/user/Desktop/allproject/react-native-call-keeper"
cd "$PACKAGE_DIR" || exit 1

# Step 1: Get user information
echo -e "${YELLOW}📝 Step 1: Configure Package Information${NC}"
echo ""
echo "Please provide the following information:"
echo ""

read -p "Your GitHub username: " GITHUB_USERNAME
read -p "Your name: " AUTHOR_NAME
read -p "Your email: " AUTHOR_EMAIL
read -p "Package name (press Enter for 'react-native-call-keeper'): " PACKAGE_NAME
PACKAGE_NAME=${PACKAGE_NAME:-react-native-call-keeper}

echo ""
echo -e "${GREEN}✓ Information collected${NC}"
echo ""

# Step 2: Update package.json
echo -e "${YELLOW}📝 Step 2: Updating package.json...${NC}"

# Create a temporary file with updated package.json
node -e "
const fs = require('fs');
const pkg = JSON.parse(fs.readFileSync('package.json', 'utf8'));
pkg.name = '$PACKAGE_NAME';
pkg.repository = {
  type: 'git',
  url: 'https://github.com/$GITHUB_USERNAME/$PACKAGE_NAME.git'
};
pkg.author = '$AUTHOR_NAME <$AUTHOR_EMAIL>';
pkg.homepage = 'https://github.com/$GITHUB_USERNAME/$PACKAGE_NAME#readme';
pkg.bugs = {
  url: 'https://github.com/$GITHUB_USERNAME/$PACKAGE_NAME/issues'
};
fs.writeFileSync('package.json', JSON.stringify(pkg, null, 2) + '\n');
console.log('✓ package.json updated');
"

echo -e "${GREEN}✓ package.json updated${NC}"
echo ""

# Step 3: Update .podspec
echo -e "${YELLOW}📝 Step 3: Updating .podspec file...${NC}"

sed -i '' "s|https://github.com/yourusername/react-native-call-keeper.git|https://github.com/$GITHUB_USERNAME/$PACKAGE_NAME.git|g" react-native-call-keeper.podspec

echo -e "${GREEN}✓ .podspec updated${NC}"
echo ""

# Step 4: Initialize Git
echo -e "${YELLOW}📝 Step 4: Initializing Git repository...${NC}"

if [ -d ".git" ]; then
    echo "Git repository already initialized"
else
    git init
    echo -e "${GREEN}✓ Git initialized${NC}"
fi

# Step 5: Add and commit
echo -e "${YELLOW}📝 Step 5: Committing files...${NC}"

git add .
git commit -m "Initial commit: $PACKAGE_NAME v1.0.0

- Native CallKit integration for iOS
- ConnectionService integration for Android  
- TurboModule support (New Architecture)
- Expo config plugin included
- Full TypeScript support
- Comprehensive documentation"

echo -e "${GREEN}✓ Files committed${NC}"
echo ""

# Step 6: Instructions for GitHub
echo -e "${YELLOW}📝 Step 6: GitHub Setup${NC}"
echo ""
echo "Before pushing, please:"
echo "1. Go to https://github.com/new"
echo "2. Create a new repository named: ${BLUE}$PACKAGE_NAME${NC}"
echo "3. Keep it PUBLIC (required for NPM)"
echo "4. DO NOT initialize with README"
echo ""
read -p "Press Enter when you've created the GitHub repository..."

# Step 7: Add remote and push
echo ""
echo -e "${YELLOW}📝 Step 7: Pushing to GitHub...${NC}"

git remote add origin "https://github.com/$GITHUB_USERNAME/$PACKAGE_NAME.git"
git branch -M main

echo ""
echo "Pushing to GitHub..."
echo "You may be prompted for your GitHub credentials."
echo ""

if git push -u origin main; then
    echo ""
    echo -e "${GREEN}✓ Successfully pushed to GitHub!${NC}"
    echo ""
    echo "Your repository: https://github.com/$GITHUB_USERNAME/$PACKAGE_NAME"
else
    echo ""
    echo -e "${RED}✗ Failed to push to GitHub${NC}"
    echo ""
    echo "You can push manually with:"
    echo "  git push -u origin main"
    echo ""
    exit 1
fi

# Step 8: NPM Publishing
echo ""
echo -e "${YELLOW}📝 Step 8: NPM Publishing${NC}"
echo ""
echo "Would you like to publish to NPM now?"
echo ""
read -p "Publish to NPM? (y/N): " PUBLISH_NPM

if [[ "$PUBLISH_NPM" =~ ^[Yy]$ ]]; then
    echo ""
    echo "Checking NPM login status..."
    
    if npm whoami &> /dev/null; then
        echo -e "${GREEN}✓ Already logged in to NPM as: $(npm whoami)${NC}"
    else
        echo "Please login to NPM:"
        npm login
    fi
    
    echo ""
    echo "Publishing to NPM..."
    
    if npm publish; then
        echo ""
        echo -e "${GREEN}✓ Successfully published to NPM!${NC}"
        echo ""
        echo "Your package: https://www.npmjs.com/package/$PACKAGE_NAME"
    else
        echo ""
        echo -e "${RED}✗ Failed to publish to NPM${NC}"
        echo ""
        echo "Common issues:"
        echo "  - Package name already taken (try: @$GITHUB_USERNAME/$PACKAGE_NAME)"
        echo "  - Not logged in (run: npm login)"
        echo "  - Version already published (run: npm version patch)"
    fi
else
    echo ""
    echo "Skipping NPM publish."
    echo "You can publish later with: npm publish"
fi

# Final summary
echo ""
echo -e "${BLUE}"
echo "╔══════════════════════════════════════════════════════════╗"
echo "║                    🎉 Setup Complete!                    ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo ""
echo "✅ Git repository initialized"
echo "✅ Files committed"
echo "✅ Pushed to GitHub"
echo ""
echo "📦 Package: $PACKAGE_NAME"
echo "🔗 GitHub: https://github.com/$GITHUB_USERNAME/$PACKAGE_NAME"
echo ""
echo "📚 Next steps:"
echo "  1. Add topics to GitHub repo (react-native, callkit, voip)"
echo "  2. Enable GitHub Actions (if needed)"
echo "  3. Test installation: npm install $PACKAGE_NAME"
echo "  4. Share with the community!"
echo ""
echo "See PUSH_GUIDE.md for more details."
echo ""

