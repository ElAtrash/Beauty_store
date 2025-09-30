# frozen_string_literal: true

puts "🌱 Starting comprehensive beauty store seeding..."

puts "\n📍 Creating core brands..."

brands_data = [
  {
    name: "Fenty Beauty",
    slug: "fenty-beauty",
    description: "Beauty for All. Fenty Beauty was founded in 2017 by Rihanna with the vision of inclusion for all women. We believe that every person deserves to feel beautiful and confident in their own skin.",
    banner_url: "https://picsum.photos/1200/675?random=1001"
  },
  {
    name: "Charlotte Tilbury",
    slug: "charlotte-tilbury",
    description: "Luxury makeup and skincare inspired by iconic beauty looks from the red carpet to the catwalk. Founded by celebrity makeup artist Charlotte Tilbury MBE, bringing professional artistry to everyone.",
    banner_url: "https://picsum.photos/1200/675?random=1002"
  },
  {
    name: "The Ordinary",
    slug: "the-ordinary",
    description: "Clinical formulations with integrity. DECIEM's The Ordinary offers clinical technologies at honest prices, with straightforward communication and effective, familiar ingredients.",
    banner_url: "https://picsum.photos/1200/675?random=1003"
  },
  {
    name: "Rare Beauty",
    slug: "rare-beauty",
    description: "Find comfort in your own skin. Founded by Selena Gomez, Rare Beauty celebrates uniqueness and promotes mental health awareness while creating high-quality, easy-to-use products.",
    banner_url: "https://picsum.photos/1200/675?random=1004"
  }
]

brands = {}
brands_data.each do |brand_data|
  brand = Brand.find_or_create_by!(slug: brand_data[:slug]) do |b|
    b.name = brand_data[:name]
    b.description = brand_data[:description]
  end

  if brand_data[:banner_url] && !brand.banner_image.attached?
    begin
      require 'open-uri'
      banner_data = URI.open(brand_data[:banner_url])
      filename = "#{brand.slug}-banner.jpg"

      brand.banner_image.attach(
        io: banner_data,
        filename: filename,
        content_type: 'image/jpeg'
      )
      puts "  ✅ #{brand.name} (with banner)"
    rescue => e
      puts "  ⚠️ #{brand.name} (banner failed: #{e.message})"
    end
  else
    puts "  ✅ #{brand.name}"
  end

  brands[brand_data[:slug]] = brand
end

puts "\n📍 Creating categories..."

categories_data = [
  { name: "Face", slug: "face", description: "Foundation, concealer, powder, and face makeup", position: 1 },
  { name: "Eyes", slug: "eyes", description: "Eyeshadow, mascara, eyeliner, and brow products", position: 2 },
  { name: "Lips", slug: "lips", description: "Lipstick, lip gloss, lip liner, and lip care", position: 3 },
  { name: "Skincare", slug: "skincare", description: "Cleansers, serums, moisturizers, and treatments", position: 4 },
  { name: "Tools", slug: "tools", description: "Brushes, sponges, and beauty accessories", position: 5 },
  { name: "Fragrance", slug: "fragrance", description: "Perfumes, body mists, and scented products", position: 6 }
]

categories = {}
categories_data.each do |cat_data|
  category = Category.find_or_create_by!(slug: cat_data[:slug]) do |c|
    c.name = cat_data[:name]
    c.description = cat_data[:description]
    c.position = cat_data[:position]
  end
  categories[cat_data[:slug]] = category
  puts "  ✅ #{category.name}"
end

def attach_variant_images(variant, image_urls)
  return unless image_urls&.any?

  image_urls.each_with_index do |url, index|
    next unless url

    if index == 0 && !variant.featured_image.attached?
      begin
        require 'open-uri'
        image_data = URI.open(url)
        filename = "#{variant.product.slug}-#{variant.color&.downcase&.gsub(' ', '-') || 'variant'}-featured.jpg"
        variant.featured_image.attach(
          io: image_data,
          filename: filename,
          content_type: 'image/jpeg'
        )
        puts "    ✅ Added featured image for #{variant.color || variant.name}"
      rescue => e
        puts "    ❌ Failed to attach featured image for #{variant.color || variant.name}: #{e.message}"
      end
    else
      begin
        require 'open-uri'
        image_data = URI.open(url)
        filename = "#{variant.product.slug}-#{variant.color&.downcase&.gsub(' ', '-') || 'variant'}-#{index + 1}.jpg"
        variant.images.attach(
          io: image_data,
          filename: filename,
          content_type: 'image/jpeg'
        )
        puts "    ✅ Added image #{index + 1} for #{variant.color || variant.name}"
      rescue => e
        puts "    ❌ Failed to attach image #{index + 1} for #{variant.color || variant.name}: #{e.message}"
      end
    end
  end
end

def create_complete_product(
  name:, brand:, categories:, product_type:, price:,
  description:, how_to_use: nil, ingredients: nil, subtitle: nil,
  attributes: {}, variants: [], image_url: nil
)
  product = Product.find_or_create_by!(name: name) do |p|
    p.brand = brand
    p.product_type = product_type
    p.description = description
    p.subtitle = subtitle
    p.how_to_use = how_to_use
    p.ingredients = ingredients
    p.product_attributes = attributes
    p.active = true
    p.published_at = rand(1..30).days.ago
  end

  if product.persisted? && product.subtitle != subtitle
    product.update!(subtitle: subtitle)
  end

  categories.each do |category|
    Categorization.find_or_create_by!(product: product, category: category)
  end

  if variants.any?
    variants.each_with_index do |variant_data, index|
      variant = ProductVariant.find_or_create_by!(product: product, name: variant_data[:name]) do |v|
        v.sku = "#{product.id}-#{variant_data[:name].upcase.gsub(' ', '')}-#{rand(100..999)}"
        v.price = Money.new(variant_data[:price] * 100)
        v.stock_quantity = rand(5..50)
        v.position = index + 1
        v.color = variant_data[:color] if variant_data[:color]
        v.color_hex = variant_data[:color_hex] if variant_data[:color_hex]
        v.size_value = variant_data[:size_value] if variant_data[:size_value]
        v.size_unit = variant_data[:size_unit] if variant_data[:size_unit]
        v.size_type = variant_data[:size_type] if variant_data[:size_type]

        v.sales_count = variant_data[:sales_count] || rand(10..200)
        v.conversion_score = variant_data[:conversion_score] || rand(0.05..0.20).round(4)
        v.is_default = variant_data[:is_default] || false
        v.canonical_variant = variant_data[:canonical_variant] || false
      end

      updates_needed = {}
      updates_needed[:color] = variant_data[:color] if variant_data[:color] && variant.color != variant_data[:color]
      updates_needed[:color_hex] = variant_data[:color_hex] if variant_data[:color_hex] && variant.color_hex != variant_data[:color_hex]
      updates_needed[:size_value] = variant_data[:size_value] if variant_data[:size_value] && variant.size_value != variant_data[:size_value]
      updates_needed[:size_unit] = variant_data[:size_unit] if variant_data[:size_unit] && variant.size_unit != variant_data[:size_unit]
      updates_needed[:size_type] = variant_data[:size_type] if variant_data[:size_type] && variant.size_type != variant_data[:size_type]

      if updates_needed.any?
        variant.update!(updates_needed)
      end

      if variant_data[:image_urls]
        attach_variant_images(variant, variant_data[:image_urls])
      elsif variant_data[:image_url]
        attach_variant_images(variant, [ variant_data[:image_url] ])
      elsif image_url && !variant.featured_image.attached?
        attach_variant_images(variant, [ image_url ])
      end
    end
  else
    ProductVariant.find_or_create_by!(product: product, name: "Standard") do |v|
      v.sku = "#{product.id}-STD-#{rand(100..999)}"
      v.price = Money.new(price * 100)
      v.stock_quantity = rand(10..100)
      v.position = 1

      v.sales_count = rand(50..300)
      v.conversion_score = rand(0.08..0.18).round(4)
      v.is_default = true
      v.canonical_variant = true
    end

    default_variant = product.product_variants.first
    if default_variant && !default_variant.featured_image.attached? && image_url
      attach_variant_images(default_variant, [ image_url ])
    end
  end


  puts "  ✅ #{product.name} - #{product.brand.name}"
  product
end

puts "\n📍 Creating Fenty Beauty products..."

create_complete_product(
  name: "Pro Filt'r Soft Matte Longwear Foundation",
  subtitle: "Longwear foundation with 50 inclusive shades",
  brand: brands["fenty-beauty"],
  categories: [ categories["face"] ],
  product_type: "foundation",
  price: 36,
  description: "A soft matte, long-wearing foundation with buildable, medium to full coverage and a weightless feel. Available in 50 inclusive shades.",
  how_to_use: "**Application:** Start with clean, moisturized skin. Apply 1-2 pumps to the back of your hand. Using a damp Beauty Blender or foundation brush, blend from the center of your face outward. **Build coverage** as needed by applying in thin layers.",
  ingredients: "Water, Dimethicone, Isododecane, Alcohol Denat, Trimethylsiloxysilicate, PEG-10 Dimethicone, Disteardimonium Hectorite, Magnesium Sulfate, Vinyl Dimethicone/Methicone Silsesquioxane Crosspolymer",
  attributes: {
    finish: "Soft Matte",
    skin_type: [ "Oily", "Combination", "Normal" ],
    intended_for: [ "Face" ],
    application_area: "Face and neck",
    suitable_for: [ "All" ],
    cruelty_free: "Yes"
  },
  variants: [
    {
      name: "110 - Fair with cool undertones", price: 36, color: "Fair Cool", color_hex: "#F4C2A1", size_value: 32, size_unit: "ml", size_type: "volume",
      image_urls: [ "https://picsum.photos/800/600?random=2001" ]
    },
    {
      name: "210 - Light with warm undertones", price: 36, color: "Light Warm", color_hex: "#E8B896", size_value: 32, size_unit: "ml", size_type: "volume",
      image_urls: [ "https://picsum.photos/800/600?random=2002" ]
    },
    {
      name: "290 - Medium with warm undertones", price: 36, color: "Medium Warm", color_hex: "#D4A574", size_value: 32, size_unit: "ml", size_type: "volume",
      image_urls: [ "https://picsum.photos/800/600?random=2003" ]
    },
    {
      name: "385 - Deep with cool undertones", price: 36, color: "Deep Cool", color_hex: "#A67C52", size_value: 32, size_unit: "ml", size_type: "volume",
      image_urls: [ "https://picsum.photos/800/600?random=2004" ]
    }
  ],
  image_url: "https://picsum.photos/400/400?random=2005"
)

