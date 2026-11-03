# OLX Buy & Sell — Schema Design

## 1. Database Overview

The OLX Buy & Sell database is designed to support users, advertisements, categories, cities, boost packages, conversations, messages, offers, favourites, reports, and seller ratings.

The database contains 11 relational tables based on the supplied CSV seed data. The schema uses primary keys, foreign keys, unique constraints, NOT NULL constraints, and CHECK constraints to maintain data integrity.

All tables will be created inside the PostgreSQL schema `olx`.

## 2. Tables and Relationships

The database contains the following 11 tables:

1. `cities`
2. `categories`
3. `boost_packages`
4. `users`
5. `listings`
6. `chat_threads`
7. `chat_messages`
8. `offers`
9. `favourites`
10. `reports`
11. `seller_ratings`

### Relationship summary

| Parent table | Child table | Relationship |
|---|---|---|
| cities | users | One-to-Many |
| cities | listings | One-to-Many |
| categories | listings | One-to-Many |
| categories | categories | Self-referencing One-to-Many |
| boost_packages | listings | One-to-Many, optional on listing |
| users | listings | One-to-Many |
| listings | chat_threads | One-to-Many |
| users | chat_threads | One-to-Many as buyer |
| chat_threads | chat_messages | One-to-Many |
| users | chat_messages | One-to-Many as sender |
| listings | offers | One-to-Many |
| users | offers | One-to-Many as buyer |
| users | favourites | One-to-Many |
| listings | favourites | One-to-Many |
| listings | reports | One-to-Many |
| users | reports | One-to-Many as reporter |
| users | seller_ratings | One-to-Many as seller |
| users | seller_ratings | One-to-Many as rater |
| listings | seller_ratings | One-to-Many |

## 3. Primary Keys

| Table | Primary key |
|---|---|
| cities | `city_id` |
| categories | `category_id` |
| boost_packages | `package_id` |
| users | `user_id` |
| listings | `listing_id` |
| chat_threads | `thread_id` |
| chat_messages | `message_id` |
| offers | `offer_id` |
| favourites | `(user_id, listing_id)` |
| reports | `report_id` |
| seller_ratings | `rating_id` |

The `favourites` table uses a composite primary key because a user should not save the same listing more than once.

## 4. Important NULL and Data-Type Decisions

- `categories.parent_id` is nullable because top-level categories do not have a parent.
- `users.email` is nullable because 24,885 records have empty email values.
- `listings.description` is nullable because 23,737 records have empty descriptions.
- `listings.boost_package_id` is nullable because boost packages are optional.
- `listings.sold_at` is nullable because not every listing has been sold.
- `offers.responded_at` is nullable because some offers have not received a response.
- `seller_ratings.comment` is nullable because written feedback is optional.
- `listings.attributes` will use PostgreSQL `JSONB` because all 120,000 supplied values are valid JSON objects.
- Timestamp columns will use `TIMESTAMPTZ` because the supplied timestamps include timezone offsets.
- Price-related columns will use `NUMERIC` to preserve decimal precision.
- Boolean CSV values `t` and `f` will be stored using PostgreSQL `BOOLEAN`.

## 5. CHECK Constraint Decisions

The following checks are based on the supplied seed data and business rules:

1. Listing price must be non-negative.
2. Offer price must be non-negative.
3. Boost package price must be non-negative.
4. Boost package duration must be positive.
5. Listing image count must be non-negative.
6. Listing view count must be non-negative.
7. Listing latitude must be between -90 and 90.
8. Listing longitude must be between -180 and 180.
9. Seller rating stars must be between 1 and 5.
10. Listing item condition must be one of `FAIR`, `GOOD`, `LIKE_NEW`, or `NEW`.
11. Listing status must be one of `ACTIVE`, `EXPIRED`, `REMOVED`, or `SOLD`.
12. Offer status must be one of `ACCEPTED`, `COUNTERED`, `PENDING`, or `REJECTED`.
13. Report reason must be one of `ALREADY_SOLD`, `FRAUD`, `OFFENSIVE`, `SPAM`, or `WRONG_CATEGORY`.
14. Report status must be one of `ACTIONED`, `DISMISSED`, or `OPEN`.

Boolean columns will use the PostgreSQL BOOLEAN data type, which already restricts values to true and false.

