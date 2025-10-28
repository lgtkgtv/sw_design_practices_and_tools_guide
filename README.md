## 🚀 Which Software Development Practices Should You Use—and When?

Modern software development relies on **battle-tested practices** that solve recurring problems.  
They're not theoretical—they're **pragmatic tools** that: Save time, Reduce bugs, Enable fast, stable delivery

---

## 🔐 Priority Order (Security/DevOps Context)
```
| Practice                   | What It Is                                               | Core Benefit                                               |
|----------------------------|----------------------------------------------------------|------------------------------------------------------------|
| **Security-by-Design**     | Build security into architecture from the start          | Prevents vulnerabilities rather than fixing them later     |
| **TDD**                    | Write tests before code; Red→Green→Refactor cycle        | Ensures testable, correct code with high coverage          |
| **Clean Code**             | Readable, maintainable code following conventions        | Easy to understand and modify                              |
| **Modular Architecture**   | Decompose system into independent, cohesive modules      | Reusability, maintainability, scalability                  |
| **API-First Development**  | Design API contract before implementation                | Clear interfaces, parallel development, better integration |
| **SOLID Principles**       | 5 OOP design prncpls (Single Responsibility, Open/Closed | Flexible, maintainable object-oriented design              |
|                            | ..Liskov Substitutn, Intrfc Segregation, DependncyInvrsn)|                                                            |
| **Design Patterns**        | Proven solutions to common prob (Gang of Four, etc)      | Avoid reinventing wheels, shared vocabulary                |
| **AWS Well-Architected**   | AWS's 6 pillars: Security, Reliability, Performance,     | Cloud system design best practices                         |
|                            | ..  Cost, Operational Excellence, Sustainability)        |                                                            |
```
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
```mr

| Context                | Practices to Use                            |
| ---------------------- | ------------------------------------------- |
| **Always use**         | Clean Code, Modular Architecture            |
| **Cloud Projects**     | Well-Architected Framework, IaC tools       |
| **Service-Based**      | API-First                                   |
| **OOP Codebase**       | SOLID, Design Patterns                      |

---

## 📚 What's in This Repo?

Each document in this repo provides **in-depth training and guidance** on:
* All listed **software development practices**
* Common **tools** and their real-world usage
* **Contextual examples** to apply each practice correctly

---
> These practices aren't "nice-to-haves" — they're your **survival kit** in modern software development.  
> Adopt early. Use consistently. Improve continuously.  

---
# Cheatsheet
---

### Test-Driven Development (TDD)

| Practice                   | What It Is                                               | Core Benefit                                               |
|----------------------------|----------------------------------------------------------|------------------------------------------------------------|
| **TDD**                    | Write tests before code; Red→Green→Refactor cycle        | Ensures testable, correct code with high coverage          |

**Example Workflow:**
```
1. Write failing test: test_calculate_discount()
   assert calculate_discount(100, 0.1) == 90
2. Run test → RED (fails, function doesn't exist)
3. Write minimal code to pass:
   def calculate_discount(price, rate):
       return price * (1 - rate)
4. Run test → GREEN (passes)
5. Refactor for edge cases, maintain green
```
**Tools to Enforce/Assist:**
- **Testing Frameworks:** pytest (Python), JUnit (Java), Jest (JavaScript), gtest (C++)
- **Coverage Tools:** pytest-cov, JaCoCo, Istanbul, lcov
- **CI/CD Integration:** GitHub Actions, Jenkins (fail build if tests fail)
- **Test Generators:** Claude CLI, GitHub Copilot, Hypothesis (property-based testing)  
  
|                         |                                                                      |
|:------------------------|:---------------------------------------------------------------------|
| **When to Use TDD**     | Building user authentication, payment processing, API endpoints      |
| **When NOT to use TDD** | Building UI or quick prototypes; <br> NOTE: TDD not useful in situations requiring lot's of design iterations, and if the API's change too frequently!  | 



### 2. Clean Code

**Example - Before vs After:**
```python
# Before (unclear)
def f(x, y):
    return x * y * 0.9 if x > 100 else x * y

# After (clean)
def calculate_total_with_volume_discount(quantity, unit_price):
    VOLUME_DISCOUNT_THRESHOLD = 100
    VOLUME_DISCOUNT_RATE = 0.9
    
    subtotal = quantity * unit_price
    if quantity > VOLUME_DISCOUNT_THRESHOLD:
        return subtotal * VOLUME_DISCOUNT_RATE
    return subtotal
```

**Tools to Enforce/Assist:**
- **Linters:** pylint, flake8, ESLint, checkstyle, clang-tidy
- **Formatters:** Black (Python), Prettier (JS), clang-format (C/C++)
- **Code Review:** SonarQube, CodeClimate, Codacy
- **AI Assistants:** Claude CLI (code review), GitHub Copilot
- **IDE Plugins:** IntelliJ inspections, VS Code extensions

**When Applied:** Code reviews, refactoring legacy code, pair programming

---
