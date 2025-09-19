# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_09_16_154437) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "brands", force: :cascade do |t|
    t.string "name", null: false
    t.string "slug", null: false
    t.text "description"
    t.string "logo_url"
    t.boolean "featured", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "products_count", default: 0, null: false
    t.index ["slug"], name: "index_brands_on_slug", unique: true
  end

  create_table "cart_items", force: :cascade do |t|
    t.bigint "cart_id", null: false
    t.bigint "product_variant_id", null: false
    t.integer "quantity", default: 1, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "price_snapshot_cents", default: 0, null: false
    t.string "price_snapshot_currency", limit: 3, default: "USD", null: false
    t.index ["cart_id", "product_variant_id"], name: "index_cart_items_on_cart_id_and_product_variant_id", unique: true
    t.index ["cart_id"], name: "index_cart_items_on_cart_id"
    t.index ["price_snapshot_cents"], name: "index_cart_items_on_price_snapshot_cents"
    t.index ["product_variant_id"], name: "index_cart_items_on_product_variant_id"
  end

  create_table "carts", force: :cascade do |t|
    t.bigint "user_id"
    t.string "session_id"
    t.datetime "abandoned_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "session_token", limit: 32, null: false
    t.index ["session_id"], name: "index_carts_on_session_id"
    t.index ["session_token"], name: "index_carts_on_session_token", unique: true
    t.index ["user_id"], name: "index_carts_on_user_id"
  end

  create_table "categories", force: :cascade do |t|
    t.string "name", null: false
    t.string "slug", null: false
    t.text "description"
    t.bigint "parent_id"
    t.integer "position", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["parent_id", "position"], name: "index_categories_on_parent_id_and_position"
    t.index ["parent_id"], name: "index_categories_on_parent_id"
    t.index ["slug"], name: "index_categories_on_slug", unique: true
  end

  create_table "categorizations", force: :cascade do |t|
    t.bigint "product_id", null: false
    t.bigint "category_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category_id"], name: "index_categorizations_on_category_id"
    t.index ["product_id", "category_id"], name: "index_categorizations_on_product_id_and_category_id", unique: true
    t.index ["product_id"], name: "index_categorizations_on_product_id"
  end

  create_table "collection_products", force: :cascade do |t|
    t.bigint "collection_id", null: false
    t.bigint "product_id", null: false
    t.integer "position", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["collection_id", "position"], name: "index_collection_products_on_collection_id_and_position"
    t.index ["collection_id", "product_id"], name: "index_collection_products_on_collection_id_and_product_id", unique: true
    t.index ["collection_id"], name: "index_collection_products_on_collection_id"
    t.index ["product_id"], name: "index_collection_products_on_product_id"
  end

  create_table "collections", force: :cascade do |t|
    t.string "name", null: false
    t.string "slug", null: false
    t.text "description"
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_collections_on_slug", unique: true
  end

  create_table "customer_profiles", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "skin_type"
    t.text "skin_concerns", default: [], array: true
    t.jsonb "tags", default: []
    t.integer "total_spent_cents", default: 0, null: false
    t.string "total_spent_currency", default: "USD", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_customer_profiles_on_user_id"
  end

  create_table "discounts", force: :cascade do |t|
    t.string "code", null: false
    t.string "discount_type", null: false
    t.integer "value_cents", default: 0, null: false
    t.string "value_currency", default: "USD", null: false
    t.integer "usage_limit"
    t.integer "usage_count", default: 0, null: false
    t.datetime "valid_from"
    t.datetime "valid_until"
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active", "valid_from", "valid_until"], name: "index_discounts_on_active_and_valid_from_and_valid_until"
    t.index ["code"], name: "index_discounts_on_code", unique: true
  end

  create_table "order_items", force: :cascade do |t|
    t.bigint "order_id", null: false
    t.bigint "product_id", null: false
    t.bigint "product_variant_id", null: false
    t.string "product_name", null: false
    t.string "variant_name"
    t.integer "quantity", null: false
    t.integer "unit_price_cents", default: 0, null: false
    t.string "unit_price_currency", default: "USD", null: false
    t.integer "total_price_cents", default: 0, null: false
    t.string "total_price_currency", default: "USD", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["order_id"], name: "index_order_items_on_order_id"
    t.index ["product_id"], name: "index_order_items_on_product_id"
    t.index ["product_variant_id"], name: "index_order_items_on_product_variant_id"
  end

  create_table "orders", force: :cascade do |t|
    t.string "number", null: false
    t.bigint "user_id"
    t.string "email", null: false
    t.string "status", default: "pending"
    t.string "payment_status", default: "pending"
    t.string "fulfillment_status", default: "unfulfilled"
    t.integer "subtotal_cents", default: 0, null: false
    t.string "subtotal_currency", default: "USD", null: false
    t.integer "tax_total_cents", default: 0, null: false
    t.string "tax_total_currency", default: "USD", null: false
    t.integer "shipping_total_cents", default: 0, null: false
    t.string "shipping_total_currency", default: "USD", null: false
    t.integer "discount_total_cents", default: 0, null: false
    t.string "discount_total_currency", default: "USD", null: false
    t.integer "total_cents", default: 0, null: false
    t.string "total_currency", default: "USD", null: false
    t.jsonb "billing_address", default: {}
    t.jsonb "shipping_address", default: {}
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "phone_number", null: false
    t.string "delivery_method", default: "courier"
    t.string "courier_name"
    t.text "delivery_notes"
    t.date "delivery_date"
    t.string "delivery_time_slot"
    t.datetime "delivery_scheduled_at"
    t.index ["delivery_method"], name: "index_orders_on_delivery_method"
    t.index ["number"], name: "index_orders_on_number", unique: true
    t.index ["phone_number"], name: "index_orders_on_phone_number"
    t.index ["status"], name: "index_orders_on_status"
    t.index ["user_id"], name: "index_orders_on_user_id"
  end

  create_table "product_variants", force: :cascade do |t|
    t.bigint "product_id", null: false
    t.string "name", null: false
    t.string "sku", null: false
    t.string "barcode"
    t.integer "price_cents", default: 0, null: false
    t.string "price_currency", default: "USD", null: false
    t.integer "compare_at_price_cents", default: 0, null: false
    t.string "compare_at_price_currency", default: "USD", null: false
    t.integer "cost_cents", default: 0, null: false
    t.string "cost_currency", default: "USD", null: false
    t.string "color"
    t.integer "stock_quantity", default: 0
    t.boolean "track_inventory", default: true, null: false
    t.boolean "allow_backorder", default: false, null: false
    t.integer "position", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "size_value", precision: 10, scale: 2
    t.string "size_unit"
    t.string "size_type"
    t.decimal "conversion_score", precision: 8, scale: 4, default: "0.0", null: false
    t.integer "sales_count", default: 0, null: false
    t.boolean "is_default", default: false, null: false
    t.boolean "canonical_variant", default: false, null: false
    t.string "color_hex"
    t.index ["color_hex"], name: "index_product_variants_on_color_hex"
    t.index ["product_id", "conversion_score"], name: "index_product_variants_on_product_and_conversion"
    t.index ["product_id", "is_default"], name: "index_product_variants_on_product_and_default"
    t.index ["product_id", "position"], name: "index_product_variants_on_product_id_and_position"
    t.index ["product_id", "sales_count"], name: "index_product_variants_on_product_and_sales"
    t.index ["product_id"], name: "index_product_variants_on_product_id"
    t.index ["size_type", "size_value"], name: "index_product_variants_on_size_type_and_size_value"
    t.index ["sku"], name: "index_product_variants_on_sku", unique: true
  end

  create_table "products", force: :cascade do |t|
    t.string "name", null: false
    t.string "slug", null: false
    t.text "description"
    t.string "product_type"
    t.bigint "brand_id"
    t.text "ingredients"
    t.text "how_to_use"
    t.string "skin_types", default: [], array: true
    t.boolean "active", default: true, null: false
    t.datetime "published_at"
    t.string "meta_title"
    t.text "meta_description"
    t.integer "reviews_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "subtitle"
    t.jsonb "product_attributes", default: {}
    t.index ["active", "published_at"], name: "index_products_on_active_and_published_at"
    t.index ["brand_id"], name: "index_products_on_brand_id"
    t.index ["product_attributes"], name: "index_products_on_product_attributes", using: :gin
    t.index ["slug"], name: "index_products_on_slug", unique: true
    t.check_constraint "jsonb_typeof(product_attributes) = 'object'::text", name: "product_attributes_is_object"
  end

  create_table "reviews", force: :cascade do |t|
    t.bigint "product_id", null: false
    t.bigint "user_id", null: false
    t.integer "rating", null: false
    t.string "title"
    t.text "body"
    t.boolean "verified_purchase", default: false, null: false
    t.string "status", default: "pending"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["product_id", "status"], name: "index_reviews_on_product_id_and_status"
    t.index ["product_id"], name: "index_reviews_on_product_id"
    t.index ["rating"], name: "index_reviews_on_rating"
    t.index ["user_id"], name: "index_reviews_on_user_id"
    t.check_constraint "rating >= 1 AND rating <= 5", name: "rating_range"
  end

  create_table "sessions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "first_name"
    t.string "last_name"
    t.string "phone_number"
    t.string "preferred_language", default: "ar"
    t.string "governorate"
    t.string "city"
    t.date "date_of_birth"
    t.boolean "admin", default: false
    t.integer "orders_count", default: 0, null: false
    t.index ["admin", "created_at"], name: "index_users_on_admin_and_created_at"
    t.index ["admin"], name: "index_users_on_admin"
    t.index ["date_of_birth"], name: "index_users_on_date_of_birth"
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
    t.index ["governorate", "city"], name: "index_users_on_governorate_and_city"
    t.index ["governorate"], name: "index_users_on_governorate"
    t.index ["phone_number"], name: "index_users_on_phone_number"
    t.index ["preferred_language"], name: "index_users_on_preferred_language"
    t.check_constraint "date_of_birth IS NULL OR date_of_birth < CURRENT_DATE", name: "date_of_birth_in_past"
    t.check_constraint "first_name IS NULL OR length(first_name::text) >= 2", name: "first_name_min_length"
    t.check_constraint "last_name IS NULL OR length(last_name::text) >= 2", name: "last_name_min_length"
    t.check_constraint "preferred_language IS NULL OR (preferred_language::text = ANY (ARRAY['ar'::character varying::text, 'en'::character varying::text]))", name: "valid_language"
  end

  create_table "wishlists", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "product_variant_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["product_variant_id"], name: "index_wishlists_on_product_variant_id"
    t.index ["user_id", "product_variant_id"], name: "index_wishlists_on_user_id_and_product_variant_id", unique: true
    t.index ["user_id"], name: "index_wishlists_on_user_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "cart_items", "carts"
  add_foreign_key "cart_items", "product_variants"
  add_foreign_key "carts", "users"
  add_foreign_key "categories", "categories", column: "parent_id"
  add_foreign_key "categorizations", "categories"
  add_foreign_key "categorizations", "products"
  add_foreign_key "collection_products", "collections"
  add_foreign_key "collection_products", "products"
  add_foreign_key "customer_profiles", "users"
  add_foreign_key "order_items", "orders"
  add_foreign_key "order_items", "product_variants"
  add_foreign_key "order_items", "products"
  add_foreign_key "orders", "users"
  add_foreign_key "product_variants", "products"
  add_foreign_key "products", "brands"
  add_foreign_key "reviews", "products"
  add_foreign_key "reviews", "users"
  add_foreign_key "sessions", "users"
  add_foreign_key "wishlists", "product_variants"
  add_foreign_key "wishlists", "users"
end
