# frozen_string_literal: true

#
# Comprehensive Beauty Store Seeds
# Optimized for testing Homepage, Product Pages, Brand Search, and Brand Pages
#

puts "🌱 Starting comprehensive beauty store seeding..."

# ===============================================================================
# CORE BRANDS - 4 major brands with complete information
# ===============================================================================

puts "\n📍 Creating core brands..."

brands_data = [
  {
    name: "Fenty Beauty",
    slug: "fenty-beauty",
    description: "Beauty for All. Fenty Beauty was founded in 2017 by Rihanna with the vision of inclusion for all women. We believe that every person deserves to feel beautiful and confident in their own skin.",
    banner_url: "https://images.unsplash.com/photo-1596462502278-27bfdc403348?w=1200&h=675&fit=crop&auto=format&q=80"
  },
  {
    name: "Charlotte Tilbury",
    slug: "charlotte-tilbury",
    description: "Luxury makeup and skincare inspired by iconic beauty looks from the red carpet to the catwalk. Founded by celebrity makeup artist Charlotte Tilbury MBE, bringing professional artistry to everyone.",
    banner_url: "https://images.unsplash.com/photo-1522335789203-aabd1fc54bc9?w=1200&h=675&fit=crop&auto=format&q=80"
  },
  {
    name: "The Ordinary",
    slug: "the-ordinary",
    description: "Clinical formulations with integrity. DECIEM's The Ordinary offers clinical technologies at honest prices, with straightforward communication and effective, familiar ingredients.",
    banner_url: "https://images.unsplash.com/photo-1620916566398-39f1143ab7be?w=1200&h=675&fit=crop&auto=format&q=80"
  },
  {
    name: "Rare Beauty",
    slug: "rare-beauty",
    description: "Find comfort in your own skin. Founded by Selena Gomez, Rare Beauty celebrates uniqueness and promotes mental health awareness while creating high-quality, easy-to-use products.",
    banner_url: "https://images.unsplash.com/photo-1583241800098-d4940f177abc?w=1200&h=675&fit=crop&auto=format&q=80"
  }
]

brands = {}
brands_data.each do |brand_data|
  brand = Brand.find_or_create_by!(slug: brand_data[:slug]) do |b|
    b.name = brand_data[:name]
    b.description = brand_data[:description]
  end

  # Attach banner image
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
      puts "  ⚠️  #{brand.name} (banner failed: #{e.message})"
    end
  else
    puts "  ✅ #{brand.name}"
  end

  brands[brand_data[:slug]] = brand
end

# ===============================================================================
# CATEGORIES - Organized product categories
# ===============================================================================

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

# ===============================================================================
# HELPER METHOD - Create products with complete data
# ===============================================================================

def create_complete_product(
  name:, brand:, categories:, product_type:, price:,
  description:, how_to_use: nil, ingredients: nil,
  attributes: {}, variants: [], image_url: nil
)
  product = Product.find_or_create_by!(name: name) do |p|
    p.brand = brand
    p.product_type = product_type
    p.description = description
    p.how_to_use = how_to_use
    p.ingredients = ingredients
    p.product_attributes = attributes
    p.active = true
    p.published_at = rand(1..30).days.ago
  end

  # Add to categories
  categories.each do |category|
    Categorization.find_or_create_by!(product: product, category: category)
  end

  # Create variants
  if variants.any?
    variants.each_with_index do |variant_data, index|
      ProductVariant.find_or_create_by!(product: product, name: variant_data[:name]) do |v|
        v.sku = "#{product.id}-#{variant_data[:name].upcase.gsub(' ', '')}-#{rand(100..999)}"
        v.price = Money.new(variant_data[:price] * 100)
        v.stock_quantity = rand(5..50)
        v.position = index + 1
        v.color = variant_data[:color] if variant_data[:color]
        v.size_value = variant_data[:size_value] if variant_data[:size_value]
        v.size_unit = variant_data[:size_unit] if variant_data[:size_unit]
        v.size_type = variant_data[:size_type] if variant_data[:size_type]
      end
    end
  else
    # Default variant
    ProductVariant.find_or_create_by!(product: product, name: "Standard") do |v|
      v.sku = "#{product.id}-STD-#{rand(100..999)}"
      v.price = Money.new(price * 100)
      v.stock_quantity = rand(10..100)
      v.position = 1
    end
  end

  # Attach image
  if image_url && !product.featured_image.attached?
    begin
      require 'open-uri'
      image_data = URI.open(image_url)
      filename = "#{product.slug}-featured.jpg"

      product.featured_image.attach(
        io: image_data,
        filename: filename,
        content_type: 'image/jpeg'
      )
    rescue => e
      puts "    ⚠️ Image failed for #{product.name}: #{e.message}"
    end
  end

  puts "  ✅ #{product.name} - #{product.brand.name}"
  product
