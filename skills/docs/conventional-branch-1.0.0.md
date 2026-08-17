# Conventional Branch 1.0.0

## Summary

Conventional Branch refers to a structured and standardized naming convention for Git branches which aims to make branch more readable and actionable. We’ve suggested some branch prefixes you might want to use but you can also specify your own naming convention. A consistent naming convention makes it easier to identify branches by type.

### Key Points

1. **Purpose-driven Branch Names**: Each branch name clearly indicates its purpose, making it easy for all developers to understand what the branch is for.
2. **Integration with CI/CD**: By using consistent branch names, it can help automated systems (like Continuous Integration/Continuous Deployment pipelines) to trigger specific actions based on the branch type (e.g., auto-deployment from release branches).
3. **Team Collaboration**: It encourages collaboration within teams by making branch purpose explicit, reducing misunderstandings, and making it easier for team members to switch between tasks without confusion.

## Specification

### Branch Naming Prefixes

The branch specification supports the following prefixes and should be structured as:

> [!INFO] \<type>/\<description>

- **`master`**: The main development branch
- **`feat/`**: For new features (e.g., `feat/add-login-page`)
- **`fix/`** : For bug fixes (e.g., `fix/fix-header-bug`)
- **`hotfix/`**: For urgent fixes (e.g., `hotfix/security-patch`)
- **`release/`**: For branches preparing a release (e.g., `release/v1.2.0`)
- **`chore/`**: For non-code tasks like dependency, docs updates (e.g., `chore/update-dependencies`)

---

### Basic Rules

1. **Use Lowercase Alphanumerics, Hyphens, and Dots**: Always use lowercase letters (`a-z`), numbers (`0-9`), and hyphens (`-`) to separate words. Avoid special characters, underscores, or spaces. For release branches, dots (`.`) may be used in the description to represent version numbers (e.g., `release/v1.2.0`).
2. **No Consecutive, Leading, or Trailing Hyphens or Dots**: Ensure that hyphens and dots do not appear consecutively (e.g., `feat/new--login`, `release/v1.-2.0`), nor at the start or end of the description (e.g., `feat/-new-login`, `release/v1.2.0.`).
3. **Keep It Clear and Concise**: The branch name should be descriptive yet concise, clearly indicating the purpose of the work.
4. **Include Ticket Numbers**: If applicable, include the ticket number from your project management tool to make tracking easier. For example, for a ticket `issue-123`, the branch name could be `feat/issue-123-new-login`.

## Conclusion

- **Clear Communication**: The branch name alone provides a clear understanding of its purpose the code change.
- **Automation-Friendly**: Easily hooks into automation processes (e.g., different workflows for `feat`, `release`, etc.).
- **Scalability**: Works well in large teams where many developers are working on different tasks simultaneously.

In summary, conventional branch is designed to improve project organization, communication, and automation within Git workflows.

## Related Specifications

- [Conventional Commits 1.0.0](conventional-commits-1.0.0.md) - Commit message convention with aligned type prefixes (`feat:`, `fix:`, `chore:`)
- [Semantic Versioning 2.0.0](semantic-versioning-2.0.0.md) - Version numbering used in `release/` branches (e.g., `release/v1.2.0`)
- [Keep a Changelog 1.1.0](keep-a-changelog-1.1.0.md) - Changelog format that complements the branch-based workflow