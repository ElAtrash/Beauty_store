# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

puts "🌱 Starting to seed the beauty store database..."

# Create Brands
puts "Creating brands..."
brands = [
  { name: "Fenty Beauty", slug: "fenty-beauty", description: "Beauty for all" },
  { name: "Rare Beauty", slug: "rare-beauty", description: "Find comfort in your own skin" },
  { name: "Charlotte Tilbury", slug: "charlotte-tilbury", description: "Luxury makeup and skincare" },
  { name: "The Ordinary", slug: "the-ordinary", description: "Clinical formulations with integrity" },
  { name: "Glossier", slug: "glossier", description: "Beauty inspired by real life" },
  { name: "Drunk Elephant", slug: "drunk-elephant", description: "Biocompatible skincare" }
]

created_brands = brands.map do |brand_attrs|
  Brand.find_or_create_by!(slug: brand_attrs[:slug]) do |brand|
    brand.name = brand_attrs[:name]
    brand.description = brand_attrs[:description]
  end
end

puts "✅ Created #{created_brands.size} brands"

# Create Categories
puts "Creating categories..."
categories_data = [
  { name: "Skincare", slug: "skincare", description: "Products for healthy, glowing skin", position: 1 },
  { name: "Makeup", slug: "makeup", description: "Enhance your natural beauty", position: 2 },
  { name: "Fragrance", slug: "fragrance", description: "Discover your signature scent", position: 3 },
  { name: "Hair & Body", slug: "hair-body", description: "Complete care for hair and body", position: 4 }
]

categories_data.each do |cat_attrs|
  Category.find_or_create_by!(slug: cat_attrs[:slug]) do |category|
    category.name = cat_attrs[:name]
    category.description = cat_attrs[:description]
    category.position = cat_attrs[:position]
  end
end

# Create subcategories
subcategories_data = [
  { name: "Cleansers", parent: "skincare", position: 1 },
  { name: "Moisturizers", parent: "skincare", position: 2 },
  { name: "Serums", parent: "skincare", position: 3 },
  { name: "Foundation", parent: "makeup", position: 1 },
  { name: "Lipstick", parent: "makeup", position: 2 },
  { name: "Eyeshadow", parent: "makeup", position: 3 }
]

subcategories_data.each do |subcat|
  parent_category = Category.find_by!(slug: subcat[:parent])
  Category.find_or_create_by!(name: subcat[:name], parent: parent_category) do |category|
    category.position = subcat[:position]
  end
end

puts "✅ Created #{Category.count} categories"