## 6. Data Validation Results

The supplied CSV files were inspected before schema creation.

| Validation | Result |
|---|---|
| CSV record counts | All 11 files match expected counts |
| Primary key uniqueness | All proposed keys passed |
| Favourites composite key | No duplicate combinations |
| Foreign-key reference checks | All 18 proposed checks passed |
| JSON validation | All 120,000 listing attributes are valid JSON objects |
| NULL analysis | Empty values identified in seven columns |
| Status and condition values | Distinct values inspected |
| Numeric ranges | Minimum and maximum values inspected |

## 7. Normalization

The database is designed to follow Third Normal Form (3NF).

- Each table represents a distinct entity or relationship.
- Each table has a primary key.
- Non-key attributes depend on the key, the whole key, and nothing but the key.
- City names and states are stored in the `cities` table rather than repeated as descriptive attributes in users and listings.
- Category names and hierarchy are stored in the `categories` table.
- Boost package details are separated from listings.
- Favourites use a composite primary key.

Detailed functional dependencies and normalization analysis will be documented for each table.

## 8. Derived and Potentially Redundant Columns

- `listings.view_count` is a stored counter. It may be updated as views occur rather than calculated from a separate view-event table.
- `seller_ratings.seller_id` may be derivable through the listing's seller, but it is retained in the supplied dataset.
- The seller associated with a chat thread may be derived through its listing, so storing the seller again in `chat_threads` would be redundant.
- `listings.attributes` stores category-specific properties in JSON format rather than requiring separate columns for every possible product attribute.

## 9. Conclusion

The proposed schema is based on the supplied 11 CSV files and their actual data. It aims to preserve the existing records while maintaining referential integrity, enforcing business rules, and supporting future query optimization and scalability.

## 10. Detailed Data Dictionary

### 10.1 Cities

| Column | PostgreSQL Type | Constraints | Description |
|---|---|---|---|
| city_id | INTEGER | PRIMARY KEY, NOT NULL | Unique identifier for each city |
| city_name | VARCHAR(100) | NOT NULL | Name of the city |
| state | VARCHAR(100) | NOT NULL | State in which the city is located |

**Functional Dependency:**

city_id → city_name, state

**Normalization:** The table is in 3NF because city_id uniquely determines all non-key attributes, and no non-key attribute determines another non-key attribute.

### 10.2 Categories

| Column | PostgreSQL Type | Constraints | Description |
|---|---|---|---|
| category_id | INTEGER | PRIMARY KEY, NOT NULL | Unique identifier for each category |
| category_name | VARCHAR(100) | NOT NULL | Name of the category |
| parent_id | INTEGER | NULL allowed, FOREIGN KEY REFERENCES categories(category_id) | Parent category identifier |

**Functional Dependency:**

category_id → category_name, parent_id

**Normalization:** The table is in 3NF because category_id determines all non-key attributes. The self-referencing parent_id represents the category hierarchy.

**Design note:** parent_id is nullable because top-level categories do not have a parent.

### 10.3 Boost Packages

| Column | PostgreSQL Type | Constraints | Description |
|---|---|---|---|
| package_id | INTEGER | PRIMARY KEY, NOT NULL | Unique identifier for each boost package |
| package_name | VARCHAR(100) | NOT NULL | Name of the boost package |
| price | NUMERIC(10,2) | NOT NULL, CHECK (price >= 0) | Price of the boost package |
| duration_days | INTEGER | NOT NULL, CHECK (duration_days > 0) | Number of days the boost package remains active |

**Functional Dependency:**

package_id → package_name, price, duration_days

**Normalization:** The table is in 3NF because package_id uniquely determines all non-key attributes, and there are no partial or transitive dependencies.

### 10.4 Users

| Column | PostgreSQL Type | Constraints | Description |
|---|---|---|---|
| user_id | INTEGER | PRIMARY KEY, NOT NULL | Unique identifier for each user |
| full_name | VARCHAR(150) | NOT NULL | Full name of the user |
| phone | VARCHAR(20) | UNIQUE, NOT NULL | Unique phone number |
| email | VARCHAR(255) | UNIQUE, NULL allowed | Optional unique email address |
| city_id | INTEGER | FOREIGN KEY REFERENCES cities(city_id), NOT NULL | City associated with the user |
| phone_verified | BOOLEAN | NOT NULL | Indicates whether the phone number is verified |
| is_banned | BOOLEAN | NOT NULL | Indicates whether the user is banned |
| joined_at | TIMESTAMPTZ | NOT NULL | Date and time when the user registered |

