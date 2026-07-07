# Razorpay Integration Update & Dynamic Pricing Guide

## Part 1: What Was Just Changed (Current Implementation)

We have successfully replaced Google Play Billing with a basic Razorpay Subscriptions implementation. Currently, prices are fixed (non-dynamic) while we ensure the core architecture works.

Here is the exact summary of the changes made:

### 1. Vercel Backend (`backend-phoneguard`)
- **Initialized Node.js Project**: Created a new serverless project at `d:\Flutter Apps\backend-phoneguard`.
- **Created Endpoints**: Built `api/index.js` containing secure Vercel API routes for creating Subscriptions (`/api/createSubscription`), creating Orders (`/api/createOrder`), and listening to Webhooks (`/api/webhook`).
- **Injected Razorpay Keys**: Securely added the provided `rzp_test_T9JiUpdjbI85MT` and the Secret Key to the `.env` file so they are never exposed on the front-end.

### 2. PhoneGuard App Frontend (`phoneguard`)
- **Restored SMS Features**: Discarded uncommitted Play Store compliance changes on the `website-version` branch to restore offline SMS features.
- **Updated Dependencies**: Removed `in_app_purchase` and added `razorpay_flutter` and `http` to the `pubspec.yaml`.
- **Refactored `SubscriptionProvider`**: 
  - Entirely rewritten to manage the Razorpay SDK instance.
  - Interacts with our Vercel backend to request `order_id` (Lifetime plans) and `subscription_id` (Monthly/Yearly plans) over HTTP.
  - Hardcoded to use fixed Plan IDs (`plan_monthly_id`, `plan_yearly_id`) for now.
- **Updated UI (`PaywallScreen`)**: Safely detached from the old Google Play `ProductDetails` objects and connected the existing UI to Razorpay's mapping.

---

## Part 2: Future Step - Dynamic Pricing Architecture

When you are ready to implement dynamic, multi-currency pricing (to perfectly mimic Google Play Billing), follow this 4-step architecture:

### Step 1: Create a Pricing Matrix
Instead of hardcoding prices in your app, create a configuration map (or fetch it remotely via Firebase Remote Config). Define prices for your core markets, and set a "Default" (usually USD) for everyone else.

```dart
// Example Pricing Matrix in SubscriptionProvider
final pricingMatrix = {
  'IN': { 
    'currency': 'INR', 'symbol': '₹', 
    'monthly': 99, 'lifetime': 2499,
    'monthly_plan_id': 'plan_inr_monthly_id' 
  },
  'US': { 
    'currency': 'USD', 'symbol': '$', 
    'monthly': 1.49, 'lifetime': 34.99,
    'monthly_plan_id': 'plan_usd_monthly_id' 
  },
  'DEFAULT': { 
    'currency': 'USD', 'symbol': '$', 
    'monthly': 1.49, 'lifetime': 34.99,
    'monthly_plan_id': 'plan_usd_monthly_id' 
  }
};
```

### Step 2: Detect the User's Country
When the user opens the Paywall, the app needs to know where they are.
The most reliable way is using a free IP-geolocation API in the background. For example, making an HTTP GET request to `http://ip-api.com/json` returns their country code (e.g., `US` or `IN`).

### Step 3: Razorpay Dashboard Configuration (Crucial)
Razorpay Subscriptions are strictly locked to a single currency.
This means you **cannot** use the same Razorpay Plan ID for an Indian user and a US user. 

In your Razorpay Dashboard, you must manually create:
- 1 Monthly Plan in **INR** (Yields `plan_inr_monthly_id`)
- 1 Monthly Plan in **USD** (Yields `plan_usd_monthly_id`)

*(Note: For one-time payments like Lifetime, you do not need Plans. You just pass the converted `amount` and `currency` directly to your backend order creation endpoint).*

### Step 4: Tie it Together on the Paywall
1. The app detects the user is in the `US`.
2. It looks up the `US` config in the Pricing Matrix.
3. The UI automatically uses the symbol `$` and the price `1.49` to display `$1.49/mo`.
4. When they click "Buy Subscription", the app sends the corresponding `plan_usd_monthly_id` to your Vercel backend `/api/createSubscription`.
5. For the Lifetime payment, you send `currency: "USD"` and `amount: 34.99` to the backend `/api/createOrder`, and Razorpay creates a USD order.
