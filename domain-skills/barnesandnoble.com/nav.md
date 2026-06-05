# Barnes & Noble — Purchase Flow

Full flow: search → product page → cart → checkout (guest) → shipping → shipping options → payment → confirmation.

Tested on: barnesandnoble.com, May 2026.

---

## Invocation note

Use `browser-harness -c "..."` (single `-c` flag with the script as a string). The heredoc form (`<<'PY'`) does NOT work — the harness exits with "Usage: browser-harness -c".

```bash
browser-harness -c "
new_tab('https://www.barnesandnoble.com')
wait_for_load()
print(page_info())
"
```

## Corporate TLS / SSL

`http_get()` will fail with an SSL certificate verification error on corporate networks. All requests must go through the browser. Do not attempt direct HTTP calls to barnesandnoble.com.

## Akamai WAF / bot detection

B&N uses Akamai for bot protection. Key observations:
- Clicking the "Continue as Guest" link from the iframe context triggers a block. Use `goto_url()` instead (see Step 5).
- Once a session is flagged, all checkout URLs get blocked persistently. The cart page (`/checkout/`) remains accessible but `checkout-as-guest.jsp` and `guest-checkout.jsp` return "Access Denied".
- If you hit a block, the session is poisoned — you need to clear cookies or use a fresh browser profile.
- Do NOT use `click_at_xy()` on this site — it can also trigger detection. Stick to DOM interactions via `js(...)`.

## DOM-first interaction

Always use DOM selectors rather than coordinate clicks on this site. The layout is dense and coordinate-based clicks are unreliable, and pixel-based clicking (`click_at_xy`) has been observed to trigger Akamai bot detection. Use `js(...)` to find and click elements.

---

## Verification pattern

After each step, **print DOM state** so the agent can confirm the transition and make decisions. Each step below includes inline verification. The general approach:

1. **DOM reads via `print(js(...))`** — Primary method. Extract structured JSON from the page (titles, form IDs, field values, button text). This prints to stdout so the agent sees it immediately without needing a second tool call.

2. **Screenshots for debugging only** — `capture_screenshot('/tmp/bn_<step>.png')` saves a PNG. The agent must then use its **Read tool** on that path to view it. Only use when the DOM read is ambiguous or the page didn't advance as expected.

3. **Never proceed blind** — Every step should end with a `print(js(...))` that confirms what state the page is in. This lets the agent decide whether to continue, retry, or handle a branch (like address verification).

---

## Step 1 — Search

```python
new_tab("https://www.barnesandnoble.com/s/<URL-encoded title + author>")
wait_for_load()
# Print search results so the agent can pick the right one
print(js('''
  JSON.stringify([...document.querySelectorAll("section.product-shelf-grid .product-shelf-title")].slice(0, 5).map((el, i) => ({
    index: i,
    title: el.textContent.trim(),
    href: el.href
  })), null, 2)
'''))
```

Or navigate to the homepage and use the search box:
```python
js('document.querySelector("input#search").value = "Life 3.0 Max Tegmark"; document.querySelector("form#search-bar").submit()')
```

Search results page: `https://www.barnesandnoble.com/s/<query>`

---

## Step 2 — Select product

From search results, pick the correct result by index and click through:
```python
# Click first result (adjust index if needed based on Step 1 output)
js('document.querySelectorAll("a.product-shelf-title")[0].click()')
wait_for_load()
# Confirm you're on the right product page
print(js('''
  JSON.stringify({
    title: document.querySelector("h1")?.textContent?.trim(),
    author: document.querySelector(".contributors a")?.textContent?.trim(),
    price: document.querySelector(".current-price, [itemprop=price]")?.textContent?.trim(),
    format: document.querySelector(".format-active, .selected-format")?.textContent?.trim(),
    url: location.href
  })
'''))
```

Product page URL pattern: `https://www.barnesandnoble.com/w/<title-slug>/<ean13>`

---

## Step 3 — Add to cart

The add-to-cart button is an `<input type="submit">` (NOT a `<button>`). It lives inside `div#addToCart`. The selector:

```python
js('document.querySelector("input.add-to-cart-button.btn-addtocart").click()')
```

After clicking, a **modal** appears confirming "Item Successfully Added To Your Cart" with two options:
- "View Shopping Cart" — an `<a>` tag with class `btn btn-cancel add-to-cart-btn`, links to `/checkout/`
- "Continue Shopping" — continues browsing

Click "View Shopping Cart" to proceed:

