# Software Engineering Practices - Concise Guide

## WHAT & WHY

Modern software development relies on battle-tested practices that solve recurring problems. These practices ensure code is **secure**, **maintainable**, **testable**, and **scalable**.  

 They're not theoretical—they're pragmatic tools that save time, reduce bugs, and enable teams to move fast without breaking things.

**The Big Picture:**   
`Security-first design` prevents vulnerabilities.  
`TDD` ensures correctness.  
`Clean code` enables collaboration.  
`Modular architecture` scales systems.  
`API-first design` enables parallel development.  
`SOLID/Patterns` solve structural problems.    
`Tools` enforce it all automatically.

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

## Quick Decision Tree

**Always**: Clean Code, Modular Architecture  
**Cloud?**: Add Well-Architected Framework + IaC tools  
**Services?**: Add API-First    
**OOP?**: Add SOLID + Design Patterns  


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
             
              Tools: pytest, linters, Coverity etc SAST
    
```

---

## HOW: Practice Implementation

### 1. Security-by-Design

**Concept:** Build security into architecture from day one, not bolt it on later.

**Workflow:**
```
Design → Threat Model (STRIDE) → Implement Controls → Verify → Monitor
```

**Example - User Authentication System:**
```
Assets: User credentials, session tokens, PII
Threats (STRIDE):
  S (Spoofing): Multi-factor authentication, JWT with short expiry
  T (Tampering): Input validation, parameterized queries, HMAC
  R (Repudiation): Audit logs, non-repudiation signatures
  I (Info Disclosure): Encryption (TLS, AES-256), no secrets in code
  D (DoS): Rate limiting, CAPTCHA, resource quotas
  E (Elevation): RBAC, least privilege, principle of least authority

Implementation:
✓ Secrets in vault (AWS Secrets Manager, HashiCorp Vault)
✓ Input validation at API boundary (Pydantic, JSON Schema)
✓ SQL parameterization (SQLAlchemy, psycopg2)
✓ Rate limiting (Redis, AWS WAF)
✓ Security headers (HSTS, CSP, X-Frame-Options)
```

**Tools:**
- **Threat Modeling:** Microsoft Threat Modeling Tool, OWASP Threat Dragon, Claude CLI
- **SAST:** Semgrep, Bandit (Python), SpotBugs (Java), clang-tidy (C++)
- **DAST:** OWASP ZAP, Burp Suite
- **Secrets:** TruffleHog, GitGuardian, git-secrets
- **Dependencies:** Snyk, Dependabot, OWASP Dependency-Check
- **AI Assist:** Claude CLI for threat modeling, security code review

---

### 2. Test-Driven Development (TDD)

**Concept:** Write tests before code. Red → Green → Refactor.

**Workflow:**
```
1. Write failing test (Red)
2. Write minimal code to pass (Green)
3. Refactor while keeping tests green
4. Repeat
```

**Example 1 - User Registration:**
```python
# Step 1: Write test first (RED)
def test_register_user_creates_account():
    user = register_user("john@example.com", "SecurePass123!")
    assert user.id is not None
    assert user.email == "john@example.com"
    assert user.password != "SecurePass123!"  # should be hashed

# Step 2: Minimal implementation (GREEN)
def register_user(email, password):
    hashed_password = bcrypt.hashpw(password.encode(), bcrypt.gensalt())
    user = User(email=email, password=hashed_password)
    db.save(user)
    return user

# Step 3: Refactor (stay GREEN)
# Add validation, error handling, etc.
```

**Example 2 - API Endpoint:**
```python
# Test first
def test_create_user_returns_201():
    response = client.post("/users", json={"name": "John", "email": "john@test.com"})
    assert response.status_code == 201
    assert response.json["id"] is not None

def test_create_user_validates_email():
    response = client.post("/users", json={"name": "John", "email": "invalid"})
    assert response.status_code == 400
    assert "email" in response.json["errors"]

# Then implement endpoint
@app.post("/users")
def create_user(user: UserCreate):
    # Implementation follows tests
```

**Tools:**
- **Python:** pytest, pytest-cov, Hypothesis (property testing)
- **Java:** JUnit, TestNG, JaCoCo (coverage)
- **JavaScript:** Jest, Mocha, Istanbul
- **C/C++:** Google Test, Catch2, gcov
- **CI/CD:** GitHub Actions, Jenkins (fail on coverage drop)
- **AI Assist:** Claude CLI, GitHub Copilot (generate tests)

---

### 3. Clean Code

**Concept:** Code should read like well-written prose. Self-documenting.

**Core Principles:**
- Meaningful names
- Functions do one thing
- No magic numbers
- DRY (Don't Repeat Yourself)
- Comments explain WHY, not WHAT

**Example 1 - Function Naming:**
```python
# Bad
def proc(x, y, z):
    return x * y * z * 0.9 if x > 100 else x * y * z

