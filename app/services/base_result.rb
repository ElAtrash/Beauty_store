# frozen_string_literal: true

class BaseResult
  attr_reader :resource, :errors, :success, :metadata, :cart, :order

  def initialize(success:, resource: nil, errors: [], cart: nil, order: nil, **metadata)
    @success = success
    @resource = resource
    @errors = Array(errors)
    @metadata = metadata
    @cart = cart
    @order = order
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
