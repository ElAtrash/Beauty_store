# ✅ Do's (Recommended)

Based on modern e-commerce UX + best practices:

1. Keep it as simple as possible

- Single-page checkout (all steps visible).
- Auto-save data between steps (Turbo Streams / AJAX) to avoid losing progress.

2. Guest checkout first

- Don't force account creation. Allow guest checkout, and offer account creation after order completion ("save your info for next time").
- Pre-fill known data if the user is logged in.

3. Payment methods _(more details will be added later in this file)_

- Avoid handling card data directly → always use provider SDK / JS.

4. Shipping & delivery UX

- Self pickup option
- Show delivery options with costs + estimated dates upfront.
- Offer free shipping threshold messaging
- Auto-suggest addresses (Google Places, Mapbox, or similar).

5. Cart → Checkout consistency

- Persist cart → checkout data without surprises.
- Show order summary (cart items + total cost) at all times during checkout.
- Allow editing cart items without leaving checkout (Turbo Frame updates inside sidebar).

6. Error handling

- Inline validation with clear error messages.
- Highlight fields with errors.
- Keep error messages human-friendly ("Your card was declined, please try another payment method").

7. Security & trust

- Use HTTPS everywhere.
- Show trust badges only if they're meaningful (SSL, secure payment provider logos).
- Comply with PCI-DSS if handling payments directly.

8. Post-checkout experience

- Confirmation page: clear order summary, estimated delivery, next steps.
- Send order confirmation email immediately.
- Offer "track your order" link if available.

# ❌ Don'ts (to avoid)

- Forcing account creation before checkout.
- Hiding fees until the last step (tax, shipping) → leads to drop-offs.
- Overcomplicating forms (e.g., asking for unnecessary details).
- Reloading pages on every step (use Turbo / Turbo Streams for smooth transitions).
- Mixing upsells too aggressively — keep upsells subtle in cart or confirmation, not blocking checkout.
- Long checkout forms without auto-save (users rage-quit if they lose data).

# ⚡ Technical Recommendations (Rails + Stimulus/Turbo)

- Controllers/services:
  - CheckoutsController with steps (shipping, payment, review).
  - Service objects for payments: Payments::StripeCheckout, Payments::PaypalCheckout.
- Models:
  - Order, OrderItem, Shipment, PaymentIntent.
  - Keep cart separate from order (copy cart → order on checkout start).
- UI:
  - Use Turbo Frames for step containers (shipping address form, payment form).
  - Stimulus for interactive bits (address auto-complete, payment SDK integration).

# 💳 Payments

Since target customers are in Lebanon payments has very real implications for checkout flow, because customer expectations, available infrastructure, and regulations differ from the "default Stripe/PayPal" setup.

- **Card adoption is limited.** Many Lebanese cards don't work reliably with international gateways (due to capital controls, currency restrictions, or banks blocking foreign payments).
- **Cash on Delivery (COD)** is very popular and often preferred. Offering COD as a payment option can significantly increase conversion rates.
- **Local payment gateways**: Consider integrating with local payment providers that are popular in Lebanon (e.g., ZainCash, OMT, Whish Money, PinPay).
- **Expats abroad ordering for relatives in Lebanon**: international cards / PayPal / Western Union / Remittance-based payment methods.
  ✅ Recommendation: Support COD by default (must be built into checkout).

# 💵 Currency & Pricing

- Lebanon has multiple exchange rates (official rate, Sayrafa rate, street rate).
- Customers expect prices in USD (fresh dollars), not LBP, to avoid confusion.
- If you list in LBP, you must clearly state the exchange rate used (risk of disputes)
  ✅ Recommendation: Default prices to USD. Allow COD in USD cash or equivalent in LBP at delivery (with rate disclosed).

# 📦 Shipping & Delivery