# Good
def calculate_order_total(quantity, unit_price, tax_rate):
    BULK_DISCOUNT_THRESHOLD = 100
    BULK_DISCOUNT_RATE = 0.1
    
    subtotal = quantity * unit_price * (1 + tax_rate)
    if quantity > BULK_DISCOUNT_THRESHOLD:
        return subtotal * (1 - BULK_DISCOUNT_RATE)
    return subtotal
```

**Example 2 - Single Responsibility:**
```python
# Bad - function does too much
def process_order(order):
    # Validate
    if not order.items:
        raise ValueError("Empty order")
    # Calculate
    total = sum(item.price for item in order.items)
    # Save
    db.save(order)
    # Email
    send_email(order.user.email, f"Order confirmed: ${total}")
    # Log
    logger.info(f"Order {order.id} processed")

# Good - separated concerns
def validate_order(order):
    if not order.items:
        raise ValueError("Empty order")

def calculate_total(order):
    return sum(item.price for item in order.items)

def save_order(order):
    db.save(order)

def send_confirmation_email(user, order_total):
    send_email(user.email, f"Order confirmed: ${order_total}")

def process_order(order):
    validate_order(order)
    total = calculate_total(order)
    save_order(order)
    send_confirmation_email(order.user, total)
    logger.info(f"Order {order.id} processed")
```

**Tools:**
- **Linters:** pylint, flake8, ESLint, checkstyle, clang-tidy
- **Formatters:** Black, Prettier, clang-format, gofmt
- **Code Review:** SonarQube, CodeClimate, Codacy
- **Metrics:** Radon (complexity), CodeScene (hotspots)
- **AI Assist:** Claude CLI (refactoring suggestions)

---

### 4. Modular Architecture

**Concept:** Decompose system into independent, cohesive modules with clear boundaries.

**Example - E-commerce System:**
```
# Bad - Everything in one file
app.py (10,000 lines)

# Good - Modular structure
ecommerce/
├── auth/
│   ├── __init__.py
│   ├── authentication.py    # Login, JWT
│   ├── authorization.py     # RBAC
│   └── models.py
├── catalog/
│   ├── products.py
│   ├── search.py
│   └── inventory.py
├── orders/
│   ├── cart.py
│   ├── checkout.py
│   ├── payment.py
│   └── fulfillment.py
├── users/
│   ├── profiles.py
│   ├── preferences.py
│   └── notifications.py
└── api/
    ├── routes.py            # Thin layer, delegates to modules
    └── schemas.py
```

**Benefits:**
- Each module can be developed/tested/deployed independently
- Clear ownership (team A owns auth, team B owns orders)
- Easier to reason about (bounded context)
- Reusable across projects

**Tools:**
- **Analysis:** dependency-cruiser, Madge, JDepend
- **Enforcement:** ArchUnit (fail build on violations)
- **Visualization:** PlantUML, Mermaid, draw.io
- **Build:** Poetry, Maven, Gradle, CMake

---

### 5. API-First Development

**Concept:** Design and document API contract before implementation. Frontend/backend develop in parallel.

**Workflow:**
```
1. Design API (OpenAPI 3.0 spec)
2. Review with stakeholders
3. Generate mock server
4. Frontend uses mock API
5. Backend implements to contract
6. Contract tests verify compliance
```

**Example - User Management API:**
```yaml
# Step 1: Design OpenAPI spec
openapi: 3.0.0
paths:
  /users:
    post:
      summary: Create user
      requestBody:
        content:
          application/json:
            schema:
              type: object
              required: [name, email]
              properties:
                name: {type: string, minLength: 1}
                email: {type: string, format: email}
      responses:
        '201':
          description: User created
          content:
            application/json:
              schema:
                type: object
                properties:
                  id: {type: integer}
                  name: {type: string}
                  email: {type: string}
        '400':
          description: Validation error
```

```python
# Step 2: Generate mock server (prism)
# $ prism mock openapi.yaml

# Step 3: Frontend develops against mock
# fetch('/users', {method: 'POST', body: {...}})

# Step 4: Backend implements to spec
@app.post("/users", response_model=UserResponse, status_code=201)
def create_user(user: UserCreate):
    # Implementation must match spec
    validate_email(user.email)
    db_user = User(name=user.name, email=user.email)
    db.save(db_user)
    return UserResponse(id=db_user.id, name=db_user.name, email=db_user.email)

