# Workspace UX Architecture

## 1. Purpose

This document defines the UX architecture authority for Reshet's workspace direction.

Reshet is not defined primarily as a graph viewer. Reshet is a persistent semantic workspace for exploring words, relations, and meaning context over time.

This document explains why the user experience is structured around a workspace, persistent navigation, semantic continuity, and coordinated panes. It does not define low-level implementation details.

## 2. Authority Scope

This document is authoritative for:

- UX philosophy
- workspace concept
- pane relationship
- persistent semantic workspace direction
- graph role in the workspace
- navigation continuity concept
- persistent UX direction
- responsive philosophy direction
- UX boundary rules

This document is not authoritative for:

- graph traversal semantics
- edge direction algorithms
- graph expansion rules
- search ranking or scoring
- debounce behavior
- repository interaction details
- database schema
- Flutter widget structure
- exact responsive breakpoint values
- rendering optimization
- visual styling systems
- typography or color systems
- exact navigation behavior specifications

Detailed implementation rules must be defined in their own documents or code-level contracts.

## 3. Core Philosophy

Reshet's core UX goal is to help the user maintain semantic orientation while moving through related words.

The user should not experience each graph, detail view, search result, or exploration state as an isolated screen. These surfaces should feel like coordinated views inside one persistent workspace.

The UX prioritizes:

- semantic continuity over isolated page transitions
- persistent access over one-off navigation
- contextual exploration over static viewing
- workspace stability over temporary workflow convenience

Graph exploration remains important, but the graph is not the application shell. The graph is one contextual workspace surface among others.

## 4. Persistent Semantic Workspace

A persistent semantic workspace keeps the user's current meaning context available while allowing exploration to continue.

The workspace should preserve the user's orientation across:

- selected word
- center or focus word
- related words
- detail context
- exploration history
- search entry points
- creation or correction flow

Persistence does not mean every panel must always be visually present on every device. It means the UX architecture should avoid unnecessary loss of semantic context when the user moves between related tasks.

The workspace model exists to support the user's mental continuity: "where am I in the semantic network, what am I looking at, and what can I do next?"

## 5. MainWorkspace Concept

The target workspace concept is:

```text
MainWorkspace
 ├─ GraphPane
 ├─ DetailPane
 └─ ExplorePane
```

These are conceptual panes or views within one semantic workspace. They are not separate application identities.

### GraphPane

GraphPane presents relation context. Its role is to help the user understand how the current word is connected to other words.

GraphPane should remain contextual. It should not become the only organizing shell for the whole application.

### DetailPane

DetailPane presents the selected word's readable semantic information.

DetailPane should clarify the user's current focus without taking over navigation authority.

### ExplorePane

ExplorePane supports broader exploration continuity: history, adjacent context, semantic movement, and workspace-level coordination.

ExplorePane is not merely a graph replacement. It represents the user's ongoing exploration state.

### Pane Coordination

The panes may be visually combined or separated depending on platform and layout needs, but their responsibilities remain distinct.

The workspace should support semantic context synchronization. Changes in focus, selection, or exploration context should preserve semantic coherence across panes without collapsing their responsibilities into a single overloaded view.

## 6. Graph Role

The graph is a contextual semantic surface.

Its role is to expose relationship structure around the current context. It should help the user see connections, inspect relation meaning, and move through the semantic network.

The graph is not:

- the application shell
- the global navigation system
- the only workspace authority
- a replacement for detail reading
- a replacement for search
- a replacement for persistent semantic navigation

Graph-specific rules such as traversal semantics, relation direction interpretation, expansion limits, edge rendering, and layout algorithms belong to graph authority documents, not this UX architecture document.

## 7. Persistent Navigation Concept

Persistent navigation exists to preserve semantic access while the user explores.

Strong Rail is the target semantic navigation spine. It gives persistent access to Strong-based semantic anchors without forcing the graph area to carry global navigation responsibility.

Strong Rail should support:

- persistent visibility where the platform can support it
- stable semantic access
- quick return to known anchors
- continuity between search, graph, detail, and exploration context
- minimal intrusion into the graph workspace

Strong Rail is not:

- a detail renderer
- an explorer replacement
- a heavy interaction panel
- a temporary debug surface
- a graph layout control surface

