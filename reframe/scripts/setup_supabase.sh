#!/bin/bash
# Supabase Setup Script for Reframe
# 
# Prerequisites:
# 1. Create a Supabase account at https://supabase.com
# 2. Create a new project
# 3. Get your access token from: https://supabase.com/dashboard/account/tokens
# 4. Add these secrets to Cursor Dashboard (Cloud Agents > Secrets):
#    - SUPABASE_ACCESS_TOKEN=your_access_token
#    - SUPABASE_PROJECT_REF=your_project_ref (found in project settings URL)

set -e

echo "========================================="
echo "Reframe - Supabase Setup"
echo "========================================="

# Check for required environment variables
if [ -z "$SUPABASE_ACCESS_TOKEN" ]; then
    echo ""
    echo "❌ SUPABASE_ACCESS_TOKEN not found in environment"
    echo ""
    echo "To set up Supabase:"
    echo "1. Go to https://supabase.com and create an account"
    echo "2. Create a new project (note the project reference ID)"
    echo "3. Go to https://supabase.com/dashboard/account/tokens"
    echo "4. Create a new access token"
    echo "5. Add to Cursor Dashboard > Cloud Agents > Secrets:"
    echo "   SUPABASE_ACCESS_TOKEN=your_token"
    echo "   SUPABASE_PROJECT_REF=your_project_ref"
    echo ""
    exit 1
fi

if [ -z "$SUPABASE_PROJECT_REF" ]; then
    echo ""
    echo "❌ SUPABASE_PROJECT_REF not found"
    echo "   Find it in your project URL: https://supabase.com/dashboard/project/[PROJECT_REF]"
    echo ""
    exit 1
fi

echo "✓ Credentials found"

# Link to the project
echo ""
echo "Linking to Supabase project..."
cd "$(dirname "$0")/../supabase"
supabase link --project-ref "$SUPABASE_PROJECT_REF"

# Apply migrations
echo ""
echo "Applying database migrations..."
supabase db push

# Get project info
echo ""
echo "Getting project info..."
PROJECT_INFO=$(supabase projects list --output json | jq -r ".[] | select(.id==\"$SUPABASE_PROJECT_REF\")")

PROJECT_URL="https://${SUPABASE_PROJECT_REF}.supabase.co"

echo ""
echo "========================================="
echo "✅ Supabase Setup Complete!"
echo "========================================="
echo ""
echo "Add these to your Cursor Dashboard secrets:"
echo ""
echo "  SUPABASE_URL=${PROJECT_URL}"
echo ""
echo "For the anon key, go to:"
echo "  https://supabase.com/dashboard/project/${SUPABASE_PROJECT_REF}/settings/api"
echo ""
echo "Then add:"
echo "  SUPABASE_ANON_KEY=your_anon_key"
echo ""
