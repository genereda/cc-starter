# thriftbooks.com — Navigation Playbook

Status: COMPLETE (session 2 — full flow verified)

## Core Principle: DOM over Screenshots

Screenshot-based coordinate clicking is unreliable on this site. Use DOM inspection and JS-driven interaction (`js(...)`) for all interactions. Screenshots only for high-level state verification, always wrapped in a timeout:

```python
import signal

def safe_screenshot(name, secs=8):
    def _h(s, f): raise TimeoutError
    signal.signal(signal.SIGALRM, _h)
    signal.alarm(secs)
    try:
        return capture_screenshot(name)
    except TimeoutError:
        print(f"[WARN] screenshot timed out: {name}")
        return None
    finally:
        signal.alarm(0)
```

## URL Patterns

- Homepage: `https://www.thriftbooks.com`
- Search: `https://www.thriftbooks.com/browse/?b.search=<query>#b.s=mostPopular-desc&b.p=1&b.pp=50`
- Cart: `https://www.thriftbooks.com/shopping-cart/`
- Checkout start: `https://www.thriftbooks.com/checkout/`
- Shipping: `https://www.thriftbooks.com/checkout/shipping/`
- Payment (final): `https://www.thriftbooks.com/checkout/payment/`

## Verified Full Flow

### 1. Search and Add to Cart

Search results use `AllEditionsItem-tile` as the book tile wrapper.

```python
# Navigate to search
goto_url("https://www.thriftbooks.com/browse/?b.search=Nexus+Yuval+Noah+Harari#b.s=mostPopular-desc&b.p=1&b.pp=50")
wait_for_load()

# Click Add To Cart on the first matching result
clicked = js("""
  const tiles = document.querySelectorAll('.AllEditionsItem-tile');
  const tile = Array.from(tiles).find(t => t.innerText.includes('Nexus') && t.innerText.includes('Harari'));
  const btn = tile?.querySelector('button');
  btn?.click();
  return btn?.innerText?.trim();
""")
# Verify: cart count updates, button text changes to "Added to Cart"
```

Cart count indicator is found via: `document.querySelector('[class*="cartBadge"]')` or the aria-label on the cart nav element.

### 2. Go to Cart and Proceed to Checkout

```python
goto_url("https://www.thriftbooks.com/shopping-cart/")
wait_for_load()
# Verify cart items with ShoppingCartItem-title links
# Click "Proceed to Checkout"
js("document.querySelector('.ShoppingCart-proceedButton')?.click()")
wait_for_load()
# → navigates to https://www.thriftbooks.com/checkout/
```

### 3. Guest Checkout

The checkout start page has two sections: "Returning Customers" (login) and "New Customers" (guest or new account).

**Key checkbox:** `GuestSignIn_CreateAnAccount` — must be **unchecked** for guest checkout.

```python
# Uncheck "Create an account" checkbox
js("document.getElementById('GuestSignIn_CreateAnAccount')?.click()")

# Fill email fields (standard .value setter works here — not React-controlled)
js("""
  document.getElementById('GuestSignIn_EmailAddress').value = 'user@example.com';
  document.getElementById('GuestSignIn_ConfirmEmail').value = 'user@example.com';
  document.getElementById('GuestSignIn_EmailAddress').dispatchEvent(new Event('input', {bubbles:true}));
  document.getElementById('GuestSignIn_ConfirmEmail').dispatchEvent(new Event('input', {bubbles:true}));
""")

# Click Continue (the one in the New Customers section)
js("""
  Array.from(document.querySelectorAll('input[type=submit]'))
    .find(b => b.value === 'Continue')?.click();
""")
wait_for_load()
# → navigates to https://www.thriftbooks.com/checkout/shipping/
```

### 4. Shipping Address

**React-controlled inputs** — must use the native input value setter, not `.value =`:

```python
def react_type(element_id, text):
    return js(f"""
      const el = document.getElementById('{element_id}');
      const setter = Object.getOwnPropertyDescriptor(window.HTMLInputElement.prototype, 'value').set;
      setter.call(el, '{text}');
      el.dispatchEvent(new Event('input', {{ bubbles: true }}));
      el.dispatchEvent(new Event('change', {{ bubbles: true }}));
      return el.value;
    """)

def react_select(element_id, value):
    return js(f"""
      const el = document.getElementById('{element_id}');
      const setter = Object.getOwnPropertyDescriptor(window.HTMLSelectElement.prototype, 'value').set;
      setter.call(el, '{value}');
      el.dispatchEvent(new Event('change', {{ bubbles: true }}));
      return el.value;
    """)
```

