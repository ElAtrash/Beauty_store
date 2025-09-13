---
name: generate
description: Rails generator shortcuts for models, controllers, components, and more
aliases: ["g", "gen"]
---

# Rails Generator Command

Generate Rails components quickly with proper conventions and testing.

## Usage Examples:

- `/generate model User name:string email:string`
- `/generate controller Products index show`
- `/generate component ProductCard product:Product`
- `/generate service CreateOrder`
- `/generate migration AddPriceToProducts price:decimal`

## What I'll do:

1. Run the appropriate Rails generator with bundle exec
2. Follow your project's conventions from CLAUDE.md
3. Create associated tests (RSpec specs)
4. Apply code formatting with RuboCop
5. For ViewComponents: create component, template, and test files

**Arguments**: $ARGUMENTS

!bundle exec rails generate $ARGUMENTS