create_complete_product(
  name: "Gloss Bomb Universal Lip Luminizer",
  subtitle: "Explosive shine lip gloss for all skin tones",
  brand: brands["fenty-beauty"],
  categories: [ categories["lips"] ],
  product_type: "lip_gloss",
  price: 21,
  description: "An explosive shine lip gloss that feels as good as it looks. The XXL wand gives you the exact right amount of gloss for a perfect application.",
  how_to_use: "**Easy Application:** Glide the XXL wand across lips starting from the center and working outward. **Layering:** Apply over lipstick for extra shine or wear alone for a natural glossy look.",
  ingredients: "Polybutene, Diisostearyl Malate, Hydrogenated Polyisobutene, Phenyl Trimethicone, Tridecyl Trimellitate, Fragrance/Parfum, Vanillin",
  attributes: {
    texture: "Glossy",
    finish: "High Gloss",
    water_resistant: "No",
    intended_for: [ "Lips" ],
    application_area: "Lips",
    suitable_for: [ "All" ],
    cruelty_free: "Yes"
  },
  variants: [
    {
      name: "Fenty Glow - Universal nude", price: 21, color: "Universal Nude", color_hex: "#D4A574", size_value: 9, size_unit: "ml", size_type: "volume",
      image_urls: [ "https://picsum.photos/800/600?random=2006" ]
    },
    {
      name: "Fu$$y - Pinky peach", price: 21, color: "Pinky Peach", color_hex: "#F4A6A6", size_value: 9, size_unit: "ml", size_type: "volume",
      image_urls: [ "https://picsum.photos/800/600?random=2007" ]
    },
    {
      name: "Sweet Mouth - Sheer berry", price: 21, color: "Sheer Berry", color_hex: "#C85A8E", size_value: 9, size_unit: "ml", size_type: "volume",
      image_urls: [ "https://picsum.photos/800/600?random=2008" ]
    }
  ],
  image_url: "https://picsum.photos/400/400?random=2009"
)

create_complete_product(
  name: "Match Stix Matte Skinstick Concealer",
  subtitle: "Portable magnetic concealer that won't crease",
  brand: brands["fenty-beauty"],
  categories: [ categories["face"] ],
  product_type: "concealer",
  price: 28,
  description: "A portable, magnetic concealer stick with matte coverage that won't cake or crease. Covers, conceals, and contours with ease.",
  how_to_use: "**Concealing:** Apply directly to blemishes or under-eye area. **Contouring:** Use a shade 2-3 shades deeper than your skin tone. **Blending:** Pat and blend with fingertips or a damp sponge.",
  ingredients: "Dimethicone, Synthetic Wax, Phenyl Trimethicone, Caprylyl Methicone, Mica, Polyethylene, Silica",
  attributes: {
    finish: "Matte",
    skin_type: [ "Oily", "Combination", "Normal" ],
    intended_for: [ "Face" ],
    application_area: "Under eyes, blemishes, contour",
    suitable_for: [ "All" ],
    cruelty_free: "Yes"
  },
  variants: [
    { name: "Light", price: 28, color: "Light", color_hex: "#F4C2A1", size_value: 8, size_unit: "g", size_type: "weight" },
    { name: "Medium", price: 28, color: "Medium", color_hex: "#D4A574", size_value: 8, size_unit: "g", size_type: "weight" },
    { name: "Deep", price: 28, color: "Deep", color_hex: "#A67C52", size_value: 8, size_unit: "g", size_type: "weight" }
  ],
  image_url: "https://picsum.photos/400/400?random=2010"
)

puts "\n📍 Creating Charlotte Tilbury products..."

create_complete_product(
  name: "Matte Revolution Lipstick - Pillow Talk",
  subtitle: "Award-winning bestselling lipstick",
  brand: brands["charlotte-tilbury"],
  categories: [ categories["lips"] ],
  product_type: "lipstick",
  price: 34,
  description: "The award-winning, bestselling lipstick with a revolutionary formula that delivers intense, long-lasting color with a comfortable matte finish.",
  how_to_use: "**Perfect Application:** Exfoliate lips first for smooth application. Apply directly from the bullet or use a lip brush for precision. **Long-lasting Wear:** Blot with tissue and reapply for all-day wear.",
  ingredients: "Dimethicone, Bis-Diglyceryl Polyacyladipate-2, Hydrogenated Polyisobutene, Petrolatum, Caprylic/Capric Triglyceride, Mica",
  attributes: {
    texture: "Matte",
    finish: "Matte",
    water_resistant: "Yes",
    transfer_resistant: "Yes",
    intended_for: [ "Lips" ],
    application_area: "Lips",
    suitable_for: [ "All" ],
    cruelty_free: "Yes"
  },
  variants: [
    { name: "Pillow Talk", price: 34, color: "Nude Pink", color_hex: "#E8B8AB", size_value: 3.5, size_unit: "g", size_type: "weight" },
    { name: "Walk of No Shame", price: 34, color: "Berry", color_hex: "#B85A8E", size_value: 3.5, size_unit: "g", size_type: "weight" },
    { name: "Red Carpet Red", price: 34, color: "Classic Red", color_hex: "#D4232A", size_value: 3.5, size_unit: "g", size_type: "weight" }
  ],
  image_url: "https://picsum.photos/400/400?random=2011"
)

create_complete_product(
  name: "Hollywood Flawless Filter",
  subtitle: "Complexion booster for supermodel glow",
  brand: brands["charlotte-tilbury"],
  categories: [ categories["face"] ],
  product_type: "highlighter",
  price: 49,
  description: "The complexion booster that can be used as a primer, highlighter, or mixed with foundation for an instantly gorgeous, supermodel glow.",
  how_to_use: "**As Primer:** Apply before foundation for a glowing base. **As Highlighter:** Apply to high points of face after foundation. **Mixed:** Blend 1-2 drops with foundation for all-over glow.",
  ingredients: "Aqua/Water/Eau, Dimethicone, Glycerin, Butylene Glycol, Synthetic Fluorphlogopite, Mica, Tin Oxide",
  attributes: {
    texture: "Liquid",
    finish: "Radiant",
    intended_for: [ "Face" ],
    application_area: "Face, cheekbones, nose",
    suitable_for: [ "All" ],
    cruelty_free: "Yes"
  },
  variants: [
    { name: "Light/Medium", price: 49, color: "Light Medium", color_hex: "#F0D4B8", size_value: 30, size_unit: "ml", size_type: "volume" },
    { name: "Medium/Dark", price: 49, color: "Medium Dark", color_hex: "#C89B7B", size_value: 30, size_unit: "ml", size_type: "volume" }
  ],
  image_url: "https://picsum.photos/400/400?random=2012"
)

create_complete_product(
  name: "Magic Cream Moisturizer",
  subtitle: "Celebrity favorite red carpet moisturizer",
  brand: brands["charlotte-tilbury"],
  categories: [ categories["skincare"] ],
  product_type: "moisturizer",
  price: 100,
  description: "The award-winning moisturizer that hydrates, plumps, and primes skin for a smooth, luminous complexion. A celebrity favorite for red carpet events.",
  how_to_use: "**Daily Use:** Apply to clean skin morning and evening. **Pre-Makeup:** Allow to absorb for 5 minutes before applying foundation for the perfect base.",
  ingredients: "Aqua/Water/Eau, Glycerin, Caprylic/Capric Triglyceride, Dimethicone, Butyrospermum Parkii (Shea) Butter, Hyaluronic Acid",
  attributes: {
    skin_type: [ "Dry", "Normal", "Combination" ],
    intended_for: [ "Face" ],
    application_area: "Face and neck",
    suitable_for: [ "All" ],
    cruelty_free: "Yes"
  },
  variants: [
    { name: "50ml", price: 100, size_value: 50, size_unit: "ml", size_type: "volume" },
    { name: "15ml Travel", price: 35, size_value: 15, size_unit: "ml", size_type: "volume" }
  ],
  image_url: "https://picsum.photos/400/400?random=2013"
)

puts "\n📍 Creating The Ordinary products..."

create_complete_product(
  name: "Niacinamide 10% + Zinc 1%",
  subtitle: "High-strength blemish fighting formula",
  brand: brands["the-ordinary"],
  categories: [ categories["skincare"] ],
  product_type: "serum",
  price: 7,
  description: "A high-strength vitamin and mineral blemish formula with 10% Niacinamide and 1% Zinc PCA to reduce the appearance of skin blemishes and congestion.",
  how_to_use: "**Application:** Apply to entire face morning and evening before heavier creams. **Patch Test:** Test on small area first. **Avoid:** Eye area and use with strong actives.",
  ingredients: "Aqua (Water), Niacinamide, Pentylene Glycol, Zinc PCA, Dimethyl Isosorbide, Tamarindus Indica Seed Gum, Xanthan Gum, Isoceteth-20",
  attributes: {
    skin_type: [ "Oily", "Combination", "Acne-Prone" ],
    intended_for: [ "Face" ],
    application_area: "Face, avoiding eye area",
    suitable_for: [ "All", "Sensitive Skin" ],
    cruelty_free: "Yes"
  },
  variants: [
    { name: "30ml", price: 7, size_value: 30, size_unit: "ml", size_type: "volume" }
  ],
  image_url: "https://picsum.photos/400/400?random=2014"
)

create_complete_product(
  name: "Hyaluronic Acid 2% + B5",
  subtitle: "Multi-depth hydration with vitamin B5",
  brand: brands["the-ordinary"],
  categories: [ categories["skincare"] ],
  product_type: "serum",
  price: 8,
  description: "A water-based serum with three types of Hyaluronic Acid and Vitamin B5 for multi-depth hydration and enhanced skin repair.",
  how_to_use: "**Best Practice:** Apply to damp skin for maximum hydration. **Layering:** Use before oils and creams. **Frequency:** Can be used twice daily.",
  ingredients: "Aqua (Water), Sodium Hyaluronate, Panthenol, Ahnfeltia Concinna Extract, Glycerin, Pentylene Glycol, Polyacrylate Crosspolymer-6",
  attributes: {
    skin_type: [ "Dry", "Normal", "Sensitive" ],
    intended_for: [ "Face" ],
    application_area: "Face and neck",
    suitable_for: [ "All", "Sensitive Skin" ],
    cruelty_free: "Yes"
  },
  variants: [
    { name: "30ml", price: 8, size_value: 30, size_unit: "ml", size_type: "volume" },
    { name: "60ml", price: 13, size_value: 60, size_unit: "ml", size_type: "volume" }
  ],
  image_url: "https://picsum.photos/400/400?random=2015"
)

create_complete_product(
  name: "Retinol 0.5% in Squalane",
  subtitle: "Moderate-strength anti-aging serum",
  brand: brands["the-ordinary"],
  categories: [ categories["skincare"] ],
  product_type: "serum",
  price: 10,
  description: "A moderate-strength retinol serum in squalane base for experienced retinol users. Targets signs of aging while being gentle on skin.",
  how_to_use: "**Evening Only:** Apply a few drops to face after water-based serums. **Start Slowly:** Use 2-3 times per week, building tolerance. **Sun Protection:** Always use SPF the next morning.",
  ingredients: "Squalane, Retinol, Solanum Lycopersicum (Tomato) Fruit Extract, Rosmarinus Officinalis (Rosemary) Leaf Extract",
  attributes: {
    skin_type: [ "Normal", "Combination", "Mature" ],
    intended_for: [ "Face" ],
    application_area: "Face, avoiding eye area",
    suitable_for: [ "Experienced Users" ],
    cruelty_free: "Yes"
  },
  variants: [
    { name: "30ml", price: 10, size_value: 30, size_unit: "ml", size_type: "volume" }
  ],
  image_url: "https://picsum.photos/400/400?random=2016"
)

puts "\n📍 Creating Rare Beauty products..."

