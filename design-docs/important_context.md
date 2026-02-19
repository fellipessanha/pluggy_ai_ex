# Pluggy API - Important Context

This file captures all the context gathered during the design session for building the `pluggy_ai` Elixir library. Use this to resume work.

---

## 1. API Basics

- **Base URL**: `https://api.pluggy.ai`
- **Documentation**: https://docs.pluggy.ai/reference/
- **OpenAPI Spec**: https://api.pluggy.ai/oas3.json (also downloaded to `./oas3.json`)
- **Auth**: POST `/auth` with `{clientId, clientSecret}` -> returns `{apiKey}` in response body
- **Auth header**: `X-API-KEY: <apiKey>` on all subsequent requests
- **API key TTL**: 2 hours
- **Connect token TTL**: 30 minutes
- **Response format**: JSON with camelCase keys
- **Pluggy Connect Widget CDN**: `https://cdn.pluggy.ai/pluggy-connect/v2.8.2/pluggy-connect.js`

---

## 2. Complete API Endpoint Listing

### Auth
| Method | Path | Required Params | Body Fields |
|--------|------|----------------|-------------|
| POST | /auth | - | clientId, clientSecret |
| POST | /connect_token | - | itemId?, options? |

### Connectors
| Method | Path | Required Params | Body/Query |
|--------|------|----------------|------------|
| GET | /connectors | - | query: countries, types, name, sandbox, healthDetails, isOpenFinance, supportsPaymentInitiation, supportsSmartTransfers, supportsAutomaticPix |
| GET | /connectors/{id} | id (number, path) | query: healthDetails |
| POST | /connectors/{id}/validate | id (number, path) | body: ItemParameter |

### Items
| Method | Path | Required Params | Body |
|--------|------|----------------|------|
| POST | /items | - | connectorId, parameters, webhookUrl, products, clientUserId, avoidDuplicates, oauthRedirectUri |
| GET | /items/{id} | id (UUID, path) | - |
| PATCH | /items/{id} | id (UUID, path) | webhookUrl, clientUserId, parameters, products |
| DELETE | /items/{id} | id (UUID, path) | - |
| POST | /items/{id}/mfa | id (UUID, path) | key-value MFA params |
| PATCH | /items/{id}/disable-auto-sync | id (UUID, path) | - |

### Consents
| Method | Path | Required Params | Query |
|--------|------|----------------|-------|
| GET | /consents | - | itemId (required) |
| GET | /consents/{id} | id (UUID, path) | - |

### Accounts
| Method | Path | Required Params | Query |
|--------|------|----------------|-------|
| GET | /accounts | - | itemId (required), type (BANK\|CREDIT, optional) |
| GET | /accounts/{id} | id (path) | - |
| GET | /accounts/{id}/statements | id (path) | - |

### Transactions
| Method | Path | Required Params | Query |
|--------|------|----------------|-------|
| GET | /transactions | - | accountId (required), ids, from, to, pageSize (1-500), page, billId, createdAtFrom |
| GET | /transactions/{id} | id (UUID, path) | - |
| PATCH | /transactions/{id} | id (UUID, path) | body: categoryId |

### Investments
| Method | Path | Required Params | Query |
|--------|------|----------------|-------|
| GET | /investments | - | itemId (required), type, pageSize, page |
| GET | /investments/{id} | id (UUID, path) | - |
| GET | /investments/{id}/transactions | id (UUID, path) | pageSize, page |

### Identity
| Method | Path | Required Params | Query |
|--------|------|----------------|-------|
| GET | /identity | - | itemId (required) |
| GET | /identity/{id} | id (UUID, path) | - |

### Webhooks
| Method | Path | Required Params |
|--------|------|----------------|
| GET | /webhooks | - |
| POST | /webhooks | body (schema not detailed in OAS) |
| GET | /webhooks/{id} | id (path) |
| PATCH | /webhooks/{id} | id (path), body |
| DELETE | /webhooks/{id} | id (path) |

### Categories
| Method | Path | Required Params | Query/Body |
|--------|------|----------------|------------|
| GET | /categories | - | query: parentId |
| GET | /categories/{id} | id (path) | - |
| GET | /categories/rules | - | - |
| POST | /categories/rules | - | body: categoryId, description, matchType, transactionType, accountType |

### Loans
| Method | Path | Required Params | Query |
|--------|------|----------------|-------|
| GET | /loans | - | itemId (required) |
| GET | /loans/{id} | id (path) | - |

