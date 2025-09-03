# frozen_string_literal: true

module Products
  class DefaultVariantSelector
    class << self
      def call(product, scope: nil)
        new(product, scope).call
      end
    end

    def initialize(product, scope = nil)
      @product  = product
      @variants = scope || product.product_variants
    end

    def call
      return nil unless variants_exist?

      try_admin_override ||
        try_out_of_stock_fallback ||
        try_bestseller ||
        try_size_or_entry_default ||
        try_canonical_or_first
    end

    private

    attr_reader :product, :variants

    def variants_exist?
      variants.exists?
    end

    def try_admin_override
      variants.marked_default.in_stock.first
    end

    def try_out_of_stock_fallback
      return nil if variants.in_stock.exists?
      variants.canonical.first || variants.ordered.first
    end

    def try_bestseller
      performance_variants = variants.in_stock.with_performance
      return nil unless performance_variants.exists?

      performance_variants.order(
        Arel.sql("(sales_count * 0.7 + conversion_score * 0.3) DESC")
      ).first
    end

    def try_size_or_entry_default
      in_stock = variants.in_stock

      if product.size_only_variants?
        in_stock.ordered_by_size.first
      else
        find_entry_level(in_stock)
      end
    end

    def find_entry_level(scope)
      sorted = scope.ordered_by_price
      return sorted.first if sorted.limit(3).size <= 2
      sorted.offset(1).first
    end

    def try_canonical_or_first
      variants.in_stock.canonical.first || variants.in_stock.ordered.first
    end
  end
end
