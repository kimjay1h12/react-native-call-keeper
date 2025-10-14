# Publishing Guide

This guide explains how to publish `react-native-call-keeper` to NPM.

## Prerequisites

1. NPM account with publishing rights
2. Git repository set up
3. All tests passing
4. Documentation up to date

## Pre-publish Checklist

- [ ] All code is committed
- [ ] Version number is updated in `package.json`
- [ ] `CHANGELOG.md` is updated
- [ ] Tests are passing (`npm test`)
- [ ] Linting is clean (`npm run lint`)
- [ ] TypeScript compiles (`npm run typecheck`)
- [ ] README is up to date
- [ ] Example app works on iOS
- [ ] Example app works on Android

## Publishing Steps

### 1. Update Version

Update the version in `package.json`:

```bash
# For patch release (bug fixes)
npm version patch

# For minor release (new features, backward compatible)
npm version minor

# For major release (breaking changes)
npm version major
```

This will:
- Update `package.json`
- Create a git tag
- Commit the changes

### 2. Update Changelog

Update `CHANGELOG.md` with:
- Version number and date
- All changes since last release
- Breaking changes (if any)
- New features
- Bug fixes

### 3. Build the Package

```bash
npm run prepare
```

This will:
- Clean previous builds
- Build TypeScript files
- Generate declaration files

### 4. Test the Build

```bash
# Check what will be published
npm pack --dry-run

# Or create an actual tarball to inspect
npm pack
```

### 5. Publish to NPM

```bash
# Login to NPM (first time only)
npm login

# Publish the package
npm publish
```

For beta/alpha releases:
```bash
npm publish --tag beta
npm publish --tag alpha
```

### 6. Create GitHub Release

1. Go to GitHub repository
2. Click "Releases" → "Create a new release"
3. Choose the version tag
4. Add release notes from CHANGELOG
5. Publish release

### 7. Verify Publication

```bash
# Check on NPM
npm view react-native-call-keeper

# Test installation in a new project
npx react-native init TestApp
cd TestApp
npm install react-native-call-keeper
```

## Version Strategy

Follow [Semantic Versioning](https://semver.org/):

- **MAJOR** (1.0.0 → 2.0.0): Breaking changes
- **MINOR** (1.0.0 → 1.1.0): New features, backward compatible
- **PATCH** (1.0.0 → 1.0.1): Bug fixes

## Automated Publishing

The package includes GitHub Actions workflows:

### CI Workflow (`.github/workflows/ci.yml`)
- Runs on every push/PR
- Lints code
- Type checks
- Builds package
- Tests on iOS and Android

### Publish Workflow (`.github/workflows/publish.yml`)
- Triggered on GitHub release
- Builds the package
- Publishes to NPM

To use automated publishing:

1. Add `NPM_TOKEN` to GitHub Secrets:
   - Get token from npmjs.com (Settings → Access Tokens)
   - Add to GitHub repo (Settings → Secrets → New repository secret)

2. Create a release on GitHub:
   - Tag version matches package.json
   - Workflow automatically publishes to NPM

## Beta/Pre-releases

For testing before stable release:

```bash
# Update version with beta tag
npm version 1.1.0-beta.0

# Publish with beta tag
npm publish --tag beta

# Users install with:
npm install react-native-call-keeper@beta
```

## Post-publish

After publishing:

1. **Announce the release**
   - Post on Twitter/X
   - Update documentation site
   - Notify users in Discord/Slack

2. **Monitor for issues**
   - Watch GitHub issues
   - Check NPM download stats
   - Respond to questions

3. **Update dependent projects**
   - Update your own apps
   - Test in production
   - Document any migration steps

## Unpublishing

⚠️ **WARNING**: Unpublishing is permanent and should be avoided!

Only unpublish within 72 hours of publishing:

```bash
npm unpublish react-native-call-keeper@1.0.0
```

Instead, consider:
- Publishing a fixed version
- Using `npm deprecate` for bad versions

```bash
npm deprecate react-native-call-keeper@1.0.0 "Critical bug, use 1.0.1 instead"
```

## Troubleshooting

### "You do not have permission to publish"

Solution: Make sure you're logged in and have access rights:
```bash
npm login
npm whoami
```

### "Version already exists"

Solution: Increment version number:
```bash
npm version patch
```

### "Missing required fields"

Solution: Check `package.json` has all required fields:
- name
- version
- description
- main
- types
- files
- repository
- keywords
- author
- license

### Build errors

Solution: Clean and rebuild:
```bash
npm run clean
npm run prepare
```

## Best Practices

1. **Test thoroughly** before publishing
2. **Update documentation** with every release
3. **Follow semantic versioning** strictly
4. **Write detailed changelog** entries
5. **Tag releases** in git
6. **Keep dependencies updated**
7. **Respond to issues** quickly
8. **Monitor package health** (npm stats, GitHub stars)

## Support

If you encounter issues during publishing:
- Check NPM status: https://status.npmjs.org/
- Review NPM docs: https://docs.npmjs.com/
- Contact NPM support: https://www.npmjs.com/support

## Release Checklist Template

```markdown
## Release vX.Y.Z

- [ ] Code complete and reviewed
- [ ] Tests passing (iOS & Android)
- [ ] Version updated in package.json
- [ ] CHANGELOG.md updated
- [ ] README.md reviewed
- [ ] Example app tested
- [ ] Built successfully (`npm run prepare`)
- [ ] Dry run checked (`npm pack --dry-run`)
- [ ] Published to NPM (`npm publish`)
- [ ] Git tagged (`git tag vX.Y.Z`)
- [ ] GitHub release created
- [ ] Announcement posted
- [ ] Documentation updated
```

## Maintenance

Regular maintenance tasks:

- **Weekly**: Monitor issues and PRs
- **Monthly**: Update dependencies
- **Quarterly**: Review and update documentation
- **Yearly**: Major version planning

## Next Steps

After successful publication:
1. Update this guide if needed
2. Document any issues encountered
3. Share learnings with team
4. Plan next release