# Step 5: Contract tests verify
def test_create_user_matches_contract():
    response = client.post("/users", json={"name": "John", "email": "john@test.com"})
    assert response.status_code == 201
    validate_openapi_schema(response.json, "UserResponse")
```

**Tools:**
- **Design:** Swagger Editor, Stoplight Studio, Postman
- **Mock Servers:** Prism, Mockoon, WireMock
- **Contract Testing:** Pact, Spring Cloud Contract, Schemathesis
- **Validation:** OpenAPI Validator, Spectral (linting)
- **Auto-docs:** FastAPI, Swagger UI, Redoc
- **Codegen:** OpenAPI Generator, swagger-codegen

---

## SOLID Principles - Multiple Examples

### S - Single Responsibility Principle
*A class should have one, and only one, reason to change.*

**Example 1 - User Class:**
```python
# Violation
class User:
    def __init__(self, username, email):
        self.username = username
        self.email = email
    
    def save_to_database(self):           # Reason to change: DB schema
        db.execute(f"INSERT INTO users...")
    
    def send_welcome_email(self):         # Reason to change: Email template
        smtp.send(self.email, "Welcome!")
    
    def validate_email(self):             # Reason to change: Validation rules
        return "@" in self.email

# Fixed
class User:
    def __init__(self, username, email):
        self.username = username
        self.email = email

class UserRepository:
    def save(self, user):
        db.execute(f"INSERT INTO users...")

class EmailService:
    def send_welcome_email(self, user):
        smtp.send(user.email, "Welcome!")

class EmailValidator:
    def is_valid(self, email):
        return "@" in email and "." in email
```

**Example 2 - Invoice Processing:**
```python
# Violation
class Invoice:
    def calculate_total(self):      # Business logic
        return sum(item.price for item in self.items)
    
    def print_invoice(self):        # Presentation
        print(f"Invoice: {self.calculate_total()}")
    
    def save_to_file(self):         # Persistence
        with open("invoice.txt", "w") as f:
            f.write(str(self.calculate_total()))

# Fixed
class Invoice:
    def calculate_total(self):
        return sum(item.price for item in self.items)

class InvoicePrinter:
    def print(self, invoice):
        print(f"Invoice: {invoice.calculate_total()}")

class InvoicePersistence:
    def save(self, invoice):
        with open("invoice.txt", "w") as f:
            f.write(str(invoice.calculate_total()))
```

---

### O - Open/Closed Principle
*Open for extension, closed for modification.*

**Example 1 - Discount Calculator:**
```python
# Violation - Need to modify class for new discount types
class OrderPricing:
    def calculate_total(self, order, discount_type):
        total = order.subtotal
        if discount_type == "percentage":
            return total * 0.9
        elif discount_type == "fixed":
            return total - 10
        elif discount_type == "bogo":  # New requirement = modify class
            return total * 0.5
        return total

# Fixed - Open for extension via new classes
class DiscountStrategy:
    def apply(self, total):
        raise NotImplementedError

class PercentageDiscount(DiscountStrategy):
    def __init__(self, percent):
        self.percent = percent
    def apply(self, total):
        return total * (1 - self.percent)

class FixedDiscount(DiscountStrategy):
    def __init__(self, amount):
        self.amount = amount
    def apply(self, total):
        return total - self.amount

class BOGODiscount(DiscountStrategy):  # New type = new class, no modification
    def apply(self, total):
        return total * 0.5

class OrderPricing:
    def calculate_total(self, order, discount: DiscountStrategy):
        total = order.subtotal
        return discount.apply(total)
```

**Example 2 - Report Generator:**
```python
# Violation
class ReportGenerator:
    def generate(self, data, format):
        if format == "pdf":
            return self._generate_pdf(data)
        elif format == "excel":
            return self._generate_excel(data)
        elif format == "json":  # New format = modify class
            return self._generate_json(data)

# Fixed
class ReportFormatter:
    def format(self, data):
        raise NotImplementedError

class PDFFormatter(ReportFormatter):
    def format(self, data):
        return generate_pdf(data)

class ExcelFormatter(ReportFormatter):
    def format(self, data):
        return generate_excel(data)

class JSONFormatter(ReportFormatter):  # New format = new class
    def format(self, data):
        return json.dumps(data)

class ReportGenerator:
    def __init__(self, formatter: ReportFormatter):
        self.formatter = formatter
    
    def generate(self, data):
        return self.formatter.format(data)
