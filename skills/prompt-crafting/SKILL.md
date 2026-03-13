---
name: prompt-crafting
description: Use when the user asks to create, write, or optimize a prompt for a subagent, an AI task, or any reusable LLM instruction — walks through gathering requirements and outputs a ready-to-use .md file
argument-hint: [description] or [expert] for advanced prompt engineering mode
---

# Crafting Optimized Prompts

## Mode Selection

- **Default mode** — invoked with `/prompt-crafting` or `/prompt-crafting <description>`. Interactive workflow to create a task prompt saved as `.md`.
- **Expert mode** — invoked with `/prompt-crafting expert`. Deep prompt engineering using advanced techniques (XML structure, few-shot, chain-of-thought, prefilling, multi-model). Read references before proceeding.

If the argument contains "expert", skip to the **Expert Mode** section below. Otherwise continue with the default workflow.

---

## Default Mode — Task Prompt Builder

### Workflow

1. **Ask the user** what the prompt should accomplish (if not already clear)
2. **Determine prompt type** from the table below — ask if ambiguous
3. **Gather the 5 sections** by asking targeted questions (one at a time)
4. **Write the prompt** to a `.md` file using the structure below
5. **Present the file path** and offer to refine

### Gathering Information

Ask these questions one at a time. Skip any the user already answered.

1. **Goal:** "What should the agent accomplish? What's the scope?"
2. **Context:** "What does the agent need to know? (project path, stack, patterns, relevant code)"
3. **Constraints:** "What should the agent NOT do? (read-only? specific files only? no refactoring?)"
4. **Steps:** "Is there a specific sequence to follow, or is the goal self-explanatory?"
5. **Output format:** "How should the agent report back? (table, list, structured sections, specific fields)"

### Prompt Type Reference

| Prompt type | Must include | Common pitfall |
|---|---|---|
| **Research/audit** | Scope boundaries, output table format | Agent explores too broadly, returns narrative instead of structured data |
| **Implementation** | Full task spec (pasted), file paths, existing patterns to follow | Agent invents own patterns, ignores codebase conventions |
| **Review** | What to review against (spec, checklist), severity levels | Agent rubber-stamps or nitpicks style instead of checking substance |
| **Debugging** | Error messages (pasted), reproduction steps, what was already tried | Agent re-investigates what was already ruled out |

### The 5-Section Structure

Write the `.md` file following this structure:

```markdown
# [Descriptive title]

[1-2 sentence goal. Be specific about scope and intent.]

## Context

[Everything the agent needs to understand the task.
Paste content directly — never tell an agent to "read the plan" or "check the spec."

Include: project location, stack/framework, relevant patterns, dependencies.
Exclude: conversation history, unrelated project parts, things derivable from code.]

## Constraints

[What NOT to do. At minimum: scope (which files) + modification policy (read-only vs. edit).]

- ...
- ...

## Steps

[Only if the sequence is non-obvious. Otherwise omit this section.]

1. ...
2. ...

## Output Format

[Exact format for the response. This is the #1 cause of unusable results when missing.]

Return: ...
```

### Key Principles

- **Paste, don't reference** — agents have no memory of your conversation. Embed all needed context.
- **Constrain by default** — at minimum specify scope (which files) and modification policy (read-only vs. edit).
- **Specify output** — "report your findings" is not a format. A markdown table with named columns is.
- **One goal per prompt** — if you need two things, write two prompts.

### File Naming

Save prompts to the location the user specifies. If none specified, suggest:
- `prompts/<descriptive-name>.md` in the current project
- Or `~/.claude/prompts/<descriptive-name>.md` for cross-project prompts

### Anti-Patterns

| Don't | Do |
|---|---|
| "Read the plan file at docs/plan.md" | Paste the relevant task text directly |
| "Fix the bug" (no error context) | Paste error message, stack trace, what was tried |
| No constraints at all | At minimum: scope + modification policy |
| "Report your findings" | Specify format: table, list, structured sections |
| Include full conversation context | Include only what's needed for this specific task |
| One giant paragraph | Use the 5-section structure with clear headers |

---

## Expert Mode — Advanced Prompt Engineering

