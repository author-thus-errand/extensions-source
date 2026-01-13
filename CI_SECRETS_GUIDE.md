# GitHub CI Secrets Configuration Guide

This document explains all the secrets required for the CI/CD workflows in this repository and how to generate them.

## Required Secrets

Based on the workflow files analysis, the following secrets need to be added to your GitHub repository:

### 1. **SIGNING_KEY** (Required for build_push.yml)
- **Purpose**: Base64-encoded Android keystore file (`.jks`) used to sign APK files during release builds
- **Used in**: `.github/workflows/build_push.yml` (line 88)
- **How it's used**: Decoded and written to `signingkey.jks` before building extensions

### 2. **ALIAS** (Required for build_push.yml)
- **Purpose**: The key alias name within the keystore
- **Used in**: `.github/workflows/build_push.yml` (line 93) and `common.gradle` (line 58)
- **How it's used**: Identifies which key to use from the keystore when signing APKs

### 3. **KEY_STORE_PASSWORD** (Required for build_push.yml)
- **Purpose**: Password for the keystore file
- **Used in**: `.github/workflows/build_push.yml` (line 94) and `common.gradle` (line 57)
- **How it's used**: Unlocks the keystore file during the signing process

### 4. **KEY_PASSWORD** (Required for build_push.yml)
- **Purpose**: Password for the specific key within the keystore
- **Used in**: `.github/workflows/build_push.yml` (line 95) and `common.gradle` (line 59)
- **How it's used**: Unlocks the specific signing key within the keystore

### 5. **BOT_PAT** (Required for build_push.yml - publish job)
- **Purpose**: Personal Access Token for pushing to the `keiyoushi/extensions` repository
- **Used in**: `.github/workflows/build_push.yml` (line 148)
- **How it's used**: Authenticates when checking out and pushing to the extensions repo
- **Note**: Only needed if `github.repository == 'keiyoushi/extensions-source'`

### 6. **CODEBERG_SSH** (Optional - for codeberg_mirror.yml)
- **Purpose**: SSH private key for mirroring the repository to Codeberg
- **Used in**: `.github/workflows/codeberg_mirror.yml` (line 26)
- **How it's used**: Authenticates SSH connection to `git@codeberg.org:keiyoushi/extensions-source.git`
- **Note**: Only needed if you want to mirror to Codeberg and if `github.repository == 'keiyoushi/extensions-source'`

### 7. **MEMBER_TOKEN** (Optional - for issue_moderator.yml)
- **Purpose**: GitHub token with permissions to check organization membership
- **Used in**: `.github/workflows/issue_moderator.yml` (line 21)
- **How it's used**: Used by the issue moderator action to identify organization members

## How to Generate the Secrets

### Generating Android Signing Key (SIGNING_KEY, ALIAS, KEY_STORE_PASSWORD, KEY_PASSWORD)

#### Step 1: Generate a new keystore

```bash
keytool -genkey -v -keystore signingkey.jks -keyalg RSA -keysize 2048 -validity 10000 -alias <your-alias>
```

You'll be prompted to:
- Create a keystore password (save this as **KEY_STORE_PASSWORD**)
- Enter your personal information (CN, OU, O, L, ST, C)
- **Note**: By default, `keytool` uses the same password for both the keystore and the key. You'll only be prompted once for a password, which becomes both **KEY_STORE_PASSWORD** and **KEY_PASSWORD**.
- The alias you specify is your **ALIAS**

#### Step 2: Convert keystore to base64

```bash
base64 signingkey.jks > signingkey_base64.txt
```

Or on macOS/Linux in one line:
```bash
base64 -w 0 signingkey.jks
```

Or on Windows:
```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("signingkey.jks"))
```

The output is your **SIGNING_KEY** secret.

#### Step 3: Store the values securely
- **SIGNING_KEY**: The base64 output from step 2
- **ALIAS**: The alias you used in the keytool command
- **KEY_STORE_PASSWORD**: The keystore password you set
- **KEY_PASSWORD**: The same password you set for the keystore (unless you explicitly set a different one)

### Generating BOT_PAT (Personal Access Token)

1. Go to GitHub Settings → Developer settings → Personal access tokens → Tokens (classic)
2. Click "Generate new token (classic)"
3. Give it a descriptive name (e.g., "Extensions Repo Publisher")
4. Select the following scopes:
   - `repo` (Full control of private repositories)
