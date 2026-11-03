# OLX Buy & Sell — Problem Understanding

## 1. Project Overview

OLX is a used-goods marketplace where users post advertisements, communicate with buyers, negotiate prices, and complete transactions. The database must support fast customer-facing operations as well as reporting, analytics, moderation, and future growth.

## 2. Business Problems and Stakeholders

| Problem | Business Requirement | Stakeholder | Classification |
|---|---|---|---|
| P1 — Browse and Search | Quickly find active advertisements using price, car details, and location filters. | Buyers | Customer-facing / Real-time |
| P2 — Ad Management | Load ad pages, display My Ads, post advertisements, and update their status efficiently. | Sellers | Customer-facing / Real-time |
| P3 — Chat System | Load chat inboxes, display unread message counts, and send messages quickly. | Buyers and Sellers | Customer-facing / Real-time |
| P4 — Moderation | Quickly identify reported advertisements, spam activity, and duplicate listings. | Trust & Safety / Moderation | Customer-facing / Real-time |
| P5 — Boost Package Analysis | Identify boost packages that have never been purchased and support monetisation decisions. | Monetisation Team | Reporting / Analytics |
| P6 — Category Insights | Calculate price guides, selling time, offer acceptance rates, and seller responsiveness. | Category Managers | Reporting / Analytics |
| P7 — Growth and Platform Operations | Generate growth reports, process reminders and nightly jobs, and prepare the database for 20× data growth. | Growth / Platform Team | Reporting / Analytics and Batch Processing |

## 3. Assumptions

1. A user can act as both a buyer and a seller.
2. Each advertisement belongs to a seller and a category.
3. Advertisements remain active for 30 days unless sold or removed.
4. A buyer can save advertisements to favourites, send offers, report suspicious advertisements, and communicate with sellers.
5. Chat conversations are associated with advertisements and involve a buyer and the corresponding seller.
6. Boost packages are optional and may be purchased for advertisements.
7. Seller ratings are submitted after a deal.
8. The database should support future growth of approximately 20 times the current data volume.

## 4. Conclusion

The OLX database must provide efficient real-time operations for buyers, sellers, and moderation teams while supporting analytical reports and large-scale data processing. A well-designed schema and appropriate query optimization will help meet these requirements.