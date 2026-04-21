# 01 — What Is Chaos Engineering?

> **Type:** Explanation  
> **Phase:** Foundations

## Overview

Chaos Engineering is the discipline of experimenting on a distributed system in order to build confidence in the system's capability to withstand turbulent conditions in production.

It is **not** about breaking things randomly. It is about **controlled, hypothesis-driven experiments** that reveal systemic weaknesses before they manifest as outages.

## History

| Year | Event |
|------|-------|
| 2010 | Netflix migrates to AWS; creates the **Chaos Monkey** to randomly terminate EC2 instances |
| 2011 | The **Simian Army** expands: Latency Monkey, Conformity Monkey, Security Monkey |
| 2014 | Bruce Wong & Dan Woods publish the first definition of Chaos Engineering |
| 2016 | Netflix publishes the **Principles of Chaos Engineering** at principlesofchaos.org |
| 2017 | LitmusChaos, Gremlin, and Chaos Toolkit emerge |
| 2020+ | Cloud-native chaos: Chaos Mesh, AWS FIS, Azure Chaos Studio |

## The Simian Army

Netflix's original chaos tooling — a family of services that introduced failures:

- **Chaos Monkey** — randomly terminates virtual machine instances
- **Chaos Gorilla** — simulates an entire AWS Availability Zone outage
- **Latency Monkey** — induces artificial delays in the REST layer
- **Conformity Monkey** — shuts down instances that don't follow best practices
- **Security Monkey** — finds and terminates insecure configurations

## Core Principles

From [principlesofchaos.org](https://principlesofchaos.org/):

1. **Build a Hypothesis around Steady-State Behavior**
2. **Vary Real-world Events** (server crashes, hard drive malfunctions, severed network connections)
3. **Run Experiments in Production** (or a production-like environment)
4. **Automate Experiments to Run Continuously**
5. **Minimize Blast Radius** — start small, expand based on confidence

## Chaos Engineering vs. Other Practices

| Practice | Goal | Scope |
|----------|------|-------|
| Unit Testing | Prove code correctness | Function / class |
| Integration Testing | Prove services interact correctly | Service boundary |
| Load Testing | Find performance limits | Throughput / latency |
| Penetration Testing | Find security vulnerabilities | Attack surface |
| **Chaos Engineering** | Expose unknown system weaknesses | Entire sociotechnical system |

## The Chaos Engineering Loop

```
Define Steady State
        ↓
Hypothesize (What should remain true during chaos?)
        ↓
Inject Failure (controlled, scoped)
        ↓
Observe & Measure
        ↓
Analyze (did the hypothesis hold?)
        ↓
Fix weaknesses → repeat
```

## Further Reading

- [Principles of Chaos Engineering](https://principlesofchaos.org/)
- [Chaos Engineering — O'Reilly Book](https://www.oreilly.com/library/view/chaos-engineering/9781492043850/)
- [Netflix Tech Blog — Chaos Engineering](https://netflixtechblog.com/tagged/chaos-engineering)

---
*Part of the 100-Lesson Chaos Engineering Series.*
