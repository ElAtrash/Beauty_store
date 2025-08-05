# Claude Assistant Configuration

## Rails Command Guidelines

**ALWAYS use `bundle exec` prefix for Rails commands:**

✅ **Correct:**
- `bundle exec rails console`
- `bundle exec rails server` 
- `bundle exec rails tailwindcss:build`
- `bundle exec rails db:seed`
- `bundle exec rails db:migrate`

❌ **Incorrect (causes zsh: command not found):**
- `rails console`
- `rails server`
- `rails tailwindcss:build`

## Other Ruby/Gem Commands

**Always use bundle exec for gem executables:**
- `bundle exec rspec`
- `bundle exec rubocop`
- `bundle exec rake`

## Project-Specific Notes

- This is a Rails 8.0.2 application
- Uses Tailwind CSS via `tailwindcss-rails` gem
- Database: PostgreSQL
- Uses ViewComponents architecture
- Pagy for pagination (not Kaminari)

## CSS Architecture

- Single `@layer components` with organized sections
- No circular dependencies in `@apply` directives
- Component classes use actual Tailwind utilities, not custom utility classes