```

---

### L - Liskov Substitution Principle
*Subtypes must be substitutable for their base types.*

**Example:**
```python
# Violation
class Rectangle:
    def __init__(self, width, height):
        self.width = width
        self.height = height
    
    def set_width(self, width):
        self.width = width
    
    def set_height(self, height):
        self.height = height
    
    def area(self):
        return self.width * self.height

class Square(Rectangle):  # Violation: Square changes inherited behavior
    def set_width(self, width):
        self.width = width
        self.height = width  # Side effect!
    
    def set_height(self, height):
        self.width = height
        self.height = height

# This breaks!
def test_rectangle(rect: Rectangle):
    rect.set_width(5)
    rect.set_height(4)
    assert rect.area() == 20  # Fails for Square!

# Fixed
class Shape:
    def area(self):
        raise NotImplementedError

class Rectangle(Shape):
    def __init__(self, width, height):
        self.width = width
        self.height = height
    
    def area(self):
        return self.width * self.height

class Square(Shape):
    def __init__(self, side):
        self.side = side
    
    def area(self):
        return self.side * self.side
```

---

### I - Interface Segregation Principle
*Don't force clients to depend on interfaces they don't use.*

**Example:**
```python
# Violation - Fat interface
class Worker:
    def work(self):
        pass
    def eat(self):
        pass
    def sleep(self):
        pass

class HumanWorker(Worker):
    def work(self):
        print("Working...")
    def eat(self):
        print("Eating...")
    def sleep(self):
        print("Sleeping...")

class RobotWorker(Worker):  # Robot doesn't eat or sleep!
    def work(self):
        print("Working...")
    def eat(self):
        raise NotImplementedError("Robots don't eat")
    def sleep(self):
        raise NotImplementedError("Robots don't sleep")

# Fixed - Segregated interfaces
class Workable:
    def work(self):
        pass

class Eatable:
    def eat(self):
        pass

class Sleepable:
    def sleep(self):
        pass

class HumanWorker(Workable, Eatable, Sleepable):
    def work(self):
        print("Working...")
    def eat(self):
        print("Eating...")
    def sleep(self):
        print("Sleeping...")

class RobotWorker(Workable):  # Only implements what it needs
    def work(self):
        print("Working...")
```

---

### D - Dependency Inversion Principle
*Depend on abstractions, not concretions.*

**Example 1 - Database Layer:**
```python
# Violation - High-level depends on low-level
class MySQLDatabase:
    def save(self, data):
        # MySQL-specific code
        pass

class UserService:
    def __init__(self):
        self.db = MySQLDatabase()  # Tight coupling!
    
    def create_user(self, user):
        self.db.save(user)

# Fixed - Both depend on abstraction
class Database(ABC):
    @abstractmethod
    def save(self, data):
        pass

class MySQLDatabase(Database):
    def save(self, data):
        # MySQL implementation
        pass

class PostgreSQLDatabase(Database):
    def save(self, data):
        # PostgreSQL implementation
        pass

class UserService:
    def __init__(self, db: Database):  # Depends on abstraction
        self.db = db
    
    def create_user(self, user):
        self.db.save(user)

# Usage
user_service = UserService(MySQLDatabase())  # Easy to swap
user_service = UserService(PostgreSQLDatabase())
```

**Example 2 - Email Service:**
```python
# Violation
class SMTPEmailSender:
    def send(self, to, subject, body):
        # SMTP implementation
        pass

class NotificationService:
    def __init__(self):
        self.email_sender = SMTPEmailSender()  # Tight coupling
    
    def notify(self, user, message):
        self.email_sender.send(user.email, "Notification", message)

# Fixed
class EmailSender(ABC):
    @abstractmethod
    def send(self, to, subject, body):
        pass

class SMTPEmailSender(EmailSender):
    def send(self, to, subject, body):
        # SMTP implementation
        pass

class SendGridEmailSender(EmailSender):
    def send(self, to, subject, body):
        # SendGrid implementation
        pass

class NotificationService:
    def __init__(self, email_sender: EmailSender):  # Depends on abstraction
        self.email_sender = email_sender
    
    def notify(self, user, message):
        self.email_sender.send(user.email, "Notification", message)
```

---

## Design Patterns - Multiple Examples

### 1. Strategy Pattern
*Define a family of algorithms, encapsulate each, make them interchangeable.*

**Example 1 - Payment Processing:**
```python
class PaymentStrategy:
    def pay(self, amount):
        raise NotImplementedError

class CreditCardPayment(PaymentStrategy):
    def __init__(self, card_number):
        self.card_number = card_number
    
    def pay(self, amount):
        print(f"Charging ${amount} to card {self.card_number}")
        # Stripe API call
        return True

