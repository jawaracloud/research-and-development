# 02 — Chaos Engineering vs. Testing vs. Fault Injection

> **Type:** Explanation  
> **Phase:** Foundations

## Overview

Chaos engineering is frequently confused with other quality-assurance disciplines. This lesson draws clear boundaries between chaos engineering, traditional testing, and fault injection, so you choose the right tool for the right problem.

## Comparison Table

| Dimension | Traditional Testing | Fault Injection | Chaos Engineering |
|-----------|--------------------|-----------------|--------------------|
| **When** | Before deploy | During QA | In production (or staging) |
| **Goal** | Verify correctness | Trigger specific code paths | Discover unknown weaknesses |
| **Driven by** | Requirements | Known failure modes | Hypothesis |
| **Scope** | Unit → E2E | Module / subsystem | Entire sociotechnical system |
| **Repeatability** | Deterministic | Deterministic | Often probabilistic |
| **Output** | Pass/Fail | Pass/Fail | Insight + confidence score |

## Traditional Testing

Validates that the system behaves **as specified**. Tests are written **before** or alongside code and pass/fail deterministically.

```
Requirement → Code → Test → Green/Red
```

**Limitation**: Tests only cover *known* failure scenarios. Distributed systems fail in ways that are impossible to anticipate at the unit level.

## Fault Injection

Deliberately inserts faults (null pointers, bad return codes, disk errors) into software to ensure error-handling paths work correctly.

- **Hardware FI**: Bit flips, power cuts
- **Software FI**: Returning errors from mocked dependencies
- **Protocol FI**: Malformed packets

**Limitation**: You must know *which* fault to inject. You test what you already think can fail.

## Chaos Engineering

Goes further: it tests **emergent behaviour** of the whole system under realistic turbulent conditions.

> _"Chaos engineering is not about introducing chaos — it's about eliminating it through controlled, scientific exploration."_

Key differentiators:
1. **Hypothesis first** — you predict what *should* remain stable
2. **Blast radius control** — you limit the scope and can abort
3. **Continuous** — experiments run in CI or on a schedule

## Decision Framework

```
Is there a known code path to test?
  ├─ YES → Fault Injection / Unit Test
  └─ NO  → Can you predict what should stay stable?
               ├─ YES → Chaos Engineering
               └─ NO  → Load / Performance Testing first
```

## Further Reading

- [Casey Rosenthal — Chaos Engineering book chapter 2](https://www.oreilly.com/library/view/chaos-engineering/9781492043850/)
- [AWS — Fault Injection vs. Chaos Engineering](https://aws.amazon.com/blogs/architecture/)

---
*Part of the 100-Lesson Chaos Engineering Series.*