create_complete_product(
  name: "Soft Pinch Liquid Blush",
  subtitle: "Weightless liquid blush for natural flush",
  brand: brands["rare-beauty"],
  categories: [ categories["face"] ],
  product_type: "blush",
  price: 23,
  description: "A weightless, long-wearing liquid blush that builds and blends seamlessly for a soft, healthy flush that lasts all day.",
  how_to_use: "**Application:** Squeeze a small amount onto the back of your hand or directly onto cheeks. **Blending:** Gently pat and blend with fingertips or a damp sponge. **Build Color:** Add more for intensity.",
  ingredients: "Water/Aqua/Eau, Dimethicone, Butylene Glycol, Glycerin, PEG-10 Dimethicone, Synthetic Fluorphlogopite, Mica",
  attributes: {
    texture: "Liquid",
    finish: "Natural",
    intended_for: [ "Face" ],
    application_area: "Cheeks, temples",
    suitable_for: [ "All" ],
    cruelty_free: "Yes"
  },
  variants: [
    { name: "Joy - Soft Berry", price: 23, color: "Berry", color_hex: "#B85A8E", size_value: 15, size_unit: "ml", size_type: "volume" },
    { name: "Bliss - Soft Peach", price: 23, color: "Peach", color_hex: "#F4A6A6", size_value: 15, size_unit: "ml", size_type: "volume" },
    { name: "Hope - Soft Pink", price: 23, color: "Pink", color_hex: "#E8B8AB", size_value: 15, size_unit: "ml", size_type: "volume" }
  ],
  image_url: "https://picsum.photos/400/400?random=2017"
)

create_complete_product(
  name: "Perfect Strokes Universal Volumizing Mascara",
  subtitle: "Universal mascara with hourglass brush",
  brand: brands["rare-beauty"],
  categories: [ categories["eyes"] ],
  product_type: "mascara",
  price: 20,
  description: "A universal mascara with a unique hourglass-shaped brush that lifts, lengthens, and volumizes lashes for a natural or dramatic look.",
  how_to_use: "**Application:** Start at lash base and wiggle brush upward through lashes. **Building:** Apply multiple coats while wet for more drama. **Lower Lashes:** Use tip of brush for precision.",
  ingredients: "Water/Aqua/Eau, Paraffin, Potassium Cetyl Phosphate, Copernicia Cerifera (Carnauba) Wax, Ethylene/Acrylic Acid Copolymer",
  attributes: {
    texture: "Liquid",
    water_resistant: "No",
    intended_for: [ "Eyes" ],
    application_area: "Eyelashes",
    suitable_for: [ "All" ],
    cruelty_free: "Yes"
  },
  variants: [
    { name: "Black", price: 20, color: "Black", color_hex: "#000000", size_value: 10, size_unit: "ml", size_type: "volume" },
    { name: "Brown", price: 20, color: "Brown", color_hex: "#8B4513", size_value: 10, size_unit: "ml", size_type: "volume" }
  ],
  image_url: "https://picsum.photos/400/400?random=2018"
)

create_complete_product(
  name: "Kind Words Matte Lip Liner",
  subtitle: "Long-wearing highly pigmented lip liner",
  brand: brands["rare-beauty"],
  categories: [ categories["lips"] ],
  product_type: "lip_liner",
  price: 14,
  description: "A long-wearing, highly pigmented lip liner that glides on smoothly and helps lip color stay put all day.",
  how_to_use: "**Outlining:** Start at the center of lips and work outward following natural lip line. **Filling:** Fill in entire lip as a base for lipstick. **Solo Wear:** Wear alone for a matte lip look.",
  ingredients: "Dimethicone, Synthetic Wax, Caprylyl Methicone, Phenyl Trimethicone, Polyethylene, Mica, Silica",
  attributes: {
    texture: "Matte",
    finish: "Matte",
    intended_for: [ "Lips" ],
    application_area: "Lip line and lips",
    suitable_for: [ "All" ],
    cruelty_free: "Yes"
  },
  variants: [
    { name: "Grateful - Nude Pink", price: 14, color: "Nude Pink", color_hex: "#E8B8AB", size_value: 1.1, size_unit: "g", size_type: "weight" },
    { name: "Brave - Deep Berry", price: 14, color: "Berry", color_hex: "#B85A8E", size_value: 1.1, size_unit: "g", size_type: "weight" },
    { name: "Honest - Classic Red", price: 14, color: "Red", color_hex: "#D4232A", size_value: 1.1, size_unit: "g", size_type: "weight" }
  ],
  image_url: "https://picsum.photos/400/400?random=2019"
)

puts "\n📍 Creating additional test products..."

create_complete_product(
  name: "Fenty Eau de Parfum",
  subtitle: "Rihanna's signature warm spicy scent",
  brand: brands["fenty-beauty"],
  categories: [ categories["fragrance"] ],
  product_type: "perfume",
  price: 140,
  description: "Rihanna's signature scent. A warm, spicy, and sweet fragrance that celebrates the many sides of every woman.",
  how_to_use: "**Application:** Spray on pulse points including wrists, behind ears, and neck. **Layering:** Apply to moisturized skin for longer wear. **Storage:** Keep away from direct sunlight.",
  ingredients: "Alcohol Denat., Fragrance (Parfum), Water (Aqua), Alpha-Isomethyl Ionone, Benzyl Salicylate, Citronellol",
  attributes: {
    fragrance_family: "Oriental Spicy",
    longevity: "Long-lasting (6+ hours)",
    sillage: "Moderate",
    intended_for: [ "Body" ],
    application_area: "Pulse points",
    suitable_for: [ "All" ],
    cruelty_free: "Yes"
  },
  variants: [
    { name: "50ml", price: 140, size_value: 50, size_unit: "ml", size_type: "volume" },
    { name: "10ml Travel", price: 40, size_value: 10, size_unit: "ml", size_type: "volume" }
  ],
  image_url: "https://picsum.photos/400/400?random=2020"
)

create_complete_product(
  name: "Foundation Brush - Precision",
  subtitle: "Dense synthetic brush for flawless application",
  brand: brands["rare-beauty"],
  categories: [ categories["tools"] ],
  product_type: "brush",
  price: 28,
  description: "A dense, synthetic foundation brush designed for flawless, full-coverage application. Cruelty-free and easy to clean.",
  how_to_use: "**Application:** Dot foundation on face, then buff in circular motions for seamless blending. **Cleaning:** Wash weekly with gentle brush cleanser and lay flat to dry.",
  ingredients: "Synthetic Taklon bristles, Aluminum ferrule, Wooden handle with matte finish",
  attributes: {
    material: "Synthetic",
    hair_type: "Taklon",
    intended_for: [ "Face" ],
    application_area: "Face",
    suitable_for: [ "All" ],
    cruelty_free: "Yes"
  },
  variants: [
    { name: "Standard", price: 28, size_value: 1, size_unit: "piece", size_type: "quantity" }
  ],
  image_url: "https://picsum.photos/400/400?random=2021"
)

puts "\n📍 Creating products with extensive variants and galleries..."

fenty_foundation_pro = create_complete_product(
  name: "Pro Filt'r Hydrating Longwear Foundation",
  subtitle: "Hydrating sister to the original Pro Filt'r",
  brand: brands["fenty-beauty"],
  categories: [ categories["face"] ],
  product_type: "foundation",
  price: 39,
  description: "The hydrating sister to the original Pro Filt'r foundation. Buildable medium to full coverage with a natural finish that won't cake or look heavy.",
  how_to_use: "**For Best Results:** Start with clean, moisturized skin. Apply 1-2 pumps to a damp beauty sponge. **Application:** Press and roll the sponge from the center of your face outward. **Building Coverage:** Add thin layers as needed for desired coverage level.",
  ingredients: "Water, Dimethicone, Glycerin, Butylene Glycol, Phenyl Trimethicone, Dimethicone/Vinyl Dimethicone Crosspolymer, Sodium Hyaluronate, Tocopheryl Acetate",
  attributes: {
    finish: "Natural",
    skin_type: [ "Dry", "Normal", "Combination" ],
    intended_for: [ "Face" ],
    application_area: "Face and neck",
    suitable_for: [ "All" ],
    cruelty_free: "Yes"
  },
  variants: [
    { name: "100 - Fair with neutral undertones", price: 39, color: "Fair Neutral", color_hex: "#F5C6A5", size_value: 32, size_unit: "ml", size_type: "volume" },
    { name: "110 - Fair with cool undertones", price: 39, color: "Fair Cool", color_hex: "#F4C2A1", size_value: 32, size_unit: "ml", size_type: "volume" },
    { name: "120 - Fair with warm undertones", price: 39, color: "Fair Warm", color_hex: "#F6C8A8", size_value: 32, size_unit: "ml", size_type: "volume" },
    { name: "130 - Fair with olive undertones", price: 39, color: "Fair Olive", color_hex: "#F0C4A2", size_value: 32, size_unit: "ml", size_type: "volume" },
    { name: "150 - Light with neutral undertones", price: 39, color: "Light Neutral", color_hex: "#EDBF99", size_value: 32, size_unit: "ml", size_type: "volume" },
    { name: "160 - Light with cool undertones", price: 39, color: "Light Cool", color_hex: "#ECBA94", size_value: 32, size_unit: "ml", size_type: "volume" },
    { name: "170 - Light with warm undertones", price: 39, color: "Light Warm", color_hex: "#F0C29C", size_value: 32, size_unit: "ml", size_type: "volume" },
    { name: "180 - Light with olive undertones", price: 39, color: "Light Olive", color_hex: "#E9BE98", size_value: 32, size_unit: "ml", size_type: "volume" },
    { name: "200 - Light-Medium with neutral undertones", price: 39, color: "Light-Medium Neutral", color_hex: "#E2B18A", size_value: 32, size_unit: "ml", size_type: "volume" },
    { name: "210 - Light-Medium with cool undertones", price: 39, color: "Light-Medium Cool", color_hex: "#E0AC85", size_value: 32, size_unit: "ml", size_type: "volume" },
    { name: "220 - Light-Medium with warm undertones", price: 39, color: "Light-Medium Warm", color_hex: "#E8B896", size_value: 32, size_unit: "ml", size_type: "volume" },
    { name: "230 - Light-Medium with olive undertones", price: 39, color: "Light-Medium Olive", color_hex: "#DEB088", size_value: 32, size_unit: "ml", size_type: "volume" },
    { name: "250 - Medium with neutral undertones", price: 39, color: "Medium Neutral", color_hex: "#D7A47B", size_value: 32, size_unit: "ml", size_type: "volume" },
    { name: "260 - Medium with cool undertones", price: 39, color: "Medium Cool", color_hex: "#D49F76", size_value: 32, size_unit: "ml", size_type: "volume" },
    { name: "270 - Medium with warm undertones", price: 39, color: "Medium Warm", color_hex: "#D4A574", size_value: 32, size_unit: "ml", size_type: "volume" },
    { name: "280 - Medium with olive undertones", price: 39, color: "Medium Olive", color_hex: "#CFA378", size_value: 32, size_unit: "ml", size_type: "volume" },
    { name: "300 - Medium-Deep with neutral undertones", price: 39, color: "Medium-Deep Neutral", color_hex: "#C4956B", size_value: 32, size_unit: "ml", size_type: "volume" },
    { name: "310 - Medium-Deep with cool undertones", price: 39, color: "Medium-Deep Cool", color_hex: "#C19066", size_value: 32, size_unit: "ml", size_type: "volume" },
    { name: "320 - Medium-Deep with warm undertones", price: 39, color: "Medium-Deep Warm", color_hex: "#C89769", size_value: 32, size_unit: "ml", size_type: "volume" },
    { name: "330 - Medium-Deep with olive undertones", price: 39, color: "Medium-Deep Olive", color_hex: "#BE936A", size_value: 32, size_unit: "ml", size_type: "volume" },
    { name: "350 - Deep with neutral undertones", price: 39, color: "Deep Neutral", color_hex: "#B0855A", size_value: 32, size_unit: "ml", size_type: "volume" },
    { name: "360 - Deep with cool undertones", price: 39, color: "Deep Cool", color_hex: "#AD8055", size_value: 32, size_unit: "ml", size_type: "volume" },
    { name: "370 - Deep with warm undertones", price: 39, color: "Deep Warm", color_hex: "#B38759", size_value: 32, size_unit: "ml", size_type: "volume" },
    { name: "385 - Deep with olive undertones", price: 39, color: "Deep Olive", color_hex: "#A67C52", size_value: 32, size_unit: "ml", size_type: "volume" }
  ],
  image_url: "https://picsum.photos/400/400?random=2022"
)