# Create Products
puts "Creating products..."
products_data = [
  # Existing products with updated data
  {
    name: "Fenty Beauty Pro Filt'r Soft Matte Longwear Foundation",
    brand: "fenty-beauty",
    categories: [ "makeup", "foundation" ],
    description: "An oil-free, soft matte, longwear foundation with buildable, medium to full coverage and a weightless feel.",
    skin_types: [ "oily", "combination", "normal" ],
    published_at: 1.month.ago,
    active: true,
    image_url: "https://images.unsplash.com/photo-1631730486651-2057b2427c8e?w=400&h=400&fit=crop",
    variants: [
      { name: "110 (Fair with cool undertones)", sku: "FENTY-FOUND-110", price: 34.00, stock: 50, compare_at_price: 40.00 },
      { name: "150 (Light with cool undertones)", sku: "FENTY-FOUND-150", price: 34.00, stock: 45 },
      { name: "200 (Light with warm undertones)", sku: "FENTY-FOUND-200", price: 34.00, stock: 30 }
    ]
  },
  {
    name: "The Ordinary Niacinamide 10% + Zinc 1%",
    brand: "the-ordinary",
    categories: [ "skincare", "serums" ],
    description: "A high-strength vitamin and mineral blemish formula with 10% niacinamide and 1% zinc PCA.",
    skin_types: [ "oily", "combination", "sensitive" ],
    published_at: 2.weeks.ago,
    active: true,
    image_url: "https://images.unsplash.com/photo-1620916566398-39f1143ab7be?w=400&h=400&fit=crop",
    variants: [
      { name: "30ml", sku: "TO-NIACIN-30ML", price: 7.00, stock: 100, compare_at_price: 9.00 },
      { name: "60ml", sku: "TO-NIACIN-60ML", price: 12.00, stock: 80 }
    ]
  },
  {
    name: "Rare Beauty Soft Pinch Liquid Blush",
    brand: "rare-beauty",
    categories: [ "makeup" ],
    description: "A weightless, long-lasting liquid blush that blends and builds beautifully for a soft, healthy flush.",
    skin_types: [ "dry", "normal", "combination" ],
    published_at: 3.days.ago,
    active: true,
    image_url: "https://images.unsplash.com/photo-1596462502278-27bfdc403348?w=400&h=400&fit=crop",
    variants: [
      { name: "Joy (Warm berry)", sku: "RARE-BLUSH-JOY", price: 20.00, stock: 25 },
      { name: "Bliss (Soft pink)", sku: "RARE-BLUSH-BLISS", price: 20.00, stock: 30 },
      { name: "Hope (Dusty rose)", sku: "RARE-BLUSH-HOPE", price: 20.00, stock: 20, compare_at_price: 25.00 }
    ]
  },

  # NEW PRODUCTS - Adding 47 more products
  {
    name: "NARS Natural Radiant Longwear Foundation",
    brand: "fenty-beauty",
    categories: [ "makeup", "foundation" ],
    description: "Medium to full buildable coverage with a natural, radiant finish that lasts up to 16 hours.",
    skin_types: [ "normal", "dry", "combination" ],
    published_at: 1.week.ago,
    active: true,
    image_url: "https://images.unsplash.com/photo-1522335789203-aabd1fc54bc9?w=400&h=400&fit=crop",
    variants: [
      { name: "Mont Blanc", sku: "NARS-FOUND-MB", price: 47.00, stock: 30 },
      { name: "Gobi", sku: "NARS-FOUND-GOBI", price: 47.00, stock: 25 }
    ]
  },
  {
    name: "CeraVe Hydrating Facial Cleanser",
    brand: "the-ordinary",
    categories: [ "skincare", "cleansers" ],
    description: "A gentle, non-foaming cleanser that removes makeup and dirt while maintaining the skin's natural barrier.",
    skin_types: [ "dry", "normal", "sensitive" ],
    published_at: 2.days.ago,
    active: true,
    image_url: "https://images.unsplash.com/photo-1556228578-8c89e6adf883?w=400&h=400&fit=crop",
    variants: [
      { name: "236ml", sku: "CERAVE-CLEAN-236", price: 12.00, stock: 80, compare_at_price: 15.00 }
    ]
  },
  {
    name: "Urban Decay All Nighter Setting Spray",
    brand: "glossier",
    categories: [ "makeup" ],
    description: "A weightless makeup setting spray that keeps makeup looking fresh for up to 16 hours.",
    skin_types: [ "normal", "oily", "combination", "dry" ],
    published_at: 5.days.ago,
    active: true,
    image_url: "https://images.unsplash.com/photo-1615397349754-cfa2066a298e?w=400&h=400&fit=crop",
    variants: [
      { name: "118ml", sku: "UD-SETTING-118", price: 33.00, stock: 45 }
    ]
  },
  {
    name: "Tarte Shape Tape Concealer",
    brand: "rare-beauty",
    categories: [ "makeup" ],
    description: "Full coverage, long-wearing concealer that never creases or cracks.",
    skin_types: [ "normal", "oily", "combination" ],
    published_at: 1.week.ago,
    active: true,
    image_url: "https://images.unsplash.com/photo-1583241800098-d4940f177abc?w=400&h=400&fit=crop",
    variants: [
      { name: "Light Medium", sku: "TARTE-CONC-LM", price: 27.00, stock: 35, compare_at_price: 32.00 },
      { name: "Medium", sku: "TARTE-CONC-MED", price: 27.00, stock: 40 }
    ]
  },
  {
    name: "Benefit Brow Definer Pencil",
    brand: "charlotte-tilbury",
    categories: [ "makeup" ],
    description: "Ultra-fine tip brow pencil that mimics natural brow hairs for precise application.",
    skin_types: [ "normal", "oily", "combination", "dry" ],
    published_at: 3.days.ago,
    active: true,
    image_url: "https://images.unsplash.com/photo-1598440947619-2c35fc9aa908?w=400&h=400&fit=crop",
    variants: [
      { name: "Medium Brown", sku: "BENEFIT-BROW-MB", price: 25.00, stock: 50 },
      { name: "Dark Brown", sku: "BENEFIT-BROW-DB", price: 25.00, stock: 45 }
    ]
  },
  {
    name: "Laneige Water Sleeping Mask",
    brand: "drunk-elephant",
    categories: [ "skincare", "moisturizers" ],
    description: "An overnight moisture mask that quickly absorbs while you sleep to deeply hydrate skin.",
    skin_types: [ "dry", "normal", "combination" ],
    published_at: 4.days.ago,
    active: true,
    image_url: "https://images.unsplash.com/photo-1556228720-195a672e8a03?w=400&h=400&fit=crop",
    variants: [
      { name: "70ml", sku: "LANEIGE-SLEEP-70", price: 34.00, stock: 25 }
    ]
  },
  {
    name: "MAC Ruby Woo Lipstick",
    brand: "charlotte-tilbury",
    categories: [ "makeup", "lipstick" ],
    description: "Intense color payoff in a no-nonsense matte finish. The iconic blue-based red.",
    skin_types: [ "normal", "oily", "combination", "dry" ],
    published_at: 1.day.ago,
    active: true,
    image_url: "https://images.unsplash.com/photo-1586495777744-4413f21062fa?w=400&h=400&fit=crop",
    variants: [
      { name: "Ruby Woo", sku: "MAC-RUBY-WOO", price: 19.00, stock: 60, compare_at_price: 22.00 }
    ]
  },
  {
    name: "Paula's Choice 2% BHA Liquid Exfoliant",
    brand: "the-ordinary",
    categories: [ "skincare", "serums" ],
    description: "Gentle, leave-on exfoliant with 2% BHA (salicylic acid) that removes dead skin cells.",
    skin_types: [ "oily", "combination", "normal" ],
    published_at: 6.days.ago,
    active: true,
    image_url: "https://images.unsplash.com/photo-1620916566398-39f1143ab7be?w=400&h=400&fit=crop",
    variants: [
      { name: "118ml", sku: "PC-BHA-118", price: 30.00, stock: 70 },
      { name: "30ml", sku: "PC-BHA-30", price: 10.00, stock: 90, compare_at_price: 13.00 }
    ]
  },
  {
    name: "Maybelline Sky High Mascara",
    brand: "glossier",
    categories: [ "makeup" ],
    description: "Volumizing and lengthening mascara with bamboo extract and fibers for limitless length.",
    skin_types: [ "normal", "oily", "combination", "dry" ],
    published_at: 2.days.ago,
    active: true,
    image_url: "https://images.unsplash.com/photo-1631730486651-2057b2427c8e?w=400&h=400&fit=crop",
    variants: [
      { name: "Black", sku: "MAYBE-MASC-BLK", price: 11.00, stock: 85 },
      { name: "Brown", sku: "MAYBE-MASC-BRN", price: 11.00, stock: 40 }
    ]
  },
  {
    name: "Tatcha The Water Cream",
    brand: "drunk-elephant",
    categories: [ "skincare", "moisturizers" ],
    description: "Oil-free, anti-aging water cream that releases a burst of skin-improving Japanese botanicals.",
    skin_types: [ "oily", "combination", "normal" ],
    published_at: 1.week.ago,
    active: true,
    image_url: "https://images.unsplash.com/photo-1556228720-195a672e8a03?w=400&h=400&fit=crop",
    variants: [
      { name: "50ml", sku: "TATCHA-WATER-50", price: 68.00, stock: 20, compare_at_price: 78.00 }
    ]
  },
  {
    name: "Anastasia Beverly Hills Brow Wiz",
    brand: "fenty-beauty",
    categories: [ "makeup" ],
    description: "Ultra-slim, retractable brow pencil that's perfect for outlining and detailing brows.",
    skin_types: [ "normal", "oily", "combination", "dry" ],
    published_at: 3.days.ago,
    active: true,
    image_url: "https://images.unsplash.com/photo-1598440947619-2c35fc9aa908?w=400&h=400&fit=crop",
    variants: [
      { name: "Taupe", sku: "ABH-BROW-TAUPE", price: 23.00, stock: 55 },
      { name: "Chocolate", sku: "ABH-BROW-CHOC", price: 23.00, stock: 50 }
    ]
  },
  {
    name: "Neutrogena Hydro Boost Water Gel",
    brand: "the-ordinary",
    categories: [ "skincare", "moisturizers" ],
    description: "Oil-free gel moisturizer with hyaluronic acid that instantly quenches dry skin.",
    skin_types: [ "dry", "normal", "combination" ],
    published_at: 5.days.ago,
    active: true,
    image_url: "https://images.unsplash.com/photo-1556228720-195a672e8a03?w=400&h=400&fit=crop",
    variants: [
      { name: "47g", sku: "NEUTRO-HYDRO-47", price: 15.00, stock: 75 }
    ]
  },
  {
    name: "Too Faced Better Than Sex Mascara",
    brand: "rare-beauty",
    categories: [ "makeup" ],
    description: "Volumizing mascara that delivers dramatic volume and sexy length.",
    skin_types: [ "normal", "oily", "combination", "dry" ],
    published_at: 1.day.ago,
    active: true,
    image_url: "https://images.unsplash.com/photo-1631730486651-2057b2427c8e?w=400&h=400&fit=crop",
    variants: [
      { name: "Black", sku: "TF-MASC-BLK", price: 25.00, stock: 65, compare_at_price: 29.00 }
    ]
  },
  {
    name: "Clinique Dramatically Different Moisturizing Lotion",
    brand: "drunk-elephant",
    categories: [ "skincare", "moisturizers" ],
    description: "Dermatologist-developed face moisturizer that strengthens skin's moisture barrier.",
    skin_types: [ "dry", "combination", "normal" ],
    published_at: 1.week.ago,
    active: true,
    image_url: "https://images.unsplash.com/photo-1556228720-195a672e8a03?w=400&h=400&fit=crop",
    variants: [
      { name: "125ml", sku: "CLIN-MOIST-125", price: 29.00, stock: 45 }
    ]
  },
  {
    name: "L'Oreal True Match Foundation",
    brand: "glossier",
    categories: [ "makeup", "foundation" ],
    description: "Perfectly matches skin's tone and undertone with micro-fine powder for a natural finish.",
    skin_types: [ "normal", "dry", "combination" ],
    published_at: 2.days.ago,
    active: true,
    image_url: "https://images.unsplash.com/photo-1522335789203-aabd1fc54bc9?w=400&h=400&fit=crop",
    variants: [
      { name: "N2 Vanilla", sku: "LOREAL-TM-N2", price: 12.00, stock: 90 },
      { name: "W3 Nude Beige", sku: "LOREAL-TM-W3", price: 12.00, stock: 85 }
    ]
  },
  {
    name: "Estee Lauder Double Wear Foundation",
    brand: "charlotte-tilbury",
    categories: [ "makeup", "foundation" ],
    description: "Full coverage, 24-hour wear foundation that looks natural and feels lightweight.",
    skin_types: [ "oily", "combination", "normal" ],
    published_at: 4.days.ago,
    active: true,
    image_url: "https://images.unsplash.com/photo-1522335789203-aabd1fc54bc9?w=400&h=400&fit=crop",
    variants: [
      { name: "1W2 Sand", sku: "EL-DW-1W2", price: 46.00, stock: 35, compare_at_price: 52.00 },
      { name: "2W1 Dawn", sku: "EL-DW-2W1", price: 46.00, stock: 30 }
    ]
  },
  {
    name: "Cetaphil Gentle Skin Cleanser",
    brand: "the-ordinary",
    categories: [ "skincare", "cleansers" ],
    description: "Mild, non-irritating formulation that soothes skin as it cleans without over-drying.",
    skin_types: [ "sensitive", "dry", "normal" ],
    published_at: 3.days.ago,
    active: true,
    image_url: "https://images.unsplash.com/photo-1556228578-8c89e6adf883?w=400&h=400&fit=crop",
    variants: [
      { name: "591ml", sku: "CETA-CLEAN-591", price: 14.00, stock: 100 }
    ]
  },
  {
    name: "Milk Makeup Hydro Grip Primer",
    brand: "fenty-beauty",
    categories: [ "makeup" ],
    description: "Silicone-free makeup primer with hyaluronic acid that grips makeup for 12-hour wear.",
    skin_types: [ "normal", "dry", "combination" ],
    published_at: 2.days.ago,
    active: true,
    image_url: "https://images.unsplash.com/photo-1615397349754-cfa2066a298e?w=400&h=400&fit=crop",
    variants: [
      { name: "45ml", sku: "MILK-PRIMER-45", price: 36.00, stock: 40 }
    ]
  },
  {
    name: "Morphe 35O Nature Glow Eyeshadow Palette",
    brand: "rare-beauty",
    categories: [ "makeup", "eyeshadow" ],
    description: "35-shade eyeshadow palette with warm, earthy tones for versatile eye looks.",
    skin_types: [ "normal", "oily", "combination", "dry" ],
    published_at: 5.days.ago,
    active: true,
    image_url: "https://images.unsplash.com/photo-1583241800098-d4940f177abc?w=400&h=400&fit=crop",
    variants: [
      { name: "35O Palette", sku: "MORPH-35O", price: 25.00, stock: 30, compare_at_price: 30.00 }
    ]
  },
  {
    name: "Olaplex No.3 Hair Perfector",
    brand: "drunk-elephant",
    categories: [ "hair-body" ],
    description: "At-home treatment that reduces breakage and strengthens hair for healthier-looking hair.",
    skin_types: [ "normal", "dry", "oily", "combination" ],
    published_at: 1.week.ago,
    active: true,
    image_url: "https://images.unsplash.com/photo-1556228578-8c89e6adf883?w=400&h=400&fit=crop",
    variants: [
      { name: "100ml", sku: "OLAPLEX-3-100", price: 28.00, stock: 55 }
    ]
  },
  {
    name: "NYX Professional Makeup Epic Ink Liner",
    brand: "glossier",
    categories: [ "makeup" ],
    description: "Waterproof liquid eyeliner with an ultra-fine tip for precise application.",
    skin_types: [ "normal", "oily", "combination", "dry" ],
    published_at: 1.day.ago,
    active: true,
    image_url: "https://images.unsplash.com/photo-1583241800098-d4940f177abc?w=400&h=400&fit=crop",
    variants: [
      { name: "Black", sku: "NYX-LINER-BLK", price: 7.00, stock: 120 }
    ]
  },
  {
    name: "Drunk Elephant Protini Polypeptide Cream",
    brand: "drunk-elephant",
    categories: [ "skincare", "moisturizers" ],
    description: "Anti-aging face moisturizer with signal peptides that restores younger-looking skin.",
    skin_types: [ "normal", "dry", "combination" ],
    published_at: 6.days.ago,
    active: true,
    image_url: "https://images.unsplash.com/photo-1556228720-195a672e8a03?w=400&h=400&fit=crop",
    variants: [
      { name: "50ml", sku: "DE-PROTINI-50", price: 68.00, stock: 25, compare_at_price: 78.00 }
    ]
  },
  {
    name: "Revlon Super Lustrous Lipstick",
    brand: "charlotte-tilbury",
    categories: [ "makeup", "lipstick" ],
    description: "Moisturizing lipstick with silk-infused formula for smooth, comfortable wear.",
    skin_types: [ "normal", "dry", "combination", "oily" ],
    published_at: 3.days.ago,
    active: true,
    image_url: "https://images.unsplash.com/photo-1586495777744-4413f21062fa?w=400&h=400&fit=crop",
    variants: [
      { name: "Pink in the Afternoon", sku: "REV-PINK-AFT", price: 8.00, stock: 80 },
      { name: "Certainly Red", sku: "REV-CERT-RED", price: 8.00, stock: 75 }
    ]
  },
  {
    name: "The Inkey List Hyaluronic Acid Serum",
    brand: "the-ordinary",
    categories: [ "skincare", "serums" ],
    description: "Lightweight serum that holds up to 1000 times its weight in water for intense hydration.",
    skin_types: [ "dry", "normal", "combination", "sensitive" ],
    published_at: 4.days.ago,
    active: true,
    image_url: "https://images.unsplash.com/photo-1620916566398-39f1143ab7be?w=400&h=400&fit=crop",
    variants: [
      { name: "30ml", sku: "INKEY-HA-30", price: 8.00, stock: 95 }
    ]
  },
  {
    name: "Elf Camo Concealer",
    brand: "fenty-beauty",
    categories: [ "makeup" ],
    description: "Full coverage concealer that's crease-resistant and provides up to 16 hours of wear.",
    skin_types: [ "normal", "oily", "combination" ],
    published_at: 2.days.ago,
    active: true,
    image_url: "https://images.unsplash.com/photo-1583241800098-d4940f177abc?w=400&h=400&fit=crop",
    variants: [
      { name: "Light Peach", sku: "ELF-CAMO-LP", price: 6.00, stock: 110, compare_at_price: 8.00 },
      { name: "Medium Beige", sku: "ELF-CAMO-MB", price: 6.00, stock: 105 }
    ]
  },
  {
    name: "Pixi Glow Tonic",
    brand: "glossier",
    categories: [ "skincare", "serums" ],
    description: "Exfoliating toner with 5% glycolic acid that gently removes dead skin cells for glowing skin.",
    skin_types: [ "normal", "combination", "oily" ],
    published_at: 1.week.ago,
    active: true,
    image_url: "https://images.unsplash.com/photo-1620916566398-39f1143ab7be?w=400&h=400&fit=crop",
    variants: [
      { name: "250ml", sku: "PIXI-GLOW-250", price: 29.00, stock: 60 },
      { name: "100ml", sku: "PIXI-GLOW-100", price: 15.00, stock: 80 }
    ]
  },
  {
    name: "Charlotte Tilbury Pillow Talk Lipstick",
    brand: "charlotte-tilbury",
    categories: [ "makeup", "lipstick" ],
    description: "Universally flattering pinky-brown nude lipstick that enhances everyone's natural lip color.",
    skin_types: [ "normal", "dry", "combination", "oily" ],
    published_at: 5.days.ago,
    active: true,
    image_url: "https://images.unsplash.com/photo-1586495777744-4413f21062fa?w=400&h=400&fit=crop",
    variants: [
      { name: "Pillow Talk", sku: "CT-PILLOW-TALK", price: 34.00, stock: 45, compare_at_price: 40.00 }
    ]
  },
  {
    name: "La Roche-Posay Toleriane Double Repair Face Moisturizer",
    brand: "drunk-elephant",
    categories: [ "skincare", "moisturizers" ],
    description: "Daily face moisturizer with ceramides and niacinamide for sensitive skin.",
    skin_types: [ "sensitive", "dry", "normal" ],
    published_at: 3.days.ago,
    active: true,
    image_url: "https://images.unsplash.com/photo-1556228720-195a672e8a03?w=400&h=400&fit=crop",
    variants: [
      { name: "75ml", sku: "LRP-TOLER-75", price: 20.00, stock: 70 }
    ]
  },
  {
    name: "Glossier Boy Brow",
    brand: "glossier",
    categories: [ "makeup" ],
    description: "Tinted brow gel that fluffs, fills, and holds brows in place for a feathery, full finish.",
    skin_types: [ "normal", "oily", "combination", "dry" ],
    published_at: 1.day.ago,
    active: true,
    image_url: "https://images.unsplash.com/photo-1598440947619-2c35fc9aa908?w=400&h=400&fit=crop",
    variants: [
      { name: "Brown", sku: "GLOS-BOY-BRN", price: 16.00, stock: 85 },
      { name: "Black", sku: "GLOS-BOY-BLK", price: 16.00, stock: 80 }
    ]
  },
  {
    name: "Tatcha Rice Water Cleanser",
    brand: "the-ordinary",
    categories: [ "skincare", "cleansers" ],
    description: "pH-balanced cream cleanser that removes makeup and impurities while softening skin.",
    skin_types: [ "dry", "normal", "sensitive" ],
    published_at: 6.days.ago,
    active: true,
    image_url: "https://images.unsplash.com/photo-1556228578-8c89e6adf883?w=400&h=400&fit=crop",
    variants: [
      { name: "120ml", sku: "TATCHA-RICE-120", price: 34.00, stock: 40 }
    ]
  },
  {
    name: "Fenty Beauty Glossy Potion Lip Gloss",
    brand: "fenty-beauty",
    categories: [ "makeup", "lipstick" ],
    description: "Non-sticky lip gloss with a glossy finish and comfortable wear.",
    skin_types: [ "normal", "dry", "combination", "oily" ],
    published_at: 2.days.ago,
    active: true,
    image_url: "https://images.unsplash.com/photo-1586495777744-4413f21062fa?w=400&h=400&fit=crop",
    variants: [
      { name: "Fu$$y", sku: "FENTY-GLOSS-FUSSY", price: 20.00, stock: 55 },
      { name: "Fenty Glow", sku: "FENTY-GLOSS-GLOW", price: 20.00, stock: 50, compare_at_price: 24.00 }
    ]
  },
  {
    name: "Kiehl's Ultra Facial Cream",
    brand: "drunk-elephant",
    categories: [ "skincare", "moisturizers" ],
    description: "24-hour daily face moisturizer for normal to dry skin that leaves skin soft and comfortable.",
    skin_types: [ "dry", "normal", "combination" ],
    published_at: 1.week.ago,
    active: true,
    image_url: "https://images.unsplash.com/photo-1556228720-195a672e8a03?w=400&h=400&fit=crop",
    variants: [
      { name: "50ml", sku: "KIEHLS-ULTRA-50", price: 22.00, stock: 65 },
      { name: "125ml", sku: "KIEHLS-ULTRA-125", price: 37.00, stock: 45 }
    ]
  },
  {
    name: "Benefit Gimme Brow+ Volumizing Eyebrow Gel",
    brand: "charlotte-tilbury",
    categories: [ "makeup" ],
    description: "Tinted volumizing eyebrow gel with tiny microfibers that adhere to skin and hairs.",
    skin_types: [ "normal", "oily", "combination", "dry" ],
    published_at: 4.days.ago,
    active: true,
    image_url: "https://images.unsplash.com/photo-1598440947619-2c35fc9aa908?w=400&h=400&fit=crop",
    variants: [
      { name: "Shade 3", sku: "BENEFIT-GIMME-3", price: 24.00, stock: 70 },
      { name: "Shade 4", sku: "BENEFIT-GIMME-4", price: 24.00, stock: 65 }
    ]
  },
  {
    name: "Supergoop! Unseen Sunscreen SPF 40",
    brand: "the-ordinary",
    categories: [ "skincare" ],
    description: "Invisible, weightless sunscreen that provides broad-spectrum SPF 40 protection.",
    skin_types: [ "normal", "oily", "combination", "sensitive" ],
    published_at: 3.days.ago,
    active: true,
    image_url: "https://images.unsplash.com/photo-1556228578-8c89e6adf883?w=400&h=400&fit=crop",
    variants: [
      { name: "50ml", sku: "SUPER-SUN-50", price: 34.00, stock: 50, compare_at_price: 38.00 }
    ]
  },
  {
    name: "Rare Beauty Positive Light Liquid Luminizer",
    brand: "rare-beauty",
    categories: [ "makeup" ],
    description: "Buildable liquid highlighter that gives skin a luminous, healthy-looking glow.",
    skin_types: [ "normal", "dry", "combination" ],
    published_at: 2.days.ago,
    active: true,
    image_url: "https://images.unsplash.com/photo-1596462502278-27bfdc403348?w=400&h=400&fit=crop",
    variants: [
      { name: "Enlighten", sku: "RARE-LUM-ENLIGHT", price: 22.00, stock: 40 },
      { name: "Mesmerize", sku: "RARE-LUM-MESMER", price: 22.00, stock: 35 }
    ]
  },
  {
    name: "Maybelline Instant Age Rewind Concealer",
    brand: "glossier",
    categories: [ "makeup" ],
    description: "Multi-use concealer and treatment that erases dark circles and signs of fatigue.",
    skin_types: [ "normal", "dry", "combination" ],
    published_at: 5.days.ago,
    active: true,
    image_url: "https://images.unsplash.com/photo-1583241800098-d4940f177abc?w=400&h=400&fit=crop",
    variants: [
      { name: "Fair", sku: "MAYBE-AGE-FAIR", price: 9.00, stock: 95 },
      { name: "Light", sku: "MAYBE-AGE-LIGHT", price: 9.00, stock: 90 }
    ]
  },
  {
    name: "First Aid Beauty Ultra Repair Cream",
    brand: "drunk-elephant",
    categories: [ "skincare", "moisturizers" ],
    description: "Intensive moisturizer for face and body that repairs and relieves very dry skin.",
    skin_types: [ "dry", "sensitive", "normal" ],
    published_at: 1.week.ago,
    active: true,
    image_url: "https://images.unsplash.com/photo-1556228720-195a672e8a03?w=400&h=400&fit=crop",
    variants: [
      { name: "170g", sku: "FAB-REPAIR-170", price: 36.00, stock: 55 }
    ]
  },
  {
    name: "Urban Decay Naked3 Eyeshadow Palette",
    brand: "fenty-beauty",
    categories: [ "makeup", "eyeshadow" ],
    description: "12-shade eyeshadow palette featuring rose-hued neutrals with a mix of finishes.",
    skin_types: [ "normal", "oily", "combination", "dry" ],
    published_at: 6.days.ago,
    active: true,
    image_url: "https://images.unsplash.com/photo-1583241800098-d4940f177abc?w=400&h=400&fit=crop",
    variants: [
      { name: "Naked3 Palette", sku: "UD-NAKED3", price: 54.00, stock: 25, compare_at_price: 60.00 }
    ]
  },
  {
    name: "Glossier Generation G Lipstick",
    brand: "glossier",
    categories: [ "makeup", "lipstick" ],
    description: "Sheer-matte lipstick that gives lips a soft wash of color with a lived-in matte finish.",
    skin_types: [ "normal", "dry", "combination", "oily" ],
    published_at: 1.day.ago,
    active: true,
    image_url: "https://images.unsplash.com/photo-1586495777744-4413f21062fa?w=400&h=400&fit=crop",
    variants: [
      { name: "Cake", sku: "GLOS-GEN-CAKE", price: 18.00, stock: 75 },
      { name: "Leo", sku: "GLOS-GEN-LEO", price: 18.00, stock: 70 }
    ]
  },
  {
    name: "Drunk Elephant T.L.C. Framboos Glycolic Night Serum",
    brand: "drunk-elephant",
    categories: [ "skincare", "serums" ],
    description: "AHA/BHA night serum that gently resurfaces skin to reveal a smoother, brighter complexion.",
    skin_types: [ "normal", "combination", "oily" ],
    published_at: 4.days.ago,
    active: true,
    image_url: "https://images.unsplash.com/photo-1620916566398-39f1143ab7be?w=400&h=400&fit=crop",
    variants: [
      { name: "30ml", sku: "DE-FRAM-30", price: 90.00, stock: 20, compare_at_price: 105.00 }
    ]
  },
  {
    name: "Too Faced Melted Matte Liquid Lipstick",
    brand: "rare-beauty",
    categories: [ "makeup", "lipstick" ],
    description: "Highly pigmented liquid lipstick with an opaque matte finish that's comfortable to wear.",
    skin_types: [ "normal", "dry", "combination", "oily" ],
    published_at: 3.days.ago,
    active: true,
    image_url: "https://images.unsplash.com/photo-1586495777744-4413f21062fa?w=400&h=400&fit=crop",
    variants: [
      { name: "Melted Berry", sku: "TF-MELT-BERRY", price: 21.00, stock: 60 },
      { name: "Melted Ruby", sku: "TF-MELT-RUBY", price: 21.00, stock: 55 }
    ]
  },
  {
    name: "CeraVe PM Facial Moisturizing Lotion",
    brand: "the-ordinary",
    categories: [ "skincare", "moisturizers" ],
    description: "Lightweight, night moisturizer with niacinamide and hyaluronic acid for normal to dry skin.",
    skin_types: [ "dry", "normal", "sensitive" ],
    published_at: 5.days.ago,
    active: true,
    image_url: "https://images.unsplash.com/photo-1556228720-195a672e8a03?w=400&h=400&fit=crop",
    variants: [
      { name: "89ml", sku: "CERAVE-PM-89", price: 14.00, stock: 85 }
    ]
  },
  {
    name: "Anastasia Beverly Hills Modern Renaissance Palette",
    brand: "charlotte-tilbury",
    categories: [ "makeup", "eyeshadow" ],
    description: "14-shade eyeshadow palette featuring berry and warm red tones in matte and metallic finishes.",
    skin_types: [ "normal", "oily", "combination", "dry" ],
    published_at: 1.week.ago,
    active: true,
    image_url: "https://images.unsplash.com/photo-1583241800098-d4940f177abc?w=400&h=400&fit=crop",
    variants: [
      { name: "Modern Renaissance", sku: "ABH-MOD-REN", price: 42.00, stock: 30, compare_at_price: 48.00 }
    ]
  },
  {
    name: "Milani Baked Blush",
    brand: "fenty-beauty",
    categories: [ "makeup" ],
    description: "Baked blush with a silky texture that provides buildable color with a natural finish.",
    skin_types: [ "normal", "dry", "combination", "oily" ],
    published_at: 2.days.ago,
    active: true,
    image_url: "https://images.unsplash.com/photo-1596462502278-27bfdc403348?w=400&h=400&fit=crop",
    variants: [
      { name: "Luminoso", sku: "MILANI-LUMI", price: 8.00, stock: 90 },
      { name: "Berry Amore", sku: "MILANI-BERRY", price: 8.00, stock: 85 }
    ]
  },
  {
    name: "Ordinary Vitamin C Suspension 23% + HA Spheres 2%",
    brand: "the-ordinary",
    categories: [ "skincare", "serums" ],
    description: "Water-free vitamin C serum with 23% L-Ascorbic Acid for brightening and anti-aging.",
    skin_types: [ "normal", "combination", "oily" ],
    published_at: 6.days.ago,
    active: true,
    image_url: "https://images.unsplash.com/photo-1620916566398-39f1143ab7be?w=400&h=400&fit=crop",
    variants: [
      { name: "30ml", sku: "TO-VIT-C-30", price: 7.00, stock: 95 }
    ]
  },
  {
    name: "Tarte Amazonian Clay Blush",
    brand: "rare-beauty",
    categories: [ "makeup" ],
    description: "Long-wearing blush with Amazonian clay that provides 12-hour wear and buildable coverage.",
    skin_types: [ "normal", "oily", "combination", "dry" ],
    published_at: 3.days.ago,
    active: true,
    image_url: "https://images.unsplash.com/photo-1596462502278-27bfdc403348?w=400&h=400&fit=crop",
    variants: [
      { name: "Paaarty", sku: "TARTE-PARTY", price: 29.00, stock: 45, compare_at_price: 34.00 },
      { name: "Dollface", sku: "TARTE-DOLL", price: 29.00, stock: 40 }
    ]
  },
  {
    name: "Youth to the People Superfood Cleanser",
    brand: "drunk-elephant",
    categories: [ "skincare", "cleansers" ],
    description: "Daily facial cleanser with superfoods like spinach, kale, and green tea for healthy skin.",
    skin_types: [ "normal", "combination", "oily" ],
    published_at: 4.days.ago,
    active: true,
    image_url: "https://images.unsplash.com/photo-1556228578-8c89e6adf883?w=400&h=400&fit=crop",
    variants: [
      { name: "237ml", sku: "YTTP-SUPER-237", price: 36.00, stock: 50 }
    ]
  },
  {
    name: "MAC Fix+ Setting Spray",
    brand: "glossier",
    categories: [ "makeup" ],
    description: "Multi-purpose setting spray that can prep, set, and refresh makeup throughout the day.",
    skin_types: [ "normal", "dry", "combination", "oily" ],
    published_at: 1.day.ago,
    active: true,
    image_url: "https://images.unsplash.com/photo-1615397349754-cfa2066a298e?w=400&h=400&fit=crop",
    variants: [
      { name: "100ml", sku: "MAC-FIX-100", price: 23.00, stock: 70 },
      { name: "30ml", sku: "MAC-FIX-30", price: 12.00, stock: 95 }
    ]
  }
]