Activated when the user passes `expert` as argument. This mode provides deep prompt engineering techniques for system prompts, user prompts, few-shot examples, and prompt optimization across models.

### Step 0: Read References

**CRITICAL — Before proceeding, read the relevant reference files from `{SKILL_PATH}/references/`.**

Select which references to read based on the user's need:

| Need | Reference to read |
|---|---|
| Claude-specific prompt | `anthropic-best-practices.md` + `xml-structure.md` |
| GPT-specific prompt | `openai-best-practices.md` |
| Needs examples/few-shot | `few-shot-patterns.md` |
| Complex reasoning task | `reasoning-techniques.md` |
| System prompt design | `system-prompt-patterns.md` |
| Long-running/multi-session | `context-management.md` |
| Reviewing/fixing a prompt | `anti-patterns.md` + `clarity-principles.md` |
| Starting from a template | `prompt-templates.md` |

### Step 1: Gather Requirements

Ask the user (via AskUserQuestion):

1. **Purpose** — Generate content, analyze/extract, transform data, make decisions, or other?
2. **Target model** — Claude (use XML tags), GPT (use markdown), or multi-model?
3. **Complexity** — Simple (single task), Medium (multiple steps), Complex (reasoning + edge cases)?
4. **Output format** — Free text, JSON, code, or specific template?

### Step 2: Draft the Prompt

Use this template, adapting tags for the target model:

```xml
<context>
[Background the model needs to understand the task]
</context>

<objective>
[Clear statement of what to accomplish]
</objective>

<instructions>
[Step-by-step process, numbered if sequential]
</instructions>

<constraints>
[Rules, limitations, things to avoid]
</constraints>

<output_format>
[Exact structure of expected output]
</output_format>

<examples>
[2-4 input/output pairs if format matters]
</examples>

<success_criteria>
[How to verify the task was done correctly]
</success_criteria>
```

### Step 3: Apply Techniques by Complexity

- **Simple** — Clear instructions + output format
- **Medium** — Add few-shot examples + constraints
- **Complex** — Add chain-of-thought reasoning + edge cases + validation + prefilling (Claude)

### Core Techniques

| Technique | When to use | Reference |
|---|---|---|
| **Be clear and direct** | Always — first pass | `clarity-principles.md` |
| **XML tags** | Claude prompts, complex structure | `xml-structure.md` |
| **Few-shot examples** | Output format matters, pattern > rules | `few-shot-patterns.md` |
| **Chain of thought** | Complex reasoning, math, multi-step | `reasoning-techniques.md` |
| **System prompts** | Persistent behavior, role, constraints | `system-prompt-patterns.md` |
| **Prefilling** | Enforce output format (Claude only) | `anthropic-best-practices.md` |
| **Context management** | Long sessions, multi-turn, state tracking | `context-management.md` |

### Step 4: Review Checklist

- [ ] Task clearly stated, no ambiguity
- [ ] Output format specified with example
- [ ] Edge cases addressed
- [ ] No vague language ("try", "maybe", "generally")
- [ ] Appropriate techniques for task complexity
- [ ] Would someone with zero context understand it?

### Anti-Patterns (Expert)

| Don't | Do |
|---|---|
| "Help with the data" | "Extract emails from CSV, deduplicate, output as JSON array" |
| "Don't use jargon" | "Write in plain language for a non-technical audience" |
| Describe format in words only | Show 2-3 concrete input/output examples |
| "Process the file" | "Process the file. If empty, return []. If malformed, return error with line number." |

### Reference Guides

- [references/clarity-principles.md](references/clarity-principles.md)
- [references/xml-structure.md](references/xml-structure.md)
- [references/few-shot-patterns.md](references/few-shot-patterns.md)
- [references/reasoning-techniques.md](references/reasoning-techniques.md)
- [references/system-prompt-patterns.md](references/system-prompt-patterns.md)
- [references/context-management.md](references/context-management.md)
- [references/anthropic-best-practices.md](references/anthropic-best-practices.md)
- [references/openai-best-practices.md](references/openai-best-practices.md)
- [references/anti-patterns.md](references/anti-patterns.md)
- [references/prompt-templates.md](references/prompt-templates.md)
