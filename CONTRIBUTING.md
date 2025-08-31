# Contributing to Typewriter

Thank you for your interest in contributing to Typewriter! This document provides guidelines for different types of contributions to help you get started.

## 🚀 Quick Start

Before contributing, please:

1. **Join our Discord**: [https://discord.gg/HtbKyuDDBw](https://discord.gg/HtbKyuDDBw)
2. **Read our Code of Conduct**: [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md)
3. **Check existing issues**: Browse [GitHub Issues](https://github.com/gabber235/Typewriter/issues) to see what needs work

## 📋 Types of Contributions

Typewriter has three main areas where you can contribute, each with different processes:

---

## 📚 Documentation

**✅ Pull Requests Welcome!**

We always appreciate improvements to our documentation. Changes to documentation should almost always be submitted as a Pull Request.

### What You Can Contribute

- Fix typos, grammar, or formatting issues
- Improve existing documentation clarity
- Add missing documentation for features
- Create tutorials or guides
- Update outdated information

### Getting Started with Documentation

The documentation is built with Docusaurus and lives in the `documentation/` folder.

#### Setup
```bash
cd documentation/
npm ci
```

#### Making Changes
1. Edit files in `docs/docs/` (user documentation) or `docs/develop/` (developer guides)
2. Use Markdown/MDX format
3. Keep lines under 120 characters
4. Place images in the appropriate `assets/` folder

#### Testing Your Changes
```bash
npm run test
```

#### Code Snippets
- All code examples should live in `extensions/_DocsExtension`
- Never place code directly in docs files
- Use the `<CodeSnippet>` component to embed code from `snippets.json`

### Submitting Documentation PRs

1. **Fork** the repository
2. **Create a branch** with a descriptive name (e.g., `docs/fix-installation-guide`)
3. **Make your changes** following the guidelines above
4. **Test** that the documentation builds without errors
5. **Create a Pull Request** with:
   - Clear title describing what you changed
   - Description explaining why the change was needed
   - Any relevant screenshots if you modified UI documentation

---

## 🧩 Extensions

**✅ Pull Requests Welcome!**

Extensions are self-contained modules that add functionality to Typewriter. We encourage community contributions to extensions!

### What You Can Contribute

- Bug fixes in existing extensions
- New features for existing extensions
- Entirely new extensions
- Performance improvements
- Code refactoring

### Getting Started with Extensions

Extensions are Kotlin projects built with Gradle in the `extensions/` folder.

#### Prerequisites
- Java Development Kit (JDK) 21 or higher
- Basic understanding of Kotlin and Gradle
- Familiarity with the Spigot/Paper API

#### Setup
```bash
cd extensions/
./gradlew build
```

#### Creating a New Extension
1. Create a directory ending with `Extension` (e.g., `MyFeatureExtension`)
2. Set up `build.gradle.kts` using the `typewriter` plugin
3. Follow the structure of existing extensions

#### Code Style for Extensions
- Use 4 spaces for indentation
- Wrap lines at 120 characters
- Keep functions short and focused
- Use guard clauses over nested conditionals
- Document public APIs with KDoc
- Avoid inline comments - refactor unclear code instead

### Submitting Extension PRs

1. **Fork** the repository
2. **Create a branch** with a descriptive name (e.g., `extension/add-particle-effects`)
3. **Make your changes** following the code style guidelines
4. **Test your extension**:
   ```bash
   ./gradlew build
   ```
5. **Create a Pull Request** with:
   - Clear title and description of the new functionality
   - Examples of how to use the new features
   - Any breaking changes clearly noted

---

## ⚙️ Engine

**⚠️ Discord Discussion Required First!**

The engine is the core of Typewriter and changes here affect all users. **Engine contributions have a strict approval process.**

### 🚨 Important: Talk to Us First!

**Before working on any engine changes:**

1. **Join the Discord**: [https://discord.gg/HtbKyuDDBw](https://discord.gg/HtbKyuDDBw)
2. **Post in the appropriate channel** explaining your planned changes
3. **Schedule a voice chat with Gabber235** to discuss your proposal
4. **Wait for approval** before starting development

### Why This Process?

- Engine changes impact all Typewriter users
- We may already have different plans for the area you want to change
- Many engine change requests get rejected due to architectural concerns
- We want to ensure consistency with our long-term vision

### Types of Engine Changes (All Require Pre-Approval)

- Core functionality modifications
- API changes
- Performance optimizations
- Bug fixes in core systems
- New engine features

### Engine Development Setup

The engine consists of three modules in the `engine/` folder:

- `engine-core` – Platform-agnostic logic and API definitions
- `engine-loader` – Bootstraps the core and loads extensions  
- `engine-paper` – Paper-specific implementation and test harness

#### Building & Testing
```bash
cd engine/
../gradlew build
../gradlew check
```

#### Code Style for Engine
- Use 4 spaces for indentation
- Wrap lines at 120 characters
- Keep functions short and focused
- Prefer composition over inheritance
- Document public APIs with KDoc
- Avoid inline comments

### If Your Engine PR Gets Approved

After Discord approval:

1. **Create your branch** with a descriptive name
2. **Follow the established patterns** in the existing codebase
3. **Write tests** for your changes in `engine-paper/src/test`
4. **Ensure all tests pass**: `../gradlew check`
5. **Create a Pull Request** referencing the Discord discussion

---

## 🌐 Web Panel (App)

The Flutter-based web UI can also be contributed to, though this is more complex.

### Setup
```bash
cd app/
# On Linux:
../install_flutter_linux.sh
# Then in a new shell or after source ~/.bashrc:
flutter pub get
flutter build web
```

### Testing
```bash
flutter test
```

---

## 🔧 General Development Guidelines

### Branch Naming
Use descriptive branch names:
- `docs/fix-installation-typos`
- `extension/add-hologram-support`
- `engine/optimize-event-handling`
- `fix/web-panel-connection-issue`

### Commit Messages
- Keep subject line under 72 characters
- Use imperative mood ("Add feature" not "Added feature")
- Include more details in the body if needed

### Code Quality
- Ensure your code builds before submitting PRs
- Follow the code style for each component (see AGENTS.md files)
- Write tests when applicable
- Keep changes focused and atomic

### Getting Help

- **Discord**: [https://discord.gg/HtbKyuDDBw](https://discord.gg/HtbKyuDDBw) - For questions, discussions, and engine pre-approval
- **GitHub Issues**: For bug reports and feature requests
- **Documentation**: [https://docs.typewritermc.com/](https://docs.typewritermc.com/)

---

## 🎯 What Happens After You Submit?

### Documentation PRs
- Usually reviewed within a few days
- May require minor formatting or content adjustments
- Generally accepted if they improve clarity or fix issues

### Extension PRs  
- Reviewed for code quality and functionality
- May require changes to match coding standards
- Generally welcomed if they add value

### Engine PRs
- Only reviewed if pre-approved through Discord
- Thorough review for impact on all users
- May require significant changes or architectural discussions
- Higher chance of rejection without prior discussion

---

## 📄 License

By contributing to Typewriter, you agree that your contributions will be licensed under the same license as the project. See [LICENSE](LICENSE) for details.

---

## 🙏 Thank You!

Every contribution, no matter how small, helps make Typewriter better for everyone. We appreciate your time and effort!

**Remember**: When in doubt, ask questions in our Discord. We're here to help! 🚀