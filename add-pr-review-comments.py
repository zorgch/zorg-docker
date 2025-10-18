#!/usr/bin/env python3
"""
Script to add review comments to PR #19 on the owasp-coraza-waf.yaml file.
This script uses the GitHub API to post inline review comments on specific lines.
"""

import json
import os
import sys
import requests

# Configuration
REPO_OWNER = "zorgch"
REPO_NAME = "zorg-docker"
PR_NUMBER = 19

# Review comments data
REVIEW_COMMENTS = [
    {
        "path": "resources/reverseproxy/owasp-coraza-waf.yaml",
        "line": 36,
        "side": "RIGHT",
        "body": """**Suggestion: Add audit logging configuration**

```yaml
            # Audit Logging Configuration
            - SecAuditEngine RelevantOnly
            - SecAuditLogRelevantStatus "^(?:(5|4)(0|1)[0-9])$"
            - SecAuditLogParts ABIJDEFHZ
            - SecAuditLogType Serial
            - SecAuditLogFormat Native
```

**Explanation:** This enables comprehensive audit logging for security events matching 4xx and 5xx responses (excluding 404s). The audit log helps with security monitoring, incident response, and compliance requirements."""
    },
    {
        "path": "resources/reverseproxy/owasp-coraza-waf.yaml",
        "line": 37,
        "side": "RIGHT",
        "body": """**Suggestion: Add request body handling directives**

```yaml
            # Request Body Handling
            - SecRequestBodyLimit 13107200
            - SecRequestBodyInMemoryLimit 131072
            - SecRequestBodyLimitAction Reject
```

**Explanation:** These directives properly configure request body size limits (12.5 MB max, 128 KB in-memory buffer). Without these, the WAF may not handle large file uploads correctly or could be vulnerable to denial-of-service attacks via oversized requests."""
    },
    {
        "path": "resources/reverseproxy/owasp-coraza-waf.yaml",
        "line": 38,
        "side": "RIGHT",
        "body": """**Suggestion: Change to On and add proper configuration**

```yaml
            # Response Body Handling (enable for data leakage detection)
            - SecResponseBodyAccess On
            - SecResponseBodyMimeType text/plain text/html text/xml
            - SecResponseBodyLimit 524288
            - SecResponseBodyLimitAction ProcessPartial
```

**Explanation:** Enabling response body inspection helps detect data leakage issues and errors. The recommended limit is 512 KB. Consider the performance trade-off - you can keep it Off if response inspection isn't needed for your use case."""
    },
    {
        "path": "resources/reverseproxy/owasp-coraza-waf.yaml",
        "line": 42,
        "side": "RIGHT",
        "body": """**Suggestion: Add request body parser rules before the security rules**

```yaml
            # Request Body Parsers
            - SecRule REQUEST_HEADERS:Content-Type "^(?:application(?:/soap\\+|/)|text/)xml" "id:200000,phase:1,t:none,t:lowercase,pass,nolog,ctl:requestBodyProcessor=XML"
            - SecRule REQUEST_HEADERS:Content-Type "^application/json" "id:200001,phase:1,t:none,t:lowercase,pass,nolog,ctl:requestBodyProcessor=JSON"
            - SecRule REQUEST_HEADERS:Content-Type "^application/[a-z0-9.-]+[+]json" "id:200006,phase:1,t:none,t:lowercase,pass,nolog,ctl:requestBodyProcessor=JSON"
            
            # Request Body Error Handling
            - SecRule REQBODY_ERROR "!@eq 0" "id:200002,phase:2,t:none,log,deny,status:400,msg:'Failed to parse request body.',logdata:'%{reqbody_error_msg}',severity:2"
            - SecRule MULTIPART_STRICT_ERROR "!@eq 0" "id:200003,phase:2,t:none,log,deny,status:400,msg:'Multipart request body failed strict validation.'"
```

**Explanation:** These rules enable proper parsing of XML and JSON request bodies, which is critical for API security. The error handling rules reject malformed requests that could be attack attempts or evasion techniques."""
    },
    {
        "path": "resources/reverseproxy/owasp-coraza-waf.yaml",
        "line": 35,
        "side": "RIGHT",
        "body": """**Suggestion: Add data directory configuration at the beginning of the directives section**

```yaml
            # Persistent Data Storage
            - SecDataDir /tmp/
```

**Explanation:** Coraza needs a location to store persistent data. While /tmp is the default, you may want to use a dedicated volume-mounted directory for better security and data persistence."""
    },
    {
        "path": "resources/reverseproxy/owasp-coraza-waf.yaml",
        "line": 49,
        "side": "RIGHT",
        "body": """**Suggestion: Make the whitelist rule more specific**

```yaml
            # Whitelist Rules (adjust regex to match your actual static asset paths)
            - SecRule REQUEST_URI "@rx ^/(assets|static|images|css|js)/.*\\.(css|js|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$" "id:104,phase:1,pass,nolog,msg:'Allow static assets'"
```

**Explanation:** The current regex allows these file types anywhere in the URL path, which might be too permissive. Consider restricting to specific directories where static assets are actually served from."""
    },
    {
        "path": "resources/reverseproxy/owasp-coraza-waf.yaml",
        "line": 50,
        "side": "RIGHT",
        "body": """**WARNING: Security implications of disabling body inspection for POST**

Add a warning comment above this line:

```yaml
            # WARNING: Disabling requestBodyAccess for POST requests significantly reduces security
            # This prevents inspection of POST data, which is a common attack vector
            # Consider using more specific exclusions instead of blanket POST exemption
```

**Explanation:** The current rule `SecRule REQUEST_METHOD "@streq POST" "id:900140,phase:1,pass,nolog,ctl:requestBodyAccess=Off"` disables all POST body inspection, which defeats much of the WAF's purpose. This should be reconsidered or replaced with more targeted exclusions for specific endpoints."""
    }
]