end

# ===============================================================================
# FENTY BEAUTY PRODUCTS - Inclusive, diverse range
# ===============================================================================

puts "\n📍 Creating Fenty Beauty products..."

# Pro Filt'r Foundation
create_complete_product(
  name: "Pro Filt'r Soft Matte Longwear Foundation",
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
    { name: "110 - Fair with cool undertones", price: 36, color: "Fair Cool" },
    { name: "210 - Light with warm undertones", price: 36, color: "Light Warm" },
    { name: "290 - Medium with warm undertones", price: 36, color: "Medium Warm" },
    { name: "385 - Deep with cool undertones", price: 36, color: "Deep Cool" }
  ],
  image_url: "https://images.unsplash.com/photo-1596462502278-27bfdc403348?w=400&h=400&fit=crop"
)

# Gloss Bomb
create_complete_product(
  name: "Gloss Bomb Universal Lip Luminizer",
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
    { name: "Fenty Glow - Universal nude", price: 21 },
    { name: "Fu$$y - Pinky peach", price: 21 },
    { name: "Sweet Mouth - Sheer berry", price: 21 }
  ],
  image_url: "https://images.unsplash.com/photo-1599948128020-9a44d83d1d13?w=400&h=400&fit=crop"
)

# Match Stix Concealer
create_complete_product(
  name: "Match Stix Matte Skinstick Concealer",
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
    { name: "Light", price: 28 },
    { name: "Medium", price: 28 },
    { name: "Deep", price: 28 }
  ],
  image_url: "https://images.unsplash.com/photo-1607748862156-7c548e7e98f4?w=400&h=400&fit=crop"
)

# ===============================================================================
# CHARLOTTE TILBURY PRODUCTS - Luxury complete lines
# ===============================================================================

puts "\n📍 Creating Charlotte Tilbury products..."

# Pillow Talk Lipstick
create_complete_product(
  name: "Matte Revolution Lipstick - Pillow Talk",
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
    { name: "Pillow Talk", price: 34, color: "Nude Pink" },
    { name: "Walk of No Shame", price: 34, color: "Berry" },
    { name: "Red Carpet Red", price: 34, color: "Classic Red" }
  ],
  image_url: "https://images.unsplash.com/photo-1586495777744-4413f21062fa?w=400&h=400&fit=crop"
)

# Hollywood Flawless Filter
create_complete_product(
  name: "Hollywood Flawless Filter",
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
    { name: "Light/Medium", price: 49 },
    { name: "Medium/Dark", price: 49 }
  ],
  image_url: "https://images.unsplash.com/photo-1522335789203-aabd1fc54bc9?w=400&h=400&fit=crop"
)

# Magic Cream Moisturizer
create_complete_product(
  name: "Magic Cream Moisturizer",
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
  image_url: "https://images.unsplash.com/photo-1556228720-195a672e8a03?w=400&h=400&fit=crop"
)

# ===============================================================================
# THE ORDINARY PRODUCTS - Clinical skincare focus
# ===============================================================================

puts "\n📍 Creating The Ordinary products..."

# Niacinamide Serum
create_complete_product(
  name: "Niacinamide 10% + Zinc 1%",
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
  image_url: "https://images.unsplash.com/photo-1620916566398-39f1143ab7be?w=400&h=400&fit=crop"
)

# Hyaluronic Acid Serum
create_complete_product(
  name: "Hyaluronic Acid 2% + B5",
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
  image_url: "https://images.unsplash.com/photo-1556228578-8c89e6adf883?w=400&h=400&fit=crop"
)

# Retinol Serum
create_complete_product(
  name: "Retinol 0.5% in Squalane",
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
  image_url: "https://images.unsplash.com/photo-1598440947619-2c35fc9aa908?w=400&h=400&fit=crop"
)

# ===============================================================================
# RARE BEAUTY PRODUCTS - Trendy, easy-to-use
# ===============================================================================

puts "\n📍 Creating Rare Beauty products..."

# Soft Pinch Blush
create_complete_product(
  name: "Soft Pinch Liquid Blush",
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
    { name: "Joy - Soft Berry", price: 23, color: "Berry" },
    { name: "Bliss - Soft Peach", price: 23, color: "Peach" },
    { name: "Hope - Soft Pink", price: 23, color: "Pink" }
  ],
  image_url: "https://images.unsplash.com/photo-1583241800098-d4940f177abc?w=400&h=400&fit=crop"
)

