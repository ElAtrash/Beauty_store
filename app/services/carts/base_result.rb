# frozen_string_literal: true

class Carts::BaseResult
  attr_reader :resource, :cart, :errors, :success, :metadata

  def initialize(success:, resource: nil, cart: nil, errors: [], **metadata)
    @success = success
    @resource = resource
    @cart = cart
    @errors = Array(errors)
    @metadata = metadata
  end

  def success?
    @success
  end

  def failure?
    !@success
  end

  def merged_items_count
    metadata[:merged_items_count] || 0
  end

  def merged_any_items?
    merged_items_count > 0
  end

  def cleared_variants
    metadata[:cleared_variants] || []
  end

  def cleared_items_count
    metadata[:cleared_items_count] || 0
  end
end
