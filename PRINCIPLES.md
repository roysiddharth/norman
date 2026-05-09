# Harness Engineering Principles

> Source: Synthesized from the transcript "The Harness Is the Agent" (youtube.com/watch?v=Xxuxg8PcBvc)
> and three research papers: *Natural-Language Agent Harnesses* (arXiv:2603.25723),
> *Meta-Harness: End-to-End Optimization of Model Harnesses* (arXiv:2603.28052),
> and *OS-Symphony* (arXiv:2601.07779). April 2026.

---

## The Core Idea

**Agent = Model + Harness.**

Stanford researchers found that the same model, on the same benchmark, can show up to **6× performance variation** depending solely on how it is wrapped. Langchain confirmed this by modifying only harness infrastructure — their coding agent jumped from outside the top 30 to rank 5 on TerminalBench 2. The model did not change.

The implication is sharp: if you build agents, you are a harness engineer, whether you call yourself one or not.

---

## What the Harness Is

A raw LLM is like a CPU — powerful but inert. It has no RAM, no disk, no IO by itself. The harness is the operating system that coordinates what the CPU sees and when:

| Analogy | Agent Component |
|---------|----------------|
| CPU | Model weights |
| RAM | Context window |
| Disk | External databases |
| Device drivers | Tool integrations |
| Operating system | The harness |

Concretely, the harness is everything that is not model weights:
- System prompts
- Tool definitions
- Orchestration logic
- Memory management
- Verification loops
- Safety guardrails

---

## Principle 1: Separate What Changes From What Stays Fixed

The biggest structural mistake in harness design is mixing concerns that have different rates of change. Naive harnesses scatter logic across controller code, framework defaults, and verifier scripts — so two systems that nominally differ by one design choice actually differ in prompts, tools, verification gates, and state semantics simultaneously. This makes it impossible to know what actually caused a performance difference.

The *Natural-Language Agent Harnesses* paper formalizes a clean three-layer separation:

1. **Backend infrastructure** — tool access, file I/O, child-agent spawning. Fixed across tasks.
2. **Runtime charter** — universal rules: how contracts bind, how state persists, how child agents are managed. Fixed per deployment.
3. **Natural-Language Harness (NLH)** — task-specific control logic: contracts, roles, stage structure, failure taxonomies. Changes per task.

**Why this matters:** Fixing the charter while swapping the NLH lets you test harness design. Fixing the NLH while swapping the charter lets you test runtime policy. This is controlled experimentation — something harness engineering previously never had.

---

## Principle 2: Use Execution Contracts to Bound Agent Calls

Fuzzy LLM completions become unreliable when there is no structure around what a completion is supposed to produce. Execution contracts are the solution: they turn each agent invocation into a bounded, inspectable call with five required elements:

1. **Required outputs** — what artifacts must be produced and in what format
2. **Budgets** — token limits, call count limits, time bounds
3. **Permission scope** — which tools, file paths, and network access are allowed
4. **Completion conditions** — acceptance criteria and validation gates
5. **Designated output paths** — path-addressable locations where results must be written

Think of execution contracts as function signatures for agents. They prevent drift between what the harness claims happened and what the external evaluator accepts. Without them, a verifier can pass a patch that the benchmark rejects — because the verifier's local acceptance criteria are not aligned with the evaluator's criteria.

---

## Principle 3: Externalize State to Files

Transient context is fragile. Long-horizon tasks lose state under truncation, restart, and delegation. File-backed state solves this by externalizing durable memory to path-addressable files.

A practical canonical structure:
- `TASK.md` — task statement, linked inputs, designated outputs
- `RESPONSE.md` — final response with success/failure status and artifact pointers
- `state/task_history.jsonl` — append-only record of invocations
- `children/*/` — child-local task packets, copied inputs, scratch, artifacts
- `artifacts/` — benchmark-facing outputs

**The deeper benefit:** File-backed state shifts verification from brittle visual/heuristic checks to deterministic, auditable evidence. OS-Symphony demonstrated this directly: migrating from a screenshot-grounded repair loop to file-backed state dropped LLM calls from ~1,200 to 34, runtime from 361 minutes to 141 minutes, and improved task success from 30.4% to 47.2% — a 16.8 percentage point gain on OSWorld. The representation change alone drove this. Same strategy, different substrate.

---

## Principle 4: The Harness Is an Orchestration Pattern, Not a Reasoning Pattern

About 90% of all compute — tokens, tool calls, LLM calls — flows through delegated child agents, not the parent orchestrator. The parent harness decomposes, delegates, and verifies. It does not reason about the task itself.

This has a direct design implication: the harness should be lean. Its job is to define stage structure, manage contracts, and ensure artifacts are produced and verified — not to embed reasoning logic that belongs in the model.

Anthropic identified five canonical orchestration patterns:
1. **Prompt chaining** — sequential steps where each output feeds the next
2. **Routing** — classifying input and directing to the appropriate handler
3. **Parallelization** — running independent subtasks concurrently
4. **Orchestrator-workers** — a coordinator that spawns and manages specialized subagents
5. **Evaluator-optimizer loops** — a generator paired with an evaluator that grades and feeds back