# Perfect Strokes Mascara
create_complete_product(
  name: "Perfect Strokes Universal Volumizing Mascara",
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
    { name: "Black", price: 20, color: "Black" },
    { name: "Brown", price: 20, color: "Brown" }
  ],
  image_url: "https://images.unsplash.com/photo-1571781926291-c477ebfd024b?w=400&h=400&fit=crop"
)

# Kind Words Lip Liner
create_complete_product(
  name: "Kind Words Matte Lip Liner",
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
    { name: "Grateful - Nude Pink", price: 14, color: "Nude Pink" },
    { name: "Brave - Deep Berry", price: 14, color: "Berry" },
    { name: "Honest - Classic Red", price: 14, color: "Red" }
  ],
  image_url: "https://images.unsplash.com/photo-1611930022073-b7a4ba5fcccd?w=400&h=400&fit=crop"
)

# ===============================================================================
# ADDITIONAL PRODUCTS FOR TESTING - Various brands & categories
# ===============================================================================

puts "\n📍 Creating additional test products..."

# High-end fragrance for pricing variety
create_complete_product(
  name: "Fenty Eau de Parfum",
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
  image_url: "https://images.unsplash.com/photo-1541643600914-78b084683601?w=400&h=400&fit=crop"
)

# Professional brush for tools category
create_complete_product(
  name: "Foundation Brush - Precision",
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
  image_url: "https://images.unsplash.com/photo-1515688594390-b649af70d282?w=400&h=400&fit=crop"
)

# ===============================================================================
# PRODUCTS WITH EXTENSIVE VARIANTS & MULTIPLE IMAGES - For testing UI components
# ===============================================================================

puts "\n📍 Creating products with extensive variants and galleries..."

# Foundation with 20+ shades - Testing extensive variant selection
fenty_foundation_pro = create_complete_product(
  name: "Pro Filt'r Hydrating Longwear Foundation",
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
    { name: "100 - Fair with neutral undertones", price: 39, color: "Fair Neutral" },
    { name: "110 - Fair with cool undertones", price: 39, color: "Fair Cool" },
    { name: "120 - Fair with warm undertones", price: 39, color: "Fair Warm" },
    { name: "130 - Fair with olive undertones", price: 39, color: "Fair Olive" },
    { name: "150 - Light with neutral undertones", price: 39, color: "Light Neutral" },
    { name: "160 - Light with cool undertones", price: 39, color: "Light Cool" },
    { name: "170 - Light with warm undertones", price: 39, color: "Light Warm" },
    { name: "180 - Light with olive undertones", price: 39, color: "Light Olive" },
    { name: "200 - Light-Medium with neutral undertones", price: 39, color: "Light-Medium Neutral" },
    { name: "210 - Light-Medium with cool undertones", price: 39, color: "Light-Medium Cool" },
    { name: "220 - Light-Medium with warm undertones", price: 39, color: "Light-Medium Warm" },
    { name: "230 - Light-Medium with olive undertones", price: 39, color: "Light-Medium Olive" },
    { name: "250 - Medium with neutral undertones", price: 39, color: "Medium Neutral" },
    { name: "260 - Medium with cool undertones", price: 39, color: "Medium Cool" },
    { name: "270 - Medium with warm undertones", price: 39, color: "Medium Warm" },
    { name: "280 - Medium with olive undertones", price: 39, color: "Medium Olive" },
    { name: "300 - Medium-Deep with neutral undertones", price: 39, color: "Medium-Deep Neutral" },
    { name: "310 - Medium-Deep with cool undertones", price: 39, color: "Medium-Deep Cool" },
    { name: "320 - Medium-Deep with warm undertones", price: 39, color: "Medium-Deep Warm" },
    { name: "330 - Medium-Deep with olive undertones", price: 39, color: "Medium-Deep Olive" },
    { name: "350 - Deep with neutral undertones", price: 39, color: "Deep Neutral" },
    { name: "360 - Deep with cool undertones", price: 39, color: "Deep Cool" },
    { name: "370 - Deep with warm undertones", price: 39, color: "Deep Warm" },
    { name: "385 - Deep with olive undertones", price: 39, color: "Deep Olive" }
  ],
  image_url: "https://images.unsplash.com/photo-1596462502278-27bfdc403348?w=400&h=400&fit=crop"
)

