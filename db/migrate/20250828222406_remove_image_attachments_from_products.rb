class RemoveImageAttachmentsFromProducts < ActiveRecord::Migration[8.0]
  def up
    # Remove all product image attachments from Active Storage
    ActiveStorage::Attachment.where(
      record_type: 'Product',
      name: [ 'featured_image', 'images' ]
    ).find_each do |attachment|
      attachment.purge_later
    end

    puts "Removed all product image attachments"
  end

  def down
    # Cannot restore deleted images, this migration is irreversible for data
    puts "WARNING: Cannot restore deleted product images. You'll need to re-seed or manually re-attach images."
  end
end
