# frozen_string_literal: true

class Cart::ModalComponent < Modal::BaseComponent
  def initialize(title:, item_count:, cart_empty:, total_cents:, currency: "USD")
    @item_count = validate_item_count(item_count)
    @cart_empty = validate_cart_empty(cart_empty)
    @money = create_money_object(total_cents, currency)
    super(id: "cart", title: title, size: :medium, position: :right)
  end

  private

  attr_reader :item_count, :cart_empty, :money

  def empty_cart?
    cart_empty
  end

  def additional_data_attributes
    super.merge(cart_data_attributes)
  end

  def container_classes
    class_names(
      super,
      empty_cart? ? "cart-modal--empty" : "cart-modal--has-items"
    )
  end

  def cart_data_attributes
    {
      "cart-modal-target" => "modal",
      "cart-item-count" => item_count,
      "cart-empty" => empty_cart?,
      "cart-total-cents" => money.cents,
      "cart-currency" => money.currency.iso_code
    }
  end

  def validate_item_count(count)
    raise ArgumentError, "item_count must be a non-negative integer" unless count.is_a?(Integer) && count >= 0
    count
  end

  def validate_cart_empty(empty)
    raise ArgumentError, "cart_empty must be a boolean" unless [ true, false ].include?(empty)
    empty
  end

  def create_money_object(cents, currency)
    validate_total_cents(cents)
    validate_currency(currency)
    Money.new(cents, currency)
  end

  def validate_total_cents(cents)
    unless cents.is_a?(Integer) && cents >= 0
      raise ArgumentError, "total_cents must be a non-negative integer, got: #{cents.inspect}"
    end
  end

  def validate_currency(currency)
    unless currency.is_a?(String) && !currency.blank?
      raise ArgumentError, "currency must be a non-blank string, got: #{currency.inspect}"
    end

    Money::Currency.new(currency)
  rescue Money::Currency::UnknownCurrency => e
    raise ArgumentError, "invalid currency code: #{currency} - #{e.message}"
  end
end
