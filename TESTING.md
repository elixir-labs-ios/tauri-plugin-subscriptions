# Testing Guide

This guide explains how to test the subscription plugin in development and production environments.

## iOS Testing

### Prerequisites

1. An Apple Developer account
2. Xcode installed on macOS
3. A physical iOS device (in-app purchases don't work in the simulator)

### Setup Steps

#### 1. Configure App Store Connect

1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Navigate to your app → Features → In-App Purchases
3. Create your subscription products:
   - Click "+" to add a new subscription
   - Fill in:
     - Reference Name (internal use only)
     - Product ID (e.g., `com.yourapp.subscription.monthly`)
     - Subscription Group Name
     - Duration (e.g., 1 month, 1 year)
     - Price
     - Localized descriptions
4. Save and submit for review (for sandbox testing, approval is quick)

#### 2. Create Sandbox Test Users

1. In App Store Connect, go to Users and Access → Sandbox
2. Click "+" to add a tester
3. Fill in:
   - Email (use a valid email format but doesn't need to be a real working email, e.g., `test1@example.com`)
   - Password
   - First/Last Name
   - Country/Region (must match your app's availability)
4. Create multiple testers to test different scenarios

**Note:** While the email doesn't need to be a real working address, it must be in a valid email format and unique within your sandbox testers.

#### 3. Configure Your Xcode Project

1. Open your Tauri iOS project in Xcode: `src-tauri/gen/apple/YourApp.xcodeproj`
2. Select your app target
3. Go to "Signing & Capabilities"
4. Ensure "In-App Purchase" capability is added
5. Set up your development team and provisioning profile

#### 4. Test on Device

1. Build and run your app on a physical device
2. Sign out of any existing Apple ID:
   - Settings → App Store → Sign Out
3. Run your app and attempt a purchase
4. When prompted, sign in with your sandbox test account
5. Complete the purchase flow

### iOS Testing Scenarios

#### Test Subscription Purchase

```typescript
import { purchaseProduct } from 'tauri-plugin-subscriptions';

async function testPurchase() {
  try {
    const result = await purchaseProduct('com.yourapp.subscription.monthly');
    console.log('Purchase successful:', result);
  } catch (error) {
    console.error('Purchase failed:', error);
  }
}
```

#### Test Subscription Restoration

```typescript
import { restorePurchases } from 'tauri-plugin-subscriptions';

async function testRestore() {
  try {
    const restored = await restorePurchases();
    console.log('Restored purchases:', restored);
  } catch (error) {
    console.error('Restore failed:', error);
  }
}
```

#### Test Subscription Status

```typescript
import { getSubscriptionStatus } from 'tauri-plugin-subscriptions';

async function testStatus() {
  try {
    const status = await getSubscriptionStatus('com.yourapp.subscription.monthly');
    console.log('Subscription status:', status);
    console.log('Is active:', status.isActive);
  } catch (error) {
    console.error('Status check failed:', error);
  }
}
```

### iOS Sandbox Environment Features

- Accelerated subscription renewal (e.g., 1-month subscriptions renew every 5 minutes)
- Quick cancellation and re-subscription
- Test various subscription states:
  - Active
  - Expired
  - In grace period
  - In billing retry
  - Cancelled but still active

### Important iOS Notes

- Sandbox purchases are free
- Subscriptions auto-renew faster in sandbox (for testing)
- Always test on a real device
- Don't use production Apple IDs for sandbox testing
- Clear test data by deleting and reinstalling the app

## Android Testing

### Prerequisites

1. Google Play Developer account
2. Android device or emulator
3. App uploaded to Google Play Console (can be in internal testing)

### Setup Steps

#### 1. Configure Google Play Console

1. Go to [Google Play Console](https://play.google.com/console)
2. Navigate to your app → Monetize → Subscriptions
3. Create subscription products:
   - Click "Create subscription"
   - Fill in:
     - Product ID (e.g., `monthly_subscription`)
     - Name and description
     - Billing period (e.g., 1 month)
     - Price
     - Localized content
4. Save and activate the subscription

#### 2. Set Up License Testing

1. In Google Play Console, go to Settings → License testing
2. Add test Gmail accounts (these will have free access to in-app products)
3. Save changes

#### 3. Upload Your App

1. Create a signed APK or AAB:
   ```bash
   # Using Tauri CLI (choose the appropriate command for your setup)
   npx tauri android build
   # or
   cargo tauri android build
   # or if you have tauri in your package.json scripts
   npm run tauri android build
   ```
2. Upload to Google Play Console → Internal testing
3. Add testers (their Gmail addresses)
4. Publish the internal test

#### 4. Install and Test

1. Join the internal test (testers receive an email link)
2. Download the app from Play Store
3. Sign in with a test account
4. Attempt purchases (they will be free for license testers)

### Android Testing Scenarios

#### Test Product Retrieval

```typescript
import { getProducts } from 'tauri-plugin-subscriptions';

async function testGetProducts() {
  try {
    const products = await getProducts([
      'monthly_subscription',
      'yearly_subscription'
    ]);
    console.log('Products:', products);
  } catch (error) {
    console.error('Failed to get products:', error);
  }
}
```

#### Test Purchase Flow

```typescript
import { purchaseProduct } from 'tauri-plugin-subscriptions';

async function testPurchase() {
  try {
    const result = await purchaseProduct('monthly_subscription');
    console.log('Purchase result:', result);
  } catch (error) {
    console.error('Purchase error:', error);
  }
}
```

#### Test Purchase Restoration

```typescript
import { restorePurchases } from 'tauri-plugin-subscriptions';

async function testRestore() {
  try {
    const purchases = await restorePurchases();
    console.log('Restored purchases:', purchases);
  } catch (error) {
    console.error('Restore error:', error);
  }
}
```

### Android Testing Types

#### License Testing (Recommended for Development)

- Add email addresses in Google Play Console → Settings → License testing
- Purchases are free for these accounts
- No actual billing
- Perfect for development and QA

#### Internal Testing

- Real Play Store installation
- Limited to approved testers
- Still uses test billing (free for license testers)
- Most realistic testing environment

### Important Android Notes

- License test accounts get free purchases
- Test products must be activated in Play Console
- App must be uploaded to Play Console (even for testing)
- Subscriptions can be managed in Play Store app
- Always test acknowledgment flow

## Common Testing Scenarios

### 1. First-Time Purchase

**Test:**
- Launch app without any previous purchases
- Browse subscription options
- Select and complete a purchase
- Verify purchase success

**Expected:**
- Products load correctly
- Purchase flow completes
- Subscription becomes active
- Receipt/transaction ID is returned

### 2. Subscription Renewal

**Test:**
- Wait for subscription renewal (accelerated in sandbox)
- Check subscription status before and after renewal

**Expected:**
- Status remains active after renewal
- Expiry date updates

### 3. Restore Purchases

**Test:**
- Make a purchase on one device
- Install app on another device with same account
- Trigger restore purchases

**Expected:**
- Previous purchases are restored
- Subscription status reflects active subscription

### 4. Subscription Expiration

**Test:**
- Let subscription expire (or cancel and wait)
- Check subscription status

**Expected:**
- `isActive` returns false
- Expiry date is in the past
- App behaves correctly for non-subscribers

### 5. Purchase Cancellation

**Test:**
- Start purchase flow
- Cancel before completion

**Expected:**
- Purchase is cancelled gracefully
- Error is handled properly
- User can retry

### 6. Network Errors

**Test:**
- Disable network
- Attempt to load products
- Attempt to purchase

**Expected:**
- Appropriate error messages
- Graceful degradation
- Ability to retry when network restored

## Debugging Tips

### iOS Debugging

1. **Enable StoreKit logging:**
   ```bash
   # In Xcode, edit scheme → Run → Arguments
   # Add environment variable:
   # Name: OS_ACTIVITY_MODE
   # Value: disable
   ```

2. **Check console logs:**
   - View in Xcode console during testing
   - Look for StoreKit-related messages

3. **Receipt validation:**
   - Test with real receipts in sandbox
   - Verify receipt structure

### Android Debugging

1. **Enable verbose logging:**
   ```kotlin
   // In your Android code
   Log.d("Subscriptions", "Purchase state: ${purchase.purchaseState}")
   ```

2. **Check Logcat:**
   ```bash
   adb logcat | grep -i billing
   ```

3. **Verify billing connection:**
   - Check BillingClient connection status
   - Ensure billing library is properly initialized

## Production Testing Checklist

Before releasing to production, verify:

- [ ] All product IDs match between code and store consoles
- [ ] Receipt validation is implemented (server-side)
- [ ] Error handling covers all scenarios
- [ ] Restore purchases functionality works
- [ ] Subscription status checks are accurate
- [ ] UI provides clear feedback during purchases
- [ ] Privacy policy and terms of service are linked
- [ ] Auto-renewal terms are clearly stated
- [ ] Cancellation instructions are provided
- [ ] Tested on multiple devices and OS versions

## Troubleshooting

### "Product not found" error

- Verify product IDs match exactly (case-sensitive)
- Ensure products are active in store console
- For iOS: Wait 1-2 hours after creating products
- For Android: Products must be activated

### "Billing unavailable" error

- Check device has Google Play Services (Android)
- Verify app is signed with release key (Android)
- Ensure billing permission is in manifest (Android)
- Check In-App Purchase capability (iOS)

### "User cancelled" frequently

- Review purchase UI/UX
- Ensure pricing is clear
- Verify authentication flow is smooth
- Check if device restrictions are enabled

### Purchases not restoring

- Verify user is signed in with correct account
- Check restore implementation calls correct API
- Ensure transactions are properly finished/acknowledged
- Review transaction observer implementation (iOS)

## Resources

### iOS

- [StoreKit Documentation](https://developer.apple.com/documentation/storekit)
- [App Store Connect Help](https://help.apple.com/app-store-connect/)
- [Testing In-App Purchases](https://developer.apple.com/documentation/storekit/in-app_purchase/testing_in-app_purchases)

### Android

- [Google Play Billing Library](https://developer.android.com/google/play/billing)
- [Test Google Play Billing](https://developer.android.com/google/play/billing/test)
- [Subscriptions Guide](https://developer.android.com/google/play/billing/subscriptions)

## Support

If you encounter issues:

1. Check this testing guide
2. Review the INTEGRATION_GUIDE.md
3. Search GitHub issues
4. Create a new issue with:
   - Platform (iOS/Android)
   - Error message
   - Steps to reproduce
   - Expected vs actual behavior
