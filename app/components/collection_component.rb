# frozen_string_literal: true

class CollectionComponent < BaseComponent
  private

  def render_empty_state(message: "No items to display")
    content_tag :div, class: "empty-state text-center py-8 text-muted" do
      message
    end
  end

  def batch_render_collection(collection, batch_size: 50, &block)
    return [] if collection.empty?

    collection.each_slice(batch_size).flat_map do |batch|
      batch.map(&block)
    end
  end

  def collection_container_classes(*additional_classes)
    css_classes("collection-container", *additional_classes)
  end

  def safe_collection_count(collection)
    return 0 unless collection.respond_to?(:count) || collection.respond_to?(:size)

    collection.respond_to?(:count) ? collection.count : collection.size
  rescue StandardError
    0
  end
end
