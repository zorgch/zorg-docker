# Adding Review Comments to PR #19

This directory contains a script to add code review comments to Pull Request #19 for the `owasp-coraza-waf.yaml` file.

## Overview

The script `add-pr-review-comments.py` will add 7 review comments to specific lines in the file `resources/reverseproxy/owasp-coraza-waf.yaml` as part of PR #19.

## Review Comments Summary

The script adds the following review comments:

1. **Line 36** - Suggestion to add audit logging configuration after `SecRuleEngine On`
2. **Line 37** - Suggestion to add request body handling directives after `SecRequestBodyAccess On`
3. **Line 38** - Suggestion to change `SecResponseBodyAccess` to `On` and add proper configuration
4. **Line 42** - Suggestion to add request body parser rules before the security rules
5. **Line 35** - Suggestion to add data directory configuration at the beginning of directives
6. **Line 49** - Review of the whitelist rule to make it more specific
7. **Line 50** - Warning about security implications of disabling body inspection for POST requests

## Prerequisites

- Python 3.6 or higher
- `requests` library: `pip install requests`
- A GitHub Personal Access Token with `repo` scope

## Usage

### 1. Install dependencies

```bash
pip install requests
```

### 2. Set up GitHub token

Create a GitHub Personal Access Token with `repo` scope at:
https://github.com/settings/tokens

Then export it as an environment variable:

```bash
export GITHUB_TOKEN=your_github_token_here
```

### 3. Run the script

```bash
python3 add-pr-review-comments.py
```

## What the Script Does

The script:
1. Connects to the GitHub API
2. Fetches the latest commit SHA from PR #19
3. Creates a review with all 7 inline comments on specific lines
4. Posts the review to the PR

## Review Comment Details

### Comment 1: Audit Logging (Line 36)
Adds comprehensive audit logging configuration for security events.

### Comment 2: Request Body Handling (Line 37)
Configures proper request body size limits (12.5 MB max, 128 KB in-memory buffer).

### Comment 3: Response Body Handling (Line 38)
Suggests enabling response body inspection for data leakage detection.

### Comment 4: Request Body Parsers (Line 42)
Adds rules for proper XML and JSON parsing, critical for API security.

### Comment 5: Data Directory (Line 35)
Configures persistent data storage location for Coraza.

### Comment 6: Whitelist Specificity (Line 49)
Suggests making the static asset whitelist more restrictive.

### Comment 7: POST Security Warning (Line 50)
Warns about security implications of disabling POST body inspection.

## Alternative: Manual Review

If you prefer to add these comments manually through the GitHub web interface:

1. Go to https://github.com/zorgch/zorg-docker/pull/19/files
2. Click on the line number you want to comment on
3. Click the blue "+" icon that appears
4. Paste the comment text from the script
5. Click "Start a review" or "Add review comment"

## Troubleshooting

### "GITHUB_TOKEN environment variable not set"
Make sure you've exported your GitHub token as shown above.

### "401 Unauthorized"
Your GitHub token may be invalid or expired. Generate a new one.

### "403 Forbidden"
Your GitHub token doesn't have the necessary `repo` scope. Create a new token with the correct permissions.

### "404 Not Found"
Make sure PR #19 exists and you have access to the repository.

## License

This script is part of the zorg-docker project and follows the same GPL-3.0 license.