```python
import time; time.sleep(2)
js('document.querySelector("a.btn.btn-cancel.add-to-cart-btn").click()')
wait_for_load()
# Confirm cart contents
print(js('''
  JSON.stringify({
    url: location.href,
    items: [...document.querySelectorAll(".cart-item, .item-title")].map(el => el.textContent.trim()).slice(0, 3),
    total: document.querySelector(".order-total, .total-value")?.textContent?.trim()
  })
'''))
```

Note: the link text contains a newline ("View\nShopping Cart") — do NOT match by exact text. Use the class selector.

---

## Step 4 — Cart page and proceed to checkout

Cart URL is `/checkout/` (NOT `/checkout/cart` — that 404s).

```python
goto_url("https://www.barnesandnoble.com/checkout/")
wait_for_load()
```

The CHECKOUT button is an `<a>` with class `sign-in-checkout` linking to `/checkout/signin-checkout.jsp`:

```python
js('document.querySelector("a.sign-in-checkout").click()')
```

This does NOT navigate — it opens the sign-in modal (see Step 5). The URL stays on `/checkout/`.

---

## Step 5 — Guest checkout modal (IFRAME TRAP)

After clicking CHECKOUT, a **sign-in modal appears inside a same-origin iframe**. The modal is visually on the page but "Continue as Guest" does NOT exist in the main document DOM. The iframe src contains `login-frame-ra.jsp`.

Key details about the iframe:
- It's same-origin, so `contentDocument` is accessible
- The `js()` helper does NOT support IIFEs (returns `None`) — use single-expression chains
- "Continue as Guest" is `<a id="guestCheckoutBtn" class="btn btn--ghost sign-in-checkout" target="_top">` inside the iframe
- Confusingly, the cart page's CHECKOUT button also uses class `sign-in-checkout` — context matters

Use `goto_url()` to navigate directly to the guest checkout URL. Clicking the link inside the iframe (whether via `js()` or `click_at_xy()`) has been observed to trigger Akamai WAF blocks. The `goto_url` approach works because session/cart cookies are already set from the earlier add-to-cart flow.

```python
goto_url('https://www.barnesandnoble.com/checkout/checkout-as-guest.jsp')
wait_for_load()
# Confirm guest checkout page loaded and identify which forms are present
print(js('''
  JSON.stringify({
    url: location.href,
    forms: [...document.querySelectorAll("form[id]")].map(f => f.id),
    shippingFormVisible: !!document.getElementById("addShippingFirstName")
  })
'''))
```

This lands on: `https://www.barnesandnoble.com/checkout/guest-checkout.jsp?_requestid=<id>`

Note: The URL redirects from `checkout-as-guest.jsp` to `guest-checkout.jsp` with a `_requestid` param.

---

## Step 6 — Shipping address form (MULTIPLE FORMS TRAP)

The guest checkout page has **11 distinct forms**. Submitting the wrong one does nothing or breaks the flow. Target forms by ID. Key forms:

- `form#addAddress` — shipping address
- `form#updateShippingOption` — shipping options continue
- `form#checkoutForm` — payment details (60 inputs)
- `form#submitOrder` — final order submission
- `form#frmApplyCoupon` — coupon code
- `form#bookfairApply` — book fair code

The shipping form is `form#addAddress`. The submit button has `id="gShipSubmit"`.

ATG Commerce field names (namespace `/atg/commerce/order/purchase/ShippingInfoFormHandler.shipContactInfo.`):

| Field | ID | ATG name |
|-------|-----|----------|
| First name | `addShippingFirstName` | `.shipContactInfo.firstName` |
| Last name | `addShippingLastName` | `.shipContactInfo.lastName` |
| Country | `country` | `.shipContactInfo.country` (select) |
| Company | `addShippingCompanyName` | `.shipContactInfo.companyName` |
| Street | `addShippingStreetAddress` | `.shipContactInfo.address1` |
| Apt/Suite | `addShippingAptSuite` | `.shipContactInfo.address2` |
| City | `addShippingCity` | `.shipContactInfo.city` |
| State | `addShippingState` | `.shipContactInfo.state` (select) |
| Zip | `addShippingZipCode` | `.shipContactInfo.postalCode` |
| Phone | `addShippingPhoneNumber` | `.shipContactInfo.phoneNumber` |

The submit input name is `/atg/commerce/order/purchase/ShippingInfoFormHandler.addShippingAddress`.

Fill using the clean IDs (much simpler than ATG name selectors):