- **Local delivery services**: Many local couriers (e.g., Aramex, Wakilni, Toters Delivery, DHL Express).
- **Self-pickup**: Many customers prefer to pick up orders from a local store or warehouse to avoid delivery fees and delays.
- **Cash payment at delivery**: collected by courier.
- **Addressing** is messy (no reliable street names/zip codes). Delivery often works by:
  - Taking phone number
  - Courier calling customer on delivery day for directions
  - Landmarks instead of street addresses ("next to ABC Mall, 2nd floor").
    ✅ Recommendation: Address field should allow freeform text + optional landmarks.

# ✅ What to Do for Lebanon

- Offer COD first, then add card/wallet payments later.
- USD pricing with clear LBP conversion policy if you accept it.
- Simplify checkout form:
  - Name
  - Phone (required)
  - Address (free text + landmarks)
- Payment method (COD default, card optional)
- Courier integration (if possible), or at least generate a delivery note/receipt for the courier.
- Post-order confirmation via SMS/WhatsApp (email less reliable).

# Review current orders and order_items tables schema

✅ What Looks Good

- Monetized fields with cents + currency → 👍 (future-proof for multi-currency).
- Order totals broken down (subtotal, tax, shipping, discount, total) → good for transparency.
- Order items store product + variant names → important for historical integrity (if product names change later).
- JSONB for addresses → flexible and avoids migration churn.
- Status, payment_status, fulfillment_status separated → this matches Shopify-style flows.

⚠️ Things That Could Be Improved

1. order_items table

- Storing product_id and product_variant_id and denormalized names.
- ⚠️ For Lebanon, prices can fluctuate daily (exchange rates, promotions). Already locking unit_price_cents and total_price_cents, which is correct.
  👉 Improvement:
  - Add a sku string column (from variant) for external references, reporting, and fulfillment.
  - Optional: store metadata JSONB (e.g., size, color, notes from variant) to make future display easier.

2. orders table