# Attach multiple gallery images to foundation
if fenty_foundation_pro
  gallery_urls = [
    "https://images.unsplash.com/photo-1596462502278-27bfdc403348?w=400&h=400&fit=crop",
    "https://images.unsplash.com/photo-1522335789203-aabd1fc54bc9?w=400&h=400&fit=crop",
    "https://images.unsplash.com/photo-1607748862156-7c548e7e98f4?w=400&h=400&fit=crop",
    "https://images.unsplash.com/photo-1586495777744-4413f21062fa?w=400&h=400&fit=crop",
    "https://images.unsplash.com/photo-1599948128020-9a44d83d1d13?w=400&h=400&fit=crop"
  ]

  gallery_urls.each_with_index do |url, index|
    begin
      require 'open-uri'
      image_data = URI.open(url)
      filename = "#{fenty_foundation_pro.slug}-gallery-#{index + 1}.jpg"

      fenty_foundation_pro.images.attach(
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

# Eyeshadow palette with many shades - Testing color variants
charlotte_palette = create_complete_product(
  name: "Luxury Palette - The Queen of Glow",
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
    { name: "Champagne Pop - Warm shimmer", price: 75, color: "Champagne" },
    { name: "Bronzed Garnet - Deep bronze", price: 75, color: "Bronze" },
    { name: "Golden Goddess - Warm gold", price: 75, color: "Gold" },
    { name: "Copper Charge - Metallic copper", price: 75, color: "Copper" },
    { name: "Rose Gold - Pink gold", price: 75, color: "Rose Gold" },
    { name: "Smoky Quartz - Cool brown", price: 75, color: "Brown" },
    { name: "Midnight Matte - Deep black", price: 75, color: "Black" },
    { name: "Chocolate - Warm brown", price: 75, color: "Chocolate" },
    { name: "Nude Pink - Soft pink", price: 75, color: "Pink" },
    { name: "Pearl - Iridescent white", price: 75, color: "Pearl" },
    { name: "Plum Perfect - Deep plum", price: 75, color: "Plum" },
    { name: "Vintage Vamp - Burgundy", price: 75, color: "Burgundy" }
  ],
  image_url: "https://images.unsplash.com/photo-1522335789203-aabd1fc54bc9?w=400&h=400&fit=crop"
)