### Merchants
| Method | Path | Required Params | Query |
|--------|------|----------------|-------|
| GET | /merchants | - | cnpjs |

### Bills
| Method | Path | Required Params | Query |
|--------|------|----------------|-------|
| GET | /bills | - | accountId (required) |
| GET | /bills/{id} | id (path) | - |

### Payment Customers
| Method | Path | Required Params | Query/Body |
|--------|------|----------------|------------|
| GET | /payments/customers | - | query: pageSize, page, name, email, cpf, cnpj |
| POST | /payments/customers | - | body: name, email, cpf, cnpj, type, connectorId |
| GET | /payments/customers/{id} | id (path) | - |
| PATCH | /payments/customers/{id} | id (path) | body: name, email, cpf, cnpj, type, id |
| DELETE | /payments/customers/{id} | id (path) | - |

### Payment Recipients
| Method | Path | Required Params | Query/Body |
|--------|------|----------------|------------|
| GET | /payments/recipients | - | query: pageSize, page, isDefault, pixKey, name |
| POST | /payments/recipients | - | body: name, taxNumber, paymentInstitutionId, account |
| GET | /payments/recipients/{id} | id (path) | - |
| PATCH | /payments/recipients/{id} | id (path) | body: name, taxNumber, paymentInstitutionId, account |
| DELETE | /payments/recipients/{id} | id (path) | - |

### Payment Recipient Institutions
| Method | Path | Required Params | Query |
|--------|------|----------------|-------|
| GET | /payments/recipients/institutions | - | pageSize, page, name |
| GET | /payments/recipients/institutions/{id} | id (path) | - |

### Payment Requests
| Method | Path | Required Params | Body |
|--------|------|----------------|------|
| GET | /payments/requests | - | query: pageSize, page, from, to, customer, pixKey |
| POST | /payments/requests | - | body: amount, description, recipientId, customerId, callbackUrls, clientPaymentId, isSandbox, schedule |
| POST | /payments/requests/pix-qr | - | body: customerId, pixQrCode, callbackUrls, isSandbox |
| GET | /payments/requests/{id} | id (path) | - |
| PATCH | /payments/requests/{id} | id (path) | body: amount, description, recipientId, customerId, callbackUrls, clientPaymentId, isSandbox |
| DELETE | /payments/requests/{id} | id (path) | - |

### Payment Schedules
| Method | Path | Required Params |
|--------|------|----------------|
| GET | /payments/requests/{id}/schedules | id (path) |
| POST | /payments/requests/{id}/schedules/cancel | id (path) |
| POST | /payments/requests/{id}/schedules/{scheduleId}/cancel | id, scheduleId (path) |

### Automatic PIX
| Method | Path | Required Params | Body |
|--------|------|----------------|------|
| POST | /payments/requests/automatic-pix | - | body: customerId, recipientId, description, fixedAmount, startDate, interval, expiresAt, firstPayment, isRetryAccepted, maximumVariableAmount, minimumVariableAmount, callbackUrls, clientPaymentId |
| POST | /payments/requests/{id}/automatic-pix/schedule | id (path) | body: amount, date, description, recipientId, clientPaymentId |
| GET | /payments/requests/{id}/automatic-pix/schedules | id (path) | - |
| GET | /payments/requests/{requestId}/automatic-pix/schedules/{paymentId} | requestId, paymentId (path) | - |
| POST | /payments/requests/{id}/automatic-pix/cancel | id (path) | - |
| POST | /payments/requests/{id}/automatic-pix/schedules/{scheduleId}/cancel | id, scheduleId (path) | - |
| POST | /payments/requests/{id}/automatic-pix/schedules/{scheduleId}/retry | id, scheduleId (path) | body: date |

### Payment Intents
| Method | Path | Required Params | Body/Query |
|--------|------|----------------|------------|
| POST | /payments/intents | - | body: paymentRequestId, connectorId, parameters, paymentMethod, isDynamicPix |
| GET | /payments/intents | - | query: paymentRequestId (required) |
| GET | /payments/intents/{id} | id (path) | - |

### Smart Transfers
| Method | Path | Required Params | Body/Query |
|--------|------|----------------|------------|
| GET | /smart-transfers/preauthorizations | - | query: pageSize, page |
| POST | /smart-transfers/preauthorizations | - | body: connectorId, parameters, recipientIds, configuration, callbackUrls, clientPreauthorizationId |
| GET | /smart-transfers/preauthorizations/{id} | id (path) | - |
| POST | /smart-transfers/payments | - | body: preauthorizationId, amount, description, recipientId, clientPaymentId |
| GET | /smart-transfers/payments/{id} | id (path) | - |