- Addresses as JSONB is fine, but in Lebanon customers often just leave a phone number + text
  👉 suggestions: Keep shipping_address as JSONB and add a phone_number string column directly on orders (don't bury it in JSON). This will be the most important field.
- User association is optional (user_id) → good for guest checkout.
- Statuses:
  - Right now status + payment_status + fulfillment_status could get messy.
  - Better to have:
    - status (enum: pending_confirmation, confirmed, canceled, completed).
    - payment_status (enum: pending, paid, refunded, cod_due).
    - fulfillment_status (enum: unfulfilled, shipped, delivered).
- Currency handling: we'll accept LBP, add exchange_rate (decimal) column so you can lock the USD→LBP rate at order time.
- Delivery handling:
  - Add delivery_method (enum/string: "courier", "pickup", "digital")
  - Add courier_name (string, optional).
  - Add cod_amount_cents (in case COD is different due to rounding/fees).

# Suggested Schema Changes

orders:

```ruby
  t.string   "number", null: false
  t.bigint   "user_id"
  t.string   "email", null: false
  t.string   "phone_number", null: false          # 🔑 Lebanon-first
  t.string   "status", default: "pending"         # high-level order status
  t.string   "payment_status", default: "pending"
  t.string   "fulfillment_status", default: "unfulfilled"

  t.integer  "subtotal_cents", default: 0, null: false
  t.string   "subtotal_currency", default: "USD", null: false
  t.integer  "tax_total_cents", default: 0, null: false
  t.string   "tax_total_currency", default: "USD", null: false
  t.integer  "shipping_total_cents", default: 0, null: false
  t.string   "shipping_total_currency", default: "USD", null: false
  t.integer  "discount_total_cents", default: 0, null: false
  t.string   "discount_total_currency", default: "USD", null: false
  t.integer  "total_cents", default: 0, null: false
  t.string   "total_currency", default: "USD", null: false

  t.decimal  "exchange_rate", precision: 12, scale: 6   # 🔑 if LBP offered
  t.string   "delivery_method"                          # courier, pickup, etc.
  t.string   "courier_name"                             # Aramex, Wakilni…
  t.integer  "cod_amount_cents"                         # optional, for COD

  t.jsonb    "billing_address", default: {}
  t.jsonb    "shipping_address", default: {}
  t.text     "notes"
```

order_items:

```ruby
  t.bigint   "order_id", null: false
  t.bigint   "product_id", null: false
  t.bigint   "product_variant_id", null: false
  t.string   "sku"                       # 🔑 store variant SKU
  t.string   "product_name", null: false
  t.string   "variant_name"
  t.jsonb    "metadata", default: {}     # 🔑 store attributes (color, size)
  t.integer  "quantity", null: false
  t.integer  "unit_price_cents", default: 0, null: false
  t.string   "unit_price_currency", default: "USD", null: false
  t.integer  "total_price_cents", default: 0, null: false
  t.string   "total_price_currency", default: "USD", null: false
```

# Development Priorities

Phase 1 — Minimum Viable Checkout (Basic Order Capture)
Goal: Let customers place an order and see it in their account / admin.

1. Schema setup (use your current tables with small tweaks)
   Add phone_number to orders.
   Keep USD as default currency.
   Store addresses (or even just shipping_address: {city, area, notes}).
2. Frontend (checkout page)
   Simple form: name, email, phone number, address text area.
   Payment method: hard-coded "Cash on Delivery" for now.
3. Backend
   Controller action OrdersController#create that:
   Builds order from current_cart.
   Copies cart items into order_items.
   Clears cart.
   Basic mailer: send confirmation email (or SMS stub).
4. Admin / Dashboard (basic)
   Orders index: order number, status, total, customer name + phone.
   Order show page with line items.

Phase 2 — Operational Enhancements
Goal: Make the workflow easier for staff and scalable.

1. Order statuses
   Add enum/state machine (pending_confirmation, confirmed, canceled, completed).
   Default to pending_confirmation.
   Staff can confirm manually (via admin dashboard).
2. Fulfillment + payment statuses
   fulfillment_status: unfulfilled, shipped, delivered.
   payment_status: pending, cod_due, paid.
3. Better contact info
   Store phone_number explicitly.
   Add validation (must start with +961 or local 03/70/71/etc).
   Cart to Order refactor
4. Extract CartToOrderService that handles:
   Creating order + order_items.
   Copying prices from snapshot.
   Locking exchange rate if needed.

Phase 3 — Customer Experience Upgrades
Goal: Make the checkout modern, reduce friction, build trust.

1. Checkout UX
   Address form split into name, phone, city, area, extra notes.
   Auto-save progress in localStorage or session.
2. Order tracking for customer
   "My Orders" page with statuses (confirmed, shipped, etc).
   Simple public tracking link (order number + email/phone).
3. Wishlist → Notify → Preorder link
   Use "NOTIFY ME" button flow from earlier.
   On order creation, allow "notify when restocked".
4. Confirmation UX
   After placing order:
   Show thank-you page with order summary.
   Option to share order via WhatsApp (Lebanon users love this).

Phase 4 — Multi-Currency & Payment Integrations
Goal: Handle USD/LBP and start automating payments.
1. Exchange rate handling
  Add exchange_rate to orders.
  Store total_usd + total_lbp at checkout.
  Let user choose preferred display.
2. Online payments (optional)
  Integrate with local gateways (e.g., PayFort, PayTabs, or ZainCash).
  Keep COD as primary option.
3. Discounts & promotions
  Add discount_code on orders.
  Introduce promotion_rules table later.

Phase 5 — Operational Scaling
Goal: Support growth, reporting, logistics integration.
1. Courier integrations
  Add delivery_method + courier_name on orders.
  Option to export orders to CSV for couriers.
  Later, API integration with Aramex / Wakilni.
2. Admin features
  Bulk status update (mark 10 orders as "shipped").
  Reports: sales by day, best-selling products, COD collection report.
3. Order notes & tags
  Add staff notes (e.g., "customer asked for evening delivery").
  Tags for segmentation ("VIP", "fraud-risk").

Phase 6 — Advanced Enhancements
Goal: Match modern e-commerce leaders.
1. Split payments (part COD, part online).
2. Partial fulfillment (some items shipped, some backordered).
3. Subscriptions / repeat orders.
4. Multi-store / multi-currency at scale.
5. Analytics integration (GA4, Meta Pixel, server-side tracking).