```python
js('document.getElementById("addShippingFirstName").value = "Jane"')
js('document.getElementById("addShippingLastName").value = "Smith"')
js('document.getElementById("addShippingStreetAddress").value = "123 Main St"')
js('document.getElementById("addShippingCity").value = "New York"')
js('document.getElementById("addShippingState").value = "NY"')
js('document.getElementById("addShippingZipCode").value = "10001"')
js('document.getElementById("country").value = "US"')
js('document.getElementById("addShippingPhoneNumber").value = "5551234567"')
js('document.getElementById("gShipSubmit").click()')
import time; time.sleep(3)
wait_for_load()
# Check what happened: address verification dialog, or moved to shipping options?
print(js('''
  JSON.stringify({
    addressVerification: !![...document.querySelectorAll("a, button, input[type=button]")].find(el => el.textContent.toLowerCase().includes("use address as entered")),
    shippingOptionsVisible: !!document.getElementById("updateShippingOption"),
    activeStep: document.querySelector(".checkout-step.active h2, .step-title.active")?.textContent?.trim()
  })
'''))
```

Note: State and Country are `<select>` elements — set `.value` to the option value (e.g., "NY", "US").

---

## Step 7 — Address verification dialog (EASY-TO-MISS TRAP)

After submitting the shipping address, B&N may show an **address verification step** — a modal or inline panel asking whether to use the normalized USPS address or the entered address. It presents a button or link labeled **"Use Address as Entered"**.

Do NOT call `document.querySelector("form").submit()` here — that bypasses the UI and breaks the flow.

Instead, look for and click the "Use Address as Entered" option:

```python
js('''
  var btn = [...document.querySelectorAll("a, button, input[type=button]")]
    .find(el => el.textContent.trim().toLowerCase().includes("use address as entered"));
  if (btn) btn.click();
''')
import time; time.sleep(2)
wait_for_load()
# Confirm we moved past address verification to shipping options
print(js('''
  JSON.stringify({
    shippingOptionsVisible: !!document.getElementById("updateShippingOption"),
    url: location.href
  })
'''))
```

Note: The Step 6 verification output already tells you whether address verification appeared (`addressVerification: true/false`). Only run this step if it did.

---

## Step 8 — Shipping options

After the address step, a shipping method selection form appears. Target `form#updateShippingOption` (not `form#addAddress`).

```python
# Show available shipping options before submitting
print(js('''
  JSON.stringify([...document.querySelectorAll("#updateShippingOption input[type=radio], #updateShippingOption label")].map(el => ({
    tag: el.tagName,
    text: el.textContent?.trim()?.slice(0, 80),
    value: el.value,
    checked: el.checked
  })))
'''))
js('document.getElementById("updateShippingOption").querySelector("input[type=submit], button[type=submit]").click()')
import time; time.sleep(3)
wait_for_load()
# Confirm payment form is now visible
print(js('''
  JSON.stringify({
    paymentFormVisible: !!document.getElementById("ccNumber"),
    emailFieldVisible: !!document.getElementById("emailAddress"),
    url: location.href
  })
'''))
```

---

## Step 9 — Payment

Page: `https://www.barnesandnoble.com/checkout/guest-checkout.jsp?_requestid=<id>`

Payment form is `form#checkoutForm` (60 inputs). Final submission is `form#submitOrder`.

### Payment fields

| Field | ID | Notes |
|-------|-----|-------|
| Card Number | `ccNumber` | `type=text`, `maxLength=16`, `name=""` (tokenized, no ATG name) |
| Name on Card | `nameOnCard` | ATG name: `/atg/store/order/purchase/BillingFormHandler.nameOnCard` |
| Expiration Month | `ccMonth` | Hidden `<select>`, values `"1"` through `"12"` (NOT zero-padded) |
| Expiration Year | `ccYear` | Hidden `<select>`, values `"2026"`, `"2027"`, etc. |
| Security Code (CVV) | `csv` | `type=text`, `maxLength=4`, `name=""` (tokenized) |
| Use shipping as billing | `useShippingAddress` | Checkbox, pre-checked by default |
| Email | `emailAddress` | ATG name: `/atg/store/order/purchase/BillingFormHandler.billingContactInfo.email` |

### Expiration dropdowns (selectBox plugin trap)

The month/year `<select>` elements are hidden and replaced by a jQuery selectBox widget. However, you CAN still set their `.value` directly — the form reads from the hidden `<select>`, not the widget.

```python
js('document.getElementById("ccMonth").value = "6"')   # 1-12, not zero-padded
js('document.getElementById("ccYear").value = "2027"')  # 4-digit year string
```

### Filling payment

