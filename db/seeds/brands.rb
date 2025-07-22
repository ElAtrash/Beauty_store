# frozen_string_literal: true

# Sample brands for testing alphabet navigation
sample_brands = [
  # A
  { name: "Anastasia Beverly Hills", description: "Professional makeup and brow products" },
  { name: "Armani Beauty", description: "Luxury Italian cosmetics and fragrances" },

  # B
  { name: "Benefit Cosmetics", description: "Fun and quirky beauty products" },
  { name: "Bobbi Brown", description: "Professional makeup artist brand" },

  # C
  { name: "Clinique", description: "Dermatologist-developed skincare and makeup" },
  { name: "CeraVe", description: "Dermatologist recommended skincare" },

  # D
  { name: "Dior", description: "French luxury beauty and fashion house" },
  { name: "Drunk Elephant", description: "Clean skincare with effective ingredients" },

  # E
  { name: "Estée Lauder", description: "Prestige beauty and skincare" },
  { name: "Elf Cosmetics", description: "Affordable high-quality makeup" },

  # F
  { name: "Fresh", description: "Natural beauty inspired by French pharmacy" },

  # G
  { name: "Glow Recipe", description: "Fruit-powered Korean skincare" },

  # H
  { name: "Huda Beauty", description: "Bold and glamorous makeup" },

  # I
  { name: "Ilia Beauty", description: "Clean beauty that doesn't compromise on performance" },

  # J
  { name: "Jack Black", description: "Superior skincare for men" },

  # K
  { name: "Kiehl's", description: "Since 1851, skincare expertise" },

  # L
  { name: "Laura Mercier", description: "Flawless face makeup and skincare" },

  # M
  { name: "Marc Jacobs Beauty", description: "Effortlessly cool makeup" },
  { name: "Milk Makeup", description: "Vegan, cruelty-free makeup" },

  # N
  { name: "NARS", description: "Uncompromising makeup artistry" },
  { name: "Neutrogena", description: "Dermatologist recommended skincare" },

  # O
  { name: "Olaplex", description: "Professional bond building hair care" },

  # P
  { name: "Pat McGrath Labs", description: "Luxury makeup by legendary artist" },

  # R
  { name: "Retinol", description: "Anti-aging skincare solutions" },

  # S
  { name: "Sephora Collection", description: "Beauty for all, expertly curated" },
  { name: "Supergoop!", description: "Clean sunscreen for every day" },

  # T
  { name: "Tatcha", description: "Japanese beauty wisdom" },
  { name: "Tarte", description: "Natural, high-performance makeup" },

  # U
  { name: "Urban Decay", description: "Beautiful makeup with an edge" },

  # V
  { name: "Valentino Beauty", description: "Italian luxury beauty" },

  # Y
  { name: "Yves Saint Laurent", description: "French luxury beauty and couture" },

  # Numbers
  { name: "3INA", description: "Spanish makeup brand with bold colors" },
  { name: "100% Pure", description: "Ultra-natural beauty products" }
]

puts "Creating sample brands..."

sample_brands.each do |brand_data|
  brand = Brand.find_or_create_by(name: brand_data[:name]) do |b|
    b.description = brand_data[:description]
    b.featured = false
  end

  if brand.persisted?
    puts "✅ Created/found brand: #{brand.name}"
  else
    puts "❌ Failed to create brand: #{brand_data[:name]} - #{brand.errors.full_messages.join(', ')}"
  end
end

puts "\nBrands summary:"
puts "Total brands: #{Brand.count}"
puts "Featured brands: #{Brand.featured.count}"
