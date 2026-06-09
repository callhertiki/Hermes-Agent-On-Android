---
agent: Kumu
type: example-output
tags: [example, teacher]
---

# Kumu — Example Output

> This shows what a good Kumu response looks like. Use it to calibrate what you expect.

---

## Example: Lesson on Python Functions

**Prompt sent:** `Create a lesson on Python functions. My level is beginner.`

---

## Python Functions

### Overview
A function is a named block of reusable code. Instead of writing the same instructions five times, you write them once, give them a name, and call that name whenever you need them. Functions make code shorter, easier to read, and easier to fix.

### Core Concepts

**1. Defining a function**
You use the `def` keyword followed by a name and parentheses.
```python
def greet():
    print("Hello!")
```
Calling it: `greet()` — this runs the code inside.

**2. Parameters — giving the function input**
Parameters are placeholders for values you'll pass in when calling the function.
```python
def greet(name):
    print(f"Hello, {name}!")

greet("Mahealani")  # → Hello, Mahealani!
```

**3. Return values — getting output back**
A function can give you back a result using `return`.
```python
def add(a, b):
    return a + b

result = add(3, 5)  # result is now 8
```

### Worked Example
**Problem:** Write a function that takes a temperature in Celsius and returns it in Fahrenheit.

```python
def celsius_to_fahrenheit(celsius):
    fahrenheit = (celsius * 9/5) + 32
    return fahrenheit

print(celsius_to_fahrenheit(100))  # → 212.0
print(celsius_to_fahrenheit(0))    # → 32.0
```

### Practice Exercises
1. Write a function called `square` that takes a number and returns it squared.
2. Write a function called `full_name` that takes a first and last name and returns them joined with a space.
3. Write a function called `is_even` that takes a number and returns `True` if it's even, `False` if not.

### Summary
A function is a named, reusable block of code. You define it once with `def`. You can give it inputs (parameters) and it can give you outputs (`return`). Functions prevent repetition and make programs easier to understand.

**Next lesson:** Variable scope — what does a function "see" vs. what stays private to it?

---

*Kumu output — Noʻeau OS Phase 1*