# Attach multiple images to eyeshadow palette
if charlotte_palette
  palette_gallery_urls = [
    "https://images.unsplash.com/photo-1522335789203-aabd1fc54bc9?w=400&h=400&fit=crop",
    "https://images.unsplash.com/photo-1571781926291-c477ebfd024b?w=400&h=400&fit=crop",
    "https://images.unsplash.com/photo-1596462502278-27bfdc403348?w=400&h=400&fit=crop",
    "https://images.unsplash.com/photo-1607748862156-7c548e7e98f4?w=400&h=400&fit=crop",
    "https://images.unsplash.com/photo-1586495777744-4413f21062fa?w=400&h=400&fit=crop",
    "https://images.unsplash.com/photo-1599948128020-9a44d83d1d13?w=400&h=400&fit=crop"
  ]

  palette_gallery_urls.each_with_index do |url, index|
    begin
      require 'open-uri'
      image_data = URI.open(url)
      filename = "#{charlotte_palette.slug}-gallery-#{index + 1}.jpg"

      charlotte_palette.images.attach(
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

# Serum with multiple sizes - Testing size variants
ordinary_vitamin_c = create_complete_product(
  name: "Vitamin C Suspension 23% + HA Spheres 2%",
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
  image_url: "https://images.unsplash.com/photo-1620916566398-39f1143ab7be?w=400&h=400&fit=crop"
)

# Attach multiple images to vitamin C serum
if ordinary_vitamin_c
  serum_gallery_urls = [
    "https://images.unsplash.com/photo-1620916566398-39f1143ab7be?w=400&h=400&fit=crop",
    "https://images.unsplash.com/photo-1556228578-8c89e6adf883?w=400&h=400&fit=crop",
    "https://images.unsplash.com/photo-1598440947619-2c35fc9aa908?w=400&h=400&fit=crop",
    "https://images.unsplash.com/photo-1556228720-195a672e8a03?w=400&h=400&fit=crop"
  ]

  serum_gallery_urls.each_with_index do |url, index|
    begin
      require 'open-uri'
      image_data = URI.open(url)
      filename = "#{ordinary_vitamin_c.slug}-gallery-#{index + 1}.jpg"

      ordinary_vitamin_c.images.attach(
        io: image_data,
        filename: filename,
        content_type: 'image/jpeg'
      )
      puts "    ✅ Serum gallery image #{index + 1} attached"
    rescue => e
      puts "    ⚠️ Serum gallery image #{index + 1} failed: #{e.message}"
    end
  end
end

# Liquid blush with many shades - Testing color dropdown
rare_blush_collection = create_complete_product(
  name: "Soft Pinch Liquid Blush Collection",
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
  variants: [
    { name: "Encourage - Soft coral", price: 23, color: "Coral" },
    { name: "Joy - Soft berry", price: 23, color: "Berry" },
    { name: "Bliss - Soft peach", price: 23, color: "Peach" },
    { name: "Hope - Soft pink", price: 23, color: "Pink" },
    { name: "Happy - Bright coral", price: 23, color: "Bright Coral" },
    { name: "Grateful - Warm rose", price: 23, color: "Rose" },
    { name: "Believe - Deep plum", price: 23, color: "Plum" },
    { name: "Faith - Mauve pink", price: 23, color: "Mauve" },
    { name: "Brave - Deep berry", price: 23, color: "Deep Berry" },
    { name: "Confident - Terracotta", price: 23, color: "Terracotta" },
    { name: "Inspire - Dusty rose", price: 23, color: "Dusty Rose" },
    { name: "Worthy - Nude pink", price: 23, color: "Nude Pink" },
    { name: "Grace - Soft lavender", price: 23, color: "Lavender" },
    { name: "Strong - Brick red", price: 23, color: "Brick Red" },
    { name: "Fearless - Deep raspberry", price: 23, color: "Raspberry" }
  ],
  image_url: "https://images.unsplash.com/photo-1583241800098-d4940f177abc?w=400&h=400&fit=crop"
)

# Attach multiple images to blush collection
if rare_blush_collection
  blush_gallery_urls = [
    "https://images.unsplash.com/photo-1583241800098-d4940f177abc?w=400&h=400&fit=crop",
    "https://images.unsplash.com/photo-1611930022073-b7a4ba5fcccd?w=400&h=400&fit=crop",
    "https://images.unsplash.com/photo-1571781926291-c477ebfd024b?w=400&h=400&fit=crop",
    "https://images.unsplash.com/photo-1522335789203-aabd1fc54bc9?w=400&h=400&fit=crop",
    "https://images.unsplash.com/photo-1599948128020-9a44d83d1d13?w=400&h=400&fit=crop"
  ]

  blush_gallery_urls.each_with_index do |url, index|
    begin
      require 'open-uri'
      image_data = URI.open(url)
      filename = "#{rare_blush_collection.slug}-gallery-#{index + 1}.jpg"

      rare_blush_collection.images.attach(
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

puts "  ✅ Added 4 products with extensive variants and multiple images"

# Moisturizer with multiple sizes - Testing out-of-stock styling
charlotte_moisturizer = create_complete_product(
  name: "Magic Cream Moisturizer Deluxe Collection",
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
  image_url: "https://images.unsplash.com/photo-1556228720-195a672e8a03?w=400&h=400&fit=crop"
)

# Create variants manually to control stock levels
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

# ===============================================================================
# CREATE SAMPLE REVIEWS FOR REALISTIC TESTING
# ===============================================================================

puts "\n📍 Creating sample reviews..."

# Sample user for reviews
sample_user = User.find_or_create_by!(email_address: "reviewer@beautystore.com") do |user|
  user.first_name = "Beauty"
  user.last_name = "Enthusiast"
  user.password = "password123"
  user.password_confirmation = "password123"
end

# Add reviews to popular products
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

# ===============================================================================
# FINAL STATS & SUMMARY
# ===============================================================================

puts "\n🎉 Seeding completed successfully!"
puts "\n📊 Database Summary:"
puts "  • Brands: #{Brand.count}"
puts "  • Categories: #{Category.count}"
puts "  • Products: #{Product.count}"
puts "  • Product Variants: #{ProductVariant.count}"
puts "  • Reviews: #{Review.count}"
puts "  • Products with Images: #{Product.joins(:featured_image_attachment).count}"

puts "\n🧪 Test Coverage:"
puts "  ✅ Homepage: #{Product.count} products across #{Brand.count} brands"
puts "  ✅ Product Pages: Complete data (description, ingredients, how_to_use)"
puts "  ✅ Brand Search: #{Product.count} products across categories"
puts "  ✅ Brand Pages: Each brand has #{Product.count / Brand.count} avg products"

puts "\n🚀 Ready for testing!"
puts "  • Visit homepage to see product variety"
puts "  • Click any product for complete product page testing"
puts "  • Browse brands to test brand pages and search"
puts "  • Use filters to test JSONB attribute system"
