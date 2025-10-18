#!/bin/bash
# Script to add review comments to PR #19 using GitHub API and curl
# Requires: GITHUB_TOKEN environment variable to be set

set -e  # Exit on error

# Configuration
REPO_OWNER="zorgch"
REPO_NAME="zorg-docker"
PR_NUMBER=19

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if GITHUB_TOKEN is set
if [ -z "$GITHUB_TOKEN" ]; then
    echo -e "${RED}Error: GITHUB_TOKEN environment variable not set${NC}"
    echo "Please set it with: export GITHUB_TOKEN=your_token_here"
    echo "Get a token from: https://github.com/settings/tokens"
    exit 1
fi

echo -e "${GREEN}Adding review comments to PR #${PR_NUMBER} in ${REPO_OWNER}/${REPO_NAME}${NC}"

# Get the latest commit SHA from the PR
echo "Fetching PR details..."
PR_RESPONSE=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
    -H "Accept: application/vnd.github.v3+json" \
    "https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}/pulls/${PR_NUMBER}")

COMMIT_SHA=$(echo "$PR_RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin)['head']['sha'])")
echo -e "${GREEN}Latest commit: ${COMMIT_SHA}${NC}"

# Create the review with all comments
echo "Creating review with comments..."

# Read the JSON file with all comments
REVIEW_DATA=$(cat <<'EOF'
{
  "commit_id": "COMMIT_SHA_PLACEHOLDER",
  "body": "Security and configuration review for OWASP Coraza WAF configuration",
  "event": "COMMENT",
  "comments": [
    {
      "path": "resources/reverseproxy/owasp-coraza-waf.yaml",
      "line": 36,
      "side": "RIGHT",
      "body": "**Suggestion: Add audit logging configuration**\n\n```yaml\n            # Audit Logging Configuration\n            - SecAuditEngine RelevantOnly\n            - SecAuditLogRelevantStatus \"^(?:(5|4)(0|1)[0-9])$\"\n            - SecAuditLogParts ABIJDEFHZ\n            - SecAuditLogType Serial\n            - SecAuditLogFormat Native\n```\n\n**Explanation:** This enables comprehensive audit logging for security events matching 4xx and 5xx responses (excluding 404s). The audit log helps with security monitoring, incident response, and compliance requirements."
    },
    {
      "path": "resources/reverseproxy/owasp-coraza-waf.yaml",
      "line": 37,
      "side": "RIGHT",
      "body": "**Suggestion: Add request body handling directives**\n\n```yaml\n            # Request Body Handling\n            - SecRequestBodyLimit 13107200\n            - SecRequestBodyInMemoryLimit 131072\n            - SecRequestBodyLimitAction Reject\n```\n\n**Explanation:** These directives properly configure request body size limits (12.5 MB max, 128 KB in-memory buffer). Without these, the WAF may not handle large file uploads correctly or could be vulnerable to denial-of-service attacks via oversized requests."
    },
    {
      "path": "resources/reverseproxy/owasp-coraza-waf.yaml",
      "line": 38,
      "side": "RIGHT",
      "body": "**Suggestion: Change to On and add proper configuration**\n\n```yaml\n            # Response Body Handling (enable for data leakage detection)\n            - SecResponseBodyAccess On\n            - SecResponseBodyMimeType text/plain text/html text/xml\n            - SecResponseBodyLimit 524288\n            - SecResponseBodyLimitAction ProcessPartial\n```\n\n**Explanation:** Enabling response body inspection helps detect data leakage issues and errors. The recommended limit is 512 KB. Consider the performance trade-off - you can keep it Off if response inspection isn't needed for your use case."
    },
    {
      "path": "resources/reverseproxy/owasp-coraza-waf.yaml",
      "line": 42,
      "side": "RIGHT",
      "body": "**Suggestion: Add request body parser rules before the security rules**\n\n```yaml\n            # Request Body Parsers\n            - SecRule REQUEST_HEADERS:Content-Type \"^(?:application(?:/soap\\\\+|/)|text/)xml\" \"id:200000,phase:1,t:none,t:lowercase,pass,nolog,ctl:requestBodyProcessor=XML\"\n            - SecRule REQUEST_HEADERS:Content-Type \"^application/json\" \"id:200001,phase:1,t:none,t:lowercase,pass,nolog,ctl:requestBodyProcessor=JSON\"\n            - SecRule REQUEST_HEADERS:Content-Type \"^application/[a-z0-9.-]+[+]json\" \"id:200006,phase:1,t:none,t:lowercase,pass,nolog,ctl:requestBodyProcessor=JSON\"\n            \n            # Request Body Error Handling\n            - SecRule REQBODY_ERROR \"!@eq 0\" \"id:200002,phase:2,t:none,log,deny,status:400,msg:'Failed to parse request body.',logdata:'%{reqbody_error_msg}',severity:2\"\n            - SecRule MULTIPART_STRICT_ERROR \"!@eq 0\" \"id:200003,phase:2,t:none,log,deny,status:400,msg:'Multipart request body failed strict validation.'\"\n```\n\n**Explanation:** These rules enable proper parsing of XML and JSON request bodies, which is critical for API security. The error handling rules reject malformed requests that could be attack attempts or evasion techniques."
    },
    {
      "path": "resources/reverseproxy/owasp-coraza-waf.yaml",
      "line": 35,
      "side": "RIGHT",
      "body": "**Suggestion: Add data directory configuration at the beginning of the directives section**\n\n```yaml\n            # Persistent Data Storage\n            - SecDataDir /tmp/\n```\n\n**Explanation:** Coraza needs a location to store persistent data. While /tmp is the default, you may want to use a dedicated volume-mounted directory for better security and data persistence."
    },
    {
      "path": "resources/reverseproxy/owasp-coraza-waf.yaml",
      "line": 49,
      "side": "RIGHT",
      "body": "**Suggestion: Make the whitelist rule more specific**\n\n```yaml\n            # Whitelist Rules (adjust regex to match your actual static asset paths)\n            - SecRule REQUEST_URI \"@rx ^/(assets|static|images|css|js)/.*\\\\.(css|js|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$\" \"id:104,phase:1,pass,nolog,msg:'Allow static assets'\"\n```\n\n**Explanation:** The current regex allows these file types anywhere in the URL path, which might be too permissive. Consider restricting to specific directories where static assets are actually served from."
    },
    {
      "path": "resources/reverseproxy/owasp-coraza-waf.yaml",
      "line": 50,
      "side": "RIGHT",
      "body": "**WARNING: Security implications of disabling body inspection for POST**\n\nAdd a warning comment above this line:\n\n```yaml\n            # WARNING: Disabling requestBodyAccess for POST requests significantly reduces security\n            # This prevents inspection of POST data, which is a common attack vector\n            # Consider using more specific exclusions instead of blanket POST exemption\n```\n\n**Explanation:** The current rule `SecRule REQUEST_METHOD \"@streq POST\" \"id:900140,phase:1,pass,nolog,ctl:requestBodyAccess=Off\"` disables all POST body inspection, which defeats much of the WAF's purpose. This should be reconsidered or replaced with more targeted exclusions for specific endpoints."
    }
  ]
}
EOF
)

