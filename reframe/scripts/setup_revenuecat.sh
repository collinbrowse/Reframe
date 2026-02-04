#!/bin/bash
# RevenueCat Setup Guide for Reframe
#
# RevenueCat doesn't have a public CLI for project setup.
# This script provides guidance on configuring RevenueCat.

echo "========================================="
echo "Reframe - RevenueCat Setup Guide"
echo "========================================="
echo ""
echo "RevenueCat is used for managing subscriptions and in-app purchases."
echo ""
echo "Step 1: Create RevenueCat Account"
echo "--------------------------------"
echo "1. Go to https://www.revenuecat.com"
echo "2. Sign up for a free account"
echo "3. Create a new project called 'Reframe'"
echo ""
echo "Step 2: Configure iOS App"
echo "-------------------------"
echo "1. In RevenueCat dashboard, go to Project Settings > Apps"
echo "2. Add a new iOS app:"
echo "   - App name: Reframe"
echo "   - Bundle ID: com.reframe.reframe"
echo "3. Connect to App Store Connect:"
echo "   - Add your App Store Connect API key"
echo "   - Or use shared secret from App Store Connect"
echo "4. Copy the iOS Public API Key"
echo ""
echo "Step 3: Configure Android App"
echo "-----------------------------"
echo "1. Add a new Android app:"
echo "   - App name: Reframe"
echo "   - Package name: com.reframe.reframe"
echo "2. Connect to Google Play Console:"
echo "   - Upload your Google Play service account JSON"
echo "3. Copy the Android Public API Key"
echo ""
echo "Step 4: Create Products"
echo "-----------------------"
echo "In RevenueCat > Products:"
echo ""
echo "1. Create entitlements:"
echo "   - 'premium' - Access to premium features"
echo "   - 'premium_plus' - Access to all features"
echo ""
echo "2. Create products in App Store Connect / Google Play:"
echo "   - Monthly subscription: \$9.99/month"
echo "   - Annual subscription: \$79.99/year"  
echo "   - Lifetime purchase: \$199.99 one-time"
echo ""
echo "3. Link products to entitlements in RevenueCat"
echo ""
echo "Step 5: Create Offerings"
echo "------------------------"
echo "1. Create a 'default' offering"
echo "2. Add all products to the offering"
echo ""
echo "Step 6: Add API Keys to Cursor"
echo "------------------------------"
echo "Add to Cursor Dashboard > Cloud Agents > Secrets:"
echo ""
echo "  REVENUECAT_API_KEY_IOS=your_ios_api_key"
echo "  REVENUECAT_API_KEY_ANDROID=your_android_api_key"
echo ""
echo "========================================="
echo ""

# Check if keys are set
if [ -n "$REVENUECAT_API_KEY_IOS" ] || [ -n "$REVENUECAT_API_KEY_ANDROID" ]; then
    echo "Current configuration:"
    if [ -n "$REVENUECAT_API_KEY_IOS" ]; then
        echo "  ✓ iOS API Key is set"
    else
        echo "  ✗ iOS API Key not set"
    fi
    if [ -n "$REVENUECAT_API_KEY_ANDROID" ]; then
        echo "  ✓ Android API Key is set"
    else
        echo "  ✗ Android API Key not set"
    fi
    echo ""
fi

echo "For detailed setup instructions, see:"
echo "https://docs.revenuecat.com/docs/getting-started"
echo ""
