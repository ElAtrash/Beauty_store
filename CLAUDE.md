# Claude Assistant Configuration

## 🏛️ Multi-Agent Architecture Overview

This project uses a **specialized agent system** where different agents handle specific areas of expertise. This configuration serves as the **orchestration layer** that coordinates between agents and provides high-level architectural guidance.

### 🎯 Agent Selection Guide

Use the appropriate specialist agent for different types of work:

- **🏗️ Models/Database**: `models-specialist` - ActiveRecord models, migrations, Money gem, database design
- **🎮 Controllers/Routes**: `controllers-specialist` - RESTful design, authentication, routing, API patterns
- **🔲 ViewComponents**: `viewcomponent-specialist` - Component architecture, slots, testing, ViewComponent v4
- **⚡ Frontend/Stimulus**: `stimulus-specialist` - Hotwire, Turbo, Stimulus controllers, JavaScript interactions
- **🎨 Tailwind CSS**: `tailwind-specialist` - Tailwind v4, utility-first design, responsive patterns
- **🧪 Testing**: `rspec-specialist` - RSpec patterns, TDD, test coverage, testing strategies
- **🔍 Complex Bugs**: `root-cause-analyzer` - Systematic debugging, investigation, hypothesis generation
- **📊 Architecture**: `codebase-research-analyst` - System analysis, architectural decisions, codebase exploration

### 🚀 Project Context: Beauty Store E-commerce

**Domain**: Premium beauty products e-commerce platform
**Architecture**: Rails 8.0.2 + PostgreSQL + Hotwire + ViewComponent v4 + Tailwind v4

## 🧠 Core Architectural Principles

### 1. **Clean Architecture**
- **Models**: Business logic, validations, Money objects
- **Controllers**: Thin coordinators, authentication, HTTP handling
- **Services**: Complex business operations, external integrations
- **ViewComponents**: Reusable UI with slots, proper encapsulation
- **Stimulus**: Minimal JavaScript for progressive enhancement

### 2. **Component-Driven Design**
- **ViewComponent v4**: Slot-based architecture with dual compatibility
- **Stimulus Controllers**: Targeted, minimal JavaScript enhancement
- **Unified Systems**: Consistent modal, form, and filter patterns

### 3. **Modern Rails 8 Patterns**
- **Hotwire-First**: Turbo Frames/Streams for seamless interactions
- **Money Gem**: Proper financial data handling with multi-currency support
- **Form Objects**: Complex form handling and validation
- **Service Objects**: Business logic encapsulation

## 🛠️ Technology Stack

### Backend
- **Rails 8.0.2** - Latest Rails with modern patterns
- **PostgreSQL** - Primary database
- **Money Gem** - Financial calculations and multi-currency

### Frontend
- **Hotwire (Turbo + Stimulus)** - Progressive enhancement without JavaScript framework complexity
- **ViewComponent v4** - Component-driven UI with slot architecture
- **Tailwind CSS v4** - Utility-first styling (⚠️ Note: breaking changes with `@apply`)

### Key Architectural Systems

**📋 Detailed documentation for these systems is available in `.claude/docs/agents/shared/`**

- **Modal System** - Unified modal architecture with BaseComponent
- **Filter System** - Clean URL-based filtering with Turbo Frame integration
- **Form System** - Unified FormFieldComponent with real-time validation

## 🎯 Development Philosophy

### **Maintainability First**
> Code is read far more often than it is written. Solutions must be simple, explicit, and easy for another developer to understand six months later.

### **Convention Over Configuration**
> Leverage Rails conventions and established patterns. Only deviate with clear architectural reasoning.

### **Progressive Enhancement**
> Build core functionality server-side, enhance with minimal JavaScript. Hotwire provides rich interactions without SPA complexity.

## 📋 Agent Coordination Patterns

### Simple Tasks (Direct Implementation)
- Single-component changes
- Straightforward bug fixes
- Simple feature additions

### Complex Tasks (Multi-Agent Workflow)
1. **Analyze** with appropriate research agent
2. **Implement** with relevant specialist agents
3. **Test** with rspec-specialist
4. **Review** architecture with codebase-research-analyst

### Cross-Cutting Concerns
- **Models + Views**: Use both `models-specialist` and `viewcomponent-specialist`
- **Controller + Frontend**: Use both `controllers-specialist` and `stimulus-specialist`
- **Full-Stack Features**: Coordinate multiple specialists in sequence

## ⚙️ Development Workflow

### Command Patterns
**Always use `bundle exec` for Rails commands:**
```bash
bundle exec rails console
bundle exec rails server
bundle exec rspec spec/
bundle exec rubocop
```

### Testing Strategy
- **Component Tests** - ViewComponent rendering and behavior
- **System Tests** - Critical user paths with Capybara
- **Model Tests** - Business logic, validations, Money objects
- **Controller Tests** - HTTP handling, authentication

### Code Quality
- **RuboCop** - Code style consistency
- **RSpec** - Comprehensive test coverage
- **ViewComponent Testing** - Component isolation and integration

## 🎨 Beauty Store Specific Patterns

### UI/UX Philosophy
- **Square Aesthetic** - Clean, borderless containers with subtle shadows
- **Minimal Design** - User-friendly interfaces without visual clutter
- **Mobile-First** - Responsive design with Tailwind breakpoints

### E-commerce Patterns
- **Money Objects** - All pricing uses Money gem for precision
- **Cart System** - Modal-based with Turbo Stream updates
- **Product Filtering** - Clean URLs with real-time updates
- **Checkout Flow** - Multi-step with form validation

## 🔄 Migration & Maintenance

### When Adding Features
1. **Choose appropriate specialist agent** based on primary concern
2. **Follow established patterns** from shared system documentation
3. **Update tests** with rspec-specialist
4. **Consider cross-cutting impacts** (authentication, permissions, etc.)

### When Debugging
1. **Use root-cause-analyzer** for complex issues
2. **Leverage code-finder** for locating relevant code
3. **Apply fixes** with appropriate specialist agents
4. **Verify with tests** using rspec-specialist

---

**🎯 Goal**: Maintain a scalable, maintainable codebase that serves the beauty store domain effectively while providing excellent user experience through modern Rails patterns.
