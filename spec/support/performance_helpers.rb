module PerformanceHelpers
  def stub_expensive_operations
    # Stub Rails blob URL generation
    allow_any_instance_of(Products::GalleryImage).to receive(:url).and_return("/test.jpg")
    allow_any_instance_of(Products::GalleryImage).to receive(:thumbnail_url).and_return("/test_thumb.jpg")
    allow_any_instance_of(Products::GalleryImage).to receive(:large_url).and_return("/test_large.jpg")

    # Stub attachment existence checks to avoid ActiveStorage disk I/O
    allow_any_instance_of(ActiveStorage::Attached::One).to receive(:attached?).and_return(false)
    allow_any_instance_of(ActiveStorage::Attached::Many).to receive(:attached?).and_return(false)

    # Stub other potentially slow operations
    # ActiveStorage variant processing
    allow_any_instance_of(ActiveStorage::Variant).to receive(:processed).and_return(true)
    allow_any_instance_of(ActiveStorage::VariantWithRecord).to receive(:processed).and_return(true)

    # Rails URL helpers that might be slow
    allow(Rails.application.routes.url_helpers).to receive(:rails_blob_url).and_return("/test-blob.jpg")
    allow(Rails.application.routes.url_helpers).to receive(:rails_blob_path).and_return("/test-blob.jpg")
  end
end