# Replace the placeholder with actual commit SHA
REVIEW_DATA="${REVIEW_DATA//COMMIT_SHA_PLACEHOLDER/$COMMIT_SHA}"

# Post the review
RESPONSE=$(curl -s -w "\n%{http_code}" \
    -X POST \
    -H "Authorization: token $GITHUB_TOKEN" \
    -H "Accept: application/vnd.github.v3+json" \
    -d "$REVIEW_DATA" \
    "https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}/pulls/${PR_NUMBER}/reviews")

# Extract HTTP status code (last line)
HTTP_STATUS=$(echo "$RESPONSE" | tail -n1)
# Extract response body (everything except last line)
RESPONSE_BODY=$(echo "$RESPONSE" | sed '$d')

if [ "$HTTP_STATUS" -eq 200 ]; then
    REVIEW_ID=$(echo "$RESPONSE_BODY" | python3 -c "import sys, json; print(json.load(sys.stdin)['id'])")
    REVIEW_URL=$(echo "$RESPONSE_BODY" | python3 -c "import sys, json; print(json.load(sys.stdin)['html_url'])")
    
    echo -e "${GREEN}✓ Review comments added successfully!${NC}"
    echo "Review ID: $REVIEW_ID"
    echo "Review URL: $REVIEW_URL"
    echo ""
    echo -e "${GREEN}All 7 review comments have been added to PR #${PR_NUMBER}${NC}"
else
    echo -e "${RED}Error creating review: HTTP $HTTP_STATUS${NC}"
    echo "Response: $RESPONSE_BODY"
    exit 1
fi