### Boleto Management
| Method | Path | Required Params | Body |
|--------|------|----------------|------|
| POST | /boleto-connections | - | body: connectorId, credentials |
| POST | /boleto-connections/from-item | - | body: itemId |
| POST | /boletos | - | body: boletoConnectionId, boleto |
| GET | /boletos/{id} | id (path) | - |
| POST | /boletos/{id}/cancel | id (path) | - |

---

## 3. Request Body Schemas (fields from OAS)

```
AuthRequest:               clientId, clientSecret
ConnectTokenRequest:       itemId, options
CreateItem:                connectorId, parameters, webhookUrl, products, clientUserId, avoidDuplicates, oauthRedirectUri
UpdateItem:                webhookUrl, clientUserId, parameters, products
UpdateTransaction:         categoryId
CreateClientCategoryRule:  categoryId, description, matchType, transactionType, accountType
CreatePaymentRequest:      amount, description, recipientId, customerId, callbackUrls, clientPaymentId, isSandbox, schedule
CreatePixQrPaymentRequest: customerId, pixQrCode, callbackUrls, isSandbox
UpdatePaymentRequest:      amount, description, recipientId, customerId, callbackUrls, clientPaymentId, isSandbox
CreatePaymentIntent:       paymentRequestId, connectorId, parameters, paymentMethod, isDynamicPix
CreatePaymentCustomer:     name, email, cpf, cnpj, type, connectorId
UpdatePaymentCustomer:     name, email, cpf, cnpj, type, id
CreatePaymentRecipient:    name, taxNumber, paymentInstitutionId, account
UpdatePaymentRecipient:    name, taxNumber, paymentInstitutionId, account
CreateSmartTransferPreauth: connectorId, parameters, recipientIds, configuration, callbackUrls, clientPreauthorizationId
CreateSmartTransferPayment: preauthorizationId, amount, description, recipientId, clientPaymentId
CreateBoletoConnection:    connectorId, credentials
CreateBoletoConnFromItem:  itemId
CreateBoleto:              boletoConnectionId, boleto
CreateAutomaticPixReq:     customerId, recipientId, description, fixedAmount, startDate, interval, expiresAt, firstPayment, isRetryAccepted, maximumVariableAmount, minimumVariableAmount, callbackUrls, clientPaymentId
ScheduleAutomaticPix:      amount, date, description, recipientId, clientPaymentId
RetryAutomaticPix:         date
```

---

## 4. Original Notebook Flow (pluggy_poc.livemd)

The original Livebook POC does:
1. Create base Req client with base URL + JSON headers
2. POST /auth to get apiKey
3. Build authorized Req client with X-API-KEY header
4. GET /connectors, filter/simplify results
5. POST /connect_token to get widget token
6. Render Pluggy Connect widget via Kino.JS.Live (PluggyKino module)
7. Capture item data from widget's onSuccess callback
8. GET /accounts?itemId=... to list accounts
9. GET /transactions?accountId=... for each account
10. Flatten and analyze transaction data (donations analysis)

Key issues in the original:
- Item data stored only in Kino.JS.Live process state (lost when widget goes out of scope)
- No token refresh handling
- No error handling
- Inline module definition (PluggyKino)

---

## 5. User Decisions

- **Library location**: `~/repos/pluggy_ai_ex`
- **Package name**: `pluggy_ai`
- **Module prefix**: `Pluggy`
- **Key handling**: Convert all API response keys from camelCase to snake_case atoms
- **Session**: Plain GenServer, no supervision opinions (user manages lifecycle)
- **One session = one item**: Connect token produces a single item connection
- **Data analysis**: Application-level concern, not part of the library
- **Kino widget**: Important, must be present as optional dep
- **Phoenix widget**: Also desired as optional dep (LiveComponent + JS hook)

---

## 6. Files in This Directory

- `pluggy_poc.livemd` - Original Livebook POC
- `oas3.json` - Downloaded OpenAPI 3 spec (430KB)
- `oas3_endpoints.json` - Extracted endpoint details (method, path, params, body/response refs)
- `design_docs.md` - Full architecture and module design
- `important_context.md` - This file
