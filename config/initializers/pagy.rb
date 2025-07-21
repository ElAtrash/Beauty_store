# frozen_string_literal: true

require "pagy/extras/bootstrap"
require "pagy/extras/overflow"

# Pagy Variables
# See https://ddnexus.github.io/pagy/api/pagy#variables
Pagy::DEFAULT[:items] = 40        # items per page for browsing
Pagy::DEFAULT[:size]  = [ 1, 4, 4, 1 ] # nav bar links
Pagy::DEFAULT[:overflow] = :last_page

# Bootstrap nav helper
Pagy::DEFAULT[:bootstrap] = {
  nav_class: "pagination justify-content-center",
  link_class: "page-link",
  active_class: "active"
}

# I18n
# Pagy::I18n.load(locale: 'en', filepath: 'path/to/pagy.en.yml')
# Pagy::I18n.load(locale: 'ar', filepath: 'path/to/pagy.ar.yml')
