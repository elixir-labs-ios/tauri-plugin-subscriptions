<script lang="ts">
  import { onMount } from 'svelte';
  import type { Product } from 'tauri-plugin-subscriptions';
  import { 
    hasActiveSubscription, 
    subscriptionStatus,
    MONTHLY_SUBSCRIPTION_ID,
    YEARLY_SUBSCRIPTION_ID 
  } from './subscription-store';
  import { 
    loadSubscriptionProducts, 
    purchaseSubscription, 
    restoreSubscriptions,
    formatSubscriptionPeriod,
    calculateSavings,
    formatExpiryDate,
    isExpiringSoon
  } from './subscription-utils';

  let products: Product[] = [];
  let loading = true;
  let purchasing = false;
  let restoring = false;
  let errorMessage = '';

  const PRODUCT_IDS = [MONTHLY_SUBSCRIPTION_ID, YEARLY_SUBSCRIPTION_ID];

  onMount(async () => {
    await loadProducts();
  });

  async function loadProducts() {
    try {
      loading = true;
      errorMessage = '';
      products = await loadSubscriptionProducts(PRODUCT_IDS);
    } catch (error) {
      errorMessage = error instanceof Error ? error.message : 'Failed to load products';
    } finally {
      loading = false;
    }
  }

  async function handlePurchase(productId: string) {
    try {
      purchasing = true;
      errorMessage = '';
      await purchaseSubscription(productId);
      // Success handled by the utility function
    } catch (error) {
      errorMessage = error instanceof Error ? error.message : 'Purchase failed';
    } finally {
      purchasing = false;
    }
  }

  async function handleRestore() {
    try {
      restoring = true;
      errorMessage = '';
      const restored = await restoreSubscriptions();
      
      if (restored.length === 0) {
        errorMessage = 'No purchases found to restore';
      }
    } catch (error) {
      errorMessage = error instanceof Error ? error.message : 'Restore failed';
    } finally {
      restoring = false;
    }
  }

  // Calculate savings if we have both products
  $: monthlyProduct = products.find(p => p.id === MONTHLY_SUBSCRIPTION_ID);
  $: yearlyProduct = products.find(p => p.id === YEARLY_SUBSCRIPTION_ID);
  $: savingsPercentage = monthlyProduct && yearlyProduct 
    ? calculateSavings(monthlyProduct.priceAmount, yearlyProduct.priceAmount)
    : 0;
</script>

