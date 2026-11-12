# Insights: where the Google Merchandise Store loses buyers

**Data:** GA4 BigQuery export sample (`bigquery-public-data.ga4_obfuscated_sample_ecommerce`), 1 Nov 2020 to 31 Jan 2021.
**Scope:** 360,129 sessions from 270,154 users, 4,848 sessions with a purchase, $362k revenue.
All numbers come from the queries in [`/sql`](../sql), and the raw output is in [`/data`](../data).

A session here is `user_pseudo_id` + `ga_session_id`. Unless I say otherwise, a funnel step counts any session that fired that event, in any order.

---

## TL;DR

1. **56% of sessions that start checkout don't finish.** 11,106 sessions hit `begin_checkout` and only 4,848 bought.
2. **Most of that loss is between shipping and payment.** Almost everyone who starts checkout enters shipping info, but only 61% get as far as `add_payment_info`. Once payment info is in, 71% complete.
3. **It isn't a mobile problem.** Checkout completion is 43.0% on desktop, 44.5% on mobile and 43.3% on tablet. Fixing a "bad mobile checkout" wouldn't move much here.
4. **Returning visitors convert ~7x better than first visits** (4.69% for a 4th+ session vs 0.68% for a 1st). First sessions are 73% of traffic, though.
5. **Referral traffic converts ~50% better than organic** (1.66% vs 1.10%). Paid search (cpc) is the weakest real channel at 0.98% and $0.58 revenue per session.
6. **Conversion more than halves over the holidays:** 1.81% for 1-20 Dec, then 0.76% from 21 Dec to 18 Jan. Traffic stays about the same, so people are browsing but not buying (probably shipping cut-offs).

---

## 1. The funnel

| Step | Sessions | % of all sessions | % of previous step |
|---|---:|---:|---:|
| Session | 360,129 | 100% | - |
| view_item | 77,020 | 21.4% | 21.4% |
| add_to_cart | 15,188 | 4.2% | 19.7% |
| begin_checkout | 11,106 | 3.1% | 73.1% |
| add_shipping_info | 11,105 | 3.1% | ~100% |
| add_payment_info | 6,815 | 1.9% | 61.4% |
| purchase | 4,848 | 1.3% | 71.1% |

The biggest drop in absolute terms is at the top: **79% of sessions never open a product page.** Some of that is normal (people landing on the homepage and bouncing), but it's still the largest pool of lost users.

Inside checkout, the shipping step stands out. `begin_checkout` and `add_shipping_info` are nearly identical (11,106 vs 11,105), which tells me shipping info is probably fired on the same page load as checkout start. The real decision point is **after the user sees shipping options and costs**: 39% leave before entering payment details. That's where I'd look first (shipping price, delivery times, forced account creation).

**What I'd test:** show shipping costs on the product or cart page so there's no surprise at checkout, and A/B test a free-shipping threshold.

## 2. Device

| Device | Sessions | Add to cart | Started checkout | Purchased | Checkout completion |
|---|---:|---:|---:|---:|---:|
| Desktop | 208,942 | 4.2% | 3.06% | 1.32% | 43.0% |
| Mobile | 143,185 | 4.2% | 3.12% | 1.39% | 44.5% |
| Tablet | 8,002 | 4.0% | 3.00% | 1.30% | 43.3% |

I expected mobile to be worse, since it usually is. Here it's slightly *better*. So the checkout leak above is about the offer or the flow itself, not about screen size.

## 3. New vs returning

| Session number | Sessions | Add to cart | Conversion |
|---|---:|---:|---:|
| 1st | 261,238 | 3.4% | 0.68% |
| 2nd-3rd | 65,111 | 5.4% | 2.28% |
| 4th+ | 33,780 | 8.4% | 4.69% |

Getting people back is worth a lot. A first visit converts at 0.68%, and a second or third visit is already over 3x that. Since 73% of sessions are first visits, even a small lift in return rate (email capture, remarketing, a "save your cart" prompt) would have a big effect.

## 4. Channels (first touch)

| Medium | Share of sessions | Conversion | Revenue / session |
|---|---:|---:|---:|
| organic | 34.1% | 1.10% | $0.85 |
| (none) / direct | 23.2% | 1.29% | $0.95 |
| referral | 17.6% | 1.66% | $1.31 |
| cpc | 4.3% | 0.98% | $0.58 |

*`(data deleted)` and `<Other>` are anonymised buckets in the sample, so I left them out of the table. They're still in the CSV.*

Referral visitors are worth ~1.5x an organic visitor per session. Paid search brings the least value per session, which would be worth checking against what's being spent on it.

Caveat: `traffic_source.medium` in the export is the user's **first** touch, not the session's source, so this isn't last-click attribution.

## 5. Seasonality

| Period | Sessions | Conversion |
|---|---:|---:|
| November | 108,401 | 1.49% |
| 1-20 Dec | 98,645 | 1.81% |
| 21 Dec - 18 Jan | 102,873 | 0.76% |
| 19-31 Jan | 50,210 | 1.33% |

Traffic barely changes over the holidays, but conversion falls by 58%. My guess is people still browse but know a gift won't arrive in time. A clear "order by X for Christmas delivery" banner in early December and a January sale could both help.

## 6. Data quality notes

Worth knowing before trusting any of this:

- **41% of purchase sessions skip at least one funnel event.** In the strict funnel (every step in order), only 2,848 of 4,848 purchasing sessions qualify. The gap opens at `begin_checkout`: only 5,959 of the 11,106 checkout sessions also have a `view_item` and `add_to_cart` in the same session. Most likely these are people who added to cart in an earlier session and came back to buy. That's why I use the "any order" funnel above.
- **Item-level purchase data is incomplete.** In `05_product_performance` the cart-to-purchase rates per product come out at 0-2%, which doesn't match the 32% at session level. I think this is the obfuscation (purchase items not matching the names used in view/cart events), but I haven't confirmed it. Either way, I only trust view-to-cart at product level.
- **Revenue is missing for the last few days of January** (e.g. $0 on 31 Jan with 18 purchasing sessions), so revenue totals are slightly understated.
- This is Google's **obfuscated** sample, so some values are deliberately scrambled. The *method* carries over to a real GA4 export: point `scripts/run_queries.py` at your own `analytics_XXXX.events_*` table.

---

## If I owned this store, I'd do this first

1. **Fix the shipping-to-payment drop** (39% lost). Show shipping costs before checkout and test a free-shipping threshold.
2. **Capture first-time visitors.** Use email or cart reminders so more of them come back for the session where they actually buy.
3. **Move budget from cpc toward referral/partnerships**, after checking what cpc actually costs.
4. **Plan for the post-Christmas dip** with delivery cut-off messaging in December and a January promotion.