products_data.each do |product_data|
  brand = Brand.find_by!(slug: product_data[:brand])

  product = Product.find_or_create_by!(name: product_data[:name]) do |p|
    p.brand = brand
    p.description = product_data[:description]
    p.skin_types = product_data[:skin_types]
    p.published_at = product_data[:published_at]
    p.active = product_data[:active]
  end

  # Store the image URL in a simple way (we'll enhance this later with Active Storage)
  if product_data[:image_url] && !product.respond_to?(:image_url)
    # For now, we'll add this as a custom attribute - in a real app you'd use Active Storage
    product.update_column(:meta_description, "IMAGE_URL:#{product_data[:image_url]}")
  end

  # Add categories
  product_data[:categories].each do |category_slug|
    category = Category.find_by!(slug: category_slug)
    Categorization.find_or_create_by!(product: product, category: category)
  end

  # Create variants
  product_data[:variants].each do |variant_data|
    ProductVariant.find_or_create_by!(product: product, name: variant_data[:name]) do |variant|
      variant.sku = variant_data[:sku]
      variant.price = Money.new(variant_data[:price] * 100) # Convert to cents
      variant.stock_quantity = variant_data[:stock]
      variant.position = product.product_variants.count + 1

      # Add compare_at_price if provided
      if variant_data[:compare_at_price]
        variant.compare_at_price = Money.new(variant_data[:compare_at_price] * 100)
      end
    end
  end
