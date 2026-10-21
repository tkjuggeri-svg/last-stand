---
name: design-proposal
description: Write a design proposal for a LAST STAND milestone or system as a doc in docs/ (decisions, examples, open questions), with no implementation before the user approves. Use when the user asks for a design, a proposal or a plan for a milestone.
---

# Design proposal

Write `docs/<MILESTONE>_<TOPIC>.md` (e.g. `docs/M8_META.md`, like `docs/M7_RUN_MAP.md`):

1. **Status line at the top:** "proposal, not approved, not implemented"; numbers are starting points
   for the balance tools.
2. **0. Summary:** the whole proposal in 6-10 bullets.
3. **The design, section by section:** what the player sees and does, with **concrete examples and
   numbers** (tables: costs, odds, waves, unlock order, sample texts), and the *why* of each choice.
   Read the current code and docs first: build on what exists (`RunState`, `ChapterCarry`, the systems
   and their exported wiring) and respect CLAUDE.md (autoloads, physics layers, input map, folders:
   ask first).
4. **How it would fit the code (sketch):** new resources, systems and screens, what changes, the tests
   it needs, the balance check. A sketch, not code.
5. **Open questions**, numbered (Q1, Q2, ...), **each with a recommendation**.
6. After approval: a **Decisions** table (# / question / decision / from: user or recommendation), and
   later an "As built" section with what changed during the work.

Link it from ROADMAP.md, commit and push the doc alone. **Don't implement anything until the user has
answered the open questions**; then follow the decisions.