if fenty_foundation_pro
  gallery_urls = [
    "https://picsum.photos/400/400?random=101",
    "https://picsum.photos/400/400?random=102",
    "https://picsum.photos/400/400?random=103",
    "https://picsum.photos/400/400?random=104",
    "https://picsum.photos/400/400?random=105"
  ]

  gallery_urls.each_with_index do |url, index|
    begin
      require 'open-uri'
      image_data = URI.open(url)
      filename = "#{fenty_foundation_pro.slug}-gallery-#{index + 1}.jpg"

      fenty_foundation_pro.default_variant.images.attach(
        io: image_data,
        filename: filename,
        content_type: 'image/jpeg'
      )
      puts "    ✅ Gallery image #{index + 1} attached"
    rescue => e
      puts "    ⚠️ Gallery image #{index + 1} failed: #{e.message}"
    end
  end
end

charlotte_palette = create_complete_product(
  name: "Luxury Palette - The Queen of Glow",
  subtitle: "12 mesmerizing shades for every occasion",
  brand: brands["charlotte-tilbury"],
  categories: [ categories["eyes"] ],
  product_type: "eyeshadow",
  price: 75,
  description: "A luxury eyeshadow palette featuring 12 mesmerizing shades that deliver intense color payoff and seamless blendability. From champagne highlights to smoky browns.",
  how_to_use: "**Base:** Apply lighter shades across the lid. **Definition:** Use medium tones in the crease. **Drama:** Deepen with darker shades in outer corner. **Highlight:** Add shimmer to inner corner and brow bone.",
  ingredients: "Mica, Talc, Dimethicone, Zinc Stearate, Phenoxyethanol, Caprylyl Glycol, Tin Oxide, Iron Oxides, Titanium Dioxide",
  attributes: {
    texture: "Powder",
    finish: "Matte & Shimmer",
    intended_for: [ "Eyes" ],
    application_area: "Eyelids",
    suitable_for: [ "All" ],
    cruelty_free: "Yes"
  },
  variants: [
    { name: "Champagne Pop - Warm shimmer", price: 75, color: "Champagne", color_hex: "#F7E7CE", size_value: 39, size_unit: "g", size_type: "weight" },
    { name: "Bronzed Garnet - Deep bronze", price: 75, color: "Bronze", color_hex: "#CD7F32", size_value: 39, size_unit: "g", size_type: "weight" },
    { name: "Golden Goddess - Warm gold", price: 75, color: "Gold", color_hex: "#FFD700", size_value: 39, size_unit: "g", size_type: "weight" },
    { name: "Copper Charge - Metallic copper", price: 75, color: "Copper", color_hex: "#B87333", size_value: 39, size_unit: "g", size_type: "weight" },
    { name: "Rose Gold - Pink gold", price: 75, color: "Rose Gold", color_hex: "#E8B4A0", size_value: 39, size_unit: "g", size_type: "weight" },
    { name: "Smoky Quartz - Cool brown", price: 75, color: "Brown", color_hex: "#704214", size_value: 39, size_unit: "g", size_type: "weight" },
    { name: "Midnight Matte - Deep black", price: 75, color: "Black", color_hex: "#000000", size_value: 39, size_unit: "g", size_type: "weight" },
    { name: "Chocolate - Warm brown", price: 75, color: "Chocolate", color_hex: "#7B3F00", size_value: 39, size_unit: "g", size_type: "weight" },
    { name: "Nude Pink - Soft pink", price: 75, color: "Pink", color_hex: "#E8B8AB", size_value: 39, size_unit: "g", size_type: "weight" },
    { name: "Pearl - Iridescent white", price: 75, color: "Pearl", color_hex: "#F8F6F0", size_value: 39, size_unit: "g", size_type: "weight" },
    { name: "Plum Perfect - Deep plum", price: 75, color: "Plum", color_hex: "#8E4585", size_value: 39, size_unit: "g", size_type: "weight" },
    { name: "Vintage Vamp - Burgundy", price: 75, color: "Burgundy", color_hex: "#800020", size_value: 39, size_unit: "g", size_type: "weight" }
  ],
  image_url: "https://picsum.photos/400/400?random=2023"
)

if charlotte_palette
  palette_gallery_urls = [
    "https://picsum.photos/400/400?random=201",
    "https://picsum.photos/400/400?random=202",
    "https://picsum.photos/400/400?random=203",
    "https://picsum.photos/400/400?random=204",
    "https://picsum.photos/400/400?random=205",
    "https://picsum.photos/400/400?random=206"
  ]

  palette_gallery_urls.each_with_index do |url, index|
    begin
      require 'open-uri'
      image_data = URI.open(url)
      filename = "#{charlotte_palette.slug}-gallery-#{index + 1}.jpg"

      charlotte_palette.default_variant.images.attach(
        io: image_data,
        filename: filename,
        content_type: 'image/jpeg'
      )
      puts "    ✅ Palette gallery image #{index + 1} attached"
    rescue => e
      puts "    ⚠️ Palette gallery image #{index + 1} failed: #{e.message}"
    end
  end
end

create_complete_product(
  name: "Vitamin C Suspension 23% + HA Spheres 2%",
  subtitle: "Water-free stable vitamin C suspension",
  brand: brands["the-ordinary"],
  categories: [ categories["skincare"] ],
  product_type: "serum",
  price: 8,
  description: "A water-free, stable vitamin C suspension with 23% L-Ascorbic Acid and 2% Hyaluronic Acid spheres. This textured formula provides direct vitamin C benefits.",
  how_to_use: "**Evening Use Only:** Apply a small amount to face. **Important:** Patch test first. **Mixing:** Can be mixed with other treatments. **Sun Protection:** Use SPF during the day.",
  ingredients: "Ascorbic Acid, Squalane, Isodecyl Neopentanoate, Isononyl Isononanoate, Coconut Alkanes, Ethylene/Propylene/Styrene Copolymer",
  attributes: {
    skin_type: [ "Normal", "Combination", "Oily" ],
    intended_for: [ "Face" ],
    application_area: "Face, avoiding eye area",
    suitable_for: [ "Experienced Users" ],
    cruelty_free: "Yes"
  },
  variants: [
    { name: "15ml - Travel Size", price: 8, size_value: 15, size_unit: "ml", size_type: "volume" },
    { name: "30ml - Standard", price: 12, size_value: 30, size_unit: "ml", size_type: "volume" },
    { name: "60ml - Value Size", price: 20, size_value: 60, size_unit: "ml", size_type: "volume" },
    { name: "100ml - Professional", price: 32, size_value: 100, size_unit: "ml", size_type: "volume" },
    { name: "200ml - Salon Size", price: 55, size_value: 200, size_unit: "ml", size_type: "volume" }
  ],
  image_url: "https://picsum.photos/400/400?random=2024"
)

rare_blush_collection = create_complete_product(
  name: "Soft Pinch Liquid Blush Collection",
  subtitle: "15 beautiful shades for every skin tone",
  brand: brands["rare-beauty"],
  categories: [ categories["face"] ],
  product_type: "blush",
  price: 23,
  description: "A weightless, long-wearing liquid blush that builds and blends seamlessly. Available in 15 beautiful shades to complement every skin tone.",
  how_to_use: "**Application:** Use fingertips or a damp sponge to blend. **Building:** Start with a small amount and build coverage. **Placement:** Apply to apples of cheeks and blend upward.",
  ingredients: "Water, Dimethicone, Butylene Glycol, Glycerin, PEG-10 Dimethicone, Synthetic Fluorphlogopite, Mica, Phenoxyethanol",
  attributes: {
    texture: "Liquid",
    finish: "Natural",
    intended_for: [ "Face" ],
    application_area: "Cheeks, temples",
    suitable_for: [ "All" ],
    cruelty_free: "Yes"
  },
  variants: [],
  image_url: "https://picsum.photos/400/400?random=2025"
)

