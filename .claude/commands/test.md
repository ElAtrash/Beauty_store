---
name: test
description: Run RSpec tests with various options and filters
aliases: ["spec", "rspec"]
---

# Rails Test Runner

Run your RSpec test suite with intelligent filtering and reporting.

## Usage Examples:

- `/test` - Run all tests
- `/test models` - Run model specs only
- `/test system` - Run system/feature specs
- `/test User` - Run tests for User model
- `/test --failed` - Run only previously failed tests
- `/test coverage` - Run tests with coverage report

## What I'll do:

1. Run RSpec with appropriate filters and options
2. Display results with proper formatting
3. Show coverage information when requested
4. Highlight failures and provide debugging context

**Arguments**: $ARGUMENTS

```bash
if [ -z "$1" ]; then
  echo "🧪 Running full test suite..."
  bundle exec rspec --format documentation
elif [ "$1" = "models" ]; then
  echo "🧪 Running model specs..."
  bundle exec rspec spec/models/ --format documentation
elif [ "$1" = "system" ]; then
  echo "🧪 Running system specs..."
  bundle exec rspec spec/system/ --format documentation
elif [ "$1" = "coverage" ]; then
  echo "🧪 Running tests with coverage report..."
  COVERAGE=true bundle exec rspec --format documentation
elif [ "$1" = "--failed" ]; then
  echo "🧪 Running only failed tests..."
  bundle exec rspec --only-failures --format documentation
else
  echo "🧪 Running tests for: $1"
  bundle exec rspec --format documentation -e "$1"
fi
```