<div class="subscription-page">
  <header>
    <h1>Premium Subscription</h1>
    <p>Unlock all features with a premium subscription</p>
  </header>

  {#if loading}
    <div class="loading">
      <p>Loading subscription options...</p>
    </div>
  {:else if $hasActiveSubscription && $subscriptionStatus}
    <div class="active-subscription">
      <div class="subscription-badge">
        <span class="badge-icon">✓</span>
        <h2>You're a Premium Member</h2>
      </div>
      
      <div class="subscription-info">
        <p><strong>Product:</strong> {$subscriptionStatus.productId}</p>
        {#if $subscriptionStatus.expiryDate}
          <p><strong>Expires:</strong> {formatExpiryDate($subscriptionStatus.expiryDate)}</p>
          
          {#if isExpiringSoon($subscriptionStatus.expiryDate)}
            <div class="expiry-warning">
              ⚠️ Your subscription is expiring soon!
            </div>
          {/if}
        {/if}
        
        {#if $subscriptionStatus.autoRenewStatus}
          <p class="auto-renew">🔄 Auto-renew is enabled</p>
        {/if}
      </div>

      <button class="secondary-button" on:click={handleRestore} disabled={restoring}>
        {restoring ? 'Restoring...' : 'Restore Purchases'}
      </button>
    </div>
  {:else}
    <div class="products-section">
      <h2>Choose Your Plan</h2>
      
      <div class="products-grid">
        {#each products as product}
          <div class="product-card" class:featured={product.id === YEARLY_SUBSCRIPTION_ID}>
            {#if product.id === YEARLY_SUBSCRIPTION_ID && savingsPercentage > 0}
              <div class="savings-badge">
                Save {savingsPercentage}%
              </div>
            {/if}
            
            <h3>{product.title}</h3>
            <p class="description">{product.description}</p>
            
            <div class="pricing">
              <span class="price">{product.price}</span>
              {#if product.subscriptionPeriod && product.subscriptionPeriodUnit}
                <span class="period">
                  per {formatSubscriptionPeriod(product.subscriptionPeriod, product.subscriptionPeriodUnit)}
                </span>
              {/if}
            </div>

            <button 
              class="purchase-button"
              on:click={() => handlePurchase(product.id)}
              disabled={purchasing}
            >
              {purchasing ? 'Processing...' : 'Subscribe Now'}
            </button>
          </div>
        {/each}
      </div>

      <div class="restore-section">
        <button class="text-button" on:click={handleRestore} disabled={restoring}>
          {restoring ? 'Restoring...' : 'Restore Previous Purchases'}
        </button>
      </div>
    </div>
  {/if}

  {#if errorMessage}
    <div class="error-message">
      ⚠️ {errorMessage}
    </div>
  {/if}

  <footer>
    <p class="disclaimer">
      Subscriptions auto-renew unless cancelled. Cancel anytime in your account settings.
    </p>
  </footer>
</div>

<style>
  .subscription-page {
    max-width: 900px;
    margin: 0 auto;
    padding: 2rem;
  }

  header {
    text-align: center;
    margin-bottom: 3rem;
  }

  header h1 {
    font-size: 2.5rem;
    margin-bottom: 0.5rem;
    color: #333;
  }

  header p {
    font-size: 1.1rem;
    color: #666;
  }

  .loading {
    text-align: center;
    padding: 3rem;
    color: #666;
  }

  .active-subscription {
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    color: white;
    padding: 2rem;
    border-radius: 12px;
    text-align: center;
  }

  .subscription-badge {
    margin-bottom: 1.5rem;
  }

  .badge-icon {
    display: inline-block;
    width: 60px;
    height: 60px;
    background: rgba(255, 255, 255, 0.3);
    border-radius: 50%;
    line-height: 60px;
    font-size: 2rem;
    margin-bottom: 1rem;
  }

  .subscription-info {
    background: rgba(255, 255, 255, 0.1);
    padding: 1.5rem;
    border-radius: 8px;
    margin: 1.5rem 0;
  }

  .subscription-info p {
    margin: 0.5rem 0;
  }

  .expiry-warning {
    background: rgba(255, 193, 7, 0.3);
    padding: 0.75rem;
    border-radius: 6px;
    margin-top: 1rem;
  }

  .auto-renew {
    color: #4caf50;
  }

  .products-section h2 {
    text-align: center;
    margin-bottom: 2rem;
    font-size: 2rem;
    color: #333;
  }

  .products-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
    gap: 2rem;
    margin-bottom: 2rem;
  }

  .product-card {
    position: relative;
    border: 2px solid #e0e0e0;
    border-radius: 12px;
    padding: 2rem;
    text-align: center;
    transition: transform 0.3s, box-shadow 0.3s;
  }

  .product-card:hover {
    transform: translateY(-4px);
    box-shadow: 0 8px 24px rgba(0, 0, 0, 0.15);
  }

  .product-card.featured {
    border-color: #667eea;
    border-width: 3px;
  }

  .savings-badge {
    position: absolute;
    top: -12px;
    right: 20px;
    background: #ff6b6b;
    color: white;
    padding: 0.5rem 1rem;
    border-radius: 20px;
    font-weight: bold;
    font-size: 0.9rem;
  }

  .product-card h3 {
    font-size: 1.5rem;
    margin-bottom: 1rem;
    color: #333;
  }

  .description {
    color: #666;
    margin-bottom: 1.5rem;
    min-height: 3rem;
  }

  .pricing {
    margin: 1.5rem 0;
  }

  .price {
    display: block;
    font-size: 2.5rem;
    font-weight: bold;
    color: #667eea;
  }

  .period {
    display: block;
    color: #999;
    margin-top: 0.5rem;
  }

  .purchase-button {
    width: 100%;
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    color: white;
    border: none;
    padding: 1rem 2rem;
    border-radius: 8px;
    font-size: 1.1rem;
    font-weight: 600;
    cursor: pointer;
    transition: opacity 0.3s;
  }

  .purchase-button:hover:not(:disabled) {
    opacity: 0.9;
  }

  .purchase-button:disabled {
    opacity: 0.6;
    cursor: not-allowed;
  }

  .secondary-button {
    background: rgba(255, 255, 255, 0.3);
    color: white;
    border: 2px solid white;
    padding: 0.75rem 1.5rem;
    border-radius: 8px;
    cursor: pointer;
    margin-top: 1rem;
  }

  .secondary-button:hover:not(:disabled) {
    background: rgba(255, 255, 255, 0.4);
  }

  .restore-section {
    text-align: center;
    padding: 1rem 0;
  }

  .text-button {
    background: none;
    border: none;
    color: #667eea;
    text-decoration: underline;
    cursor: pointer;
    font-size: 0.95rem;
  }

  .text-button:hover:not(:disabled) {
    color: #764ba2;
  }

  .text-button:disabled {
    opacity: 0.5;
    cursor: not-allowed;
  }

  .error-message {
    background: #ffebee;
    color: #c62828;
    padding: 1rem;
    border-radius: 8px;
    margin-top: 1rem;
    text-align: center;
  }

  footer {
    margin-top: 3rem;
    text-align: center;
  }

  .disclaimer {
    font-size: 0.85rem;
    color: #999;
    line-height: 1.5;
  }
</style>