class PayPalPayment(PaymentStrategy):
    def __init__(self, email):
        self.email = email
    
    def pay(self, amount):
        print(f"Processing ${amount} via PayPal for {self.email}")
        # PayPal API call
        return True

class CryptoPayment(PaymentStrategy):
    def __init__(self, wallet_address):
        self.wallet_address = wallet_address
    
    def pay(self, amount):
        print(f"Transferring ${amount} to {self.wallet_address}")
        # Blockchain transaction
        return True

class PaymentProcessor:
    def __init__(self, strategy: PaymentStrategy):
        self.strategy = strategy
    
    def process_payment(self, amount):
        return self.strategy.pay(amount)

# Usage
processor = PaymentProcessor(CreditCardPayment("1234-5678"))
processor.process_payment(100)

processor = PaymentProcessor(PayPalPayment("user@example.com"))
processor.process_payment(50)
```

**Example 2 - Compression Algorithms:**
```python
class CompressionStrategy:
    def compress(self, data):
        raise NotImplementedError

class ZipCompression(CompressionStrategy):
    def compress(self, data):
        return zlib.compress(data)

class GzipCompression(CompressionStrategy):
    def compress(self, data):
        return gzip.compress(data)

class Bz2Compression(CompressionStrategy):
    def compress(self, data):
        return bz2.compress(data)

class FileCompressor:
    def __init__(self, strategy: CompressionStrategy):
        self.strategy = strategy
    
    def compress_file(self, filepath):
        with open(filepath, 'rb') as f:
            data = f.read()
        return self.strategy.compress(data)
```

---

### 2. Factory Pattern
*Create objects without specifying exact class.*

**Example 1 - Document Creator:**
```python
class Document:
    def open(self):
        raise NotImplementedError

class PDFDocument(Document):
    def open(self):
        print("Opening PDF document")

class WordDocument(Document):
    def open(self):
        print("Opening Word document")

class ExcelDocument(Document):
    def open(self):
        print("Opening Excel document")

class DocumentFactory:
    @staticmethod
    def create_document(file_type):
        if file_type == "pdf":
            return PDFDocument()
        elif file_type == "docx":
            return WordDocument()
        elif file_type == "xlsx":
            return ExcelDocument()
        else:
            raise ValueError(f"Unknown document type: {file_type}")

# Usage
doc = DocumentFactory.create_document("pdf")
doc.open()
```

**Example 2 - Logger Factory:**
```python
class Logger:
    def log(self, message):
        raise NotImplementedError

class ConsoleLogger(Logger):
    def log(self, message):
        print(f"[CONSOLE] {message}")

class FileLogger(Logger):
    def __init__(self, filepath):
        self.filepath = filepath
    
    def log(self, message):
        with open(self.filepath, 'a') as f:
            f.write(f"{message}\n")

class CloudLogger(Logger):
    def log(self, message):
        # Send to CloudWatch, Datadog, etc.
        pass

class LoggerFactory:
    @staticmethod
    def create_logger(env):
        if env == "development":
            return ConsoleLogger()
        elif env == "production":
            return CloudLogger()
        elif env == "testing":
            return FileLogger("/tmp/test.log")
```

---

### 3. Observer Pattern
*One-to-many dependency: when one object changes state, all dependents are notified.*

**Example - Stock Price Notifications:**
```python
class Stock:
    def __init__(self, symbol, price):
        self.symbol = symbol
        self._price = price
        self._observers = []
    
    def attach(self, observer):
        self._observers.append(observer)
    
    def detach(self, observer):
        self._observers.remove(observer)
    
    def notify(self):
        for observer in self._observers:
            observer.update(self)
    
    @property
    def price(self):
        return self._price
    
    @price.setter
    def price(self, value):
        self._price = value
        self.notify()

class Observer:
    def update(self, stock):
        raise NotImplementedError

class EmailAlert(Observer):
    def __init__(self, email):
        self.email = email
    
    def update(self, stock):
        print(f"Email to {self.email}: {stock.symbol} is now ${stock.price}")

class SMSAlert(Observer):
    def __init__(self, phone):
        self.phone = phone
    
    def update(self, stock):
        print(f"SMS to {self.phone}: {stock.symbol} price: ${stock.price}")

class Dashboard(Observer):
    def update(self, stock):
        print(f"Dashboard updated: {stock.symbol} = ${stock.price}")

# Usage
aapl = Stock("AAPL", 150)
aapl.attach(EmailAlert("user@example.com"))
aapl.attach(SMSAlert("+1234567890"))
aapl.attach(Dashboard())

