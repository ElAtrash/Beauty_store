---
name: db
description: Database operations - migrate, rollback, seed, and status checks
aliases: ["database", "migrate"]
---

# Database Management

Handle Rails database operations with safety checks and informative output.

## Usage Examples:
- `/db migrate` - Run pending migrations
- `/db rollback` - Rollback last migration
- `/db rollback 3` - Rollback last 3 migrations
- `/db seed` - Run database seeds
- `/db reset` - Drop, create, migrate, and seed
- `/db status` - Show migration status

## What I'll do:
1. Execute database commands safely with bundle exec
2. Show before/after status for migrations
3. Provide informative output about changes
4. Handle errors gracefully with helpful messages

**Arguments**: $ARGUMENTS

```bash
case "$1" in
  "migrate")
    echo "📊 Current migration status:"
    bundle exec rails db:migrate:status | tail -5
    echo "🔄 Running migrations..."
    bundle exec rails db:migrate
    echo "✅ Migrations complete!"
    ;;
  "rollback")
    if [ -n "$2" ]; then
      echo "⏪ Rolling back last $2 migrations..."
      bundle exec rails db:rollback STEP="$2"
    else
      echo "⏪ Rolling back last migration..."
      bundle exec rails db:rollback
    fi
    echo "📊 Current migration status:"
    bundle exec rails db:migrate:status | tail -5
    ;;
  "seed")
    echo "🌱 Seeding database..."
    bundle exec rails db:seed
    echo "✅ Database seeded!"
    ;;
  "reset")
    echo "🚨 Resetting database (drop, create, migrate, seed)..."
    read -p "Are you sure? This will destroy all data! (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      bundle exec rails db:reset
      echo "✅ Database reset complete!"
    else
      echo "❌ Database reset cancelled."
    fi
    ;;
  "status")
    echo "📊 Database migration status:"
    bundle exec rails db:migrate:status
    echo ""
    echo "🗄️  Database version:"
    bundle exec rails db:version
    ;;
  *)
    echo "Usage: /db [migrate|rollback|seed|reset|status] [options]"
    ;;
esac
```