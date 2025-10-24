import { writable, derived } from 'svelte/store';
import { isSubscriptionActive, getSubscriptionStatus } from 'tauri-plugin-subscriptions';
import type { SubscriptionStatus } from 'tauri-plugin-subscriptions';

// Define your product IDs here
export const MONTHLY_SUBSCRIPTION_ID = 'com.yourapp.subscription.monthly';
export const YEARLY_SUBSCRIPTION_ID = 'com.yourapp.subscription.yearly';

// Store for subscription status
export const subscriptionStatus = writable<SubscriptionStatus | null>(null);

// Store for loading state
export const isLoadingSubscription = writable(false);

// Derived store for quick access to active status
export const hasActiveSubscription = derived(
  subscriptionStatus,
  ($status) => $status?.isActive ?? false
);

/**
 * Check subscription status for a product
 */
export async function checkSubscriptionStatus(productId: string) {
  isLoadingSubscription.set(true);
  
  try {
    const status = await getSubscriptionStatus(productId);
    subscriptionStatus.set(status);
    return status;
  } catch (error) {
    console.error('Failed to check subscription status:', error);
    return null;
  } finally {
    isLoadingSubscription.set(false);
  }
}

/**
 * Check if user has any active subscription
 */
export async function checkAnyActiveSubscription() {
  const productIds = [MONTHLY_SUBSCRIPTION_ID, YEARLY_SUBSCRIPTION_ID];
  
  for (const productId of productIds) {
    try {
      const isActive = await isSubscriptionActive(productId);
      if (isActive) {
        // If we found an active subscription, get its full status
        await checkSubscriptionStatus(productId);
        return true;
      }
    } catch (error) {
      console.error(`Failed to check subscription ${productId}:`, error);
    }
  }
  
  subscriptionStatus.set(null);
  return false;
}

/**
 * Initialize subscription checking on app startup
 */
export async function initializeSubscriptions() {
  await checkAnyActiveSubscription();
}