**Functional Dependencies:**

- user_id → full_name, phone, email, city_id, phone_verified, is_banned, joined_at
- phone → user_id, full_name, email, city_id, phone_verified, is_banned, joined_at
- email → user_id, full_name, phone, city_id, phone_verified, is_banned, joined_at (for non-NULL emails)

**Normalization:** The users table is in 3NF because each candidate key determines the non-key attributes, and city details are stored separately in the cities table.

**Design notes:**
- Email is nullable because 24,885 records have empty email values.
- All 25,115 non-empty email values are unique.
- Phone numbers are stored as VARCHAR to avoid treating them as quantities.

### 10.5 Listings

| Column | PostgreSQL Type | Constraints | Description |
|---|---|---|---|
| listing_id | INTEGER | PRIMARY KEY, NOT NULL | Unique identifier for each listing |
| seller_id | INTEGER | FOREIGN KEY REFERENCES users(user_id), NOT NULL | User who posted the listing |
| category_id | INTEGER | FOREIGN KEY REFERENCES categories(category_id), NOT NULL | Category of the listing |
| title | VARCHAR(255) | NOT NULL | Listing title |
| description | TEXT | NULL allowed | Detailed description of the listing |
| price | NUMERIC(12,2) | NOT NULL, CHECK (price >= 0) | Asking price |
| is_negotiable | BOOLEAN | NOT NULL | Indicates whether the price is negotiable |
| item_condition | VARCHAR(20) | NOT NULL, CHECK (item_condition IN ('FAIR', 'GOOD', 'LIKE_NEW', 'NEW')) | Condition of the item |
| attributes | JSONB | NOT NULL | Category-specific product attributes stored as JSON |
| city_id | INTEGER | FOREIGN KEY REFERENCES cities(city_id), NOT NULL | City where the listing is located |
| locality | VARCHAR(150) | NOT NULL | Locality of the listing |
| latitude | NUMERIC(9,6) | NOT NULL, CHECK (latitude BETWEEN -90 AND 90) | Geographic latitude |
| longitude | NUMERIC(9,6) | NOT NULL, CHECK (longitude BETWEEN -180 AND 180) | Geographic longitude |
| image_count | INTEGER | NOT NULL, CHECK (image_count >= 0) | Number of listing images |
| view_count | INTEGER | NOT NULL, CHECK (view_count >= 0) | Number of listing views |
| boost_package_id | INTEGER | NULL allowed, FOREIGN KEY REFERENCES boost_packages(package_id) | Optional boost package |
| status | VARCHAR(20) | NOT NULL, CHECK (status IN ('ACTIVE', 'EXPIRED', 'REMOVED', 'SOLD')) | Current listing status |
| posted_at | TIMESTAMPTZ | NOT NULL | Date and time when the listing was posted |
| expires_at | TIMESTAMPTZ | NOT NULL | Expiration date and time |
| sold_at | TIMESTAMPTZ | NULL allowed | Date and time when the listing was sold |

**Functional Dependency:**

listing_id → seller_id, category_id, title, description, price, is_negotiable, item_condition, attributes, city_id, locality, latitude, longitude, image_count, view_count, boost_package_id, status, posted_at, expires_at, sold_at

**Normalization:** The listings table is in 3NF because listing_id uniquely determines all non-key attributes. Seller, category, city, and boost package details are stored in their respective tables instead of being duplicated.

**Design notes:**
- Description, boost_package_id, and sold_at are nullable based on the supplied data.
- `attributes` uses JSONB because all 120,000 supplied values are valid JSON objects.
- `view_count` is a stored counter and is not calculated from a separate view-event table in this dataset.
- Latitude and longitude use geographic validity ranges rather than restricting values to the current dataset's observed range.

### 10.6 Chat Threads