def get_github_token():
    """Get GitHub token from environment variable."""
    token = os.environ.get('GITHUB_TOKEN')
    if not token:
        print("Error: GITHUB_TOKEN environment variable not set", file=sys.stderr)
        print("Please set it with: export GITHUB_TOKEN=your_token_here", file=sys.stderr)
        sys.exit(1)
    return token


def get_pr_latest_commit(token):
    """Get the latest commit SHA from the PR."""
    url = f"https://api.github.com/repos/{REPO_OWNER}/{REPO_NAME}/pulls/{PR_NUMBER}"
    headers = {
        "Authorization": f"token {token}",
        "Accept": "application/vnd.github.v3+json"
    }
    
    response = requests.get(url, headers=headers)
    response.raise_for_status()
    
    pr_data = response.json()
    return pr_data['head']['sha']


def create_review_with_comments(token, commit_sha):
    """Create a review with all the comments."""
    url = f"https://api.github.com/repos/{REPO_OWNER}/{REPO_NAME}/pulls/{PR_NUMBER}/reviews"
    headers = {
        "Authorization": f"token {token}",
        "Accept": "application/vnd.github.v3+json"
    }
    
    # Prepare the review data
    review_data = {
        "commit_id": commit_sha,
        "body": "Security and configuration review for OWASP Coraza WAF configuration",
        "event": "COMMENT",  # Can be APPROVE, REQUEST_CHANGES, or COMMENT
        "comments": REVIEW_COMMENTS
    }
    
    response = requests.post(url, headers=headers, json=review_data)
    
    if response.status_code == 200:
        print("✓ Review comments added successfully!")
        return response.json()
    else:
        print(f"Error creating review: {response.status_code}", file=sys.stderr)
        print(f"Response: {response.text}", file=sys.stderr)
        sys.exit(1)


def main():
    """Main function to add review comments to PR."""
    print(f"Adding review comments to PR #{PR_NUMBER} in {REPO_OWNER}/{REPO_NAME}")
    print(f"File: resources/reverseproxy/owasp-coraza-waf.yaml")
    print(f"Number of comments: {len(REVIEW_COMMENTS)}\n")
    
    # Get GitHub token
    token = get_github_token()
    
    # Get the latest commit SHA
    print("Fetching PR details...")
    commit_sha = get_pr_latest_commit(token)
    print(f"Latest commit: {commit_sha}\n")
    
    # Create the review with comments
    print("Creating review with comments...")
    review = create_review_with_comments(token, commit_sha)
    
    print(f"\nReview ID: {review.get('id')}")
    print(f"Review URL: {review.get('html_url')}")
    print("\nAll review comments have been added successfully!")


if __name__ == "__main__":
    main()