Every production agent combines these patterns. The architectural choices about which patterns to use, and how to layer them, drive the performance gaps more than which model is underneath.

---

## Principle 5: More Structure Is Not Always Better

This is the most counterintuitive finding from the research, and the most important one to internalize.

The *Natural-Language Agent Harnesses* ablation study (SWE-bench Verified + OSWorld) found:

| Module | SWE-bench | OSWorld | Verdict |
|--------|-----------|---------|---------|
| Self-Evolution | +4.8 | +2.7 | Helps |
| File-Backed State | +1.6 | +5.5 | Helps |
| Evidence-Backed Answering | +1.6 | ±0.0 | Neutral |
| Verifier | **-0.8** | **-8.4** | Hurts |
| Multi-Candidate Search | **-2.4** | **-5.6** | Hurts |
| Dynamic Orchestration | ±0.0 | +2.7 | Neutral |

The verifier *hurt* because its local acceptance criteria diverged from the benchmark's acceptance criteria. Adding an independent checking layer created a new failure mode: passing things that should fail, and blocking things that should pass. Verification is only valuable when it is calibrated against the actual success condition.

Multi-candidate search hurt because the overhead of managing candidates exceeded any benefit under real budget constraints.

**The principle:** Add a harness module only when you have evidence it tightens the path to your actual success criterion. Structure that does not track the acceptance condition is noise.

---

## Principle 6: Self-Evolution Is the One Module That Consistently Helps

Across both SWE-bench (+4.8 points) and OSWorld (+2.7 points), self-evolution was the only module that consistently improved performance without a proportional cost explosion.

What self-evolution does: it enforces a disciplined, acceptance-gated attempt loop. The agent stays narrow — making a single, well-formed attempt — until explicit failure signals justify broadening. It is not a wide search over candidates. It is a constraint that forces the agent to define what success looks like before attempting, and keeps it honest about whether that criterion was met.

The principle: **discipline narrowing beats expensive broadening.** The mechanism that improved performance was not expanding the search tree — it was forcing cleaner success criteria around ordinary repair attempts.

---

## Principle 7: Representation Matters as Much as Logic

The same control logic expressed in natural language outperforms the same logic in native code. This is not a small effect. The OS-Symphony migration — same strategy, rewritten as natural language — moved OSWorld performance from 30.4% to 47.2% (+16.8 points) while collapsing LLM calls by 97%.

Why does representation matter?

- **Natural language harnesses are editable and inspectable.** You can read, modify, and reason about them directly.
- **They shift reliability mechanisms.** Brittle GUI repair loops depend on screenshot plausibility. Natural language harnesses naturally route toward file-backed and artifact-backed verification, which is deterministic.
- **They enable systematic science.** When harness logic is explicit and natural language, you can run controlled ablations. When it is buried in Python control flow, you can only compare bundles.

The implication: write your harness logic as explicit, readable specifications — not as implicit behavior embedded in code structure.

---

## Principle 8: Treat the Harness as an Optimization Target

The *Meta-Harness* paper from Stanford takes the logical next step: if representation matters this much, optimize it automatically.

The optimization loop:
1. An agentic proposer (Claude Code with Opus 4.6) reads raw execution traces from prior runs
2. It diagnoses failure patterns and writes a complete new harness
3. An evaluator tests each proposal
4. Scores and traces accumulate in a growing filesystem
5. Repeat (~20 iterations, ~60 harnesses evaluated total)