| Column | PostgreSQL Type | Constraints | Description |
|---|---|---|---|
| thread_id | INTEGER | PRIMARY KEY, NOT NULL | Unique identifier for each conversation |
| listing_id | INTEGER | FOREIGN KEY REFERENCES listings(listing_id), NOT NULL | Listing associated with the conversation |
| buyer_id | INTEGER | FOREIGN KEY REFERENCES users(user_id), NOT NULL | Buyer participating in the conversation |
| created_at | TIMESTAMPTZ | NOT NULL | Date and time when the conversation was created |

**Functional Dependency:**

thread_id → listing_id, buyer_id, created_at

**Normalization:** The table is in 3NF because thread_id uniquely determines all non-key attributes.

### 10.7 Chat Messages

| Column | PostgreSQL Type | Constraints | Description |
|---|---|---|---|
| message_id | INTEGER | PRIMARY KEY, NOT NULL | Unique identifier for each message |
| thread_id | INTEGER | FOREIGN KEY REFERENCES chat_threads(thread_id), NOT NULL | Conversation to which the message belongs |
| sender_id | INTEGER | FOREIGN KEY REFERENCES users(user_id), NOT NULL | User who sent the message |
| body | TEXT | NOT NULL | Content of the message |
| sent_at | TIMESTAMPTZ | NOT NULL | Date and time when the message was sent |
| is_read | BOOLEAN | NOT NULL | Indicates whether the message has been read |

**Functional Dependency:**

message_id → thread_id, sender_id, body, sent_at, is_read

**Normalization:** The table is in 3NF because message_id uniquely determines all non-key attributes.

### 10.8 Offers

| Column | PostgreSQL Type | Constraints | Description |
|---|---|---|---|
| offer_id | INTEGER | PRIMARY KEY, NOT NULL | Unique identifier for each offer |
| listing_id | INTEGER | FOREIGN KEY REFERENCES listings(listing_id), NOT NULL | Listing for which the offer is made |
| buyer_id | INTEGER | FOREIGN KEY REFERENCES users(user_id), NOT NULL | User who made the offer |
| offer_price | NUMERIC(12,2) | NOT NULL, CHECK (offer_price >= 0) | Price proposed by the buyer |
| status | VARCHAR(20) | NOT NULL, CHECK (status IN ('ACCEPTED', 'COUNTERED', 'PENDING', 'REJECTED')) | Current status of the offer |
| created_at | TIMESTAMPTZ | NOT NULL | Date and time when the offer was created |
| responded_at | TIMESTAMPTZ | NULL allowed | Date and time when the offer received a response |

**Functional Dependency:**

offer_id → listing_id, buyer_id, offer_price, status, created_at, responded_at

**Normalization:** The table is in 3NF because offer_id uniquely determines all non-key attributes.

**Design note:** responded_at is nullable because 162 supplied records have no response timestamp.

### 10.9 Favourites

| Column | PostgreSQL Type | Constraints | Description |
|---|---|---|---|
| user_id | INTEGER | PRIMARY KEY, FOREIGN KEY REFERENCES users(user_id), NOT NULL | User who saved the listing |
| listing_id | INTEGER | PRIMARY KEY, FOREIGN KEY REFERENCES listings(listing_id), NOT NULL | Listing saved by the user |
| saved_at | TIMESTAMPTZ | NOT NULL | Date and time when the listing was saved |

**Functional Dependency:**

(user_id, listing_id) → saved_at

**Normalization:** The table is in 3NF because saved_at depends on the complete composite key. Neither user_id nor listing_id alone determines saved_at.

**Design note:** The composite primary key prevents a user from saving the same listing more than once.

### 10.10 Reports

| Column | PostgreSQL Type | Constraints | Description |
|---|---|---|---|
| report_id | INTEGER | PRIMARY KEY, NOT NULL | Unique identifier for each report |
| listing_id | INTEGER | FOREIGN KEY REFERENCES listings(listing_id), NOT NULL | Listing being reported |
| reporter_id | INTEGER | FOREIGN KEY REFERENCES users(user_id), NOT NULL | User who submitted the report |
| reason | VARCHAR(30) | NOT NULL, CHECK (reason IN ('ALREADY_SOLD', 'FRAUD', 'OFFENSIVE', 'SPAM', 'WRONG_CATEGORY')) | Reason for reporting |
| created_at | TIMESTAMPTZ | NOT NULL | Date and time when the report was created |
| status | VARCHAR(20) | NOT NULL, CHECK (status IN ('ACTIONED', 'DISMISSED', 'OPEN')) | Current status of the report |