Exact navigation behavior, jump mechanics, scrolling behavior, selection restoration, and keyboard interaction must be defined in a navigation policy document.

## 8. Search Philosophy

Search is a universal entry point into the semantic workspace.

Search should remain globally accessible in concept, independent of whether the user is currently reading detail content, inspecting the graph, or continuing an exploration path.

Search should support persistent access to the corpus without forcing the user to abandon their current semantic context unnecessarily.

Search is not defined here by ranking, scoring, normalization, debounce, or result rendering algorithms. Those belong to search-specific implementation or policy documents.

## 9. Persistent Action Concept

Creation and correction actions are part of exploration continuity.

The add action is not a secondary or hidden action in the UX architecture. It supports the natural flow:

```text
explore
-> discover a missing word or relation
-> add or correct it
-> continue exploring
```

The workspace should make this flow conceptually available without turning the entire workspace into an editing surface.

Exact creation dialogs, validation behavior, repository writes, and rollback behavior belong to implementation or data boundary documents.

## 10. Responsive Philosophy

Responsive UX must preserve the workspace philosophy while respecting platform constraints.

### Desktop and Tablet

Desktop and tablet experiences should prioritize persistent workspace UX.

These form factors can support multiple simultaneous workspace surfaces, such as persistent semantic navigation, graph context, and detail reading.

### Mobile

Mobile should use viewer or flow UX.

Mobile is not a reduced copy of the desktop workspace. It should preserve semantic continuity through flow, state, and return paths rather than by forcing all desktop panes into a smaller layout.

Exact breakpoints, platform layout decisions, and Flutter implementation details belong to a responsive layout policy document.

## 11. UX Boundary Rules

The following rules define UX responsibility boundaries:

1. Graph is not the application shell.
2. Strong Rail is not a detail renderer.
3. Strong Rail is not an explorer replacement.
4. Search is not owned by the graph surface.
5. Detail reading is not a navigation spine.
6. Temporary workflow UI must not be promoted into architecture authority.
7. Migration, debug, or verification UI must not become permanent UX policy by accident.
8. Implementation convenience must not define UX authority.
9. A pane may share visual space with another pane, but responsibility boundaries must remain clear.
10. Current implementation snapshots must not override the target UX architecture.

## 12. Relationship With Other Documents

This document defines UX architecture direction only. Related documents must own their own detailed authority.

### Graph Authority Documents

Graph authority documents define graph semantics, relation traversal, direction interpretation, expansion policy, edge behavior, and graph-specific rendering rules.

This document defines the graph's UX role inside the workspace, not graph engine behavior.

### Responsive Policy Document

A future responsive layout policy document should define platform-specific layout rules, breakpoint strategy, and pane presentation rules.

This document defines only the responsive philosophy: desktop and tablet prioritize persistent workspace UX, while mobile uses viewer or flow UX.

### Navigation Policy Document

A future navigation policy document should define Strong Rail behavior, selection rules, jump behavior, keyboard access, scroll behavior, and navigation continuity details.

This document defines only why persistent semantic navigation exists and what role it plays in the workspace.

### Migration and Historical Documents

Migration and historical documents provide evidence, transition context, and implementation history. They do not override this document's UX architecture authority.

### Repository and Data Boundary Documents

Repository, read boundary, normalization, and database documents define data authority and interaction boundaries.

This document assumes that UI surfaces consume stable semantic contracts, but it does not define repository APIs, read policies, normalization rules, or schema details.

## 13. Non-Goals

This document does not prescribe:

- exact screen layout
- Flutter widget tree
- database structure
- search scoring
- graph traversal rules
- relation direction algorithms
- graph layout algorithms
- responsive breakpoints
- visual design tokens
- typography
- color system
- performance optimizations

Those decisions require separate authority documents or implementation-level specifications.

## 14. Summary

Reshet's UX direction is a persistent semantic workspace.

The workspace coordinates graph, detail, exploration, search, navigation, and creation flows without making any single surface responsible for the whole application.

The graph remains central to semantic understanding, but it is contextual rather than shell-level. Persistent navigation and search preserve access and orientation. Responsive UX adapts the workspace philosophy to each form factor instead of shrinking one desktop layout everywhere.

This document should be used as the UX architecture authority when deciding whether future UX changes strengthen or weaken Reshet's persistent semantic workspace direction.