if rare_blush_collection
  blush_variant_data = [
    { name: "Encourage - Soft coral", price: 23, color: "Coral", color_hex: "#FF7F7F", stock: 0, size_value: 15, size_unit: "ml", size_type: "volume" },
    { name: "Joy - Soft berry", price: 23, color: "Berry", color_hex: "#B85A8E", stock: 18, size_value: 15, size_unit: "ml", size_type: "volume" },
    { name: "Bliss - Soft peach", price: 23, color: "Peach", color_hex: "#F4A6A6", stock: 0, size_value: 15, size_unit: "ml", size_type: "volume" }, # OUT OF STOCK
    { name: "Hope - Soft pink", price: 23, color: "Pink", color_hex: "#E8B8AB", stock: 30, size_value: 15, size_unit: "ml", size_type: "volume" },
    { name: "Happy - Bright coral", price: 23, color: "Bright Coral", color_hex: "#FF6347", stock: 12, size_value: 15, size_unit: "ml", size_type: "volume" },
    { name: "Grateful - Warm rose", price: 23, color: "Rose", color_hex: "#FFB6C1", stock: 0, size_value: 15, size_unit: "ml", size_type: "volume" }, # OUT OF STOCK
    { name: "Believe - Deep plum", price: 23, color: "Plum", color_hex: "#8E4585", stock: 8, size_value: 15, size_unit: "ml", size_type: "volume" },
    { name: "Faith - Mauve pink", price: 23, color: "Mauve", color_hex: "#E0B0FF", stock: 22, size_value: 15, size_unit: "ml", size_type: "volume" },
    { name: "Brave - Deep berry", price: 23, color: "Deep Berry", color_hex: "#8B0000", stock: 15, size_value: 15, size_unit: "ml", size_type: "volume" },
    { name: "Confident - Terracotta", price: 23, color: "Terracotta", color_hex: "#E2725B", stock: 0, size_value: 15, size_unit: "ml", size_type: "volume" }, # OUT OF STOCK
    { name: "Inspire - Dusty rose", price: 23, color: "Dusty Rose", color_hex: "#DCAE96", stock: 28, size_value: 15, size_unit: "ml", size_type: "volume" },
    { name: "Worthy - Nude pink", price: 23, color: "Nude Pink", color_hex: "#E8B8AB", stock: 20, size_value: 15, size_unit: "ml", size_type: "volume" },
    { name: "Grace - Soft lavender", price: 23, color: "Lavender", color_hex: "#E6E6FA", stock: 5, size_value: 15, size_unit: "ml", size_type: "volume" }, # LOW STOCK
    { name: "Strong - Brick red", price: 23, color: "Brick Red", color_hex: "#B22222", stock: 35, size_value: 15, size_unit: "ml", size_type: "volume" },
    { name: "Fearless - Deep raspberry", price: 23, color: "Raspberry", color_hex: "#E30B5D", stock: 0, size_value: 15, size_unit: "ml", size_type: "volume" } # OUT OF STOCK
  ]

  blush_variant_data.each_with_index do |variant_info, index|
    variant = ProductVariant.find_or_create_by!(product: rare_blush_collection, name: variant_info[:name]) do |v|
      v.sku = "#{rare_blush_collection.id}-#{variant_info[:color].upcase.gsub(' ', '')}-#{rand(100..999)}"
      v.price = Money.new(variant_info[:price] * 100)
      v.stock_quantity = variant_info[:stock]
      v.position = index + 1
      v.color = variant_info[:color]
      v.size_value = variant_info[:size_value] if variant_info[:size_value]
      v.size_unit = variant_info[:size_unit] if variant_info[:size_unit]
      v.size_type = variant_info[:size_type] if variant_info[:size_type]
    end

    updates_needed = {}
    updates_needed[:stock_quantity] = variant_info[:stock] if variant.persisted? && variant.stock_quantity != variant_info[:stock]
    updates_needed[:color] = variant_info[:color] if variant_info[:color] && variant.color != variant_info[:color]
    updates_needed[:size_value] = variant_info[:size_value] if variant_info[:size_value] && variant.size_value != variant_info[:size_value]
    updates_needed[:size_unit] = variant_info[:size_unit] if variant_info[:size_unit] && variant.size_unit != variant_info[:size_unit]
    updates_needed[:size_type] = variant_info[:size_type] if variant_info[:size_type] && variant.size_type != variant_info[:size_type]

    if updates_needed.any?
      variant.update!(updates_needed)
    end
  end
end

if rare_blush_collection
  blush_gallery_urls = [
    "https://picsum.photos/400/400?random=301",
    "https://picsum.photos/400/400?random=302",
    "https://picsum.photos/400/400?random=303",
    "https://picsum.photos/400/400?random=304",
    "https://picsum.photos/400/400?random=305"
  ]

  blush_gallery_urls.each_with_index do |url, index|
    begin
      require 'open-uri'
      image_data = URI.open(url)
      filename = "#{rare_blush_collection.slug}-gallery-#{index + 1}.jpg"

      rare_blush_collection.default_variant.images.attach(
        io: image_data,
        filename: filename,
        content_type: 'image/jpeg'
      )
      puts "    ✅ Blush gallery image #{index + 1} attached"
    rescue => e
      puts "    ⚠️ Blush gallery image #{index + 1} failed: #{e.message}"
    end
  end
end

charlotte_out_of_stock = create_complete_product(
  name: "Pillow Talk Eyeshadow Palette - Limited Edition",
  subtitle: "4 mesmerizing shades with some sold out",
  brand: brands["charlotte-tilbury"],
  categories: [ categories["eyes"] ],
  product_type: "eyeshadow",
  price: 55,
  description: "A limited edition eyeshadow palette featuring the iconic Pillow Talk shades. Some shades are selling fast and may be out of stock.",
  how_to_use: "**Application:** Apply lighter shades across the lid, use medium tones in the crease. **Highlight:** Add shimmer to inner corner and brow bone.",
  ingredients: "Mica, Talc, Dimethicone, Zinc Stearate, Phenoxyethanol, Caprylyl Glycol, Tin Oxide, Iron Oxides, Titanium Dioxide",
  attributes: {
    texture: "Powder",
    finish: "Matte & Shimmer",
    intended_for: [ "Eyes" ],
    application_area: "Eyelids",
    suitable_for: [ "All" ],
    cruelty_free: "Yes"
  },
  variants: [],
  image_url: "https://picsum.photos/400/400?random=2026"
)

if charlotte_out_of_stock
  out_of_stock_variant_data = [
    { name: "Pillow Talk - Rosy nude", color: "Rosy Nude", color_hex: "#E8B8AB", price: 55, stock: 12, size_value: 16, size_unit: "g", size_type: "weight" },
    { name: "Champagne Pop - Light gold", color: "Champagne", color_hex: "#F7E7CE", price: 55, stock: 0, size_value: 16, size_unit: "g", size_type: "weight" }, # OUT OF STOCK
    { name: "Smoky Rose - Deep rose", color: "Smoky Rose", color_hex: "#C85A8E", price: 55, stock: 8, size_value: 16, size_unit: "g", size_type: "weight" },
    { name: "Bronze Glow - Warm bronze", color: "Bronze", color_hex: "#CD7F32", price: 55, stock: 0, size_value: 16, size_unit: "g", size_type: "weight" }, # OUT OF STOCK
    { name: "Nude Pink - Soft pink", color: "Nude Pink", color_hex: "#E8B8AB", price: 55, stock: 15, size_value: 16, size_unit: "g", size_type: "weight" }
  ]

  out_of_stock_variant_data.each_with_index do |variant_info, index|
    variant = ProductVariant.find_or_create_by!(product: charlotte_out_of_stock, name: variant_info[:name]) do |v|
      v.sku = "#{charlotte_out_of_stock.id}-#{variant_info[:color].upcase.gsub(' ', '')}-#{rand(100..999)}"
      v.price = Money.new(variant_info[:price] * 100)
      v.stock_quantity = variant_info[:stock]
      v.position = index + 1
      v.color = variant_info[:color]
      v.size_value = variant_info[:size_value] if variant_info[:size_value]
      v.size_unit = variant_info[:size_unit] if variant_info[:size_unit]
      v.size_type = variant_info[:size_type] if variant_info[:size_type]
    end

    if variant.persisted? && variant.stock_quantity != variant_info[:stock]
      variant.update!(stock_quantity: variant_info[:stock])
    end
  end

  puts "  ✅ Pillow Talk Eyeshadow Palette - Charlotte Tilbury (with out-of-stock shades)"
end

puts "  ✅ Added 5 products with extensive variants and multiple images"

charlotte_moisturizer = create_complete_product(
  name: "Magic Cream Moisturizer Deluxe Collection",
  subtitle: "Award-winning Magic Cream in multiple sizes",
  brand: brands["charlotte-tilbury"],
  categories: [ categories["skincare"] ],
  product_type: "moisturizer",
  price: 35,
  description: "The award-winning Magic Cream in multiple convenient sizes. Hydrates, plumps, and primes skin for a smooth, luminous complexion.",
  how_to_use: "**Application:** Apply to clean skin morning and evening. **Amount:** Use a small amount - a little goes a long way. **Pre-Makeup:** Allow to absorb for 5 minutes before applying foundation.",
  ingredients: "Aqua/Water/Eau, Glycerin, Caprylic/Capric Triglyceride, Dimethicone, Butyrospermum Parkii (Shea) Butter, Hyaluronic Acid",
  attributes: {
    skin_type: [ "Dry", "Normal", "Combination" ],
    intended_for: [ "Face" ],
    application_area: "Face and neck",
    suitable_for: [ "All" ],
    cruelty_free: "Yes"
  },
  variants: [],
  image_url: "https://picsum.photos/400/400?random=2027"
)

if charlotte_moisturizer
  variant_data = [
    { name: "15ml Travel", price: 35, size_value: 15, size_unit: "ml", size_type: "volume", stock: 25 },
    { name: "30ml Standard", price: 65, size_value: 30, size_unit: "ml", size_type: "volume", stock: 0 }, # OUT OF STOCK
    { name: "50ml Value", price: 100, size_value: 50, size_unit: "ml", size_type: "volume", stock: 18 },
    { name: "100ml Professional", price: 175, size_value: 100, size_unit: "ml", size_type: "volume", stock: 12 },
    { name: "200ml Salon", price: 295, size_value: 200, size_unit: "ml", size_type: "volume", stock: 0 } # OUT OF STOCK
  ]

  variant_data.each_with_index do |variant_info, index|
    ProductVariant.find_or_create_by!(product: charlotte_moisturizer, name: variant_info[:name]) do |v|
      v.sku = "#{charlotte_moisturizer.id}-#{variant_info[:name].upcase.gsub(' ', '')}-#{rand(100..999)}"
      v.price = Money.new(variant_info[:price] * 100)
      v.stock_quantity = variant_info[:stock]
      v.position = index + 1
      v.size_value = variant_info[:size_value]
      v.size_unit = variant_info[:size_unit]
      v.size_type = variant_info[:size_type]
    end
  end

  puts "  ✅ Magic Cream Moisturizer Deluxe Collection - Charlotte Tilbury (with out-of-stock variants)"
end

puts "\n🚫 Creating products with all variants out of stock for OOS testing..."

sold_out_lipstick = create_complete_product(
  name: "Limited Edition Velvet Matte Lipstick Set",
  subtitle: "Sold out - Limited holiday collection",
  brand: brands["charlotte-tilbury"],
  categories: [ categories["lips"] ],
  product_type: "lipstick",
  price: 42,
  description: "Our most coveted limited edition matte lipstick collection in exclusive holiday shades. This collection sold out within hours of launch.",
  how_to_use: "Apply directly from bullet for full coverage or dab onto lips for a softer look.",
  ingredients: "Dimethicone, Bis-Diglyceryl Polyacyladipate-2, Hydrogenated Polyisobutene, Kaolin",
  attributes: {
    finish: [ "Matte" ],
    coverage: [ "Full" ],
    long_wearing: "Yes",
    limited_edition: "Yes",
    cruelty_free: "Yes"
  },
  variants: [
    {
      name: "Midnight Rose - Deep burgundy",
      color: "Midnight Rose",
      color_hex: "#722F37",
      price: 42,
      size_value: 3.5,
      size_unit: "g",
      size_type: "weight",
      sales_count: 300,
      conversion_score: 0.18,
      is_default: true,
      canonical_variant: false
    },
    {
      name: "Golden Hour - Warm nude",
      color: "Golden Hour",
      color_hex: "#D4A574",
      price: 42,
      size_value: 3.5,
      size_unit: "g",
      size_type: "weight",
      sales_count: 280,
      conversion_score: 0.16,
      is_default: false,
      canonical_variant: true
    },
    {
      name: "Starlight - Shimmering pink",
      color: "Starlight",
      color_hex: "#F8B8D4",
      price: 42,
      size_value: 3.5,
      size_unit: "g",
      size_type: "weight",
      sales_count: 250,
      conversion_score: 0.14,
      is_default: false,
      canonical_variant: false
    }
  ],
  image_url: "https://picsum.photos/800/600?random=2028"
)

if sold_out_lipstick
  sold_out_lipstick.product_variants.update_all(stock_quantity: 0)
  puts "  ✅ Limited Edition Velvet Matte Lipstick Set (ALL VARIANTS OUT OF STOCK)"
end