Field IDs: `country` (select, default USA=17), `firstName`, `lastName`, `organization` (optional), `addressLine1`, `addressLine2`, `city`, `state` (select), `postalCode`, `phoneNumber` (optional).

**Address validation:** The site calls `/api/checkout/VerifyAddressSmarty` on form submit. Possible responses:

- `NOT_FOUND` — address doesn't exist (stays on page, no dialog)
- `BAD_SECONDARY` — valid address but needs apt/unit number → triggers a modal

**Address verification modal** (class `ReactModalPortal`):

- "Use Unverified Address" (class `BasicModal-Button Outlined`) — proceeds anyway
- "Edit Address" — closes modal, returns to form

```python
# After clicking "Continue to Payment", handle possible modal
import time
time.sleep(3)
if page_info()['url'].endswith('/shipping/'):
    # Check for address verify modal — click "Use Selected Address" (NOT Cancel/.Outlined)
    use_selected = js("""
      const portal = document.querySelector('.ReactModalPortal');
      const btn = Array.from(portal?.querySelectorAll('button') || [])
        .find(b => b.innerText.includes('Use Selected'));
      btn?.click();
      return btn?.innerText?.trim();
    """)
    if use_selected:
        print("Clicked:", use_selected)
        time.sleep(2)
        wait_for_load()
```

### 5. Payment Page (Final Checkout)

URL: `https://www.thriftbooks.com/checkout/payment/`

Page sections: "Payment Method", "Order Details", "Use a Promo Code", "Order Summary".

**Braintree hosted fields** — card inputs live in three separate cross-origin iframes. Cannot use DOM selectors inside them. Use coordinate clicks + `type_text()` (pre-imported helper):

```python
import time

# Iframe positions (viewport coords, may shift if page layout changes — re-measure with getBoundingClientRect if needed)
# braintree-hosted-field-number:         x=326, y=350
# braintree-hosted-field-cvv:            x=181, y=406
# braintree-hosted-field-expirationDate: x=470, y=406

def fill_braintree_field(x, y, text):
    click_at_xy(x, y)
    time.sleep(0.6)
    type_text(text)
    time.sleep(0.4)

fill_braintree_field(326, 350, "4111111111111111")  # card number (Visa test)
fill_braintree_field(181, 406, "123")               # CVV
fill_braintree_field(470, 406, "12/26")             # expiry

# Verify all valid
states = js("""
  return Array.from(document.querySelectorAll('[class*="braintree-hosted-fields"]'))
    .map(el => el.className);
""")
# Each should contain "braintree-hosted-fields-valid"
```

To get current iframe positions dynamically:

```python
rects = js("""
  return ['braintree-hosted-field-number','braintree-hosted-field-expirationDate','braintree-hosted-field-cvv']
    .map(id => { const r = document.getElementById(id)?.getBoundingClientRect();
      return r ? { id, x: Math.round(r.left+r.width/2), y: Math.round(r.top+r.height/2) } : { id, error:'not found' }; });
""")
```

After filling, "Continue to Order Review" button (class `Button`) becomes clickable.  
**Do not click it in test/exploration runs** — it submits a real order.

## Gotchas

- **Cart persists across sessions** — session cookies survive; don't re-add books that are already in cart. Check cart count first.
- **`execCommand('insertText')` partially works** — updates DOM `.value` but not React fiber state; use `nativeInputValueSetter` instead.
- **Address modal is hidden until submit** — the `ReactModal__Overlay` has `visible: False` in DOM (CSS hidden) but `ReactModalPortal` is `visible: True`. Query `.ReactModalPortal` to check for modal content.
- **XHR intercept useful for debugging validation** — intercept `XMLHttpRequest` to see what the address API returns when the form won't advance.
- **JS variable redeclaration** — using `const` across sequential `js()` calls can cause `SyntaxError: Identifier already declared`. Use `let`, IIFE `(function(){...})()`, or rename vars between calls.
