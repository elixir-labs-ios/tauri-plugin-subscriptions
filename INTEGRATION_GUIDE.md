# Tauri Plugin: Subscriptions - Integration Guide

This plugin provides in-app purchase and subscription functionality for Tauri 2.0 mobile applications on iOS and Android.

## Features

- ✅ Retrieve product information from App Store (iOS) and Play Store (Android)
- ✅ Purchase products and subscriptions
- ✅ Restore previous purchases
- ✅ Check subscription status
- ✅ Cross-platform API with TypeScript bindings
- ✅ Automatic transaction handling and acknowledgment

## Installation

### 1. Add to Your Tauri Project

Add the plugin to your `Cargo.toml`:

```toml
[dependencies]
tauri-plugin-subscriptions = { git = "https://github.com/elixir-labs-ios/tauri-plugin-subscriptions" }
```

### 2. Initialize the Plugin

In your Tauri app's Rust code (typically `src-tauri/src/lib.rs`):

```rust
use tauri_plugin_subscriptions;

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    tauri::Builder::default()
        .plugin(tauri_plugin_subscriptions::init())
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
```

### 3. iOS Setup

#### Add StoreKit Capability

1. Open your Xcode project located in `src-tauri/gen/apple/`
2. Select your app target
3. Go to "Signing & Capabilities"
4. Click "+" and add "In-App Purchase" capability

#### Configure Products in App Store Connect

1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Navigate to your app → Features → In-App Purchases
3. Create your subscription or purchase products
4. Note the product IDs for use in your app

#### Register the Plugin

The plugin automatically registers with StoreKit when initialized.

### 4. Android Setup

#### Add Billing Dependency

The plugin's `build.gradle.kts` automatically includes:

```kotlin
dependencies {
    implementation("com.android.billingclient:billing:6.0.1")
}
```

#### Add Billing Permission

Already included in the plugin's `AndroidManifest.xml`:

```xml
<uses-permission android:name="com.android.vending.BILLING" />
```

#### Configure Products in Google Play Console

