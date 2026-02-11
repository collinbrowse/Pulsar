# The Big Picture
Pulsar is like a personal mission control for your activities. You open it, and it tells you what you have done, what matters, and how your profile is trending. Think of it as your activity dashboard with personality.

# Architecture Deep Dive
Imagine a restaurant kitchen: the views are the servers, taking orders and presenting dishes. The flows in `Shared/Logic` are the cooks, turning raw ingredients into meals. Networking is the pantry runner, fetching supplies from Supabase. AppState is the head chef keeping everyone in sync.

# The Codebase Map
- `App/`: App setup, configuration, and global state.
- `Features/`: User-facing screens grouped by domain.
- `Shared/Logic/`: Flow coordinators for feature behavior.
- `Shared/Models/`: Core models for the app.
- `Shared/Networking/`: Supabase integration and DTOs.
- `Shared/UI/`: Design system and reusable components.
- `PulsarTests/` and `PulsarUITests/`: Unit and UI tests.

# Tech Stack & Why
- SwiftUI because the UI is declarative, readable, and keeps state-driven updates predictable.
- Async/await because it reads like the happy-path and avoids callback spaghetti.
- Supabase for a backend that is fast to iterate on while still being production-ready.

# The Journey
- Started with a clean feature-based folder layout to keep growth tidy.
- Learned early that keeping flows in `Shared/Logic` prevents view bloat and makes tests easier.
- Hardened UI tests by adding stable accessibility identifiers to auth fields and making feed refresh tests tolerate empty states.

# Engineer's Wisdom
- Keep view code small and push logic into flows so the UI stays focused.
- Prefer explicit state over magic side effects; make data flow obvious.
- Tests are a safety net, especially for flows and models.

# If I Were Starting Over...
- I would add more sample data and previews from day one to speed up UI iteration.
- I would document API contracts earlier to avoid surprise DTO mismatches.