sold_out_serum = create_complete_product(
  name: "Miracle Recovery Serum",
  subtitle: "Temporarily out of stock - High demand item",
  brand: brands["the-ordinary"],
  categories: [ categories["skincare"] ],
  product_type: "serum",
  price: 25,
  description: "Our bestselling recovery serum with breakthrough peptide technology. Currently out of stock due to overwhelming demand and supply chain delays.",
  how_to_use: "Apply 2-3 drops to clean skin in the evening. Follow with moisturizer.",
  ingredients: "Water, Glycerin, Propanediol, Acetyl Hexapeptide-8, Palmitoyl Tripeptide-1",
  attributes: {
    skin_type: [ "All" ],
    intended_for: [ "Face" ],
    application_area: "Face and neck",
    suitable_for: [ "All" ],
    cruelty_free: "Yes"
  },
  variants: [
    {
      name: "15ml - Travel Size",
      price: 15,
      size_value: 15,
      size_unit: "ml",
      size_type: "volume",
      sales_count: 180,
      conversion_score: 0.13,
      is_default: false,
      canonical_variant: false
    },
    {
      name: "30ml - Standard",
      price: 25,
      size_value: 30,
      size_unit: "ml",
      size_type: "volume",
      sales_count: 350,
      conversion_score: 0.19,
      is_default: true,
      canonical_variant: true
    },
    {
      name: "60ml - Value Size",
      price: 45,
      size_value: 60,
      size_unit: "ml",
      size_type: "volume",
      sales_count: 220,
      conversion_score: 0.15,
      is_default: false,
      canonical_variant: false
    }
  ],
  image_url: "https://picsum.photos/400/400?random=2029"
)

if sold_out_serum
  sold_out_serum.product_variants.update_all(stock_quantity: 0)
  puts "  ✅ Miracle Recovery Serum (ALL VARIANTS OUT OF STOCK)"
end

# Sold out foundation
sold_out_foundation = create_complete_product(
  name: "Perfect Match Foundation",
  subtitle: "Out of stock - Restocking soon",
  brand: brands["fenty-beauty"],
  categories: [ categories["face"] ],
  product_type: "foundation",
  price: 38,
  description: "Our most popular foundation formula that provides flawless coverage for all skin tones. Currently sold out due to viral social media popularity.",
  how_to_use: "Apply with brush, sponge, or fingers for buildable coverage.",
  ingredients: "Water, Cyclopentasiloxane, Dimethicone, Glycerin, PEG-10 Dimethicone",
  attributes: {
    finish: [ "Natural" ],
    coverage: [ "Medium", "Full" ],
    skin_type: [ "All" ],
    long_wearing: "Yes",
    cruelty_free: "Yes"
  },
  variants: [
    {
      name: "Light Medium",
      color: "Light Medium",
      color_hex: "#E2B18A",
      price: 38,
      size_value: 32,
      size_unit: "ml",
      size_type: "volume",
      sales_count: 420,
      conversion_score: 0.22,
      is_default: true,
      canonical_variant: true
    },
    {
      name: "Medium",
      color: "Medium",
      color_hex: "#D7A47B",
      price: 38,
      size_value: 32,
      size_unit: "ml",
      size_type: "volume",
      sales_count: 390,
      conversion_score: 0.20,
      is_default: false,
      canonical_variant: false
    },
    {
      name: "Medium Deep",
      color: "Medium Deep",
      color_hex: "#C4956B",
      price: 38,
      size_value: 32,
      size_unit: "ml",
      size_type: "volume",
      sales_count: 360,
      conversion_score: 0.18,
      is_default: false,
      canonical_variant: false
    }
  ],
  image_url: "https://picsum.photos/400/400?random=2030"
)

if sold_out_foundation
  sold_out_foundation.product_variants.update_all(stock_quantity: 0)
  puts "  ✅ Perfect Match Foundation (ALL VARIANTS OUT OF STOCK)"
end

puts "\n🔥 Creating products with sales, discounts, and hit status..."

hit_foundation_sale = create_complete_product(
  name: "Viral Glow Foundation - TikTok Famous",
  subtitle: "🔥 TRENDING NOW • 20% OFF Limited Time",
  brand: brands["fenty-beauty"],
  categories: [ categories["face"] ],
  product_type: "foundation",
  price: 42,
  description: "The foundation that broke TikTok! This viral sensation delivers an unmatched glow-from-within finish. Limited time 20% discount - grab yours before it sells out again!",
  how_to_use: "**Viral Application Technique:** Apply with damp beauty sponge in stippling motions. **TikTok Tip:** Mix with one drop of facial oil for extra glow.",
  ingredients: "Water, Dimethicone, Glycerin, Hyaluronic Acid, Vitamin C, Peptides",
  attributes: {
    finish: "Radiant Glow",
    coverage: "Medium",
    skin_type: [ "All" ],
    trending: "Yes",
    viral: "TikTok",
    on_sale: "Yes",
    discount_percentage: 20,
    original_price: 42,
    sale_price: 34,
    hit_product: "Yes",
    cruelty_free: "Yes"
  },
  variants: [
    {
      name: "Fair Glow", price: 34, color: "Fair", color_hex: "#F4C2A1",
      size_value: 30, size_unit: "ml", size_type: "volume",
      sales_count: 850, conversion_score: 0.28, is_default: true
    },
    {
      name: "Light Glow", price: 34, color: "Light", color_hex: "#EDBF99",
      size_value: 30, size_unit: "ml", size_type: "volume",
      sales_count: 920, conversion_score: 0.32
    },
    {
      name: "Medium Glow", price: 34, color: "Medium", color_hex: "#D7A47B",
      size_value: 30, size_unit: "ml", size_type: "volume",
      sales_count: 1100, conversion_score: 0.35
    },
    {
      name: "Deep Glow", price: 34, color: "Deep", color_hex: "#B0855A",
      size_value: 30, size_unit: "ml", size_type: "volume",
      sales_count: 780, conversion_score: 0.29
    }
  ],
  image_url: "https://picsum.photos/400/400?random=2031"
)

if hit_foundation_sale
  hit_foundation_sale.product_variants.each do |variant|
    variant.update!(
      compare_at_price: Money.new(4200),
      price: Money.new(3400)
    )
  end
end

hit_lipstick_sale = create_complete_product(
  name: "Pillow Talk Bestseller - Award Winner",
  subtitle: "🏆 #1 BESTSELLER • 15% OFF Flash Sale",
  brand: brands["charlotte-tilbury"],
  categories: [ categories["lips"] ],
  product_type: "lipstick",
  price: 34,
  description: "The award-winning, #1 bestselling lipstick that launched a thousand dupes! Flash sale - 15% off for 48 hours only. This iconic nude has won over 20 beauty awards.",
  how_to_use: "**Celebrity Technique:** Apply directly from bullet for full color or dab with finger for a softer look. **Pro Tip:** Pair with matching lip liner for longevity.",
  ingredients: "Dimethicone, Bis-Diglyceryl Polyacyladipate-2, Hydrogenated Polyisobutene",
  attributes: {
    finish: "Matte",
    coverage: "Full",
    awards: [ "Allure Best of Beauty 2023", "Elle Beauty Award", "Glamour Beauty Award" ],
    bestseller: "Yes",
    on_sale: "Yes",
    discount_percentage: 15,
    original_price: 34,
    sale_price: 29,
    hit_product: "Yes",
    limited_time_offer: "48 hours",
    cruelty_free: "Yes"
  },
  variants: [
    {
      name: "Pillow Talk Original", price: 29, color: "Nude Pink", color_hex: "#E8B8AB",
      size_value: 3.5, size_unit: "g", size_type: "weight",
      sales_count: 2500, conversion_score: 0.45, is_default: true, canonical_variant: true
    },
    {
      name: "Pillow Talk Medium", price: 29, color: "Medium Nude", color_hex: "#D4A574",
      size_value: 3.5, size_unit: "g", size_type: "weight",
      sales_count: 1800, conversion_score: 0.38
    },
    {
      name: "Pillow Talk Deep", price: 29, color: "Deep Nude", color_hex: "#B0855A",
      size_value: 3.5, size_unit: "g", size_type: "weight",
      sales_count: 1200, conversion_score: 0.31
    }
  ],
  image_url: "https://picsum.photos/400/400?random=2032"
)

if hit_lipstick_sale
  hit_lipstick_sale.product_variants.each do |variant|
    variant.update!(
      compare_at_price: Money.new(3400),
      price: Money.new(2900)
    )
  end
end

hit_serum_sale = create_complete_product(
  name: "Miracle Glow Serum - Viral Sensation",
  subtitle: "✨ VIRAL HIT • 30% OFF Mega Sale",
  brand: brands["the-ordinary"],
  categories: [ categories["skincare"] ],
  product_type: "serum",
  price: 25,
  description: "The serum that went viral for its instant glow effect! Social media can't stop raving about the results. Mega sale - 30% off while supplies last!",
  how_to_use: "**Viral Method:** Apply 2-3 drops to damp skin for maximum glow. **Influencer Tip:** Use before makeup for that 'glass skin' effect everyone's obsessing over.",
  ingredients: "Niacinamide, Hyaluronic Acid, Vitamin C, Alpha Arbutin, Peptides",
  attributes: {
    skin_type: [ "All" ],
    viral_status: "Instagram + TikTok",
    results: "Instant Glow",
    on_sale: "Yes",
    discount_percentage: 30,
    original_price: 25,
    sale_price: 18,
    hit_product: "Yes",
    supply_limited: "Yes",
    cruelty_free: "Yes"
  },
  variants: [
    {
      name: "Standard Size", price: 18, size_value: 30, size_unit: "ml", size_type: "volume",
      sales_count: 3200, conversion_score: 0.52, is_default: true
    },
    {
      name: "Value Size", price: 32, size_value: 60, size_unit: "ml", size_type: "volume",
      sales_count: 1800, conversion_score: 0.41
    }
  ],
  image_url: "https://picsum.photos/400/400?random=2033"
)

# Update variants with sale pricing
if hit_serum_sale
  hit_serum_sale.product_variants.find_by(name: "Standard Size")&.update!(
    compare_at_price: Money.new(2500),
    price: Money.new(1800)
  )

  hit_serum_sale.product_variants.find_by(name: "Value Size")&.update!(
    compare_at_price: Money.new(4500),
    price: Money.new(3200)
  )
end

create_complete_product(
  name: "Soft Glow Liquid Blush - Trending Shades",
  subtitle: "🌟 TRENDING • Buy 2 Get 1 FREE",
  brand: brands["rare-beauty"],
  categories: [ categories["face"] ],
  product_type: "blush",
  price: 23,
  description: "The blush shades that are trending everywhere! These soft, buildable liquid blushes are flying off the shelves. Special promotion: Buy 2, Get 1 FREE!",
  how_to_use: "**Trending Technique:** Apply with fingertips and blend upward for that natural flush everyone's loving. **Viral Hack:** Mix with highlighter for extra dimension.",
  ingredients: "Water, Dimethicone, Butylene Glycol, Glycerin, Mica",
  attributes: {
    finish: "Natural Flush",
    trending_shades: [ "Sunset Coral", "Peachy Pink", "Berry Flush" ],
    promotion: "Buy 2 Get 1 FREE",
    hit_product: "Yes",
    social_proof: "10M+ views on TikTok",
    cruelty_free: "Yes"
  },
  variants: [
    {
      name: "Sunset Coral - Trending", price: 23, color: "Coral", color_hex: "#FF7F7F",
      size_value: 15, size_unit: "ml", size_type: "volume",
      sales_count: 1500, conversion_score: 0.42, is_default: true
    },
    {
      name: "Peachy Pink - Viral", price: 23, color: "Peachy Pink", color_hex: "#F4A6A6",
      size_value: 15, size_unit: "ml", size_type: "volume",
      sales_count: 1800, conversion_score: 0.48
    },
    {
      name: "Berry Flush - Hit", price: 23, color: "Berry", color_hex: "#B85A8E",
      size_value: 15, size_unit: "ml", size_type: "volume",
      sales_count: 1200, conversion_score: 0.39
    }
  ],
  image_url: "https://picsum.photos/400/400?random=2034"
)

