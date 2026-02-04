#!/bin/bash
# PostHog Setup Script for Reframe
#
# PostHog doesn't have a CLI for account creation, but this script
# helps you verify your setup and provides the configuration needed.
#
# Prerequisites:
# 1. Create a PostHog account at https://posthog.com
# 2. Create a new project
# 3. Get your Project API Key from Project Settings
# 4. Add to Cursor Dashboard secrets:
#    - POSTHOG_API_KEY=your_project_api_key

set -e

echo "========================================="
echo "Reframe - PostHog Setup"
echo "========================================="

if [ -z "$POSTHOG_API_KEY" ]; then
    echo ""
    echo "❌ POSTHOG_API_KEY not found in environment"
    echo ""
    echo "To set up PostHog:"
    echo ""
    echo "1. Go to https://posthog.com and create a free account"
    echo ""
    echo "2. Create a new project called 'Reframe'"
    echo ""
    echo "3. In your project, go to Settings > Project > Project API Key"
    echo "   (or find it at https://us.posthog.com/settings/project#api-keys)"
    echo ""
    echo "4. Copy the Project API Key (starts with 'phc_')"
    echo ""
    echo "5. Add to Cursor Dashboard > Cloud Agents > Secrets:"
    echo "   POSTHOG_API_KEY=phc_your_key_here"
    echo ""
    echo "PostHog Cloud (US) host: https://us.posthog.com"
    echo "PostHog Cloud (EU) host: https://eu.posthog.com"
    echo ""
    exit 1
fi

# Verify the API key format
if [[ ! "$POSTHOG_API_KEY" =~ ^phc_ ]]; then
    echo ""
    echo "⚠️  Warning: API key doesn't start with 'phc_'"
    echo "   Make sure you're using the Project API Key, not a Personal API Key"
    echo ""
fi

# Determine host based on key
POSTHOG_HOST="https://us.posthog.com"
if [[ "$POSTHOG_API_KEY" =~ ^phc_eu ]]; then
    POSTHOG_HOST="https://eu.posthog.com"
fi

echo ""
echo "✓ PostHog API key found"
echo ""
echo "========================================="
echo "✅ PostHog Configuration"
echo "========================================="
echo ""
echo "Add these to your Cursor Dashboard secrets:"
echo ""
echo "  POSTHOG_API_KEY=${POSTHOG_API_KEY}"
echo "  POSTHOG_HOST=${POSTHOG_HOST}"
echo ""
echo "The app is already configured to use these environment variables."
echo ""

# Test the connection
echo "Testing PostHog connection..."
RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" \
    -X POST "${POSTHOG_HOST}/capture/" \
    -H "Content-Type: application/json" \
    -d "{\"api_key\":\"${POSTHOG_API_KEY}\",\"event\":\"test_connection\",\"distinct_id\":\"setup_script\"}")

if [ "$RESPONSE" = "200" ]; then
    echo "✓ Successfully connected to PostHog!"
else
    echo "⚠️  Connection test returned: $RESPONSE"
    echo "   Please verify your API key is correct"
fi
echo ""