aapl.price = 155  # All observers notified
```

---

### 4. Decorator Pattern
*Add behavior to objects without modifying their class.*

**Example - Coffee Shop:**
```python
class Coffee:
    def cost(self):
        return 5.0
    
    def description(self):
        return "Coffee"

class CoffeeDecorator(Coffee):
    def __init__(self, coffee):
        self._coffee = coffee
    
    def cost(self):
        return self._coffee.cost()
    
    def description(self):
        return self._coffee.description()

class Milk(CoffeeDecorator):
    def cost(self):
        return self._coffee.cost() + 1.0
    
    def description(self):
        return self._coffee.description() + ", Milk"

class Sugar(CoffeeDecorator):
    def cost(self):
        return self._coffee.cost() + 0.5
    
    def description(self):
        return self._coffee.description() + ", Sugar"

class WhippedCream(CoffeeDecorator):
    def cost(self):
        return self._coffee.cost() + 1.5
    
    def description(self):
        return self._coffee.description() + ", Whipped Cream"

# Usage
coffee = Coffee()
print(f"{coffee.description()}: ${coffee.cost()}")

coffee_with_milk = Milk(coffee)
print(f"{coffee_with_milk.description()}: ${coffee_with_milk.cost()}")

fancy_coffee = WhippedCream(Sugar(Milk(Coffee())))
print(f"{fancy_coffee.description()}: ${fancy_coffee.cost()}")
# Output: Coffee, Milk, Sugar, Whipped Cream: $8.0
```

---

### 5. Repository Pattern
*Abstraction for data access.*

**Example:**
```python
class User:
    def __init__(self, id, username, email):
        self.id = id
        self.username = username
        self.email = email

class UserRepository(ABC):
    @abstractmethod
    def find_by_id(self, user_id):
        pass
    
    @abstractmethod
    def find_by_email(self, email):
        pass
    
    @abstractmethod
    def save(self, user):
        pass

class SQLUserRepository(UserRepository):
    def __init__(self, db_connection):
        self.db = db_connection
    
    def find_by_id(self, user_id):
        result = self.db.execute("SELECT * FROM users WHERE id = ?", (user_id,))
        return User(**result.fetchone()) if result else None
    
    def find_by_email(self, email):
        result = self.db.execute("SELECT * FROM users WHERE email = ?", (email,))
        return User(**result.fetchone()) if result else None
    
    def save(self, user):
        self.db.execute("INSERT INTO users VALUES (?, ?, ?)", 
                       (user.id, user.username, user.email))

class MongoUserRepository(UserRepository):
    def __init__(self, mongo_collection):
        self.collection = mongo_collection
    
    def find_by_id(self, user_id):
        doc = self.collection.find_one({"_id": user_id})
        return User(**doc) if doc else None
    
    def find_by_email(self, email):
        doc = self.collection.find_one({"email": email})
        return User(**doc) if doc else None
    
    def save(self, user):
        self.collection.insert_one({
            "_id": user.id,
            "username": user.username,
            "email": user.email
        })

# Usage - Easy to swap implementations
class UserService:
    def __init__(self, repo: UserRepository):
        self.repo = repo
    
    def register_user(self, username, email):
        existing = self.repo.find_by_email(email)
        if existing:
            raise ValueError("Email already registered")
        user = User(id=generate_id(), username=username, email=email)
        self.repo.save(user)
        return user

# Easy to swap database
service = UserService(SQLUserRepository(sql_connection))
service = UserService(MongoUserRepository(mongo_collection))
```

---

### 6. Singleton Pattern
*Ensure only one instance of a class exists.*

**Example 1 - Database Connection:**
```python
class Database:
    _instance = None
    
    def __new__(cls):
        if cls._instance is None:
            cls._instance = super().__new__(cls)
            cls._instance.connection = create_connection()
        return cls._instance
    
    def query(self, sql):
        return self.connection.execute(sql)

# Usage - always returns same instance
db1 = Database()
db2 = Database()
assert db1 is db2  # True
```

**Example 2 - Configuration Manager:**
```python
class Config:
    _instance = None
    
    def __new__(cls):
        if cls._instance is None:
            cls._instance = super().__new__(cls)
            cls._instance.settings = load_config_file()
        return cls._instance
    
    def get(self, key):
        return self.settings.get(key)

# All parts of app share same config
config = Config()
api_key = config.get("api_key")
```

---

### 7. Adapter Pattern
*Convert interface of a class into another interface clients expect.*

**Example - Third-Party Payment Gateway:**
```python
# Our system expects this interface
class PaymentGateway:
    def process_payment(self, amount, currency):
        raise NotImplementedError