small_discount_concealer = create_complete_product(
  name: "Perfect Coverage Concealer",
  subtitle: "5% off with code BEAUTY5",
  brand: brands["fenty-beauty"],
  categories: [ categories["face"] ],
  product_type: "concealer",
  price: 28,
  description: "Full coverage concealer that doesn't crease or cake. Now with 5% off using code BEAUTY5 at checkout.",
  how_to_use: "Apply directly to blemishes and under-eye area. Blend with fingertips or beauty sponge.",
  ingredients: "Dimethicone, Synthetic Wax, Phenyl Trimethicone, Caprylyl Methicone",
  attributes: {
    finish: "Natural Matte",
    coverage: "Full",
    on_sale: "Yes",
    discount_percentage: 5,
    original_price: 28,
    sale_price: 27,
    discount_code: "BEAUTY5",
    cruelty_free: "Yes"
  },
  variants: [
    { name: "Light", price: 27, color: "Light", color_hex: "#F4C2A1", size_value: 9, size_unit: "ml", size_type: "volume" },
    { name: "Medium", price: 27, color: "Medium", color_hex: "#D7A47B", size_value: 9, size_unit: "ml", size_type: "volume" },
    { name: "Deep", price: 27, color: "Deep", color_hex: "#B0855A", size_value: 9, size_unit: "ml", size_type: "volume" }
  ],
  image_url: "https://picsum.photos/400/400?random=2035"
)

if small_discount_concealer
  small_discount_concealer.product_variants.each do |variant|
    variant.update!(
      compare_at_price: Money.new(2800),
      price: Money.new(2700)
    )
  end
end

create_complete_product(
  name: "Complete Skincare Routine - Value Bundle",
  subtitle: "💝 BUNDLE DEAL • Save $25 when you buy the set",
  brand: brands["the-ordinary"],
  categories: [ categories["skincare"] ],
  product_type: "skincare_set",
  price: 45,
  description: "Complete 4-step skincare routine in one convenient bundle. Individual items worth $70 - save $25 when you buy the complete set!",
  how_to_use: "**Morning:** Cleanser + Serum + Moisturizer. **Evening:** Cleanser + Treatment + Moisturizer + Night Oil. Follow the included routine card for best results.",
  ingredients: "See individual product details for complete ingredient lists",
  attributes: {
    bundle_discount: "$25 savings",
    individual_value: "$70",
    bundle_price: "$45",
    includes: [ "Cleanser 60ml", "Serum 30ml", "Moisturizer 50ml", "Night Oil 15ml" ],
    routine_included: "Yes",
    hit_product: "Yes",
    value_deal: "Yes",
    cruelty_free: "Yes"
  },
  variants: [
    {
      name: "Complete Set", price: 45, size_value: 1, size_unit: "set", size_type: "bundle",
      sales_count: 650, conversion_score: 0.25, is_default: true
    }
  ],
  image_url: "https://picsum.photos/400/400?random=2036"
)

create_complete_product(
  name: "Holiday Glam Eyeshadow Palette - Limited Edition",
  subtitle: "🎁 LIMITED EDITION • Only 1000 made worldwide",
  brand: brands["charlotte-tilbury"],
  categories: [ categories["eyes"] ],
  product_type: "eyeshadow",
  price: 85,
  description: "Exclusive holiday palette with 16 festive shades in luxurious gold packaging. Only 1000 palettes made worldwide - each one numbered and comes with certificate of authenticity.",
  how_to_use: "**Festive Look:** Use champagne shades on lid, deeper berries in crease, and gold highlight on inner corner. **Day to Night:** Start with neutral base, add metallics for evening glamour.",
  ingredients: "Mica, Talc, Dimethicone, Real Gold Flakes, Diamond Powder",
  attributes: {
    limited_quantity: "1000 worldwide",
    packaging: "Luxury Gold Compact",
    includes: [ "Certificate of Authenticity", "Limited Edition Number", "Gold Brush Set" ],
    exclusive: "Yes",
    collectible: "Yes",
    premium: "Yes",
    holiday_collection: "Yes",
    hit_product: "Yes",
    cruelty_free: "Yes"
  },
  variants: [
    {
      name: "Holiday Glam Palette", price: 85, size_value: 48, size_unit: "g", size_type: "weight",
      sales_count: 180, conversion_score: 0.15, is_default: true
    }
  ],
  image_url: "https://picsum.photos/400/400?random=2037"
)

puts "  ✅ Viral Glow Foundation (20% OFF - was $42, now $34)"
puts "  ✅ Pillow Talk Bestseller (15% OFF - was $34, now $29)"
puts "  ✅ Miracle Glow Serum (30% OFF - was $25, now $18)"
puts "  ✅ Soft Glow Liquid Blush (Buy 2 Get 1 FREE promotion)"
puts "  ✅ Perfect Coverage Concealer (5% OFF with code BEAUTY5)"
puts "  ✅ Complete Skincare Routine Bundle (Save $25 - was $70, now $45)"
puts "  ✅ Holiday Glam Limited Edition Palette ($85 - Premium/Exclusive)"

puts "\n📍 Creating sample reviews..."

sample_user = User.find_or_create_by!(email_address: "reviewer@beautystore.com") do |user|
  user.first_name = "Beauty"
  user.last_name = "Enthusiast"
  user.password = "password123"
  user.password_confirmation = "password123"
end

popular_products = Product.limit(8)
review_texts = [
  "Amazing product! Highly recommend for daily use.",
  "Good quality but took some time to see results.",
  "Perfect for my skin type, will definitely repurchase.",
  "Nice texture and easy to apply, great value.",
  "Exceeded my expectations, love the formula!",
  "Works well but wish it came in more shades.",
  "Great for beginners, very forgiving formula.",
  "Premium quality, worth the investment."
]

popular_products.each_with_index do |product, index|
  Review.find_or_create_by!(product: product, user: sample_user) do |review|
    review.rating = [ 4, 5, 4, 5, 5, 4, 4, 5 ][index]
    review.body = review_texts[index]
    review.title = "Great product experience"
    review.status = "approved"
    review.verified_purchase = true
    review.created_at = rand(1..60).days.ago
  end
end

puts "\n🎨 Creating products with multiple images per variant for gallery testing..."

lipstick_collection = create_complete_product(
  name: "Professional Matte Lipstick Collection",
  subtitle: "Ultimate gallery test with 4+ images per shade",
  brand: brands["charlotte-tilbury"],
  categories: [ categories["lips"] ],
  product_type: "lipstick",
  price: 35,
  description: "Professional-grade matte lipsticks with comprehensive product imagery for each shade. Perfect for testing gallery functionality with multiple angles and lighting.",
  how_to_use: "Apply directly from the bullet or use a lip brush for precision application. Each shade photographed in multiple lighting conditions.",
  ingredients: "Dimethicone, Bis-Diglyceryl Polyacyladipate-2, Hydrogenated Polyisobutene",
  attributes: {
    finish: [ "Matte" ],
    coverage: [ "Full" ],
    long_wearing: "Yes",
    cruelty_free: "Yes"
  },
  variants: [
    {
      name: "Pillow Talk - Professional",
      color: "Pillow Talk",
      color_hex: "#E8B8AB",
      price: 35,
      size_value: 3.5,
      size_unit: "g",
      size_type: "weight",
      image_urls: [
        "https://picsum.photos/800/600?random=2038",
        "https://picsum.photos/800/600?random=2039",
        "https://picsum.photos/800/600?random=2040",
        "https://picsum.photos/800/600?random=2041",
        "https://picsum.photos/800/600?random=2042"
      ],
      sales_count: 95,
      conversion_score: 0.09,
      is_default: false
    },
    {
      name: "Red Carpet Red - Professional",
      color: "Red Carpet Red",
      color_hex: "#C41E3A",
      price: 35,
      size_value: 3.5,
      size_unit: "g",
      size_type: "weight",
      image_urls: [
        "https://picsum.photos/800/600?random=2043",
        "https://picsum.photos/800/600?random=2044",
        "https://picsum.photos/800/600?random=2045",
        "https://picsum.photos/800/600?random=2046"
      ],
      sales_count: 150,
      conversion_score: 0.12,
      is_default: true
    },
    {
      name: "Berry Bliss - Professional",
      color: "Berry Bliss",
      color_hex: "#8B3A62",
      price: 35,
      size_value: 3.5,
      size_unit: "g",
      size_type: "weight",
      image_urls: [
        "https://picsum.photos/800/600?random=2047",
        "https://picsum.photos/800/600?random=2048",
        "https://picsum.photos/800/600?random=2049",
        "https://picsum.photos/800/600?random=2050",
        "https://picsum.photos/800/600?random=2051",
        "https://picsum.photos/800/600?random=2052"
      ],
      sales_count: 75,
      conversion_score: 0.08,
      is_default: false
    }
  ]
)

create_complete_product(
  name: "Perfect Match Foundation Gallery Test",
  subtitle: "Foundation shades with comprehensive product imagery",
  brand: brands["fenty-beauty"],
  categories: [ categories["face"] ],
  product_type: "foundation",
  price: 36,
  description: "Professional foundation collection with extensive product imagery per shade. Perfect for testing gallery navigation and thumbnail functionality.",
  how_to_use: "Apply with damp beauty sponge or foundation brush. Each shade photographed in multiple lighting conditions for accurate color matching.",
  ingredients: "Water, Dimethicone, Isododecane, Alcohol Denat, Trimethylsiloxysilicate",
  attributes: {
    finish: "Natural",
    coverage: "Medium to Full",
    skin_type: [ "All" ],
    cruelty_free: "Yes"
  },
  variants: [
    {
      name: "110 - Fair Cool",
      color: "Fair Cool",
      color_hex: "#F4C2A1",
      price: 36,
      size_value: 32,
      size_unit: "ml",
      size_type: "volume",
      image_urls: [
        "https://picsum.photos/800/600?random=2053",
        "https://picsum.photos/800/600?random=2054",
        "https://picsum.photos/800/600?random=2055",
        "https://picsum.photos/800/600?random=2056",
        "https://picsum.photos/800/600?random=2057"
      ],
      is_default: true
    },
    {
      name: "290 - Medium Warm",
      color: "Medium Warm",
      color_hex: "#D4A574",
      price: 36,
      size_value: 32,
      size_unit: "ml",
      size_type: "volume",
      image_urls: [
        "https://picsum.photos/800/600?random=2058",
        "https://picsum.photos/800/600?random=2059",
        "https://picsum.photos/800/600?random=2060",
        "https://picsum.photos/800/600?random=2061"
      ]
    }
  ]
)