5. Set an appropriate expiration date
6. Click "Generate token"
7. Copy the token immediately (you won't be able to see it again)

### Generating CODEBERG_SSH (SSH Key for Codeberg)

```bash
# Generate a new SSH key pair
ssh-keygen -t ed25519 -C "github-actions@codeberg-mirror" -f codeberg_deploy_key

# Display the private key (this is your CODEBERG_SSH secret)
cat codeberg_deploy_key

# Display the public key (add this to Codeberg)
cat codeberg_deploy_key.pub
```

Then:
1. Copy the private key content (entire file) as the **CODEBERG_SSH** secret
2. Add the public key to your Codeberg repository:
   - Go to your Codeberg repository → Settings → Deploy Keys
   - Add a new deploy key with write access
   - Paste the public key content

### Generating MEMBER_TOKEN

1. Go to GitHub Settings → Developer settings → Personal access tokens → Tokens (classic)
2. Click "Generate new token (classic)"
3. Give it a descriptive name (e.g., "Issue Moderator Member Check")
4. Select the following scopes:
   - `read:org` (Read org and team membership)
5. Set an appropriate expiration date
6. Click "Generate token"
7. Copy the token immediately

## Adding Secrets to GitHub Repository

**Important**: Add secrets as **Repository secrets**, NOT Environment secrets. The workflows in this repository access secrets at the repository level.

1. Go to your GitHub repository
2. Click on **Settings**
3. Navigate to **Secrets and variables** → **Actions**
4. Under the **Secrets** tab, you'll see two sections:
   - **Repository secrets** ← Use this one
   - **Environment secrets** ← Do NOT use this
5. Click **New repository secret** (in the Repository secrets section)
6. Add each secret:
   - Name: The secret name (e.g., `SIGNING_KEY`)
   - Value: The secret value
7. Click **Add secret**
8. Repeat for all required secrets

**Note**: If you accidentally added secrets to an environment instead of the repository, delete them from the environment and re-add them as repository secrets.

## Which Secrets Are Mandatory?

### For Pull Request Builds (build_pull_request.yml)
- **No secrets required** - This workflow only builds in Debug mode and doesn't sign APKs

### For Main Branch Builds (build_push.yml)
**Mandatory for building:**
- `SIGNING_KEY`
- `ALIAS`
- `KEY_STORE_PASSWORD`
- `KEY_PASSWORD`

**Mandatory for publishing** (only if `github.repository == 'keiyoushi/extensions-source'`):
- `BOT_PAT`

### For Optional Features
- `CODEBERG_SSH` - Only if you want to mirror to Codeberg
- `MEMBER_TOKEN` - Only if you want enhanced issue moderation features

## Testing Your Configuration

After adding the secrets, you can test them by:

1. Making a commit to the `main` branch
2. Checking the GitHub Actions tab to see if the `build_push.yml` workflow succeeds
3. Verifying that the build job successfully:
   - Decodes the signing key
   - Builds and signs the APKs
   - Uploads artifacts (if publishing is enabled)

## Security Notes

⚠️ **Important Security Considerations:**

1. **Never commit your keystore file or passwords to the repository**
2. **Keep backups of your keystore and passwords** - losing them means you can't update your extensions
3. **Use strong passwords** for both keystore and key passwords
4. **Set appropriate expiration dates** for Personal Access Tokens
5. **Use minimal permissions** for tokens (only what's necessary)
6. **Regularly rotate your secrets** for better security
7. **Limit who has access** to repository secrets in your organization settings

## Troubleshooting

### Build fails with "signingkey.jks not found"
- Ensure `SIGNING_KEY` is properly base64 encoded
- Verify the secret is added to the repository (check Settings → Secrets)
- Make sure the base64 string has no newlines (use `base64 -w 0` on Linux or plain `base64` output as-is)

### Build fails with "command not found" when decoding SIGNING_KEY
- This usually means the workflow script needs the secret value quoted
- The workflow has been updated to properly quote the secret value
- Ensure the secret exists and is not empty

### Build fails with "keystore password was incorrect"
- Double-check your `KEY_STORE_PASSWORD` matches the password used when creating the keystore
- Ensure there are no extra spaces or newlines in the secret value

### Build fails with "key password was incorrect"
- Verify `KEY_PASSWORD` matches the key password from keystore creation (usually the same as KEY_STORE_PASSWORD)
- Confirm the `ALIAS` matches exactly (case-sensitive)
- If you only entered one password during keystore creation, use that same password for both KEY_STORE_PASSWORD and KEY_PASSWORD

### Publishing fails
- Ensure `BOT_PAT` has the correct permissions
- Verify the token hasn't expired
- Check that the target repository (`keiyoushi/extensions`) exists and the token has access

## Summary Commands

Here's a quick reference for generating all the necessary secrets:

```bash
# 1. Generate Android keystore
keytool -genkey -v -keystore signingkey.jks -keyalg RSA -keysize 2048 -validity 10000 -alias my-release-key

# 2. Convert to base64 (Linux/macOS)
base64 -w 0 signingkey.jks

# 3. Generate Codeberg SSH key (optional)
ssh-keygen -t ed25519 -C "github-actions@codeberg-mirror" -f codeberg_deploy_key

# After running these, you'll have:
# - SIGNING_KEY: Output from base64 command
# - ALIAS: "my-release-key" (or whatever you chose)
# - KEY_STORE_PASSWORD: Password you entered for keystore
# - KEY_PASSWORD: Password you entered for the key
# - CODEBERG_SSH: Content of codeberg_deploy_key file
```

For GitHub tokens (BOT_PAT and MEMBER_TOKEN), you must generate them through the GitHub web interface as described above.