# Third-party library has different interface
class StripeAPI:
    def charge(self, amount_in_cents, card_token):
        # Stripe implementation
        pass

class PayPalAPI:
    def make_payment(self, amount_dollars, account_email):
        # PayPal implementation
        pass

# Adapters convert to our interface
class StripeAdapter(PaymentGateway):
    def __init__(self):
        self.stripe = StripeAPI()
    
    def process_payment(self, amount, currency):
        amount_in_cents = int(amount * 100)
        card_token = get_card_token()
        return self.stripe.charge(amount_in_cents, card_token)

class PayPalAdapter(PaymentGateway):
    def __init__(self):
        self.paypal = PayPalAPI()
    
    def process_payment(self, amount, currency):
        account_email = get_paypal_account()
        return self.paypal.make_payment(amount, account_email)

# Our code works with any adapter
class CheckoutService:
    def __init__(self, gateway: PaymentGateway):
        self.gateway = gateway
    
    def checkout(self, cart):
        total = cart.calculate_total()
        return self.gateway.process_payment(total, "USD")

# Easy to swap payment providers
checkout = CheckoutService(StripeAdapter())
checkout = CheckoutService(PayPalAdapter())
```

---

## Tool Categories Summary

| Category | Tools | Use Case |
|----------|-------|----------|
| **Testing** | pytest, JUnit, Jest, gtest, Hypothesis | TDD, regression testing |
| **Linting** | pylint, flake8, ESLint, checkstyle, clang-tidy | Enforce clean code |
| **Formatting** | Black, Prettier, clang-format, gofmt | Consistent style |
| **Security SAST** | Semgrep, Bandit, SpotBugs, clang-tidy | Find vulnerabilities in code |
| **Security DAST** | OWASP ZAP, Burp Suite | Runtime security testing |
| **Secrets** | TruffleHog, GitGuardian, git-secrets | Prevent credential leaks |
| **Dependencies** | Snyk, Dependabot, OWASP Dependency-Check | Vulnerable libraries |
| **API Design** | Swagger Editor, Postman, Stoplight | API-first development |
| **Mocking** | Prism, Mockoon, WireMock | API mocks for parallel dev |
| **Contract Testing** | Pact, Schemathesis, Spring Cloud Contract | Verify API contracts |
| **Architecture** | ArchUnit, dependency-cruiser, PlantUML | Enforce architecture rules |
| **Code Quality** | SonarQube, CodeClimate, Codacy | Technical debt tracking |
| **CI/CD** | GitHub Actions, Jenkins, GitLab CI | Automate testing/deployment |
| **IaC** | Terraform, CloudFormation, Pulumi | Infrastructure as code |
| **AI Assistants** | Claude CLI, GitHub Copilot, OpenAI APIs | Code generation, review |

---

## Practical Scenarios

### Scenario 1: Building Secure Payment API

```
Practices Applied:
✓ Security-by-Design: STRIDE threat model, PCI-DSS compliance
✓ API-First: OpenAPI spec designed first
✓ TDD: Write tests for validation, fraud detection
✓ Design Patterns: Strategy (payment providers), Repository (data access)
✓ SOLID: Single responsibility, Dependency inversion
✓ Clean Code: Meaningful names, no magic numbers

Tools Used:
- OpenAPI: API design
- pytest: TDD
- Semgrep: Security scanning
- Stripe SDK: Payment processing
- FastAPI: Implementation
- GitHub Actions: CI/CD

Example Structure:
payment_api/
├── api/
│   ├── routes.py          # API-first contracts
│   └── schemas.py         # Pydantic validation
├── domain/
│   ├── payment.py         # Business logic
│   ├── fraud.py           # Fraud detection
│   └── strategies/        # Strategy pattern
│       ├── stripe.py
│       ├── paypal.py
│       └── crypto.py
├── infrastructure/
│   └── repositories/      # Repository pattern
│       ├── payment_repo.py
│       └── audit_repo.py
└── tests/
    ├── test_api.py        # TDD tests
    ├── test_fraud.py
    └── test_strategies.py
```

---

### Scenario 2: AI/ML Model Deployment

```
Practices Applied:
✓ Security-by-Design: Threat model (prompt injection, model extraction)
✓ API-First: POST /predict endpoint specification
✓ TDD: Input validation, output sanitization tests
✓ Modular Architecture: Preprocessing, inference, postprocessing modules
✓ Well-Architected: Security (IAM), Performance (caching), Cost (auto-scale)

