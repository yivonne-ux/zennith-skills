---
name: gaia-eats-finance
description: Gaia Eats finance ops: track POs/DOs/Invoices/Payments in Google Sheets + Drive; supports vendor follow-ups and matching.
metadata: {"openclaw": {"requires": {"bins": ["python3"]}}}
---

# Gaia Eats Finance Skill

This skill provides a lightweight, file-backed workflow to:
- Register vendors (vendorId)
- Register purchase orders (PO)
- Register delivery orders (DO)
- Register invoices
- Match PO ⇄ DO ⇄ Invoice
- Track payments and outstanding balances
- Prepare vendor follow-up messages (WhatsApp copy) and status summaries

## Storage / State
- Drive folder root: `Gaia Finance` (folderId recorded in `ops/finance_state.md`)
- Local checkpoints:
  - `ops/finance_state.md`
  - `ops/token_policy.md`

## Google Sheets (expected)
Uses these Sheets (IDs stored in `ops/finance_state.md`):
- Finance - Transactions
- Finance - Monthly Summary
- Finance - Vendor Tracker

You may add a dedicated operations sheet later:
- Finance - AP (Accounts Payable)
  - Vendors
  - POs
  - DOs
  - Invoices
  - Payments

## WhatsApp intake conventions
Ask people to send messages in a consistent format (copy/paste):

### New PO
PO: PO-2026-0001
Vendor: <name>
Amount: 123.45 MYR
Due: 2026-02-28
Notes: ...

### New DO
DO: DO-...
PO: PO-...
Date: 2026-...
Notes: ...

### New Invoice
Invoice: INV-...
Vendor: <name>
PO: PO-... (if any)
DO: DO-... (if any)
Amount: 123.45 MYR
Due: 2026-...
Attach: invoice PDF/photo

### Payment made
Payment: PAY-...
Invoice: INV-...
Amount: 123.45 MYR
Date: 2026-...
Method: bank transfer/cash
Reference: ...

## Next steps to finish wiring
1) Decide which sheet will be the source of truth for AP (new sheet recommended).
2) Provide Notion parent page link (optional) to create a Finance hub.
3) Confirm WhatsApp intake chat(s) + default permission model.
