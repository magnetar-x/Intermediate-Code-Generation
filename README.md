# Intermediate Code Generation : Implementing Complete and Partial Evaluation of Boolean Expressions

A Compiler Design project implementing Intermediate Code Generation (ICG) for boolean and arithmetic expressions using **Flex (Lex)** and **Bison (Yacc)**. This project demonstrates and compares the two fundamental paradigms of intermediate code generation for control flow and boolean expressions: **Complete (Numerical) Evaluation** and **Partial (Short-Circuit) Evaluation with Backpatching**.

---

## Table of Contents

- [Overview](#overview)
- [Theoretical Background](#theoretical-background)
  - [1. Complete Evaluation (Value-Based / Numerical)](#1-complete-evaluation-value-based--numerical)
  - [2. Partial Evaluation (Control-Flow / Short-Circuit with Backpatching)](#2-partial-evaluation-control-flow--short-circuit-with-backpatching)
- [Repository Structure](#repository-structure)
- [Supported Language Grammar](#supported-language-grammar)
- [Given Input Program](#given-input-program)
- [Evaluation Outputs & Execution Traces](#evaluation-outputs--execution-traces)
  - [Method 1: Complete Evaluation](#method-1-complete-evaluation)
  - [Method 2: Partial Evaluation](#method-2-partial-evaluation)
- [Comparative Analysis](#comparative-analysis)
- [Prerequisites & Build Instructions](#prerequisites--build-instructions)
  - [Building Complete Evaluation](#building-complete-evaluation)
  - [Building Partial Evaluation](#building-partial-evaluation)

---

## Overview

In modern compilers, during the Intermediate Code Generation (ICG) phase, high-level control structures and expressions are translated into an intermediate representation such as **Three-Address Code (TAC)**. 

Boolean expressions typically appear in two contexts:
1. To compute logical values (e.g., `flag = a > b;`)
2. To alter control flow in conditional constructs (e.g., `if (E) then S1 else S2`)

This repository provides two complete implementations demonstrating how these boolean expressions can be translated:
- **Complete Evaluation**: Evaluates all subexpressions unconditionally, producing explicit boolean numerical values (`0` or `1`) stored in temporaries, followed by testing the final result.
- **Partial Evaluation (Short-Circuiting)**: Translates boolean expressions directly into jumps and branches without computing full boolean truth values. Jump targets are resolved in a single pass using **backpatching**.

---

## Theoretical Background

### 1. Complete Evaluation (Value-Based / Numerical)

In complete evaluation:
- Boolean expressions are treated like arithmetic expressions, evaluating to concrete numerical values: `1` for true and `0` for false.
- Relational expressions (`E1 relop E2`) emit conditional and unconditional jumps to load either `0` or `1` into a temporary variable:
  ```text
  if E1 relop E2 goto L_TRUE
  t_val := 0
  goto L_NEXT
  L_TRUE: t_val := 1
  L_NEXT: ...
  ```
- Logical operators (`&&`, `||`, `!`) explicitly compute the conjunction, disjunction, or negation of these temporary variables (e.g., `t3 := t1 && t2`).
- The enclosing `if-then-else` statement subsequently tests `if t_cond != 0 goto ...` to decide branching.
- **Key trait**: Every subexpression is guaranteed to be evaluated, even if an earlier term would guarantee the result (e.g., false in a logical AND).

### 2. Partial Evaluation (Control-Flow / Short-Circuit with Backpatching)

In partial evaluation:
- Boolean expressions represent flow of control rather than concrete values.
- Evaluates operands lazily (**short-circuit semantics**):
  - In `B1 && B2`: If `B1` is false, `B2` is never evaluated; control jumps immediately to the false exit.
  - In `B1 || B2`: If `B1` is true, `B2` is never evaluated; control jumps immediately to the true exit.
- Synthesized attributes manage unresolved jumps:
  - `truelist`: List of jump instruction indices that must branch when the expression is true.
  - `falselist`: List of jump instruction indices that must branch when the expression is false.
  - `nextlist`: List of jump instruction indices that jump out of a statement when execution completes.
- Marker non-terminals (`M` and `N`) capture target instruction indices and emit jumps without known destinations (`goto _`).
- **Backpatching**: As soon as destination labels become known, pending jump addresses in the lists are backpatched (filled in).

---

## Repository Structure

```plaintext
Complete-and-Partial-Evaluation-of-TAC/
│
├── Complete-Evaluation/
│   ├── complete.l       # Lexical analyzer (Flex) for complete evaluation
│   ├── complete.y       # Parser and TAC generator (Bison) using numerical evaluation
│   ├── input.txt        # Test program input
│   ├── y.tab.h          # Bison generated header
│   ├── y.tab.c          # Bison generated parser
│   ├── lex.yy.c         # Flex generated scanner
│   └── a.out            # Compiled executable
│
├── Partial-Evaluation/
│   ├── perf.l           # Lexical analyzer (Flex) for partial evaluation
│   ├── perf.y           # Parser and TAC generator (Bison) using backpatching
│   ├── helper.h         # Backpatching list helper functions (makelist, merge, backpatch)
│   ├── input.txt        # Test program input
│   ├── y.tab.h          # Bison generated header
│   ├── y.tab.c          # Bison generated parser
│   ├── lex.yy.c         # Flex generated scanner
│   └── a.out            # Compiled executable
│
└── README.md            # Comprehensive project documentation
```

---

## Supported Language Grammar

The parser supports a subset of C-like syntax:

| Construct | Syntax |
| :--- | :--- |
| **Control Flow** | `if ( Condition ) then Statement else Statement` |
| **Blocks** | `{ Statement; Statement; ... }` |
| **Assignments** | `ID = Expression;` |
| **Logical Operators** | `&&` (AND), `\|\|` (OR), `!` (NOT) |
| **Relational Operators**| `<`, `<=`, `>`, `>=`, `==`, `!=` |
| **Arithmetic Operators**| `+`, `-`, `*`, `/`, `%` |
| **Identifiers & Literals** | Alphanumeric IDs (`[a-zA-Z_][a-zA-Z0-9_]*`), positive integers (`[0-9]+`) |

---

## Given Input Program

The input file `input.txt` provided in both directories contains:

```c
1
y = a*a - x%b;
if ( x > a + b && x > y)
then x = a - b;
else
{ y = x*x;
  a = 2* a; b = b/2;
}
```

> **Note**: The leading number `1` provides the starting label/address for generated Three-Address Code instructions via `scanf("%d", &start_label)`.

---

## Evaluation Outputs & Execution Traces

### Method 1: Complete Evaluation

#### Execution Command
```bash
cd Complete-Evaluation
./a.out < input.txt
```

#### Actual Console Output
```text
Give start label number : 1
1: t1 := a * a
2: t2 := x % b
3: t3 := t1 - t2
4: y := t3
5: t4 := a + b
6: if x>t4 goto 9
7: t5 := 0
8: goto 10
9: t5 := 1
10: if x>y goto 13
11: t6 := 0
12: goto 14
13: t6 := 1
14: t7 := t5 && t6
15: if t7!=0 goto 17
16: goto 20
17: t8 := a - b
18: x := t8
19: goto _
20: t9 := x * x
21: y := t9
22: t10 := 2 * a
23: a := t10
24: t11 := b / 2
25: b := t11
```

#### Step-by-Step Code Walkthrough

1. **Lines 1–4**: Assignment `y = a*a - x%b;`
   - `t1 := a * a`
   - `t2 := x % b`
   - `t3 := t1 - t2`
   - `y := t3`
2. **Lines 5–9**: First condition `x > a + b`
   - Computes `t4 := a + b`
   - Evaluates boolean into temporary `t5`:
     - If `x > t4` is true, branches to `9` (`t5 := 1`).
     - Otherwise falls through to `7` (`t5 := 0`) and jumps to `10`.
3. **Lines 10–13**: Second condition `x > y`
   - Evaluates boolean into temporary `t6` (regardless of `t5`):
     - If `x > y` is true, branches to `13` (`t6 := 1`).
     - Otherwise falls through to `11` (`t6 := 0`) and jumps to `14`.
4. **Line 14**: Conjunction
   - Computes explicit boolean logical AND: `t7 := t5 && t6`
5. **Lines 15–16**: Condition Dispatch
   - Checks `if t7 != 0 goto 17` (`then` branch).
   - Else falls through to `16: goto 20` (`else` branch).
6. **Lines 17–19**: `then` body (`x = a - b;`)
   - `t8 := a - b`, `x := t8`, and `goto _` (exit branch).
7. **Lines 20–25**: `else` compound body (`{ y = x*x; a = 2*a; b = b/2; }`)
   - `t9 := x * x; y := t9`
   - `t10 := 2 * a; a := t10`
   - `t11 := b / 2; b := t11`

---

### Method 2: Partial Evaluation

#### Execution Command
```bash
cd Partial-Evaluation
./a.out < input.txt
```

#### Actual Console Output
```text
Give start label number : 1
backpatch 6, with target 8
backpatch 8, with target 10
backpatch 7, 9, with target 13
truelist : 8, 
falselist : 7, 9, 
1: t1 := a * a
2: t2 := x % b
3: t3 := t1 - t2
4: y := t3
5: t4 := a + b
6: if x>t4 goto _ 8
7: goto _ 13
8: if x>y goto _ 10
9: goto _ 13
10: t5 := a - b
11: x := t5
12: goto _
13: t6 := x * x
14: y := t6
15: t7 := 2 * a
16: a := t7
17: t8 := b / 2
18: b := t8
```

#### Step-by-Step Code Walkthrough

1. **Lines 1–4**: Assignment `y = a*a - x%b;`
   - Identical arithmetic evaluation as complete evaluation (`t1`, `t2`, `t3`).
2. **Lines 5–7**: First condition `x > a + b`
   - Calculates `t4 := a + b`.
   - Emits conditional branch `6: if x>t4 goto _` (`truelist = {6}`).
   - Emits unconditional branch `7: goto _` (`falselist = {7}`).
3. **Backpatching `&&` (Short-Circuit)**:
   - For `B1 && M B2`, the marker `M` notes instruction `8` as the start of `B2`.
   - `backpatch(B1.truelist, 8)` resolves instruction `6` to branch directly to `8`.
   - If `x > t4` is false, control immediately jumps via instruction `7` to the `else` block (short-circuiting `B2`!).
4. **Lines 8–9**: Second condition `x > y`
   - Emits conditional branch `8: if x>y goto _` (`truelist = {8}`).
   - Emits unconditional branch `9: goto _` (`falselist = {9}`).
   - Resulting `falselist` merged to `{7, 9}`.
5. **Backpatching the `if-then-else`**:
   - `backpatch(truelist, 10)` resolves instruction `8` to target label `10` (`then` block).
   - `backpatch(falselist, 13)` resolves instructions `7` and `9` to target label `13` (`else` block).
6. **Lines 10–12**: `then` body (`x = a - b;`)
   - `t5 := a - b; x := t5; goto _`.
7. **Lines 13–18**: `else` body (`{ y = x*x; a = 2*a; b = b/2; }`)
   - `t6 := x * x; y := t6`
   - `t7 := 2 * a; a := t7`
   - `t8 := b / 2; b := t8`

---

## Comparative Analysis

| Feature | Complete Evaluation | Partial (Short-Circuit) Evaluation |
| :--- | :--- | :--- |
| **Boolean Evaluation** | Explicit numerical values (`0` or `1`) | Direct control flow branches |
| **Total Instructions Generated** | **25 instructions** (Labels 1–25) | **18 instructions** (Labels 1–18, **~28% reduction**) |
| **Temporary Variables Used** | **11 temporaries** (`t1` to `t11`) | **8 temporaries** (`t1` to `t8`) |
| **Subexpression Evaluation** | Always evaluates both operands of `&&` / `\|\|` | Bypasses remaining operands once outcome is determined |
| **Runtime Efficiency** | Slower (unnecessary computations & assignments) | Faster (executes minimal instructions at runtime) |
| **Side-Effect Safety** | Can cause unwanted side effects or errors (e.g. division by zero, null dereference) | Safe from errors in skipped branches |
| **Implementation Complexity** | Simpler grammar actions | Requires backpatching lists (`truelist`, `falselist`, `nextlist`) |

---

## Prerequisites & Build Instructions

### Prerequisites

Ensure you have the required compiler tools installed:

```bash
# On Debian/Ubuntu/Mint
sudo apt-get update
sudo apt-get install flex bison gcc
```

### Building Complete Evaluation

```bash
cd Complete-Evaluation

# Generate lexer and parser
yacc -d complete.y
lex complete.l

# Compile executable
gcc lex.yy.c y.tab.c -o a.out

# Run with sample input
./a.out < input.txt
```

### Building Partial Evaluation

```bash
cd Partial-Evaluation

# Generate lexer and parser
yacc -d perf.y
lex perf.l

# Compile executable
gcc lex.yy.c y.tab.c -o a.out

# Run with sample input
./a.out < input.txt
```
