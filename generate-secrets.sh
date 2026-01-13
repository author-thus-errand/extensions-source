#!/bin/bash
#
# Script to generate all necessary secrets for CI/CD
# This script will guide you through creating the required secrets
#

set -e

echo "=================================================="
echo "CI/CD Secrets Generation Script"
echo "=================================================="
echo ""
echo "This script will help you generate the secrets needed for GitHub Actions CI/CD"
echo ""

# Create a temporary directory for outputs
OUTPUT_DIR="./ci-secrets-output"
mkdir -p "$OUTPUT_DIR"

echo "All generated files will be saved to: $OUTPUT_DIR"
echo ""

# Step 1: Generate Android Keystore
echo "=================================================="
echo "Step 1: Generate Android Keystore"
echo "=================================================="
echo ""
echo "This will create a signing key for your Android APKs."
echo ""

read -p "Enter alias name for the keystore (e.g., my-release-key): " ALIAS
read -sp "Enter keystore password: " KEYSTORE_PASSWORD
echo ""
read -sp "Confirm keystore password: " KEYSTORE_PASSWORD_CONFIRM
echo ""

if [ "$KEYSTORE_PASSWORD" != "$KEYSTORE_PASSWORD_CONFIRM" ]; then
    echo "ERROR: Passwords do not match!"
    exit 1
fi

read -sp "Enter key password (can be same as keystore password): " KEY_PASSWORD
echo ""
read -sp "Confirm key password: " KEY_PASSWORD_CONFIRM
echo ""

if [ "$KEY_PASSWORD" != "$KEY_PASSWORD_CONFIRM" ]; then
    echo "ERROR: Passwords do not match!"
    exit 1
fi

echo ""
echo "Generating keystore..."
echo ""

# Generate the keystore
keytool -genkey -v \
    -keystore "$OUTPUT_DIR/signingkey.jks" \
    -keyalg RSA \
    -keysize 2048 \
    -validity 10000 \
    -alias "$ALIAS" \
    -storepass "$KEYSTORE_PASSWORD" \
    -keypass "$KEY_PASSWORD" \
    -dname "CN=Unknown, OU=Unknown, O=Unknown, L=Unknown, ST=Unknown, C=US"

echo ""
echo "✓ Keystore generated successfully: $OUTPUT_DIR/signingkey.jks"
echo ""

# Step 2: Convert to Base64
echo "=================================================="
echo "Step 2: Convert Keystore to Base64"
echo "=================================================="
echo ""

if command -v base64 &> /dev/null; then
    # Try different base64 options based on OS
    if base64 --version 2>&1 | grep -q "GNU"; then
        # GNU base64 (Linux)
        base64 -w 0 "$OUTPUT_DIR/signingkey.jks" > "$OUTPUT_DIR/SIGNING_KEY.txt"
    else
        # BSD base64 (macOS)
        base64 -i "$OUTPUT_DIR/signingkey.jks" -o "$OUTPUT_DIR/SIGNING_KEY.txt"
    fi
    echo "✓ Base64 encoded keystore saved to: $OUTPUT_DIR/SIGNING_KEY.txt"
else
    echo "ERROR: base64 command not found. Please install it or encode manually."
    exit 1
fi

echo ""

# Step 3: Save secrets to file
echo "=================================================="
echo "Step 3: Save All Secrets"
echo "=================================================="
echo ""

cat > "$OUTPUT_DIR/secrets.txt" << EOF
==================================================
GitHub Actions Secrets - KEEP THIS FILE SECURE!
==================================================

Add these secrets to your GitHub repository:
Settings → Secrets and variables → Actions → New repository secret

---
Secret Name: SIGNING_KEY
Value: (see SIGNING_KEY.txt file)
---

---
Secret Name: ALIAS
Value: $ALIAS
---

---
Secret Name: KEY_STORE_PASSWORD
Value: $KEYSTORE_PASSWORD
---

---
Secret Name: KEY_PASSWORD
Value: $KEY_PASSWORD
---

Optional Secrets (generate separately):
- BOT_PAT: Create at https://github.com/settings/tokens
- MEMBER_TOKEN: Create at https://github.com/settings/tokens
- CODEBERG_SSH: Generate with the command below

==================================================
EOF

echo "✓ All secrets saved to: $OUTPUT_DIR/secrets.txt"
echo ""

# Step 4: Optional - Generate SSH key for Codeberg
echo "=================================================="
echo "Step 4: Generate SSH Key for Codeberg (Optional)"
echo "=================================================="
echo ""
read -p "Do you want to generate an SSH key for Codeberg mirroring? (y/N): " GENERATE_SSH

if [[ "$GENERATE_SSH" =~ ^[Yy]$ ]]; then
    echo ""
    ssh-keygen -t ed25519 -C "github-actions@codeberg-mirror" -f "$OUTPUT_DIR/codeberg_deploy_key" -N ""
    echo ""
    echo "✓ SSH key generated:"
    echo "  Private key: $OUTPUT_DIR/codeberg_deploy_key (use as CODEBERG_SSH secret)"
    echo "  Public key: $OUTPUT_DIR/codeberg_deploy_key.pub (add to Codeberg deploy keys)"
    echo ""
    
    cat >> "$OUTPUT_DIR/secrets.txt" << EOF

---
Secret Name: CODEBERG_SSH
Value: (see codeberg_deploy_key file)

Add the public key (codeberg_deploy_key.pub) to Codeberg:
Repository Settings → Deploy Keys → Add Deploy Key
Enable "Allow write access"
---
EOF
fi

# Summary
echo ""
echo "=================================================="
echo "✓ Complete! Summary:"
echo "=================================================="
echo ""
echo "Generated files in $OUTPUT_DIR/:"
echo "  - signingkey.jks (backup this file securely!)"
echo "  - SIGNING_KEY.txt (base64 encoded keystore)"
echo "  - secrets.txt (all secret values)"
if [[ "$GENERATE_SSH" =~ ^[Yy]$ ]]; then
    echo "  - codeberg_deploy_key (private SSH key)"
    echo "  - codeberg_deploy_key.pub (public SSH key)"
fi
echo ""
echo "Next steps:"
echo "1. Go to your GitHub repository Settings"
echo "2. Navigate to Secrets and variables → Actions"
echo "3. Add each secret from secrets.txt"
echo "4. BACKUP signingkey.jks somewhere safe - you'll need it to update your apps!"
echo "5. For BOT_PAT and MEMBER_TOKEN, generate at: https://github.com/settings/tokens"
echo ""
echo "⚠️  IMPORTANT: Keep all files in $OUTPUT_DIR secure and private!"
echo "   Consider deleting them after adding secrets to GitHub."
echo ""