puts "  ✅ Professional Matte Lipstick Collection (5 images for Pillow Talk, 4 for Red Carpet, 6 for Berry)"
puts "  ✅ Perfect Match Foundation Gallery Test (5 images for Fair Cool, 4 for Medium Warm)"

puts "\n🎉 Seeding completed successfully!"
puts "\n📊 Database Summary:"
puts "  • Brands: #{Brand.count}"
puts "  • Categories: #{Category.count}"
puts "  • Products: #{Product.count}"
puts "  • Product Variants: #{ProductVariant.count}"
puts "  • Reviews: #{Review.count}"
puts "  • Variants with Images: #{ProductVariant.joins(:featured_image_attachment).count}"

puts "\n🧪 Test Coverage:"
puts "  ✅ Homepage: #{Product.count} products across #{Brand.count} brands"
puts "  ✅ Product Pages: Complete data (description, ingredients, how_to_use)"
puts "  ✅ Brand Search: #{Product.count} products across categories"
puts "  ✅ Brand Pages: Each brand has #{Product.count / Brand.count} avg products"

puts "\n🧪 Enhanced Variant System Test Data:"
puts "  ✅ Smart Default Fields: Added to all variants with realistic test data"
puts "  ✅ Test Scenarios Created:"

if lipstick_collection
  default_variant = lipstick_collection.default_variant
  puts "    • Matte Revolution Lipstick Collection (Mixed Stock):"
  puts "      - Default Selected: #{default_variant.color.present? ? default_variant.color : 'Standard'} (#{default_variant.in_stock? ? 'IN STOCK' : 'OUT OF STOCK'})"
  puts "      - Reason: #{default_variant.is_default? ? 'Explicitly marked default' : 'Algorithm selected'}"
  puts "      - Sales: #{default_variant.sales_count}, Conversion: #{default_variant.conversion_score}"

  puts "      - All Variants:"
  lipstick_collection.product_variants.each do |variant|
    status_icons = []
    status_icons << "🏆" if variant.is_default?
    status_icons << "⭐" if variant.canonical_variant
    status_icons << "📈" if variant.sales_count > 100
    status_icons << "🚫" unless variant.in_stock?

    puts "        #{status_icons.join(' ')} #{variant.color.present? ? variant.color : 'Standard'}: #{variant.sales_count} sales, #{variant.conversion_score} conversion (#{variant.stock_quantity} stock)"
  end
end

puts "\n    • Out of Stock Products for OOS Testing:"
oos_products = [ sold_out_lipstick, sold_out_serum, sold_out_foundation ].compact
oos_products.each do |product|
  if product
    default_variant = product.default_variant
    puts "      - #{product.name}:"
    puts "        Default: #{default_variant.color.present? ? default_variant.color : default_variant.name} (#{default_variant.is_default? ? 'Marked Default' : 'Algorithm Selected'})"
    puts "        All Variants: #{product.product_variants.count} total, 0 in stock (100% OOS)"
    puts "        OOS Fallback Logic: #{default_variant.is_default? ? 'Using marked default' : default_variant.canonical_variant ? 'Using canonical' : 'Using best-selling'}"
  end
end

puts "\n🚀 Ready for testing!"
puts "  • Visit homepage to see product variety with smart defaults"
puts "  • Click Matte Revolution Lipstick Collection to test smart variant selection"

puts "\n🔥 Test PROMOTIONAL/HIT PRODUCTS:"
puts "    - Viral Glow Foundation - TikTok Famous (20% OFF, Hit Product)"
puts "    - Pillow Talk Bestseller - Award Winner (15% OFF Flash Sale, Bestseller)"
puts "    - Miracle Glow Serum - Viral Sensation (30% OFF Mega Sale, Viral)"
puts "    - Soft Glow Liquid Blush (Buy 2 Get 1 FREE, Trending)"
puts "    - Perfect Coverage Concealer (5% OFF with code, Small Discount)"
puts "    - Complete Skincare Routine Bundle (Save $25, Value Bundle)"
puts "    - Holiday Glam Limited Edition Palette ($85, Premium/Exclusive)"

puts "\n🚫 Test FULLY OUT OF STOCK products:"
puts "    - Limited Edition Velvet Matte Lipstick Set (Charlotte Tilbury)"
puts "    - Miracle Recovery Serum (The Ordinary)"
puts "    - Perfect Match Foundation (Fenty Beauty)"
puts "  • Verify OOS visual states: grayed images, 'OUT OF STOCK' badges, grayed prices"
puts "  • Test 'Notify Me' functionality on OOS product pages"

puts "\n🎯 Test SALES & DISCOUNT FEATURES:"
puts "  • Verify strike-through original prices and discount percentages"
puts "  • Test various discount types: percentage off, bundle deals, promo codes"
puts "  • Check hit product badges and promotional messaging"
puts "  • Browse brands to test enhanced product cards with mixed stock states"
puts "  • Use filters to test improved variant handling across all scenarios"

puts "\n📋 Creating test orders for fulfillment status testing..."

# Get sample user and some products for orders
sample_user = User.find_by(email_address: "reviewer@beautystore.com")
if sample_user.nil?
  sample_user = User.create!(
    email_address: "reviewer@beautystore.com",
    first_name: "Beauty",
    last_name: "Enthusiast"
  )
end

# Get some product variants for order items
lipstick_variant = ProductVariant.joins(:product).where(products: { name: "Matte Revolution Lipstick" }).first
foundation_variant = ProductVariant.joins(:product).where(products: { name: "Airbrush Flawless Foundation" }).first
serum_variant = ProductVariant.joins(:product).where(products: { name: "Retinol 0.5% in Squalane" }).first

# Fallback to any available variants if specific ones aren't found
lipstick_variant ||= ProductVariant.limit(3).first
foundation_variant ||= ProductVariant.limit(3).second
serum_variant ||= ProductVariant.limit(3).third

# Helper method to create order items
def create_order_items(order, variants_data)
  variants_data.each do |variant, quantity|
    next unless variant
    order.order_items.create!(
      product_variant: variant,
      quantity: quantity,
      unit_price: variant.price,
      total_price: variant.price * quantity,
      product_name: variant.product.name,
      variant_name: variant.color.present? ? variant.color : "Standard"
    )
  end
  order.calculate_totals!
end

# 1. Unfulfilled Order (Just confirmed)
puts "  • Creating UNFULFILLED order..."
unfulfilled_order = Order.create!(
  user: sample_user,
  email: "customer1@beautystore.com",
  phone_number: "+96170123456",
  delivery_method: "courier",
  payment_status: "cod_due",
  fulfillment_status: "unfulfilled",
  delivery_date: 3.days.from_now.to_date,
  delivery_time_slot: "09:00-12:00",
  shipping_address: {
    address_line_1: "123 Beauty Street",
    address_line_2: "Apt 4B",
    landmarks: "Near ABC Mall"
  }
)
create_order_items(unfulfilled_order, { lipstick_variant => 2, serum_variant => 1 })

# 2. Processing Order (Being prepared)
puts "  • Creating PROCESSING order..."
processing_order = Order.create!(
  user: sample_user,
  email: "customer2@beautystore.com",
  phone_number: "+96170234567",
  delivery_method: "courier",
  payment_status: "cod_due",
  fulfillment_status: "processing",
  delivery_date: 2.days.from_now.to_date,
  delivery_time_slot: "12:00-15:00",
  shipping_address: {
    address_line_1: "456 Makeup Avenue",
    landmarks: "Green Building"
  }
)
create_order_items(processing_order, { foundation_variant => 1, lipstick_variant => 1 })

# 3. Packed Order (Ready for shipping)
puts "  • Creating PACKED order..."
packed_order = Order.create!(
  user: sample_user,
  email: "customer3@beautystore.com",
  phone_number: "+96170345678",
  delivery_method: "pickup",
  payment_status: "cod_due",
  fulfillment_status: "packed"
)
create_order_items(packed_order, { serum_variant => 2, foundation_variant => 1 })

# 4. Dispatched Order (Out for delivery/ready for pickup)
puts "  • Creating DISPATCHED order..."
dispatched_order = Order.create!(
  user: sample_user,
  email: "customer4@beautystore.com",
  phone_number: "+96170456789",
  delivery_method: "courier",
  payment_status: "cod_due",
  fulfillment_status: "dispatched",
  delivery_date: 1.day.from_now.to_date,
  delivery_time_slot: "18:00-21:00",
  shipping_address: {
    address_line_1: "789 Cosmetics Road",
    address_line_2: "Building C, Floor 2"
  }
)
create_order_items(dispatched_order, { lipstick_variant => 3 })

# 5. Delivered Order (Completed delivery)
puts "  • Creating DELIVERED order..."
delivered_order = Order.create!(
  user: sample_user,
  email: "customer5@beautystore.com",
  phone_number: "+96170567890",
  delivery_method: "courier",
  payment_status: "cod_due",
  fulfillment_status: "delivered",
  delivery_date: 1.day.ago.to_date,
  delivery_time_slot: "09:00-12:00",
  shipping_address: {
    address_line_1: "321 Skincare Lane"
  },
  delivery_notes: "Leave at front door"
)
create_order_items(delivered_order, { foundation_variant => 1, serum_variant => 1 })

# 6. Picked Up Order (Completed pickup)
puts "  • Creating PICKED UP order..."
picked_up_order = Order.create!(
  user: sample_user,
  email: "customer6@beautystore.com",
  phone_number: "+96170678901",
  delivery_method: "pickup",
  payment_status: "cod_due",
  fulfillment_status: "picked_up"
)
create_order_items(picked_up_order, { lipstick_variant => 1, foundation_variant => 1, serum_variant => 1 })

# 7. Cancelled Order
puts "  • Creating CANCELLED order..."
cancelled_order = Order.create!(
  user: sample_user,
  email: "customer7@beautystore.com",
  phone_number: "+96170789012",
  delivery_method: "courier",
  payment_status: "payment_pending",
  fulfillment_status: "cancelled",
  delivery_date: 2.days.from_now.to_date,
  delivery_time_slot: "12:00-15:00",
  shipping_address: {
    address_line_1: "654 Beauty Boulevard"
  }
)
create_order_items(cancelled_order, { serum_variant => 2 })

puts "    ✅ Created 7 test orders with different fulfillment statuses"
puts "\n📋 ORDER TESTING GUIDE:"
puts "  • Visit /checkout/{order_number} to see different timeline states:"
puts "    - #{unfulfilled_order.number}: UNFULFILLED (Order Confirmed current)"
puts "    - #{processing_order.number}: PROCESSING (Processing current)"
puts "    - #{packed_order.number}: PACKED (Ready for Pickup current)"
puts "    - #{dispatched_order.number}: DISPATCHED (Shipped/Ready current)"
puts "    - #{delivered_order.number}: DELIVERED (Delivered complete, NO 'What's Next?')"
puts "    - #{picked_up_order.number}: PICKED UP (Picked Up complete, NO 'What's Next?')"
puts "    - #{cancelled_order.number}: CANCELLED (NO 'What's Next?' container)"