Tools Used:
- FastAPI: API implementation
- pytest: Testing
- TensorFlow Serving: Model serving
- AWS SageMaker: Deployment
- MLFlow: Model versioning
- Semgrep: Security scanning

Security Controls:
- Input validation (max length, allowed characters)
- Rate limiting (prevent abuse)
- Model watermarking (detect extraction)
- Audit logging (all predictions logged)
- Encrypted model storage (S3 with KMS)

Example Structure:
ml_api/
├── api/
│   ├── inference.py       # API endpoint
│   └── validation.py      # Input sanitization
├── models/
│   ├── loader.py          # Singleton pattern
│   └── preprocessor.py    # Strategy pattern
├── security/
│   ├── rate_limiter.py
│   ├── audit_logger.py
│   └── threat_detector.py
└── tests/
    ├── test_inference.py
    └── test_security.py
```

---

### Scenario 3: Refactoring Legacy Monolith

```
Practices Applied:
✓ TDD: Write tests before refactoring (safety net)
✓ Clean Code: Extract functions, meaningful names
✓ SOLID: Break up god classes
✓ Design Patterns: Replace conditionals with Strategy/Factory
✓ Modular Architecture: Extract modules by domain

Process:
1. Add tests for current behavior
2. Identify code smells (long functions, god classes)
3. Extract responsibilities (SRP)
4. Apply patterns where appropriate
5. Run tests after each change (stay green)

Tools Used:
- pytest: Regression testing
- SonarQube: Identify hotspots
- CodeScene: Complexity visualization
- Claude CLI: Refactoring suggestions
- IDE refactoring tools

Before:
# app.py (5000 lines)
def handle_request(request):
    if request.type == "user_create":
        # 100 lines of user creation logic
    elif request.type == "payment":
        # 150 lines of payment logic
    elif request.type == "email":
        # 80 lines of email logic
    # ... 20 more types

After:
# Modular structure with patterns
app/
├── users/
│   ├── service.py       # Business logic
│   ├── repository.py    # Data access (Repository pattern)
│   └── handlers.py      # Request handlers
├── payments/
│   ├── strategies/      # Strategy pattern for payment methods
│   ├── service.py
│   └── repository.py
├── notifications/
│   ├── factory.py       # Factory for email/SMS/push
│   └── service.py
└── api/
    └── routes.py        # Thin routing layer
```

---

## Quick Reference: When to Use Each Pattern

| Pattern | Problem It Solves | Use When |
|---------|------------------|----------|
| **Strategy** | Multiple algorithms/behaviors | Payment methods, compression, sorting |
| **Factory** | Object creation complexity | Document types, loggers, connections |
| **Observer** | One-to-many notifications | Event systems, pub/sub, UI updates |
| **Decorator** | Add behavior dynamically | Middleware, logging, caching |
| **Repository** | Abstract data access | Database switching, testing |
| **Singleton** | One instance needed | Config, DB connection, cache |
| **Adapter** | Incompatible interfaces | Third-party APIs, legacy code |

---

## For Your Resume

### Recommended Version (Security/AI-ML Roles):

```markdown
### Software Engineering Practices
TDD (pytest, JUnit) | Security-by-design | Clean Code & SOLID | API-first (OpenAPI) | Modular Architecture
```

**Why this works:**
- ✅ Concise (one line)
- ✅ Shows tools you use (pytest, JUnit, OpenAPI)
- ✅ Emphasizes security (critical for your roles)
- ✅ Covers key practices without overwhelming

### Alternative (More Detail):

```markdown
### Software Engineering Practices
- Test-Driven Development with comprehensive test coverage (pytest, JUnit)
- Security-by-design with threat modeling and SAST/DAST integration
- Clean Code, SOLID principles, API-first development (OpenAPI)
- Modular architecture and design patterns
```

---

## Bottom Line

**These practices aren't checkboxes—they're tools you select based on context:**

- **Every project:** Clean Code, TDD, Security-by-Design
- **Services/APIs:** API-First, Repository pattern
- **OOP projects:** SOLID, Design Patterns
- **Cloud deployments:** Well-Architected
- **Legacy code:** Refactoring patterns, modularity

**Tools enforce practices automatically.** Set up linters, SAST tools, and CI/CD gates. Let machines catch issues, humans focus on design.

**For AI/ML Security roles, prioritize:**
1. Security-by-Design (threat modeling)
2. TDD (show reliability)
3. Clean Code (always)
4. Tools that automate security (Semgrep, Claude CLI)

You're as good as the practices you follow and the tools you use to enforce them automatically.