end

puts "✅ Created #{Product.count} products with #{ProductVariant.count} variants"

# Create a sample user for reviews
puts "Creating sample user for reviews..."
sample_user = User.find_or_create_by!(email_address: "reviewer@example.com") do |user|
  user.first_name = "Beauty"
  user.last_name = "Reviewer"
  user.password = "password123"
  user.governorate = "Beirut"
  user.preferred_language = "en"
end

# Create some sample reviews
puts "Creating sample reviews..."
sample_reviews = [
  { product: "Fenty Beauty Pro Filt'r Soft Matte Longwear Foundation", rating: 5, title: "Perfect coverage!", body: "This foundation is amazing! Perfect coverage and lasts all day." },
  { product: "The Ordinary Niacinamide 10% + Zinc 1%", rating: 4, title: "Great for oily skin", body: "Really helps control oil and minimize pores. Takes a few weeks to see results." },
  { product: "Rare Beauty Soft Pinch Liquid Blush", rating: 5, title: "So pigmented!", body: "A little goes a long way. Beautiful natural finish." }
]

sample_reviews.each do |review_data|
  product = Product.find_by!(name: review_data[:product])
  next if product.reviews.exists?(title: review_data[:title])

  Review.create!(
    product: product,
    user: sample_user,
    rating: review_data[:rating],
    title: review_data[:title],
    body: review_data[:body],
    status: "approved"
  )
end

puts "✅ Created #{Review.count} reviews"

puts "🎉 Seeding completed successfully!"
puts ""
puts "Summary:"
puts "- #{Brand.count} brands"
puts "- #{Category.count} categories"
puts "- #{Product.count} products"
puts "- #{ProductVariant.count} product variants"
puts "- #{Review.count} reviews"
