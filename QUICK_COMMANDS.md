# Quick Reference: Commands to Generate CI Secrets Locally

## Prerequisites
- `keytool` (comes with Java JDK)
- `base64` (standard on Linux/macOS)
- `ssh-keygen` (standard on Linux/macOS)

## Option 1: Automated Script (Recommended)

Run the provided script that will generate everything for you:

```bash
./generate-secrets.sh
```

This interactive script will:
1. Generate the Android keystore
2. Convert it to base64
3. Save all secrets to files
4. Optionally generate SSH key for Codeberg

## Option 2: Manual Commands

### 1. Generate Android Keystore and Base64 Encoding

```bash
# Step 1: Generate keystore (you'll be prompted for a password and info)
# Note: By default, the same password is used for both keystore and key
keytool -genkey -v \
  -keystore signingkey.jks \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -alias my-release-key

# Step 2: Convert keystore to base64
# On Linux:
base64 -w 0 signingkey.jks > SIGNING_KEY.txt

# On macOS:
base64 -i signingkey.jks -o SIGNING_KEY.txt

# On Windows PowerShell:
[Convert]::ToBase64String([IO.File]::ReadAllBytes("signingkey.jks")) | Out-File -Encoding ASCII SIGNING_KEY.txt
```

**Secrets generated:**
- `SIGNING_KEY` = content of `SIGNING_KEY.txt`
- `ALIAS` = the alias you specified (e.g., "my-release-key")
- `KEY_STORE_PASSWORD` = keystore password you entered
- `KEY_PASSWORD` = same as keystore password (unless explicitly set differently)

### 2. Generate Codeberg SSH Key (Optional)

```bash
# Generate SSH key pair
ssh-keygen -t ed25519 -C "github-actions@codeberg-mirror" -f codeberg_deploy_key -N ""

# View private key (this is CODEBERG_SSH secret)
cat codeberg_deploy_key

# View public key (add this to Codeberg deploy keys)
cat codeberg_deploy_key.pub
```

**Secret generated:**
- `CODEBERG_SSH` = content of `codeberg_deploy_key` file

### 3. Generate GitHub Personal Access Tokens (Web Only)

#### BOT_PAT (for publishing)
1. Go to: https://github.com/settings/tokens
2. Click "Generate new token (classic)"
3. Name: "Extensions Repo Publisher"
4. Scopes: Select `repo`
5. Generate and copy the token

#### MEMBER_TOKEN (for issue moderation)
1. Go to: https://github.com/settings/tokens
2. Click "Generate new token (classic)"
3. Name: "Issue Moderator"
4. Scopes: Select `read:org`
5. Generate and copy the token

## Complete Example (Copy-Paste Ready)

```bash
# Create output directory
mkdir -p ci-secrets-output
cd ci-secrets-output

# 1. Generate keystore
keytool -genkey -v \
  -keystore signingkey.jks \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -alias my-release-key \
  -storepass "YourStorePassword123" \
  -keypass "YourKeyPassword123" \
  -dname "CN=YourName, OU=YourOrg, O=YourCompany, L=YourCity, ST=YourState, C=US"

# 2. Convert to base64 (Linux/macOS)
base64 -w 0 signingkey.jks > SIGNING_KEY.txt 2>/dev/null || base64 -i signingkey.jks -o SIGNING_KEY.txt

# 3. Generate SSH key for Codeberg (optional)
ssh-keygen -t ed25519 -C "github-actions@codeberg-mirror" -f codeberg_deploy_key -N ""

# 4. Display your secrets
echo "=== Your GitHub Secrets ==="
echo ""
echo "SIGNING_KEY:"
cat SIGNING_KEY.txt
echo ""
echo ""
echo "ALIAS: my-release-key"
echo "KEY_STORE_PASSWORD: YourStorePassword123"
echo "KEY_PASSWORD: YourKeyPassword123"
echo ""
echo "CODEBERG_SSH (private key):"
cat codeberg_deploy_key
echo ""
echo ""
echo "Codeberg public key (add to Codeberg deploy keys):"
cat codeberg_deploy_key.pub

# Return to parent directory
cd ..
```

**⚠️ Replace the passwords in the example with your own secure passwords!**

## Add Secrets to GitHub

Once you have generated all the values:

1. Go to your GitHub repository
2. Click **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Add each secret:
   - Name: `SIGNING_KEY` | Value: Content from `SIGNING_KEY.txt`
   - Name: `ALIAS` | Value: `my-release-key` (or your alias)
   - Name: `KEY_STORE_PASSWORD` | Value: Your keystore password
   - Name: `KEY_PASSWORD` | Value: Your key password
   - Name: `BOT_PAT` | Value: Token from GitHub (optional)
   - Name: `CODEBERG_SSH` | Value: Content from `codeberg_deploy_key` (optional)
   - Name: `MEMBER_TOKEN` | Value: Token from GitHub (optional)

## What You Need

### Mandatory for building on main branch:
```
✓ SIGNING_KEY
✓ ALIAS
✓ KEY_STORE_PASSWORD
✓ KEY_PASSWORD
```

### Optional (only if you're the main keiyoushi repo):
```
○ BOT_PAT (for publishing)
○ MEMBER_TOKEN (for issue moderation)
○ CODEBERG_SSH (for mirroring to Codeberg)
```

### Not needed for PR builds:
PR builds use Debug mode and don't require any secrets!

## Quick Verification

Test if keytool is installed:
```bash
keytool -help
```

Test if base64 is available:
```bash
echo "test" | base64
```

Test if ssh-keygen is available:
```bash
ssh-keygen -help
```