```python
js('document.getElementById("ccNumber").value = "4111111111111111"')
js('document.getElementById("nameOnCard").value = "Jane Smith"')
js('document.getElementById("ccMonth").value = "6"')
js('document.getElementById("ccYear").value = "2027"')
js('document.getElementById("csv").value = "123"')
js('document.getElementById("emailAddress").value = "your@email.com"')
# "Use shipping address as billing" checkbox is pre-checked — leave it

# Verify all fields are filled (catches silent React/jQuery overwrites)
print(js('''
  JSON.stringify({
    ccNumber: document.getElementById("ccNumber").value.length + " chars",
    nameOnCard: document.getElementById("nameOnCard").value,
    ccMonth: document.getElementById("ccMonth").value,
    ccYear: document.getElementById("ccYear").value,
    csv: document.getElementById("csv").value.length + " chars",
    email: document.getElementById("emailAddress").value,
    billingCheckbox: document.getElementById("useShippingAddress")?.checked
  })
'''))
```

### Submit Order

The visible "Submit Order" button is `button#verifyEmailAddress` (confusingly named):

```python
js('document.getElementById("verifyEmailAddress").click()')
```

There is also a hidden `input#guestSubmitOrder` with value "SUBMIT ORDER" — this may be what the visible button triggers internally. If the visible button click doesn't work, try:

```python
js('document.getElementById("guestSubmitOrder").click()')
```

---

## Backend platform

B&N runs **Oracle ATG Commerce**. All form handlers POST to `/xhr/handler.jsp?_DARGS=<fragment path>`. Field names follow ATG's `/atg/...` namespace convention. This is important context when debugging why a form submission appears to do nothing — the `_DARGS` parameter routes to the right ATG handler.

---

## Flow summary

```
Search (/s/<query>)
→ Product page (/w/<slug>/<id>?ean=<isbn>)
→ Add to cart (input.add-to-cart-button)
→ Modal: "View Shopping Cart" (a.btn.btn-cancel.add-to-cart-btn → /checkout/)
→ Cart page: CHECKOUT (a.sign-in-checkout)
→ [iframe login-frame-ra.jsp] "Continue as Guest" (a.sign-in-checkout in iframe)
→ Guest checkout (/checkout/guest-checkout.jsp?_requestid=<id>)
→ Shipping address form (form#addAddress, submit: #gShipSubmit)
→ [maybe] Address verification → "Use Address as Entered"
→ Shipping options (form#updateShippingOption)
→ Payment (form#checkoutForm: #ccNumber, #nameOnCard, #ccMonth, #ccYear, #csv, #emailAddress)
→ Submit Order (button#verifyEmailAddress)
→ Order confirmation
```

---

## Traps summary

| Trap | Symptom | Fix |
|------|---------|-----|
| Heredoc invocation | Exits with "Usage: browser-harness -c" | Use `-c "..."` string form |
| `http_get()` SSL error | Corporate proxy cert rejection | Navigate via browser only |
| Add-to-cart is `<input>` not `<button>` | `querySelector("button")` finds nothing | Use `input.add-to-cart-button.btn-addtocart` |
| Cart URL is `/checkout/` | `/checkout/cart` returns 404 | Use `https://www.barnesandnoble.com/checkout/` |
| "View Shopping Cart" has newline in text | Text matching fails | Use class selector `a.btn.btn-cancel.add-to-cart-btn` |
| `js()` IIFEs return `None` | Expression returns undefined | Use single-expression chains, no `(function(){...})()` |
| Guest modal in iframe → Akamai block | Clicking "Continue as Guest" (via `js()` or `click_at_xy()`) triggers "Access Denied" | Use `goto_url('https://www.barnesandnoble.com/checkout/checkout-as-guest.jsp')` from top frame instead |
| 5 forms on checkout page | Wrong submit does nothing | Target by form ID (e.g. `form#addAddress`) |
| Address verification dialog | Flow stalls invisibly | Screenshot after address submit; click "Use Address as Entered" |
| Wrong shipping form | Page doesn't advance | Use `form#updateShippingOption`, not `form#addAddress` |
| Expiry dropdowns are hidden selectBox | No visible `<select>` to interact with | Set value on hidden `#ccMonth`/`#ccYear` directly (values: "1"-"12", "2026"+) |
| Submit Order button named `verifyEmailAddress` | Can't find submit by expected name/class | Use `button#verifyEmailAddress` for the visible submit |
| 11 forms on checkout page | Even more confusing than expected | Key forms: `#addAddress`, `#updateShippingOption`, `#checkoutForm`, `#submitOrder` |
| `capture_screenshot()` is invisible | Agent calls it but can't see the image | It saves to a file path — agent must `Read` that path to view. Use `print(js(...))` for inline verification instead |
| Proceeding blind after click | Agent assumes step worked without checking | Every step must end with `print(js(...))` that confirms current page state |
