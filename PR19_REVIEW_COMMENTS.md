# PR #19 Review Comments for owasp-coraza-waf.yaml

This document contains all the review comments that should be added to PR #19 on the file `resources/reverseproxy/owasp-coraza-waf.yaml`.

## How to Use This Document

You can either:
1. Use the `add-pr-review-comments.py` script to automatically add all comments
2. Manually add each comment by copying the content below and pasting it on the corresponding line in the GitHub PR review interface

To manually add a comment:
1. Go to https://github.com/zorgch/zorg-docker/pull/19/files
2. Find the file `resources/reverseproxy/owasp-coraza-waf.yaml`
3. Click on the line number indicated below
4. Click the blue "+" icon
5. Copy and paste the comment text
6. Click "Add review comment" or "Start a review"

---

## Comment 1: Line 35 (Add at beginning of directives)

**Location:** Line 35 (at the beginning of the `directives:` section, before other directives)

**Comment:**

**Suggestion: Add data directory configuration at the beginning of the directives section**

```yaml
            # Persistent Data Storage
            - SecDataDir /tmp/
```

**Explanation:** Coraza needs a location to store persistent data. While /tmp is the default, you may want to use a dedicated volume-mounted directory for better security and data persistence.

---

## Comment 2: Line 36 (After "SecRuleEngine On")

**Location:** Line 36 (after `- SecRuleEngine On`)

**Comment:**

**Suggestion: Add audit logging configuration**

```yaml
            # Audit Logging Configuration
            - SecAuditEngine RelevantOnly
            - SecAuditLogRelevantStatus "^(?:(5|4)(0|1)[0-9])$"
            - SecAuditLogParts ABIJDEFHZ
            - SecAuditLogType Serial
            - SecAuditLogFormat Native
```

**Explanation:** This enables comprehensive audit logging for security events matching 4xx and 5xx responses (excluding 404s). The audit log helps with security monitoring, incident response, and compliance requirements.

---

## Comment 3: Line 37 (After "SecRequestBodyAccess On")

**Location:** Line 37 (after `- SecRequestBodyAccess On`)

**Comment:**

**Suggestion: Add request body handling directives**

```yaml
            # Request Body Handling
            - SecRequestBodyLimit 13107200
            - SecRequestBodyInMemoryLimit 131072
            - SecRequestBodyLimitAction Reject
```

**Explanation:** These directives properly configure request body size limits (12.5 MB max, 128 KB in-memory buffer). Without these, the WAF may not handle large file uploads correctly or could be vulnerable to denial-of-service attacks via oversized requests.

---

## Comment 4: Line 38 (On "SecResponseBodyAccess Off")

**Location:** Line 38 (on the line with `- SecResponseBodyAccess Off`)

**Comment:**

**Suggestion: Change to On and add proper configuration**

```yaml
            # Response Body Handling (enable for data leakage detection)
            - SecResponseBodyAccess On
            - SecResponseBodyMimeType text/plain text/html text/xml
            - SecResponseBodyLimit 524288
            - SecResponseBodyLimitAction ProcessPartial
```

**Explanation:** Enabling response body inspection helps detect data leakage issues and errors. The recommended limit is 512 KB. Consider the performance trade-off - you can keep it Off if response inspection isn't needed for your use case.

---

## Comment 5: Line 42 (Before Security Rules section)

**Location:** Line 42 (before the `# Security Rules` comment)

**Comment:**

**Suggestion: Add request body parser rules before the security rules**

```yaml
            # Request Body Parsers
            - SecRule REQUEST_HEADERS:Content-Type "^(?:application(?:/soap\\+|/)|text/)xml" "id:200000,phase:1,t:none,t:lowercase,pass,nolog,ctl:requestBodyProcessor=XML"
            - SecRule REQUEST_HEADERS:Content-Type "^application/json" "id:200001,phase:1,t:none,t:lowercase,pass,nolog,ctl:requestBodyProcessor=JSON"
            - SecRule REQUEST_HEADERS:Content-Type "^application/[a-z0-9.-]+[+]json" "id:200006,phase:1,t:none,t:lowercase,pass,nolog,ctl:requestBodyProcessor=JSON"
            
            # Request Body Error Handling
            - SecRule REQBODY_ERROR "!@eq 0" "id:200002,phase:2,t:none,log,deny,status:400,msg:'Failed to parse request body.',logdata:'%{reqbody_error_msg}',severity:2"
            - SecRule MULTIPART_STRICT_ERROR "!@eq 0" "id:200003,phase:2,t:none,log,deny,status:400,msg:'Multipart request body failed strict validation.'"
```

**Explanation:** These rules enable proper parsing of XML and JSON request bodies, which is critical for API security. The error handling rules reject malformed requests that could be attack attempts or evasion techniques.

---

## Comment 6: Line 49 (On the static assets whitelist rule)

**Location:** Line 49 (on the line with the static assets rule: `- SecRule REQUEST_URI "@rx \.(css|js|...`)

**Comment:**

**Suggestion: Make the whitelist rule more specific**

```yaml
            # Whitelist Rules (adjust regex to match your actual static asset paths)
            - SecRule REQUEST_URI "@rx ^/(assets|static|images|css|js)/.*\\.(css|js|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$" "id:104,phase:1,pass,nolog,msg:'Allow static assets'"
```

**Explanation:** The current regex allows these file types anywhere in the URL path, which might be too permissive. Consider restricting to specific directories where static assets are actually served from.

---

## Comment 7: Line 50 (Before the POST exemption rule)

**Location:** Line 50 (before or on the line with `- SecRule REQUEST_METHOD "@streq POST"`)

**Comment:**

**WARNING: Security implications of disabling body inspection for POST**

Add a warning comment above this line:

```yaml
            # WARNING: Disabling requestBodyAccess for POST requests significantly reduces security
            # This prevents inspection of POST data, which is a common attack vector
            # Consider using more specific exclusions instead of blanket POST exemption
```

**Explanation:** The current rule `SecRule REQUEST_METHOD "@streq POST" "id:900140,phase:1,pass,nolog,ctl:requestBodyAccess=Off"` disables all POST body inspection, which defeats much of the WAF's purpose. This should be reconsidered or replaced with more targeted exclusions for specific endpoints.

---

## Summary

All 7 review comments have been documented above. They cover:

1. ✅ Data directory configuration (line 35)
2. ✅ Audit logging (line 36)
3. ✅ Request body handling (line 37)
4. ✅ Response body handling (line 38)
5. ✅ Request body parsers (line 42)
6. ✅ Whitelist specificity (line 49)
7. ✅ POST security warning (line 50)

These comments provide comprehensive security and configuration recommendations for the OWASP Coraza WAF setup.
