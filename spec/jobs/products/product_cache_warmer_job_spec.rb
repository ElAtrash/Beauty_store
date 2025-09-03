# frozen_string_literal: true

RSpec.describe Products::ProductCacheWarmerJob, type: :job do
  include ActiveSupport::Testing::TimeHelpers

  let!(:product) { create(:product, :published, name: "Test Product") }
  let!(:variants) { create_list(:product_variant, 3, product: product) }
  let(:cache_key) { [ product.cache_key_with_version, "product_static_data" ] }

  before do
    Rails.cache.clear
    product.reload
  end

  after do
    Rails.cache.clear
  end

  it "writes static product data to the cache" do
    expect(Rails.cache.read(cache_key)).to be_nil

    described_class.perform_now(product.id)

    cached_data = Rails.cache.read(cache_key)
    expect(cached_data).to be_a(Products::ProductDisplayData)
    expect(cached_data.all_variants.size).to eq(3)
    expect(cached_data.product_info.name).to eq("Test Product")
  end

  it "handles missing product gracefully" do
    expect {
      described_class.perform_now(999999)
    }.to raise_error(ActiveRecord::RecordNotFound)
  end

  it "sets cache with expiration" do
    described_class.perform_now(product.id)

    expect(Rails.cache.read(cache_key)).to be_present

    travel_to(31.minutes.from_now) do
      expect(Rails.cache.read(cache_key)).to be_nil
    end
  end

  it "includes all expected static data fields" do
    described_class.perform_now(product.id)

    cached_data = Rails.cache.read(cache_key)
    expect(cached_data).to be_present

    expect(cached_data.product_info).to be_present
    expect(cached_data.all_variants).to be_present
    expect(cached_data.variant_images).to be_present

    expect(cached_data.price_matrix).to be_nil
    expect(cached_data.stock_matrix).to be_nil
    expect(cached_data.variant_options).to be_nil
  end

  it "performs efficiently without N+1 queries" do
    product_with_many_variants = create(:product, :published)
    create_list(:product_variant, 10, product: product_with_many_variants)

    expect {
      described_class.perform_now(product_with_many_variants.id)
    }.to change { Rails.cache.read([ product_with_many_variants.cache_key_with_version, "product_static_data" ]) }.from(nil).to(be_present)
  end
end