Key findings:
- **76.4% on TerminalBench 2** (rank #2, only automatically optimized system in a field of hand-engineered entries)
- **48.6% accuracy on text classification** — 7.7 points above SOTA, using 4× fewer tokens
- **Cross-model transfer:** A harness optimized on one model improved performance on 5 held-out models (+4.7 points average). The reusable asset is not the model — it is the harness.
- **Smaller model, better results:** Haiku 4.5 with an optimized harness ranked #1 among all Haiku agents, outperforming hand-engineered systems on larger models.

The scale of feedback matters: the proposer reads ~82 files per iteration (execution traces, prior harness source code, evaluation scores) and references 20+ prior candidates per step. It forms causal hypotheses, not greedy local improvements. Removing raw traces drops accuracy from 50% to 34.9% — LLM-generated summaries cannot recover the lost diagnostic signal.

---

## Principle 9: Raw Execution Traces Are Irreplaceable Feedback

This principle follows directly from the meta-harness experiments but deserves its own statement because it is easy to dismiss.

When the proposer read only scores (no traces): 34.6% accuracy.
When the proposer read scores + LLM-generated summaries: 34.9% accuracy.
When the proposer read raw traces: **50.0% accuracy**.

Summaries compress away the exact details needed for causal diagnosis — the specific input, the model output, the error, the step in which it occurred. These details are how you know whether a code change fixed the real problem or just masked a symptom.

**Build for raw trace access.** Store full execution logs. Make them path-addressable so they can be selectively read. Do not compress them into aggregate summaries as your primary diagnostic signal.

---

## Principle 10: Harness Assumptions Expire

Every component of your harness encodes an assumption about what the model cannot do alone. As models improve, those assumptions become stale. The harness does not shrink — it moves.

Concrete examples:
- When Opus 4.6 stopped needing context resets, Anthropic dropped them entirely.
- Manus rewrote their harness five times in 6 months.
- Vercel removed 80% of an agent's tools and got better results.

This means mature harness engineering looks less like building structure up and more like **pruning it down**. It is a craft of subtraction as much as addition.

Practical discipline: periodically audit each harness component against the question "does the model still need this scaffolding, or has it internalized this capability?" Remove anything that no longer earns its overhead.

---

## Principle 11: Build Safety In Through Explicit Constraints

Safety cannot be added as an afterthought or delegated to the model's judgment alone. The research points to two complementary approaches:

**Symbolic guardrails** (AgentSpec and related work) express safety constraints as formal, verifiable policies using temporal logic and declarative specifications. The key finding: up to 74% of safety and security policy requirements can be enforced symbolically — before execution, not after. Simple mechanisms like API validation alone cover 65–81% of enforceable requirements depending on the benchmark.

**Auto-Harness** (DeepMind) compiles domain rules directly into code harnesses, eliminating ~10% of illegal moves across 145 games. One variant removes the LLM from the decision path entirely, replacing it with a deterministic code policy — showing that some decisions should not be made by the model at all.

**The principle:** Identify which constraints in your domain are deterministic and enforceable. Express them as code or formal specifications, not as instructions to the model. Reserve the model for decisions that genuinely require generalization.

---

## Principle 12: The Harness Is Portable — Treat It as an Asset

A harness optimized on one model transfers to others. It is not model-specific. This changes the economics of harness investment.

The meta-harness finding: a single harness discovered on one base model improved performance across 5 different held-out models. The discovered strategies encode task-level reasoning structure — how to organize retrieval, manage state, sequence verification — orthogonal to which model executes them.

The practical implication: invest heavily in harness engineering. A good harness is reusable across model versions, cheaper models, and organizational model fleets. When the next model release arrives, you do not start over — you run your existing harness on the new model and measure delta. The harness is the reusable intellectual property. The model is the compute substrate.

---

## Known Failure Modes

**Oneshotting:** The agent tries everything in a single pass and exhausts its context window before completing. Fix: multi-stage execution with explicit contracts and bounded scopes per stage.

**Premature completion:** A later session sees partial progress and declares the task done. Fix: artifact-backed completion certificates and explicit acceptance conditions that cannot be satisfied by partial state.

**Verifier misalignment:** A local verifier passes outputs that the external evaluator rejects, inflating apparent task completion. Fix: calibrate verifiers against the actual success criterion, not a proxy.

**Accumulation without pruning:** Adding modules that feel useful without measuring their effect against the success criterion. Fix: ablate each module; remove anything that does not move the metric you care about.

**Trace compression:** Compressing execution logs into summaries for diagnostic purposes. Fix: preserve raw traces; index them for selective access rather than compressing them.

---

## Open Problems

**Prompt injection in harness text.** Portable harness logic is a new attack surface. Research found 1 in 4 community-contributed agent skills contains a vulnerability. Shared harness artifacts require the same security review as shared code.

**Harness-model co-evolution.** Can harness strategy shape what the model learns, and the model reshape the strategy that wraps it? This feedback loop — letting training be informed by harness-level failure patterns — is the next frontier.

**Migration fidelity.** When converting a code harness to a natural-language representation, how do you measure whether the control logic was faithfully preserved? No standard metric exists yet.

**Concurrency and scaling.** The research evaluates single-threaded harness execution. Concurrent workloads, resource contention, and failure cascades in multi-agent settings remain largely unstudied.

---

## Summary

| Principle | One-line statement |
|-----------|-------------------|
| 1. Separate concerns | Fix runtime; vary harness logic; never mix the two |
| 2. Use contracts | Five-element execution contracts bound every agent call |
| 3. Externalize state | Files survive truncation; context does not |
| 4. Orchestrate, don't reason | The harness decomposes and delegates; 90% of compute lives in children |
| 5. Structure is not always better | Only add modules that tighten the path to your success criterion |
| 6. Self-evolution works | Narrow the attempt loop; discipline beats breadth |
| 7. Representation matters | Same logic in natural language outperforms code by 16.8 points |
| 8. Optimize the harness | Treat harness structure as a search target, not a design artifact |
| 9. Preserve raw traces | Summaries destroy diagnostic signal; logs are irreplaceable |
| 10. Prune regularly | Harness assumptions expire as models improve |
| 11. Encode safety formally | Deterministic constraints belong in code, not model instructions |
| 12. Harnesses are portable | An optimized harness transfers across models; it is reusable IP |