1. Go to [Google Play Console](https://play.google.com/console)
2. Navigate to your app → Monetize → Subscriptions
3. Create your subscription products
4. Note the product IDs for use in your app

## Usage

### Install npm Package

```bash
npm install tauri-plugin-subscriptions
# or
yarn add tauri-plugin-subscriptions
```

### TypeScript/JavaScript API

#### Import the Plugin

```typescript
import { 
  getProducts, 
  purchaseProduct, 
  restorePurchases,
  getSubscriptionStatus,
  isSubscriptionActive 
} from 'tauri-plugin-subscriptions';
```

#### Retrieve Products

```typescript
const productIds = [
  'com.yourapp.subscription.monthly',
  'com.yourapp.subscription.yearly'
];

try {
  const products = await getProducts(productIds);
  
  products.forEach(product => {
    console.log(`${product.title}: ${product.price}`);
    console.log(`Description: ${product.description}`);
  });
} catch (error) {
  console.error('Failed to get products:', error);
}
```

#### Purchase a Product

```typescript
try {
  const result = await purchaseProduct('com.yourapp.subscription.monthly');
  
  console.log('Purchase successful!');
  console.log('Transaction ID:', result.transactionId);
  console.log('Product ID:', result.productId);
  
  if (result.subscriptionExpiryTime) {
    const expiryDate = new Date(result.subscriptionExpiryTime * 1000);
    console.log('Subscription expires:', expiryDate);
  }
} catch (error) {
  console.error('Purchase failed:', error);
}
```

#### Restore Purchases

```typescript
try {
  const restoredPurchases = await restorePurchases();
  
  console.log(`Restored ${restoredPurchases.length} purchases`);
  
  restoredPurchases.forEach(purchase => {
    console.log(`Restored: ${purchase.productId}`);
  });
} catch (error) {
  console.error('Restore failed:', error);
}
```

#### Check Subscription Status

```typescript
const productId = 'com.yourapp.subscription.monthly';

try {
  const status = await getSubscriptionStatus(productId);
  
  if (status.isActive) {
    console.log('Subscription is active!');
    
    if (status.expiryDate) {
      const expiryDate = new Date(status.expiryDate * 1000);
      console.log('Expires on:', expiryDate);
    }
    
    console.log('Auto-renew:', status.autoRenewStatus);
  } else {
    console.log('No active subscription');
  }
} catch (error) {
  console.error('Failed to get status:', error);
}
```

#### Simple Active Check

```typescript
const isActive = await isSubscriptionActive('com.yourapp.subscription.monthly');

if (isActive) {
  // Grant access to premium features
  console.log('User has active subscription');
} else {
  // Show subscription prompt
  console.log('User needs to subscribe');
}
```

## Complete Example: Subscription Page

Here's a complete example of a subscription page in Svelte:

```svelte
<script lang="ts">
  import { onMount } from 'svelte';
  import { getProducts, purchaseProduct, isSubscriptionActive } from 'tauri-plugin-subscriptions';
  import type { Product } from 'tauri-plugin-subscriptions';

  let products: Product[] = [];
  let loading = true;
  let hasActiveSubscription = false;

  const PRODUCT_IDS = [
    'com.yourapp.subscription.monthly',
    'com.yourapp.subscription.yearly'
  ];

  onMount(async () => {
    try {
      // Load products
      products = await getProducts(PRODUCT_IDS);
      
      // Check if user already has a subscription
      for (const productId of PRODUCT_IDS) {
        if (await isSubscriptionActive(productId)) {
          hasActiveSubscription = true;
          break;
        }
      }
    } catch (error) {
      console.error('Failed to load products:', error);
    } finally {
      loading = false;
    }
  });

  async function handlePurchase(productId: string) {
    try {
      loading = true;
      await purchaseProduct(productId);
      hasActiveSubscription = true;
      alert('Purchase successful! Thank you for subscribing!');
    } catch (error) {
      console.error('Purchase failed:', error);
      alert('Purchase failed. Please try again.');
    } finally {
      loading = false;
    }
  }
</script>

<div class="subscription-page">
  <h1>Choose Your Plan</h1>
  
  {#if loading}
    <p>Loading...</p>
  {:else if hasActiveSubscription}
    <div class="active-subscription">
      <h2>You're a Premium Member!</h2>
      <p>Thank you for your support.</p>
    </div>
  {:else}
    <div class="products">
      {#each products as product}
        <div class="product-card">
          <h3>{product.title}</h3>
          <p class="description">{product.description}</p>
          <p class="price">{product.price}</p>
          <button on:click={() => handlePurchase(product.id)}>
            Subscribe Now
          </button>
        </div>
      {/each}
    </div>
  {/if}
</div>

<style>
  .subscription-page {
    padding: 2rem;
    max-width: 800px;
    margin: 0 auto;
  }

  .products {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
    gap: 2rem;
    margin-top: 2rem;
  }

  .product-card {
    border: 1px solid #ccc;
    border-radius: 8px;
    padding: 1.5rem;
    text-align: center;
  }

  .price {
    font-size: 2rem;
    font-weight: bold;
    margin: 1rem 0;
  }

  button {
    background-color: #007bff;
    color: white;
    border: none;
    padding: 0.75rem 1.5rem;
    border-radius: 4px;
    cursor: pointer;
    font-size: 1rem;
  }

  button:hover {
    background-color: #0056b3;
  }
</style>
```

## API Reference

### Types

```typescript
export enum ProductType {
  Consumable = 'Consumable',
  NonConsumable = 'NonConsumable',
  Subscription = 'Subscription'
}

export enum SubscriptionPeriod {
  Day = 'Day',
  Week = 'Week',
  Month = 'Month',
  Year = 'Year'
}

export interface Product {
  id: string;
  title: string;
  description: string;
  price: string;
  priceAmount: number;
  currencyCode: string;
  productType: ProductType;
  subscriptionPeriod?: SubscriptionPeriod;
  subscriptionPeriodUnit?: number;
}

export interface PurchaseResult {
  productId: string;
  transactionId: string;
  purchaseTime: number;
  isAcknowledged: boolean;
  subscriptionExpiryTime?: number;
  receiptData?: string;
}

export interface SubscriptionStatus {
  productId: string;
  isActive: boolean;
  expiryDate?: number;
  autoRenewStatus: boolean;
  isInTrialPeriod: boolean;
  isInGracePeriod: boolean;
}
```

### Methods

- `getProducts(productIds: string[]): Promise<Product[]>` - Retrieve products from store
- `purchaseProduct(productId: string): Promise<PurchaseResult>` - Purchase a product
- `restorePurchases(): Promise<PurchaseResult[]>` - Restore previous purchases
- `getSubscriptionStatus(productId: string): Promise<SubscriptionStatus>` - Get subscription status
- `isSubscriptionActive(productId: string): Promise<boolean>` - Quick check if subscription is active
- `formatPrice(priceAmount: number, currencyCode: string): string` - Format price with currency

## Testing

### iOS Testing

1. Create sandbox test users in App Store Connect
2. Use these test accounts to make purchases during development
3. Test on a real device (simulator doesn't support purchases)

### Android Testing

1. Add test users in Google Play Console
2. Upload your app to internal testing track
3. Test on a real device with a test account

## Important Notes

- **Receipt Validation**: The current implementation includes basic receipt handling. For production apps, implement server-side receipt validation with Apple/Google servers.
- **Security**: Never trust client-side subscription checks alone. Always verify on your backend.
- **Testing**: Use sandbox/test environments during development.
- **Error Handling**: Always implement proper error handling for purchase flows.

## License

MIT

## Support

For issues and questions, please open an issue on GitHub.
