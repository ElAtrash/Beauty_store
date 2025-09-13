# Claude Code Productivity Guide
*Maximizing Development Velocity with Rails 8 + Hotwire + ViewComponent + Tailwind v4*

## 🔄 Automatic vs Manual Agent Selection

### Automatic Agent Delegation (Recommended)
With your 11 specialized agents, Claude Code will **automatically** choose the right agent based on your request:

```
❌ Don't do: "Use the models-specialist agent to create a User model"
✅ Do: "Create a User model with name, email, and posts association"
```

Claude Code analyzes your request and automatically delegates to the appropriate specialist.

## 🎯 Most Productive Workflows

### 1. Feature Development Flow
```
You: "Add a product rating system with reviews"
→ Auto-delegates to rails-architect for planning
→ Uses models-specialist for Review model
→ Uses viewcomponent-specialist for rating UI
→ Uses rspec-specialist for testing
```

### 2. Use Slash Commands for Speed
```bash
/generate model Review product:references user:references rating:integer
/component create RatingStars rating:integer
/test models
/db migrate
/hotwire stimulus FavoriteButton
```

### 3. Switch Output Styles for Context
```bash
/output-style tdd-mode          # When writing tests first
/output-style architecture-mode # When designing systems  
/output-style debug-mode        # When fixing bugs
/output-style refactor-mode     # When improving code
```

## 🏆 Optimal Development Patterns

### Start Features with Architecture Mode
```bash
/output-style architecture-mode
"I need to add user authentication with social login"
```
→ Gets comprehensive system design approach

### Use TDD Mode for New Features
```bash
/output-style tdd-mode
"Add product favoriting functionality"
```
→ Writes tests first, then implementation

### Use Slash Commands for Routine Tasks
```bash
/db migrate                    # Database operations
/test User                     # Run specific tests
/component preview ProductCard # View component
/hotwire stimulus FavoriteButton # Create JS controller
```

### Let Hooks Handle Quality
Your hooks automatically:
- Run RuboCop after Ruby file edits
- Build Tailwind after CSS changes
- Show project status at session start
- Install gems when Gemfile changes

## 💡 Pro Tips for Maximum Productivity

### 1. Natural Language Works Best
```
✅ "Add pagination to the products listing page"
✅ "Fix the dropdown menu closing issue" 
✅ "Refactor the order creation into a service"
```

### 2. Context-Aware Requests
```
✅ "The user registration form needs better validation"
→ Auto-uses forms + validation patterns

✅ "Product cards need hover animations"  
→ Auto-uses ViewComponent + Tailwind specialists
```

### 3. Stack-Aware Development
Just mention your stack components naturally:
- "Turbo Frame" → stimulus-specialist
- "ViewComponent" → viewcomponent-specialist  
- "responsive design" → tailwind-specialist
- "database query" → models-specialist

### 4. Use Output Styles Strategically
- **Start of day**: Default mode for mixed work
- **New features**: Architecture mode for planning
- **Bug fixing**: Debug mode for systematic troubleshooting
- **Code cleanup**: Refactor mode for improvements
- **Test writing**: TDD mode for test-first approach

## 🎯 Example Productive Session

```bash
# 1. Start with project context (automatic via hooks)
# Shows git status, Rails version, database status

# 2. Plan a feature
/output-style architecture-mode
"Add a shopping cart with persistence and checkout flow"

# 3. Generate components quickly
/generate model CartItem cart:references product:references quantity:integer
/component create CartSummary cart:Cart

# 4. Switch to TDD for implementation
/output-style tdd-mode
"Implement cart item quantity updates with validation"

# 5. Test and refine
/test models
/test system
```

## 🚀 Available Tools Summary

### Specialized Agents (Auto-Selected)
- **rails-architect** - System design & coordination
- **models-specialist** - Database & ActiveRecord
- **controllers-specialist** - Routes & request handling
- **services-specialist** - Business logic & APIs
- **viewcomponent-specialist** - UI components
- **views-specialist** - Templates & layouts
- **stimulus-specialist** - Frontend interactions
- **tailwind-specialist** - CSS & responsive design
- **rspec-specialist** - Testing & TDD
- **api-specialist** - API development
- **feature-researcher** - Codebase analysis

### Slash Commands
- `/generate [type] [name]` - Rails generators
- `/test [filter]` - Run RSpec tests
- `/component [action] [name]` - ViewComponent management
- `/db [action]` - Database operations
- `/hotwire [tool] [name]` - Hotwire development

### Output Styles
- `tdd-mode` - Test-driven development
- `architecture-mode` - System design focus
- `debug-mode` - Problem diagnosis
- `refactor-mode` - Code quality improvements

### Automatic Quality Control
- RuboCop formatting after Ruby edits
- Bundle install when Gemfile changes
- Tailwind compilation after CSS changes
- Session startup context (git, Rails info)

## 🔥 Key Insight

**You rarely need to specify agents manually.** The system is designed to:

1. **Auto-delegate** based on your natural language requests
2. **Use slash commands** for speed on routine tasks
3. **Switch output styles** to change the AI's focus/approach
4. **Let hooks handle** quality control automatically

This creates a **seamless, productive flow** where you focus on **what** you want to build, not **how** to configure the tooling.

---

*This setup follows Rails conventions, enforces best practices, and maintains code quality automatically while maximizing development velocity.*