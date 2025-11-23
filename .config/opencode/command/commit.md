---
description: Generate commit message for git repo
agent: build
---

Begin with a concise checklist (3–7 bullets) summarizing your main analysis and output steps as a Markdown-style bulleted list (each line starts with '-').

Analyze the results from the staged changes:
!git diff --staged

Generate a conventional commit message by examining the git diff output, strictly following conventional commit guidelines.

After generating the commit message, validate that all format, content, and rule constraints have been met. If validation fails, self-correct as needed before output.

# Instructions
- If no changes are present, output:
  ```
  No changes detected. Cannot generate a commit message.
  ```
  and exit.
- If the diff output is ambiguous, unreadable, malformed, or cannot be parsed, output:
  ```
  Error: Unable to analyze diff. Diff is ambiguous or malformed.
  ```
  and exit.
- For any other error, output:
  ```
  Error: <error details>
  ```
  and exit.
- If valid changes exist, continue as instructed below.

## Commit Type Priority
- If multiple commit types are detected in the diff, use the highest priority type:
  `feat > fix > perf > refactor > test > docs > style > chore`

# Commit Message Format
- Commit messages must follow this template (always include a description section, even if empty):
  ```
  Commit message:
  
  <type>: <commit message>
  
  - <optional description bullet 1>
  - <optional description bullet point 2>
  - <optional description bullet points so on and so forth>
  ```
- If there are no description bullets, insert a blank line after the subject, leaving the description section empty (do not add comments or extra characters).

## Commit Types
- `feat`: New feature
- `fix`: Bug fix
- `refactor`: Code refactoring
- `docs`: Documentation
- `chore`: Maintenance (dependencies, config)
- `style`: Formatting
- `test`: Tests
- `perf`: Performance

## Commit Message Rules
1. Use lowercase for both type and subject.
2. Subject line must not exceed 50 characters.
3. Use the imperative mood (e.g., "add", not "added").
4. Omit a period at the end of the subject.
5. Ensure the subject is clear and specific.

## Commit Description Rules
1. Type and description should be lowercase.
2. Format description as a bulleted list ('-' at line start).
3. Each bullet point must not exceed 72 characters.
4. Use the imperative mood.
5. Start with component or intent for clarity when helpful (e.g., 'api: add pagination').
   (If a scope is used, include it in the 50-character subject limit.)
6. Describe what changed and why; avoid discussing how.
7. Do not mention file names, stack traces, or snippets.
8. Exclude issue numbers, PR IDs, or timestamps.
9. Use plain ASCII; do not use emojis or markup.
10. Write in present tense and active voice.
11. Keep each bullet concise and ensure clarity for changelogs.

## Output Conditions
- **If changes are detected:**
  ```
  Commit message:
  
  <type>: <commit message>
  
  - <optional description bullet 1>
  - <optional description bullet point 2>
  - <optional description bullet points so on and so forth>
  ```
- **If no changes are detected:**
  ```
  No changes detected. Cannot generate a commit message.
  ```
- **If the diff is ambiguous, unreadable, or malformed:**
  ```
  Error: Unable to analyze diff. Diff is ambiguous or malformed.
  ```
- **If another error occurs:**
  ```
  Error: <error details>
  ```

After producing any valid commit message, output the result according to the format specified above and commit the changes.
