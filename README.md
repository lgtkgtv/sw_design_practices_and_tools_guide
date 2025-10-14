````markdown
# 🚀 What Software Development Practices to Use (and When)

Modern software development relies on **battle-tested practices** that solve recurring problems.  
They're not theoretical—they're **pragmatic tools** that: Save time, Reduce bugs, Enable fast, stable delivery
---

## 🔐 Priority Order (Security/DevOps Context)

| Priority | Practice                 | Why It Matters                                |
|:--------:|--------------------------|-----------------------------------------------|
|    1     | **Security-by-Design**   | Prevents vulnerabilities before they happen   |
|    2     | **TDD**                  | Catches bugs early — proves reliability       |
|    3     | **Clean Code**           | Enables long-term maintainability             |
|    4     | **Modular Architecture** | Systems scale and evolve gracefully           |
|    5     | **API-First**            | Clear contracts when building services        |
|    6     | **SOLID Principles**     | Flexible OOP design — easier to extend/test   |
|    7     | **Design Patterns**      | Proven solutions — avoid reinventing the wheel|
|    8     | **Well-Architected**     | Best practices for cloud (esp. AWS) systems   |

---

## 🌲 Quick Decision Tree — What to Use When

```text
Are you building a service/API?
│
├─ YES → API-First + TDD + Security-by-Design
│         Tools: OpenAPI, pytest, Semgrep
│
└─ NO → Is it security-sensitive?
    │
    ├─ YES → Security-by-Design + TDD + Clean Code
    │         Tools: Threat Modeling, pytest, SAST
    │
    └─ NO → TDD + Clean Code + SOLID
````

| Context            | Practices to Use                            |
| ------------------ | ------------------------------------------- |
| **Always**         | Clean Code, Modular Architecture            |
| **Cloud Projects** | Well-Architected Framework, IaC tools       |
| **Service-Based**  | API-First                                   |
| **OOP Codebase**   | SOLID, Design Patterns                      |

---

## 📚 What's in This Repo?

Each document in this repo provides **in-depth training and guidance** on:
* All listed **software development practices**
* Common **tools** and their real-world usage
* **Contextual examples** to apply each practice correctly

---
> These practices aren't "nice-to-haves" — they're your **survival kit** in modern software development.
> Adopt early. Use consistently. Improve continuously.

```
