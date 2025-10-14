Modern software development relies on battle-tested practices that solve recurring problems. 
These practices ensure code is **secure**, **maintainable**, **testable**, and **scalable**.  
They're not theoretical—they're pragmatic tools that save time, reduce bugs, and enable teams to move fast without breaking things.

---

## Priority Order (Security/DevOps Context)

1. **Security-by-Design** ← Most important - prevents vulnerabilities
2. **TDD** ← Shows reliability - catches bugs early
3. **Clean Code** ← Always relevant - enables maintenance
4. **Modular Architecture** ← Scalability - systems grow gracefully
5. **API-First** ← If building services - clear contracts
6. **SOLID Principles** ← For OOP projects - flexible design
7. **Design Patterns** ← Proven solutions - avoid reinventing wheels
8. **Well-Architected** ← For AWS/cloud roles - infrastructure best practices

---

## Quick Decision Tree -- What software development practices to use in what situatiuons?

```
Are you building a service/API?
│
├─ YES → API-First + TDD + Security-by-Design
│
│         Example Tools: OpenAPI, pytest, Semgrep
│
└─ NO → Is it security-sensitive?
    │ 
    ├─ YES → Security-by-Design + TDD + Clean Code
    │
    │         Tools: Threat modeling, pytest, SAST tools
    │
    └─ NO → TDD + Clean Code + SOLID
```

**Always use**:    Clean Code, Modular Architecture  
**Cloud?**:        Add Well-Architected Framework + IaC tools  
**Services?**:     Add API-First    
**OOP?**:          Add SOLID + Design Patterns  

The documents in this repo will provide indepth guidance/training on these practices.
             
              Tools: pytest, linters, Coverity etc SAST
    
```
