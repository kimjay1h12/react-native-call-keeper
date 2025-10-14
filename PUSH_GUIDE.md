# 🚀 How to Push & Publish Your Package

## Step-by-Step Guide

### 1️⃣ Initialize Git Repository

```bash
cd /Users/user/Desktop/allproject/react-native-call-keeper

# Initialize git (if not already done)
git init

# Add all files
git add .

# Make first commit
git commit -m "Initial commit: react-native-call-keeper v1.0.0"
```

### 2️⃣ Create GitHub Repository

1. Go to [GitHub](https://github.com) and log in
2. Click the **"+"** icon → **"New repository"**
3. Fill in:
   - **Repository name:** `react-native-call-keeper`
   - **Description:** "Native call keep module for React Native with CallKit and ConnectionService support"
   - **Visibility:** Public (for NPM packages)
   - ⚠️ **DO NOT** initialize with README (we already have one)
4. Click **"Create repository"**

### 3️⃣ Update package.json

Before pushing, update your package details:

```bash
# Open package.json and update these fields:
```

```json
{
  "name": "react-native-call-keeper",
  "repository": {
    "type": "git",
    "url": "https://github.com/YOUR_USERNAME/react-native-call-keeper.git"
  },
  "author": "Your Name <your.email@example.com>",
  "homepage": "https://github.com/YOUR_USERNAME/react-native-call-keeper#readme",
  "bugs": {
    "url": "https://github.com/YOUR_USERNAME/react-native-call-keeper/issues"
  }
}
```

Replace `YOUR_USERNAME` with your actual GitHub username.

### 4️⃣ Push to GitHub

```bash
# Add your GitHub repository as remote
git remote add origin https://github.com/YOUR_USERNAME/react-native-call-keeper.git

# Push to GitHub
git branch -M main
git push -u origin main
```

**Alternative with SSH:**

```bash
git remote add origin git@github.com:YOUR_USERNAME/react-native-call-keeper.git
git branch -M main
git push -u origin main
```

### 5️⃣ Publish to NPM

#### A. First Time Setup

```bash
# Login to NPM (if you haven't already)
npm login

# You'll be prompted for:
# - Username
# - Password
# - Email
# - OTP (if you have 2FA enabled)
```

#### B. Test Before Publishing

```bash
# Check what will be published
npm pack --dry-run

# Or create a tarball to inspect
npm pack
# This creates: react-native-call-keeper-1.0.0.tgz
```

#### C. Publish to NPM

```bash
# Publish the package
npm publish

# For scoped packages (if needed):
npm publish --access public
```

### 6️⃣ Verify Publication

```bash
# Check on NPM
npm view react-native-call-keeper

# Test installation
cd /tmp
npx react-native init TestApp
cd TestApp
npm install react-native-call-keeper
```

---

## 🔄 For Future Updates

### Update Version

```bash
# For bug fixes (1.0.0 → 1.0.1)
npm version patch

# For new features (1.0.0 → 1.1.0)
npm version minor

# For breaking changes (1.0.0 → 2.0.0)
npm version major
```

This automatically:

- Updates `package.json`
- Creates a git tag
- Commits the change

### Push Updates

```bash
# Push code and tags
git push && git push --tags

# Publish to NPM
npm publish
```

---

## 🎯 Quick Command Reference

### Initial Setup & Push

```bash
# 1. Initialize and commit
git init
git add .
git commit -m "Initial commit: react-native-call-keeper v1.0.0"

# 2. Connect to GitHub
git remote add origin https://github.com/YOUR_USERNAME/react-native-call-keeper.git
git branch -M main
git push -u origin main

# 3. Publish to NPM
npm login
npm publish
```

### Future Updates

```bash
# Make your changes, then:
git add .
git commit -m "Description of changes"
npm version patch  # or minor/major
git push && git push --tags
npm publish
```

---

## 📋 Pre-Push Checklist

Before pushing, ensure:

- [ ] `package.json` has correct repository URL
- [ ] `package.json` has correct author info
- [ ] All code is committed
- [ ] Tests pass (`npm run typecheck`)
- [ ] Build works (`npm run prepare`)
- [ ] Documentation is up to date
- [ ] `.gitignore` is properly configured

---

## 🔐 NPM Publishing Tips

### 1. Check .npmignore

Files to exclude from NPM package (automatically handled):

```
.git/
.github/
node_modules/
example/
*.log
.DS_Store
```

### 2. Set NPM Package Visibility

For public packages:

```bash
npm publish --access public
```

For private packages (requires paid NPM account):

```bash
npm publish
```

### 3. Use NPM Tags

For beta releases:

```bash
npm version 1.1.0-beta.0
npm publish --tag beta
```

Users can install with:

```bash
npm install react-native-call-keeper@beta
```

---

## 🚨 Common Issues & Solutions

### Issue: "Repository not found"

**Solution:** Make sure the GitHub repository exists and the URL is correct.

```bash
# Check remote URL
git remote -v

# Update if needed
git remote set-url origin https://github.com/YOUR_USERNAME/react-native-call-keeper.git
```

### Issue: "You do not have permission to publish"

**Solution:**

1. Check you're logged in: `npm whoami`
2. Login again: `npm login`
3. Check package name isn't taken: `npm view react-native-call-keeper`
4. If taken, choose a different name (e.g., `@yourname/react-native-call-keeper`)

### Issue: "Version already published"

**Solution:** Update version number:

```bash
npm version patch
npm publish
```

### Issue: Authentication required

**Solution:**

```bash
# For HTTPS
git config credential.helper store

# Or use SSH instead
git remote set-url origin git@github.com:YOUR_USERNAME/react-native-call-keeper.git
```

---

## 🎨 GitHub Best Practices

### Add Topics to Your Repo

On GitHub, add relevant topics:

- `react-native`
- `callkit`
- `voip`
- `android`
- `ios`
- `turbomodules`
- `expo`

### Add GitHub Badges to README

Add these to the top of your README.md:

```markdown
# react-native-call-keeper

[![npm version](https://badge.fury.io/js/react-native-call-keeper.svg)](https://www.npmjs.com/package/react-native-call-keeper)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Platform](https://img.shields.io/badge/platform-ios%20%7C%20android-lightgrey)](https://github.com/YOUR_USERNAME/react-native-call-keeper)
```

### Enable GitHub Actions

Your workflows are already set up! They'll automatically:

- Run tests on every push
- Publish to NPM on releases

To use auto-publish:

1. Get NPM token from [npmjs.com](https://www.npmjs.com/settings/YOUR_USERNAME/tokens)
2. Add as GitHub Secret: `Settings` → `Secrets` → `NPM_TOKEN`

---

## 📦 Package Naming Options

If `react-native-call-keeper` is taken, consider:

1. **Scoped package:**

   ```json
   {
     "name": "@yourname/react-native-call-keeper"
   }
   ```

2. **Alternative names:**
   - `rn-call-keeper`
   - `react-native-callkeeper-native`
   - `react-native-native-calls`
   - `@yourname/callkeeper`

---

## ✅ After Publishing

1. **Announce on Twitter/X:**

   ```
   🚀 Just published react-native-call-keeper!

   Native CallKit & ConnectionService integration for React Native
   ✅ New Architecture support
   ✅ Expo compatible
   ✅ Full TypeScript

   npm install react-native-call-keeper

   #ReactNative #iOS #Android
   ```

2. **Share on Reddit:**
   - r/reactnative
   - r/javascript

3. **Update your portfolio/website**

4. **Add to React Native Directory:**
   https://reactnative.directory/

---

## 🎉 You're Ready!

Your package is ready to be pushed to GitHub and published to NPM!

**Quick Start Commands:**

```bash
cd /Users/user/Desktop/allproject/react-native-call-keeper
git init
git add .
git commit -m "Initial commit"
# Create GitHub repo, then:
git remote add origin YOUR_REPO_URL
git push -u origin main
npm publish
```

Good luck! 🚀
