# 🔐 Security Guide for Job Scheduler

## JWT Token and Sensitive Data Handling

### ✅ Recommended Approach: Environment Variables

**1. Set Environment Variables**
```bash
# In your .env file (never commit this!)
JWT_TOKEN=your_actual_jwt_token_here
AIRCALL_API_TOKEN=your_aircall_token_here
DATABASE_PASSWORD=your_db_password_here
```

**2. Use in YAML Configuration**
```yaml
jobs:
  - name: secure-api-call
    url: "https://api.example.com/secure-endpoint"
    headers:
      Authorization: "Bearer ${JWT_TOKEN}"
      X-API-Key: "${API_KEY}"
    data:
      credentials: "${DATABASE_PASSWORD}"
```

**3. Environment Variable Substitution**
The scheduler automatically substitutes `${VARIABLE_NAME}` with actual environment variable values.

### 🛡️ Security Best Practices

#### 1. **Never Store Tokens in YAML Files**
```yaml
# ❌ BAD - Token visible in file
headers:
  Authorization: "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."

# ✅ GOOD - Use environment variable
headers:
  Authorization: "Bearer ${JWT_TOKEN}"
```

#### 2. **Use Different Tokens for Different Services**
```bash
# .env file
JWT_TOKEN=your_main_jwt_token
AIRCALL_API_TOKEN=your_aircall_specific_token
SLACK_API_TOKEN=your_slack_token
DATABASE_PASSWORD=your_db_password
```

#### 3. **Rotate Tokens Regularly**
- Set up token expiration and rotation policies
- Use different tokens for different environments (dev/staging/prod)
- Monitor token usage and revoke unused tokens

#### 4. **Environment-Specific Configuration**
```bash
# Development
cp .env.example .env
# Edit .env with development tokens

# Production
# Set environment variables in your deployment platform
# (Docker, Kubernetes, Heroku, etc.)
```

### 🔧 Alternative Approaches

#### 1. **External Secret Management**
```bash
# Using AWS Secrets Manager
aws secretsmanager get-secret-value --secret-id my-app-secrets

# Using HashiCorp Vault
vault kv get secret/my-app/tokens
```

#### 2. **Docker Secrets (for containerized deployments)**
```dockerfile
# In your Dockerfile
COPY --chown=nodejs:nodejs . .
RUN echo "JWT_TOKEN=$(cat /run/secrets/jwt_token)" >> .env
```

#### 3. **Kubernetes Secrets**
```yaml
# kubernetes-secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: app-secrets
type: Opaque
data:
  jwt-token: <base64-encoded-token>
  api-key: <base64-encoded-key>
```

### 🚨 Security Checklist

- [ ] Never commit `.env` files to version control
- [ ] Use environment variables for all sensitive data
- [ ] Rotate tokens regularly
- [ ] Use different tokens for different services
- [ ] Monitor token usage and access logs
- [ ] Set up proper access controls and permissions
- [ ] Use HTTPS for all API calls
- [ ] Validate and sanitize all inputs
- [ ] Keep dependencies updated
- [ ] Use least privilege principle

### 📝 Example Secure Configuration

**`.env` file (not committed to git):**
```bash
# API Tokens
JWT_TOKEN=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
AIRCALL_API_TOKEN=aircall_token_here
SLACK_API_TOKEN=xoxb-your-slack-token

# Database
DATABASE_URL=postgresql://user:password@localhost:5432/db
DATABASE_PASSWORD=secure_password_here

# Other Services
REDIS_PASSWORD=redis_password_here
AWS_ACCESS_KEY_ID=your_aws_key
AWS_SECRET_ACCESS_KEY=your_aws_secret
```

**`jobs.yaml` file (safe to commit):**
```yaml
global:
  defaultTimeout: 10000
  defaultRetries: 3
  defaultHeaders:
    Content-Type: application/json

jobs:
  - name: kpi-afternoon-report
    schedule: "0 1 13 * * 1-5"  # Weekdays at 1:01 PM
    url: "https://api.aircall.io/v1/analytics/user-activity"
    method: GET
    headers:
      Authorization: "Bearer ${AIRCALL_API_TOKEN}"
    timeout: 30000
    retries: 3
    enabled: true
    description: "KPI report generation"

  - name: data-sync
    schedule: "0 */30 * * * *"  # Every 30 minutes
    url: "https://api.example.com/sync"
    method: POST
    headers:
      Authorization: "Bearer ${JWT_TOKEN}"
      X-API-Key: "${API_KEY}"
    data:
      timestamp: "${NOW}"
      action: "sync"
    timeout: 15000
    retries: 3
    enabled: true
    description: "Data synchronization"
```

### 🔍 Monitoring and Auditing

1. **Log Monitoring**: Check logs for failed authentication attempts
2. **Token Usage**: Monitor which tokens are being used and when
3. **Access Patterns**: Look for unusual access patterns
4. **Error Tracking**: Set up alerts for authentication failures

### 🆘 Emergency Procedures

1. **Token Compromise**: Immediately rotate all affected tokens
2. **File Exposure**: If YAML files with tokens are exposed, rotate all tokens
3. **Access Review**: Audit all access logs and revoke suspicious access
4. **Incident Response**: Follow your organization's security incident procedures 