**Functional Dependency:**

report_id → listing_id, reporter_id, reason, created_at, status

**Normalization:** The table is in 3NF because report_id uniquely determines all non-key attributes.

### 10.11 Seller Ratings

| Column | PostgreSQL Type | Constraints | Description |
|---|---|---|---|
| rating_id | INTEGER | PRIMARY KEY, NOT NULL | Unique identifier for each rating |
| seller_id | INTEGER | FOREIGN KEY REFERENCES users(user_id), NOT NULL | Seller receiving the rating |
| rater_id | INTEGER | FOREIGN KEY REFERENCES users(user_id), NOT NULL | User submitting the rating |
| listing_id | INTEGER | FOREIGN KEY REFERENCES listings(listing_id), NOT NULL | Listing associated with the rating |
| stars | SMALLINT | NOT NULL, CHECK (stars BETWEEN 1 AND 5) | Rating given to the seller |
| comment | TEXT | NULL allowed | Optional written feedback |
| created_at | TIMESTAMPTZ | NOT NULL | Date and time when the rating was created |

**Functional Dependency:**

rating_id → seller_id, rater_id, listing_id, stars, comment, created_at

**Normalization:** The table is in 3NF because rating_id uniquely determines all non-key attributes.

**Design note:** comment is nullable because 5,589 supplied records have empty comments.

## 11. Additional Data Validation Results

### 11.1 Seller and Listing Consistency

All 11,244 records in `seller_ratings` were checked against their associated listings.

- Total seller ratings: 11,244
- Seller/listing mismatches: 0

The `seller_id` column in `seller_ratings` is redundant because it can be derived through `listing_id` from the `listings` table. It is retained to preserve the original dataset.

### 11.2 Timestamp Validation

The following checks were performed:

| Validation | Violations |
|---|---:|
| Listing posted after expiry | 0 |
| Listing sold before posting | 0 |
| Offer responded to before creation | 0 |

The dataset supports these chronological constraints:

- `posted_at <= expires_at`
- `sold_at IS NULL OR sold_at >= posted_at`
- `responded_at IS NULL OR responded_at >= created_at`

### 11.3 Text Length Validation

Maximum observed text lengths were checked across the relevant CSV columns. The selected VARCHAR limits provide reasonable room beyond the observed values. Longer descriptive fields use TEXT, and listing attributes use JSONB.
## 12. PostgreSQL Data Loading and Integrity Verification

### 12.1 Database Setup

- Database name: `olx_de_dbms`
- PostgreSQL version: 18.6
- Schema name: `olx`
- Total tables created: 11

The schema was successfully executed using `sql/01_schema.sql`.

### 12.2 CSV Data Loading Results

All 11 CSV files were successfully imported using `sql/02_load_data.sql`.

| Table | Expected Rows | Imported Rows |
|---|---:|---:|
| Cities | 10 | 10 |
| Categories | 12 | 12 |
| Boost Packages | 6 | 6 |
| Users | 50,000 | 50,000 |
| Listings | 120,000 | 120,000 |
| Chat Threads | 59,855 | 59,855 |
| Chat Messages | 209,529 | 209,529 |
| Offers | 19,943 | 19,943 |
| Favourites | 70,000 | 70,000 |
| Reports | 7,999 | 7,999 |
| Seller Ratings | 11,244 | 11,244 |
| **Total** | **548,598** | **548,598** |

All imported row counts matched the expected CSV row counts.

### 12.3 Database Integrity Checks

Five integrity checks were executed against the imported PostgreSQL data.

| Integrity Check | Violations |
|---|---:|
| Invalid listing JSON attributes | 0 |
| Invalid listing date order | 0 |
| Invalid offer response time | 0 |
| Invalid seller rating stars | 0 |
| Seller/listing mismatches | 0 |

All five checks passed with zero violations.

### 12.4 Data Loading Conclusion

The database schema was created successfully, all 11 CSV files were imported, and all 548,598 records were verified.

The five integrity checks returned zero violations. PostgreSQL ANALYZE was also executed on all 11 tables to update database statistics.