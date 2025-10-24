import { getProducts, purchaseProduct, restorePurchases } from 'tauri-plugin-subscriptions';
import type { Product, PurchaseResult } from 'tauri-plugin-subscriptions';
import { checkAnyActiveSubscription } from './subscription-store';

/**
 * Load all available subscription products
 */
export async function loadSubscriptionProducts(productIds: string[]): Promise<Product[]> {
  try {
    const products = await getProducts(productIds);
    return products;
  } catch (error) {
    console.error('Failed to load products:', error);
    throw new Error('Could not load subscription products. Please try again later.');
  }
}

/**
 * Purchase a subscription product
 */
export async function purchaseSubscription(productId: string): Promise<PurchaseResult> {
  try {
    const result = await purchaseProduct(productId);
    
    // After successful purchase, refresh subscription status
    await checkAnyActiveSubscription();
    
    return result;
  } catch (error) {
    console.error('Purchase failed:', error);
    throw new Error('Purchase failed. Please try again.');
  }
}

/**
 * Restore previous purchases
 */
export async function restoreSubscriptions(): Promise<PurchaseResult[]> {
  try {
    const restoredPurchases = await restorePurchases();
    
    // After restoring, refresh subscription status
    await checkAnyActiveSubscription();
    
    return restoredPurchases;
  } catch (error) {
    console.error('Restore failed:', error);
    throw new Error('Failed to restore purchases. Please try again.');
  }
}

/**
 * Format a subscription period for display
 */
export function formatSubscriptionPeriod(period?: string, unit?: number): string {
  if (!period) return '';
  
  const periodUnit = unit || 1;
  const pluralize = (word: string, count: number) => count === 1 ? word : `${word}s`;
  
  switch (period) {
    case 'Day':
      return `${periodUnit} ${pluralize('day', periodUnit)}`;
    case 'Week':
      return `${periodUnit} ${pluralize('week', periodUnit)}`;
    case 'Month':
      return `${periodUnit} ${pluralize('month', periodUnit)}`;
    case 'Year':
      return `${periodUnit} ${pluralize('year', periodUnit)}`;
    default:
      return period;
  }
}

/**
 * Calculate savings percentage for yearly vs monthly
 */
export function calculateSavings(monthlyPrice: number, yearlyPrice: number): number {
  const monthlyYearlyCost = monthlyPrice * 12;
  const savings = monthlyYearlyCost - yearlyPrice;
  const savingsPercentage = (savings / monthlyYearlyCost) * 100;
  return Math.round(savingsPercentage);
}

/**
 * Format a date from unix timestamp
 */
export function formatExpiryDate(timestamp?: number): string {
  if (!timestamp) return 'Unknown';
  
  const date = new Date(timestamp * 1000);
  return date.toLocaleDateString(undefined, {
    year: 'numeric',
    month: 'long',
    day: 'numeric'
  });
}

/**
 * Check if subscription is expiring soon (within 7 days)
 */
export function isExpiringSoon(expiryTimestamp?: number): boolean {
  if (!expiryTimestamp) return false;
  
  const expiryDate = new Date(expiryTimestamp * 1000);
  const now = new Date();
  const daysUntilExpiry = (expiryDate.getTime() - now.getTime()) / (1000 * 60 * 60 * 24);
  
  return daysUntilExpiry > 0 && daysUntilExpiry <= 7;
}
