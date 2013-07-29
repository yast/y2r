Y2R Compiler Specification
==========================

This document describes how [Y2R](https://github.com/yast/y2r) translates
various
[YCP](http://doc.opensuse.org/projects/YaST/SLES10/tdg/Book-YCPLanguage.html)
constructs into Ruby. It serves both as a human-readable documentation and as an
executable specification. Technically, this is implemented by translating this
document from [Markdown](http://daringfireball.net/projects/markdown/) into
[RSpec](http://rspec.info/).

Note the specification is incomplete in that it only covers main aspects of the
translation and not all the details. Making it 100% complete would be much more
effort than we can spend now and it would also make it pretty much unreadable.
Most of the omitted details are documented using unit tests in RSpec (see the
`spec` directory).

Contents
--------

  * [Contents](#contents)
  * [Values](#values)
    * [Voids](#voids)
    * [Booleans](#booleans)
    * [Integers](#integers)
    * [Floats](#floats)
    * [Symbols](#symbols)
    * [Strings](#strings)
    * [Paths](#paths)
    * [Lists](#lists)
    * [Maps](#maps)
    * [Terms](#terms)
    * [Blocks](#blocks)
    * [Function References](#function-references)
  * [Expressions](#expressions)
    * [Variables](#variables)
    * [Equality Operators](#equality-operators)
    * [Comparison Operators](#comparison-operators)
    * [Arithmetic Operators](#arithmetic-operators)
    * [Bitwise Operators](#bitwise-operators)
    * [Logical Operators](#logical-operators)
    * [Ternary Operator](#ternary-operator)
    * [Index Operator](#index-operator)
    * [`is` Operator](#is-operator)
    * [Double Quote Operator](#double-quote-operator)
    * [Type Conversions](#type-conversions)
    * [`_` Calls](#_-calls)
    * [Builtin Calls](#builtin-calls)
    * [Function Calls](#function-calls)
  * [Statements](#statements)
    * [Assignments](#assignments)
    * [`textdomain` Statement](#textdomain-statement)
    * [`import` Statement](#import-statement)
    * [`include` Statement](#include-statement)
    * [`return` Statement](#return-statement)
    * [`break` Statement](#break-statement)
    * [`continue` Statement](#continue-statement)
    * [Statement Blocks](#statement-blocks)
    * [`if` Statement](#if-statement)
    * [`switch` Statement](#switch-statement)
    * [`while` Statement](#while-statement)
    * [`do` Statement](#do-statement)
    * [`repeat` Statement](#repeat-statement)
    * [Function Definitions](#function-definitions)
  * [Files](#files)
    * [Clients](#clients)
    * [Modules](#modules)
  * [Other](#other)
    * [Comments](#comments)

Values
------

Y2R translates most YCP values into their Ruby equivalents. Those that don't
have any are translated as instances of special classes defined in [YaST Ruby
bindings](https://github.com/yast/yast-ruby-bindings).

### Voids

Y2R translates YCP `nil`s as Ruby `nil`s.

#### YCP (fragment)

```ycp
void v = nil;
```

#### Ruby (fragment)

```ruby
v = nil
```

### Booleans

Y2R translates YCP booleans as Ruby booleans.

#### YCP (fragment)

```ycp
boolean t = true;
boolean f = false;
```

#### Ruby (fragment)

```ruby
t = true
f = false
```

### Integers

Y2R translates YCP integers as `Fixnum`s. It ignores the issue of overflow (YCP
integers can overflow while `Fixnum`s are just converted into `Bignum`s).

#### YCP (fragment)

```ycp
integer i = 42;
```

#### Ruby (fragment)

```ruby
i = 42
```

### Floats

Y2R translates YCP floats as Ruby floats. Both are stored as `double` on the C
level so the conversion is lossless.

#### YCP (fragment)

```ycp
float f1 = 42.0;   // regular syntax
float f2 = 42.;    // somewhat unusual syntax
```

#### Ruby (fragment)

```ruby
f1 = 42.0 # regular syntax
f2 = 42.0 # somewhat unusual syntax
```

### Symbols

Y2R translates YCP symbols as Ruby symbols. YCP symbols are always composed of
alphanumeric characters and uderscores, which means the equivalent Ruby symbols
will always have US-ASCII encoding.

#### YCP (fragment)

```ycp
symbol s = `abcd;
```

#### Ruby (fragment)

```ruby
s = :abcd
```

### Strings

Y2R translates YCP strings as Ruby strings. YCP strings use UTF-8 internally and
the translated code is in UTF-8 too, so the conversion is lossless.

#### YCP (fragment)

```ycp
string s = "abcd";
```

#### Ruby (fragment)

```ruby
s = "abcd"
```

### Paths

Y2R translates YCP paths as `path` calls. This method creates an instance of the
`Yast::Path` class, which represents a YCP path.

#### YCP (fragment)

```ycp
path p = .abcd;
```

#### Ruby (fragment)

```ruby
p = path(".abcd")
```

### Lists

Y2R translates YCP lists as Ruby arrays.

#### YCP (fragment)

```ycp
list l1 = [];
list l2 = [42, 43, 44];
```

#### Ruby (fragment)

```ruby
l1 = []
l2 = [42, 43, 44]
```

### Maps

Y2R translates YCP maps as Ruby hashes.

#### YCP (fragment)

```ycp
map m1 = $[];
map m2 = $[`a: 42, `b: 43, `c: 44];
```

#### Ruby (fragment)

```ruby
m1 = {}
m2 = { :a => 42, :b => 43, :c => 44 }
```

### Terms

Y2R translates YCP terms as `term` calls. This method creates an instance of the
`Yast::Term` class, which represents a YCP term.

#### YCP (fragment)

```ycp
term t1 = `a();
term t2 = `a(42, 43, 44);
```

#### Ruby (fragment)

```ruby
t1 = term(:a)
t2 = term(:a, 42, 43, 44)
```

Y2R translates some widely used terms as calls to shortcut methods instead of
`term` calls. This is mainly used for terms used to describe the UI (it makes
its description significantly shorter).

#### YCP (fragment)

```ycp
term t = `HBox(`opt(`disabled), `Empty());
```

#### Ruby (fragment)

```ruby
t = HBox(Opt(:disabled), Empty())
```

### Blocks

Y2R translates YCP blocks as Ruby lambdas.

#### YCP (fragment)

```ycp
block<void> b = { y2milestone("M1"); };
```

#### Ruby (fragment)

```ruby
b = lambda { Builtins.y2milestone("M1") }
```

### Function References

Y2R translates YCP function references as `fun_ref` calls. This method creates
an instance of the `Yast::FunRef` class, which represents a YCP function
reference.

#### YCP (complete code)

```ycp
{
  void f() {
    return;
  }

  void() r = f;
}
```

#### Ruby (complete code)

```ruby
# encoding: utf-8

module Yast
  class DefaultClient < Client
    def main
      @r = fun_ref(method(:f), "void ()")

      nil
    end

    def f
      nil
    end
  end
end

Yast::DefaultClient.new.main
```

Expressions
-----------

### Variables

Y2R translates YCP variables as Ruby variables.

#### YCP (complete code)

```ycp
{
  # global variable - toplevel
  integer i = 42;

  # global variable - nested
  {
    integer i = 43;
  }

  void f() {
    # local variable - toplevel
    integer i = 42;

    # local variable - nested
    {
      integer i = 43;
    }
  }
}
```

#### Ruby (complete code)

```ruby
# encoding: utf-8

module Yast
  class DefaultClient < Client
    def main
      # global variable - toplevel
      @i = 42

      # global variable - nested
      @i2 = 43

      nil
    end

    def f
      # local variable - toplevel
      i = 42

      # local variable - nested
      i2 = 43

      nil
    end
  end
end

Yast::DefaultClient.new.main
```

### Equality Operators

Y2R translates YCP equality operators as equivalent Ruby operators. This is
possible because they work the same for YCP types that have Ruby equivalents and
because Ruby bindings define them appropriately on all classes representing YCP
types that don't have Ruby equivalents.

#### YCP (fragment)

```ycp
boolean b1 = 42 == 43;
boolean b2 = 42 != 43;
```

#### Ruby (fragment)

```ruby
b1 = 42 == 43
b2 = 42 != 43
```

### Comparison Operators

Y2R translates YCP comparison operators as `Ops.*` calls. This is necessary
because any operand can be `nil` and Ruby comparison operators behave
differently from YCP ones in that case.

#### YCP (fragment)

```ycp
boolean b1 = 42 < 43;
boolean b2 = 42 > 43;
boolean b3 = 42 <= 43;
boolean b4 = 42 >= 43;
```

#### Ruby (fragment)

```ruby
b1 = Ops.less_than(42, 43)
b2 = Ops.greater_than(42, 43)
b3 = Ops.less_or_equal(42, 43)
b4 = Ops.greater_or_equal(42, 43)
```

### Arithmetic Operators

Y2R translates YCP arithmetic operators as equivalent Ruby operators when it is
sure that no operand is `nil`. This is possible because YCP and Ruby operators
behave identically in that case.

#### YCP (fragment)

```ycp
integer i1 = -42;
integer i2 = 42 + 43;
integer i3 = 42 - 43;
integer i4 = 42 * 43;
integer i5 = 42 / 43;
integer i6 = 42 % 43;
```

#### Ruby (fragment)

```ruby
i1 = -42
i2 = 42 + 43
i3 = 42 - 43
i4 = 42 * 43
i5 = 42 / 43
i6 = 42 % 43
```

Y2R translates YCP arithmetic operators as `Ops.*` calls when it is not sure
that no operand is `nil`. This is necessary because Ruby operators may behave
differently from the YCP ones in that case.

#### YCP (fragment)

```ycp
integer a = 42;
integer b = 43;

integer i1 = -a;
integer i2 = a + b;
integer i3 = a - b;
integer i4 = a * b;
integer i5 = a / b;
integer i6 = a % b;
```

#### Ruby (fragment)

```ruby
a = 42
b = 43

i1 = Ops.unary_minus(a)
i2 = Ops.add(a, b)
i3 = Ops.subtract(a, b)
i4 = Ops.multiply(a, b)
i5 = Ops.divide(a, b)
i6 = Ops.modulo(a, b)
```

### Bitwise Operators

Y2R translates YCP bitwise operators as equivalent Ruby operators when it is
sure that no operand is `nil`. This is possible because YCP and Ruby operators
behave identically in that case.

#### YCP (fragment)

```ycp
integer i1 = ~42;
integer i2 = 42 & 43;
integer i3 = 42 | 43;
integer i4 = 42 ^ 43;
integer i5 = 42 << 43;
integer i6 = 42 >> 43;
```

#### Ruby (fragment)

```ruby
i1 = ~42
i2 = 42 & 43
i3 = 42 | 43
i4 = 42 ^ 43
i5 = 42 << 43
i6 = 42 >> 43
```

Y2R translates YCP bitwise operators as `Ops.*` calls when it is not sure that
no operand is `nil`. This is necessary because Ruby operators may behave
differently from the YCP ones in that case.

#### YCP (fragment)

```ycp
integer a = 42;
integer b = 43;

integer i1 = ~a;
integer i2 = a & b;
integer i3 = a | b;
integer i4 = a ^ b;
integer i5 = a << b;
integer i6 = a >> b;
```

#### Ruby (fragment)

```ruby
a = 42
b = 43

i1 = Ops.bitwise_not(a)
i2 = Ops.bitwise_and(a, b)
i3 = Ops.bitwise_or(a, b)
i4 = Ops.bitwise_xor(a, b)
i5 = Ops.shift_left(a, b)
i6 = Ops.shift_right(a, b)
```

### Logical Operators

Y2R translates YCP logical operators as Ruby logical operators.

#### YCP (fragment)

```ycp
boolean b1 = !true;
boolean b2 = true && false;
boolean b3 = true || false;
```

#### Ruby (fragment)

```ruby
b1 = !true
b2 = true && false
b3 = true || false
```

### Ternary Operator

Y2R translates YCP ternary operators as Ruby ternary operators.

#### YCP (fragment)

```ycp
integer i = true ? 42 : 43;
```

#### Ruby (fragment)

```ruby
i = true ? 42 : 43
```

### Index Operator

Y2R translates YCP index operators as `Ops.get` calls when no conversion is
needed.

#### YCP (complete code)

```ycp
{
  integer f() {
    return 0;
  }

  // single-element index, nil default
  integer i = [42, 43, 44][1]:nil;

  // multi-element index, nil default
  integer j = [[42, 43, 44], [45, 46, 47], [48, 49, 50]][1, 2]:nil;

  // single-element index, non-nil eagerly-evaluated default
  integer k = [42, 43, 44][1]:0;

  // single-element index, non-nil lazily-evaluated default
  integer l = [42, 43, 44][1]:f();
}
```

#### Ruby (complete code)

```ruby
# encoding: utf-8

module Yast
  class DefaultClient < Client
    def main
      # single-element index, nil default
      @i = Ops.get([42, 43, 44], 1)

      # multi-element index, nil default
      @j = Ops.get([[42, 43, 44], [45, 46, 47], [48, 49, 50]], [1, 2])

      # single-element index, non-nil eagerly-evaluated default
      @k = Ops.get([42, 43, 44], 1, 0)

      # single-element index, non-nil lazily-evaluated default
      @l = Ops.get([42, 43, 44], 1) { f }

      nil
    end

    def f
      0
    end
  end
end

Yast::DefaultClient.new.main
```

Y2R translates YCP index operators as appropriate `Ops.get_*` calls when
conversion is needed and the shortcut methods exists.

#### YCP (fragment)

```ycp
list<any> l = [42.0, 43.0, 44.0];
integer i = l[1]:0;
```

#### Ruby (fragment)

```ruby
l = [42.0, 43.0, 44.0]
i = Ops.get_integer(l, 1, 0)
```

### `is` Operator

Y2R translates YCP `is` operators as `Ops.is` calls when no shortcut method
exists.

#### YCP (fragment)

```ycp
boolean b = is(42, list<integer>);
```

#### Ruby (fragment)

```ruby
b = Ops.is(42, "list <integer>")
```

Y2R translates YCP `is` operators as appropriate `Ops.is_*` calls when the
shortcut method exists.

```ycp
boolean b = is(42, integer);
```

#### Ruby (fragment)

```ruby
b = Ops.is_integer?(42)
```

### Double Quote Operator

Y2R translates YCP double quote operators as Ruby lambdas.

#### YCP (fragment)

```ycp
block<integer> b = ``(42);
```

#### Ruby (fragment)

```ruby
b = lambda { 42 }
```

### Type Conversions

Y2R translates YCP type conversions as `Convert.convert` calls when no shortcut
method exists.

#### YCP (fragment)

```ycp
float f = (float) 42;
```

#### Ruby (fragment)

```ruby
f = Convert.convert(42, :from => "integer", :to => "float")
```

Y2R translates YCP type conversions from `any` as appropriate `Convert.to_*`
calls when the shortcut method exists.

```ycp
any a = "string";
string s = (string) a;
```

#### Ruby (fragment)

```ruby
a = "string"
s = Convert.to_string(a)
```

### `_` Calls

Y2R translates YCP `_` calls as `_` calls.

#### YCP (fragment)

```ycp
textdomain "helloworld";

string s = _("Hello, world!");
```

#### Ruby (fragment)

```ruby
textdomain "helloworld"

s = _("Hello, world!")
```

### Builtin Calls

Y2R translates YCP builtin calls as `Builtins.*`, `SCR.*` and `WFM.*` calls.
These reimplement behavior of all YCP builtins in Ruby or proxy to the
underlying C/C++ implementation.

#### YCP (complete code)

```ycp
{
  time();
  random(100);

  SCR::Dir(.syseditor.section);
  WFM::Args();

  float f = float::abs(-42.0);
  list  l = list::reverse([42, 43, 44]);
  list  s = multiset::union([42, 43, 44], [45, 46, 47]);
}
```

#### Ruby (complete code)

```ruby
# encoding: utf-8

module Yast
  class DefaultClient < Client
    def main
      Builtins.time
      Builtins.random(100)

      SCR.Dir(path(".syseditor.section"))
      WFM.Args

      @f = Builtins::Float.abs(-42.0)
      @l = Builtins::List.reverse([42, 43, 44])
      @s = Builtins::Multiset.union([42, 43, 44], [45, 46, 47])

      nil
    end
  end
end

Yast::DefaultClient.new.main
```

Y2R handles YCP builtin calls with a block as the last argument specially. It
converts the block into a Ruby block.

#### YCP (fragment)

```ycp
foreach(integer i, [42, 43, 44], { y2milestone("M1"); });
```

#### Ruby (fragment)

```ruby
Builtins.foreach([42, 43, 44]) { |i| Builtins.y2milestone("M1") }
```

Y2R handles YCP builtin calls with a double quote expression as the last
argument specially. It converts the expression into a Ruby block.

#### YCP (fragment)

```ycp
maplist(integer i, [42, 43, 44], ``(i * i));
```

#### Ruby (fragment)

```ruby
Builtins.maplist([42, 43, 44]) { |i| Ops.multiply(i, i) }
```

### Function Calls

Y2R translates YCP function calls of toplevel functions as Ruby method calls.

#### YCP (complete code)

```ycp
{
  integer f(integer a, integer b, integer c) {
    return a + b + c;
  }

  integer i = f(1, 2, 3);
}
```

#### Ruby (complete code)

```ruby
# encoding: utf-8

module Yast
  class DefaultClient < Client
    def main
      @i = f(1, 2, 3)

      nil
    end

    def f(a, b, c)
      Ops.add(Ops.add(a, b), c)
    end
  end
end

Yast::DefaultClient.new.main
```

Y2R translates YCP function calls of nested functions as invoking the `call`
method on them.

```ycp
{
  void wrapper() {
    integer f(integer a, integer b, integer c) {
      return a + b + c;
    }

    integer i = f(1, 2, 3);
  }
}
```

#### Ruby (complete code)

```ruby
# encoding: utf-8

module Yast
  class DefaultClient < Client
    def wrapper
      f = lambda { |a, b, c| Ops.add(Ops.add(a, b), c) }

      i = f.call(1, 2, 3)

      nil
    end
  end
end

Yast::DefaultClient.new.main
```

Y2R translates YCP function reference calls as invoking the `call` method on
them.

#### YCP (complete code)

```ycp
{
  integer f(integer a, integer b, integer c) {
    return a + b + c;
  }

  integer(integer, integer, integer) r = f;

  integer i = r(1, 2, 3);
}
```

#### Ruby (complete code)

```ruby
# encoding: utf-8

module Yast
  class DefaultClient < Client
    def main
      @r = fun_ref(method(:f), "integer (integer, integer, integer)")

      @i = @r.call(1, 2, 3)

      nil
    end

    def f(a, b, c)
      Ops.add(Ops.add(a, b), c)
    end
  end
end

Yast::DefaultClient.new.main
```

Y2R translates YCP function calls with arguments passed by reference as
sequences of statements that emulate YCP behavior in Ruby.

#### YCP (complete code)

```ycp
{
  integer f(integer& a, integer& b, integer& c) {
    return a + b + c;
  }

  integer a = 1;
  integer b = 2;
  integer c = 3;

  // called as a statement
  f(a, b, c);

  // called as an expression
  integer i = f(a, b, c);
}
```

#### Ruby (complete code)

```ruby
# encoding: utf-8

module Yast
  class DefaultClient < Client
    def main
      @a = 1
      @b = 2
      @c = 3

      # called as a statement
      a_ref = arg_ref(@a)
      b_ref = arg_ref(@b)
      c_ref = arg_ref(@c)
      f(a_ref, b_ref, c_ref)
      @a = a_ref.value
      @b = b_ref.value
      @c = c_ref.value

      # called as an expression
      @i = (
        a_ref = arg_ref(@a);
        b_ref = arg_ref(@b);
        c_ref = arg_ref(@c);
        f_result = f(a_ref, b_ref, c_ref);
        @a = a_ref.value;
        @b = b_ref.value;
        @c = c_ref.value;
        f_result
      )

      nil
    end

    def f(a, b, c)
      Ops.add(Ops.add(a.value, b.value), c.value)
    end
  end
end

Yast::DefaultClient.new.main
```

Statements
----------

### Assignments

Y2R translates simple YCP assignments as Ruby assignments.

#### YCP (fragment)

```ycp
integer i = 42;

i = 43;
```

#### Ruby (fragment)

```ruby
i = 42

i = 43
```

Y2R translates YCP assignments with brackets as `Ops.set` calls.

#### YCP (fragment)

```ycp
list l = [42, 43, 44];

// single-element index
l[0] = [45];

// multi-element index
l[0,0] = 42;
```

#### Ruby (fragment)

```ruby
l = [42, 43, 44]

# single-element index
Ops.set(l, 0, [45])

# multi-element index
Ops.set(l, [0, 0], 42)
```

### `textdomain` Statement

Y2R translates YCP `textdomain` statements as `textdomain` calls.

#### YCP (fragment)

```ycp
{
  textdomain "users";
}
```

#### Ruby (fragment)

```ruby
textdomain "users"
```

### `import` Statement

Y2R translates YCP `import` statements as `Yast.import` calls.

#### YCP (fragment)

```ycp
import "String";
```

#### Ruby (fragment)

```ruby
Yast.import "String"
```

### `include` Statement

Y2R translates YCP `include` statements as `Yast.include` calls.

#### YCP (complete code)

```ycp
{
  include "include.ycp";
}
```

#### Ruby (complete code)

```ruby
# encoding: utf-8

module Yast
  class DefaultClient < Client
    def main
      Yast.include self, "include.rb"

      nil
    end
  end
end

Yast::DefaultClient.new.main
```

### `return` Statement

Y2R translates YCP `return` statements inside functions as Ruby `return`
statements.

#### YCP (complete code)

```ycp
{
  // return without value
  void f1() {
    return;

    y2milestone("M1");   // prevent optimizing the return away
  }

  // return with value
  integer f2() {
    return 42;

    y2milestone("M1");   // prevent optimizing the return away
  }
}
```

#### Ruby (complete code)

```ruby
# encoding: utf-8

module Yast
  class DefaultClient < Client
    # return without value
    def f1
      return

      Builtins.y2milestone("M1") # prevent optimizing the return away
    end

    # return with value
    def f2
      return 42

      Builtins.y2milestone("M1") # prevent optimizing the return away
    end
  end
end

Yast::DefaultClient.new.main
```

Y2R translates YCP `return` statements inside blocks as Ruby `next` statements.

#### YCP (fragment)

```ycp
// return without value
maplist(integer i, [42, 43, 44], {
  return 42;

  y2milestone("M1");   // prevent optimizing the return away
});

// return with value
foreach(integer i, [42, 43, 44], {
  return;

  y2milestone("M1");   // prevent optimizing the return away
});
```

#### Ruby (fragment)

```ruby
# return without value
Builtins.maplist([42, 43, 44]) { |i| 42 }

# return with value
Builtins.foreach([42, 43, 44]) do |i|
  next
  Builtins.y2milestone("M1") # prevent optimizing the return away
end
```

### `break` Statement

Y2R translates YCP `break` statements inside loops as Ruby `next`
statements.

```ycp
while (true) {
  break;
}

repeat {
  break;
} until(true);
```

#### Ruby (fragment)

```ruby
while true
  break
end
begin
  break
end until true
```

Y2R translates YCP `break` statements inside blocks as `raise Break` calls.

```ycp
foreach(integer i, [42, 43, 44], { break; });
```

#### Ruby (fragment)

```ruby
Builtins.foreach([42, 43, 44]) { |i| raise Break }
```

### `continue` Statement

Y2R translates YCP `continue` statements inside loops as Ruby `next` statements.

```ycp
while (true) {
  continue;
}

repeat {
  continue;
} until(true);
```

#### Ruby (fragment)

```ruby
while true
  next
end
begin
  next
end until true
```

Y2R translates YCP `continue` statements inside blocks as Ruby `next`
statements.

```ycp
foreach(integer i, [42, 43, 44], {
  continue;

  y2milestone("M1");   // prevent optimizing the continue away
});
```

#### Ruby (fragment)

```ruby
Builtins.foreach([42, 43, 44]) do |i|
  next
  Builtins.y2milestone("M1") # prevent optimizing the continue away
end
```

### Statement Blocks

Y2R translates YCP statement blocks as Ruby statements.

#### YCP (complete code)

```ycp
{
  {
    y2milestone("M1");
    y2milestone("M2");
    y2milestone("M3");
  }
}
```

#### Ruby (complete code)

```ruby
# encoding: utf-8

module Yast
  class DefaultClient < Client
    def main
      Builtins.y2milestone("M1")
      Builtins.y2milestone("M2")
      Builtins.y2milestone("M3")

      nil
    end
  end
end

Yast::DefaultClient.new.main
```

### `if` Statement

Y2R translates YCP `if` statements as Ruby `if` statements.

#### YCP (fragment)

```ycp
if (true)
  y2milestone("M1");

if (true)
  y2milestone("M2");
else
  y2milestone("M3");
```

#### Ruby (fragment)

```ruby
Builtins.y2milestone("M1") if true

if true
  Builtins.y2milestone("M2")
else
  Builtins.y2milestone("M3")
end
```

### `switch` Statement

Y2R translates YCP `switch` statements as Ruby `case` statements.

#### YCP (fragment)

```ycp
switch (42) {
  case 42:
    y2milestone("M1");
    break;

  case 43:
  case 44:
    y2milestone("M2");
    return;

  default:
    y2milestone("M3");
    break;
}
```

#### Ruby (fragment)

```ruby
case 42
  when 42
    Builtins.y2milestone("M1")
  when 43, 44
    Builtins.y2milestone("M2")
    return
  else
    Builtins.y2milestone("M3")
end
```

Y2R does not support cases without a `break` or `return` at the end. This is
mostly because Ruby doesn't have any suitable equivalent construct.

#### YCP (fragment)

```ycp
switch (42) {
  case 42:
    y2milestone("M1");
}
```

#### Error Message

```error
Case without a break or return encountered. These are not supported.
```

Y2R does not support cases with `break` in the middle. This is
mostly because Ruby doesn't have any suitable equivalent construct.

#### YCP (fragment)

```ycp
switch (42) {
  case 42:
    break;
    y2milestone("M1");
    break;
}
```

#### Error Message

```error
Case with a break in the middle encountered. These are not supported.
```

Y2R does not support defaults with `break` in the middle. This is
mostly because Ruby doesn't have any suitable equivalent construct.

#### YCP (fragment)

```ycp
switch (42) {
  default:
    break;
    y2milestone("M1");
}
```

#### Error Message

```error
Default with a break in the middle encountered. These are not supported.
```

### `while` Statement

Y2R translates YCP `while` statements as Ruby `while` statements.

#### YCP (fragment)

```ycp
while (true)
  y2milestone("M1");
```

#### Ruby (fragment)

```ruby
while true
  Builtins.y2milestone("M1")
end
```

### `do` Statement

Y2R translates YCP `do` statements as Ruby `while` statements.

#### YCP (fragment)

```ycp
do {
  y2milestone("M1");
} while(true);
```

#### Ruby (fragment)

```ruby
begin
  Builtins.y2milestone("M1")
end while true
```

### `repeat` Statement

Y2R translates YCP `repeat` statements as Ruby `until` statements.

#### YCP (fragment)

```ycp
repeat {
  y2milestone("M1");
} until(true);
```

#### Ruby (fragment)

```ruby
begin
  Builtins.y2milestone("M1")
end until true
```

### Function Definitions

Y2R translates toplevel function definitions as Ruby method definitions.

#### YCP (complete code)

```ycp
{
  integer f(integer a, integer b, integer c) {
    return a + b + c;
  }
}
```

#### Ruby (complete code)

```ruby
# encoding: utf-8

module Yast
  class DefaultClient < Client
    def f(a, b, c)
      Ops.add(Ops.add(a, b), c)
    end
  end
end

Yast::DefaultClient.new.main
```

Y2R translates nested YCP function definitions as Ruby lambdas.

#### YCP (complete code)

```ycp
{
  void wrapper() {
    integer f(integer a, integer b, integer c) {
      return a + b + c;
    }
  }
}
```

#### Ruby (complete code)

```ruby
# encoding: utf-8

module Yast
  class DefaultClient < Client
    def wrapper
      f = lambda { |a, b, c| Ops.add(Ops.add(a, b), c) }

      nil
    end
  end
end

Yast::DefaultClient.new.main
```

Y2R maintains pass-by-value semantics of parameters by calling `deep_copy` on
them. The only exceptions are immutable types (like `boolean`) and references.

#### YCP (complete code)

```ycp
{
  // parameter with a mutable type
  void f1(list a) {
    return nil;
  }

  // parameter with an immutable type
  void f2(boolean a) {
    return nil;
  }

  // parameter with a mutable type passed by reference
  void f3(list& a) {
    return nil;
  }
}
```

#### Ruby (complete code)

```ruby
# encoding: utf-8

module Yast
  class DefaultClient < Client
    # parameter with a mutable type
    def f1(a)
      a = deep_copy(a)
      nil
    end

    # parameter with an immutable type
    def f2(a)
      nil
    end

    # parameter with a mutable type passed by reference
    def f3(a)
      nil
    end
  end
end

Yast::DefaultClient.new.main
```

Y2R maintains pass-by-value semantics of return values by calling `deep_copy` on
returned variables. The only exception is immutable types (like `boolean`).

#### YCP (complete code)

```ycp
{
  // return value with a mutable type
  list f1() {
    list r = [];
    return r;
  }

  // return value with an immutable type
  integer f2() {
    integer r = 42;
    return r;
  }
}
```

#### Ruby (complete code)

```ruby
# encoding: utf-8

module Yast
  class DefaultClient < Client
    # return value with a mutable type
    def f1
      r = []
      deep_copy(r)
    end

    # return value with an immutable type
    def f2
      r = 42
      r
    end
  end
end

Yast::DefaultClient.new.main
```

Files
-----

### Clients

Y2R translates YCP clients as Ruby classes that are instantiated. Toplevel
variables become instance variables, toplevel functions become methods and
toplevel statements (such as imports) are moved into the `main` method.

#### YCP (complete code)

```ycp
{
  import "String";

  integer i = 42;

  integer f() {
    return 42;
  }
}
```

#### Ruby (complete code)

```ruby
# encoding: utf-8

module Yast
  class DefaultClient < Client
    def main
      Yast.import "String"

      @i = 42

      nil
    end

    def f
      42
    end
  end
end

Yast::DefaultClient.new.main
```

### Modules

Y2R translates YCP modules as Ruby classes that are instantiated. Toplevel
variables become instance variables, toplevel functions become methods and
toplevel statements (such as imports) are moved into the `main` method.
Constructor becomes a regular method, which is called from `main`. Global
variables and functions are explicitly published.

#### YCP (complete code)

```ycp
{
  module "M";

  import "String";

  global integer i = 42;

  global integer f() {
    return 42;
  }

  void M() {
    y2milestone("M1");
  }
}
```

#### Ruby (complete code)

```ruby
# encoding: utf-8

require "yast"

module Yast
  class MClass < Module
    def main
      Yast.import "String"

      @i = 42
      M()
    end

    def f
      42
    end

    def M
      Builtins.y2milestone("M1")

      nil
    end

    publish :variable => :i, :type => "integer"
    publish :function => :f, :type => "integer ()"
  end

  M = MClass.new
  M.main
end
```

Other
-----

### Comments

Y2R translates comments before statements and after them.

#### YCP (fragment)

```ycp
// before
y2milestone("M1"); // after
```

#### Ruby (fragment)

```ruby
# before
Builtins.y2milestone("M1") # after
```

Y2R preserves whitespace between statements.

#### YCP (fragment)

```ycp
y2milestone("M1");

y2milestone("M2");
```

#### Ruby (fragment)

```ruby
Builtins.y2milestone("M1")

Builtins.y2milestone("M2")
```

Y2R handles all kinds of YCP comments correctly.

#### YCP (fragment)

```ycp
{
  # hash

  // one line

  /* multiple
     lines */

  /*
   * multiple
   * lines
   */
  y2milestone("M1");
}
```

#### Ruby (fragment)

```ruby
# hash

# one line

# multiple
#    lines

# multiple
# lines
Builtins.y2milestone("M1")
```

Y2R translates YCP documentation comments into [YARD](http://yardoc.org/).

#### YCP (complete code)

```ycp
{
  /**
   * Function that adds three numbers.
   *
   * @param a first number to add
   * @param b second number to add
   * @param c third number to add
   * @return sum of the numbers
   */
  integer f(integer a, integer b, integer c) {
    return a + b + c;
  }
}
```

#### Ruby (complete code)

```ruby
# encoding: utf-8

module Yast
  class DefaultClient < Client
    # Function that adds three numbers.
    #
    # @param [Fixnum] a first number to add
    # @param [Fixnum] b second number to add
    # @param [Fixnum] c third number to add
    # @return sum of the numbers
    def f(a, b, c)
      Ops.add(Ops.add(a, b), c)
    end
  end
end

Yast::DefaultClient.new.main
```
