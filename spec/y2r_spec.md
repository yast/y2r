Y2R Compiler Specification
==========================

This document specifies how [Y2R](https://github.com/yast/y2r) translates
various
[YCP](http://doc.opensuse.org/projects/YaST/SLES10/tdg/Book-YCPLanguage.html)
constructs into Ruby. It serves both as a human-readable documentation and as an
executable specification. Technically, this is implemented by translating this
document from [Markdown](http://daringfireball.net/projects/markdown/) into
[RSpec](http://rspec.info/).

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
    * [Type Conversions](#type-conversions)
    * [Builtin Calls](#builtin-calls)
    * [`_` Calls](#_-calls)
    * [Function Calls](#function-calls)
    * [Function References Calling](#function-references-calling)
    * [Comparison Operators](#comparison-operators)
    * [Arithmetic Operators](#arithmetic-operators)
    * [Bitwise Operators](#bitwise-operators)
    * [Logical Operators](#logical-operators)
    * [Ternary Operator](#ternary-operator)
    * [Index Operator](#index-operator)
    * [Double Quote Operator](#double-quote-operator)
  * [Statements](#statements)
    * [`import` Statement](#import-statement)
    * [`textdomain` Statement](#textdomain-statement)
    * [Assignments](#assignments)
    * [`return` Statement](#return-statement)
    * [`break` Statement](#break-statement)
    * [`continue` Statement](#continue-statement)
    * [Function Definitions](#function-definitions)
    * [Statement Blocks](#statement-blocks)
    * [`if` Statement](#if-statement)
    * [`switch` Statement](#switch-statement)
    * [`while` Statement](#while-statement)
    * [`do` Statement](#do-statement)
    * [`repeat` Statement](#repeat-statement)
    * [Clients](#clients)
    * [Modules](#modules)
  * [Other](#other)
    * [Comments](#comments)

Values
------

Y2R translates most YCP values into their Ruby eqivalents. Those that don't have
any are translated as instances of special classes.

### Voids

Y2R translates YCP `nil` as Ruby `nil`.

#### YCP (fragment)

```ycp
void v = nil;
```

#### Ruby (fragment)

```ruby
v = nil
```

### Booleans

Y2R translates YCP booleans as Ruby booelans.

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
float f1 = 42.;
float f2 = 42.1;
```

#### Ruby (fragment)

```ruby
f1 = 42.0
f2 = 42.1
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
tre translated code is in UTF-8 too, so the conversion is lossless.

#### YCP (fragment)

```ycp
string s = "abcd";
```

#### Ruby (fragment)

```ruby
s = "abcd"
```

### Paths

Y2R translates YCP paths as calls to the `Yast.path` method, which creates an
instance of the `Yast::Path` class.

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

Y2R translates YCP terms as calls to the `Yast.term` method, which creates an
instance of the `Yast::Term` class. If term is from list of known UI terms, then
its shortcut is created.

#### YCP (fragment)

```ycp
term t1 = `a();
term t2 = `a(42, 43, 44);
term ui = `HBox(`opt(`disabled), `Empty());
```

#### Ruby (fragment)

```ruby
t1 = term(:a)
t2 = term(:a, 42, 43, 44)
ui = HBox(Opt(:disabled), Empty())
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

Y2R translates YCP function references as calls to the `fun_ref` method, which
creates an instance of the `Yast::FunRef` class.

#### YCP (complete code)

```ycp
{
  void f() {
    return;
  }

  void () fref = f;
}
```

#### Ruby (complete code)

```ruby
# encoding: utf-8

# Translated by Y2R (https://github.com/yast/y2r).
#
# Original file: default.ycp

module Yast
  class DefaultClient < Client
    def main
      @fref = fun_ref(method(:f), "void ()")
      nil
    end
    def f
      return
    end
  end
end

Yast::DefaultClient.new.main
```

Expressions
-----------

Y2R translates YCP expressions into Ruby expressions.

### Variables

Y2R translates YCP local variables as Ruby local variables.

#### YCP (complete code)

```ycp
{
  void f() {
    integer i = 42;
    integer j = i;
  }
}
```

#### Ruby (complete code)

```ruby
# encoding: utf-8

# Translated by Y2R (https://github.com/yast/y2r).
#
# Original file: default.ycp

module Yast
  class DefaultClient < Client
    def f
      i = 42
      j = i
    end
  end
end

Yast::DefaultClient.new.main
```

Y2R translates YCP variables at client toplevel as Ruby instance variables.

#### YCP (complete code)

```ycp
{
  integer i = 42;
  integer j = i;
}
```

#### Ruby (complete code)

```ruby
# encoding: utf-8

# Translated by Y2R (https://github.com/yast/y2r).
#
# Original file: default.ycp

module Yast
  class DefaultClient < Client
    def main
      @i = 42
      @j = @i
      nil
    end
  end
end

Yast::DefaultClient.new.main
```

Y2R translates YCP variables at module toplevel as Ruby instance variables.

#### YCP (complete code)

```ycp
{
  module "M";

  integer i = 42;
  integer j = i;

  global integer k = 42;
  global integer l = i;
}
```

#### Ruby (complete code)

```ruby
# encoding: utf-8

# Translated by Y2R (https://github.com/yast/y2r).
#
# Original file: default.ycp

require "yast"

module Yast
  class MClass < Module
    def main
      @i = 42
      @j = @i

      @k = 42
      @l = @i
    end
    publish :variable => :k, :type => "integer"
    publish :variable => :l, :type => "integer"
  end

  M = MClass.new
  M.main
end
```

Y2R uses suffixes to disambiguate variable aliases in blocks.

#### YCP (complete code)

```ycp
{
  void f() {
    integer i = 42;

    block<void> b = { integer i = 43; };
  }
}
```

#### Error Message

```ruby
# encoding: utf-8

# Translated by Y2R (https://github.com/yast/y2r).
#
# Original file: default.ycp

module Yast
  class DefaultClient < Client
    def f
      i = 42

      b = lambda { i2 = 43 }
    end
  end
end

Yast::DefaultClient.new.main
```

Y2R uses suffixes to disambiguate variable aliases in statement blocks.
#### YCP (complete code)

```ycp
{
  void f() {
    integer i = 42;

    {
      integer i = 43;
    }
  }
}
```

#### Error Message

```ruby
# encoding: utf-8

# Translated by Y2R (https://github.com/yast/y2r).
#
# Original file: default.ycp

module Yast
  class DefaultClient < Client
    def f
      i = 42

      i2 = 43
    end
  end
end

Yast::DefaultClient.new.main
```

### Type Conversions

Y2R translates YCP type conversions as calls of the `Yast::Convert.convert`
method or shortcut `Yast::Convert.to_<type>` if given shortcut exists.


#### YCP (fragment)

```ycp
float f  = (float) 42;
any a    = "string";
string s = (string) a;
```

#### Ruby (fragment)

```ruby
f = Convert.convert(42, :from => "integer", :to => "float")
a = "string"
s = Convert.to_string(a)
```

### Builtin Calls

Y2R translates YCP builtin calls as calls of methods in the `Yast::Builtins`,
`Yast::SCR` and `Yast::WFM` modules. These reimplement the behavior of all YCP
builtins in Ruby.

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

# Translated by Y2R (https://github.com/yast/y2r).
#
# Original file: default.ycp

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

### `_` Calls

Y2R translates YCP `_` calls as calls of the `_` method.

#### YCP (complete code)

```ycp
{
  textdomain "helloworld";

  string s = _("Hello, world!");
}
```

#### Ruby (complete code)

```ruby
# encoding: utf-8

# Translated by Y2R (https://github.com/yast/y2r).
#
# Original file: default.ycp

module Yast
  class DefaultClient < Client
    def main
      textdomain "helloworld"

      @s = _("Hello, world!")
      nil
    end
  end
end

Yast::DefaultClient.new.main
```

### Function Calls

Y2R translates YCP function calls of toplevel functions as Ruby method calls.

```ycp
{
  integer f1() {
    return 42;
  }

  integer f2(list a, list b, list c) {
    return 42;
  }

  integer f3(list& a, list& b, list& c) {
    return 42;
  }

  f1();

  list a = ["a"];
  list b = ["b"];
  list c = ["c"];

  f2(a, b, c);
  f3(a, b, c);
}
```

#### Ruby (complete code)

```ruby
# encoding: utf-8

# Translated by Y2R (https://github.com/yast/y2r).
#
# Original file: default.ycp

module Yast
  class DefaultClient < Client
    def main
      f1

      @a = ["a"]
      @b = ["b"]
      @c = ["c"]

      f2(@a, @b, @c)
      (
        a_ref = arg_ref(@a);
        b_ref = arg_ref(@b);
        c_ref = arg_ref(@c);
        f3_result = f3(a_ref, b_ref, c_ref);
        @a = a_ref.value;
        @b = b_ref.value;
        @c = c_ref.value;
        f3_result
      )
      nil
    end
    def f1
      return 42
    end

    def f2(a, b, c)
      a = deep_copy(a)
      b = deep_copy(b)
      c = deep_copy(c)
      return 42
    end

    def f3(a, b, c)
      return 42
    end
  end
end

Yast::DefaultClient.new.main
```

Y2R translates YCP function calls of nested functions as invoking the `call`
method on them.

```ycp
{
  void outer() {
    integer f1() {
      return 42;
    }

    integer f2(list a, list b, list c) {
      return 42;
    }

    integer f3(list& a, list& b, list& c) {
      return 42;
    }

    f1();

    list a = ["a"];
    list b = ["b"];
    list c = ["c"];

    f2(a, b, c);
    f3(a, b, c);
  }
}
```

#### Ruby (complete code)

```ruby
# encoding: utf-8

# Translated by Y2R (https://github.com/yast/y2r).
#
# Original file: default.ycp

module Yast
  class DefaultClient < Client
    def outer
      f1 = lambda { return 42 }

      f2 = lambda do |a2, b2, c2|
        a2 = deep_copy(a2)
        b2 = deep_copy(b2)
        c2 = deep_copy(c2)
        return 42
      end

      f3 = lambda { |a2, b2, c2| return 42 }

      f1.call

      a = ["a"]
      b = ["b"]
      c = ["c"]

      f2.call(a, b, c)
      (
        a_ref = arg_ref(a);
        b_ref = arg_ref(b);
        c_ref = arg_ref(c);
        f3_result = f3.call(a_ref, b_ref, c_ref);
        a = a_ref.value;
        b = b_ref.value;
        c = c_ref.value;
        f3_result
      )
    end
  end
end

Yast::DefaultClient.new.main
```

### Function References Calling

Y2R translates calling of YCP Function References as invoking the `call` method
on them.

#### YCP (complete code)

```ycp
{
  void f() {
    return;
  }

  void () fref = f;
  fref();
}
```

#### Ruby (complete code)

```ruby
# encoding: utf-8

# Translated by Y2R (https://github.com/yast/y2r).
#
# Original file: default.ycp

module Yast
  class DefaultClient < Client
    def main
      @fref = fun_ref(method(:f), "void ()")
      @fref.call
      nil
    end
    def f
      return
    end
  end
end

Yast::DefaultClient.new.main
```

### Comparison Operators

Y2R translates YCP comparison operators as calls of methods in the `Yast::Ops`
module that implement their behavior or ruby equivalent if behavior is same in
all cases.

#### YCP (fragment)

```ycp
boolean b1 = 42 == 43;
boolean b2 = 42 != 43;
boolean b3 = 42 < 43;
boolean b4 = 42 > 43;
boolean b5 = 42 <= 43;
boolean b6 = 42 >= 43;
```

#### Ruby (fragment)

```ruby
b1 = 42 == 43
b2 = 42 != 43
b3 = Ops.less_than(42, 43)
b4 = Ops.greater_than(42, 43)
b5 = Ops.less_or_equal(42, 43)
b6 = Ops.greater_or_equal(42, 43)
```

### Arithmetic Operators

Y2R translates YCP arithmetic operators as calls of methods in the `Yast::Ops`
module that implement their behavior. Equivalent Ruby operators can be used when
it is safe - Y2R is sure that no operand is `nil`.

#### YCP (fragment)

```ycp
# Using a variable defeats constant propagation.
integer i  = 42;

integer i1 = -i;
integer i2 = 42 + 43;
integer i3 = 42 - 43;
integer i4 = 42 * 43;
integer i5 = 42 / 43;
integer i6 = 42 % 43;

i2 = i + 43;
i3 = i - 43;
i4 = i * 43;
i5 = i / 43;
i6 = i % 43;

```

#### Ruby (fragment)

```ruby
# Using a variable defeats constant propagation.
i = 42

i1 = Ops.unary_minus(i)
i2 = 42 + 43
i3 = 42 - 43
i4 = 42 * 43
i5 = 42 / 43
i6 = 42 % 43

i2 = Ops.add(i, 43)
i3 = Ops.subtract(i, 43)
i4 = Ops.multiply(i, 43)
i5 = Ops.divide(i, 43)
i6 = Ops.modulo(i, 43)
```

### Bitwise Operators

Y2R translates YCP bitwise operators as calls of methods in the `Yast::Ops`
module that implement their behavior. Equivalent Ruby operators can be used when
it is safe - Y2R is sure that no operand is `nil`.

#### YCP (fragment)

```ycp
integer i1 = ~42;
integer i2 = 42 & 43;
integer i3 = 42 | 43;
integer i4 = 42 ^ 43;
integer i5 = 42 << 43;
integer i6 = 42 >> 43;
integer i = 42;
i1 = ~i;
i2 = i & 43;
i3 = i | 43;
i4 = i ^ 43;
i5 = i << 43;
i6 = i >> 43;

```

#### Ruby (fragment)

```ruby
i1 = ~42
i2 = 42 & 43
i3 = 42 | 43
i4 = 42 ^ 43
i5 = 42 << 43
i6 = 42 >> 43
i = 42
i1 = Ops.bitwise_not(i)
i2 = Ops.bitwise_and(i, 43)
i3 = Ops.bitwise_or(i, 43)
i4 = Ops.bitwise_xor(i, 43)
i5 = Ops.shift_left(i, 43)
i6 = Ops.shift_right(i, 43)
```

### Logical Operators

Y2R translates YCP logical operators to their Ruby equivalents.

#### YCP (fragment)

```ycp
# Using a variable defeats constant propagation.
boolean b = true;

boolean b1 = !b;
boolean b2 = true && false;
boolean b3 = true || false;
```

#### Ruby (fragment)

```ruby
# Using a variable defeats constant propagation.
b = true

b1 = !b
b2 = true && false
b3 = true || false
```

### Ternary Operator

Y2R translates YCP ternary operator as Ruby ternary operator.

#### YCP (fragment)

```ycp
# Using a variable defeats constant propagation.
boolean b = true;
integer i = b ? 42 : 43;
```

#### Ruby (fragment)

```ruby
# Using a variable defeats constant propagation.
b = true
i = b ? 42 : 43
```

### Index Operator

Y2R translates YCP index operator as a call of a method in the `Yast::Ops`
module that implements its behavior. There is no equivalent operator in Ruby.

Single-element index is passed as it is, multiple-element index is passed as an
array. The default value is passed only if it is non-`nil`.

#### YCP (fragment)

```ycp
integer i = [42, 43, 44][1]:0;
integer j = [[42, 43, 44]][0, 1]:0;
integer k = [42, 43, 44][1]:nil;
```

#### Ruby (fragment)

```ruby
i = Ops.get([42, 43, 44], 1, 0)
j = Ops.get([[42, 43, 44]], [0, 1], 0)
k = Ops.get([42, 43, 44], 1)
```

### Double Quote Operator

Y2R translates YCP double quote operator as a Ruby lambda.

#### YCP (fragment)

```ycp
block<integer> b = ``(42);
```

#### Ruby (fragment)

```ruby
b = lambda { 42 }
```

Statements
----------

Y2R translates YCP statements into Ruby statements.

### `import` Statement

Y2R translates YCP `import` statement as a `Yast.import` call.

#### YCP (fragment)

```ycp
import "String";
```

#### Ruby (fragment)

```ruby
Yast.import "String"
```

### `textdomain` Statement

Y2R translates YCP `textdomain` statement as a call to set the text domain.

#### YCP (complete code)

```ycp
{
  textdomain "users";
}
```

#### Ruby (complete code)

```ruby
# encoding: utf-8

# Translated by Y2R (https://github.com/yast/y2r).
#
# Original file: default.ycp

module Yast
  class DefaultClient < Client
    def main
      textdomain "users"
      nil
    end
  end
end

Yast::DefaultClient.new.main
```

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

Y2R translates YCP assignments with brackets as a call of a method in the
`Yast::Ops` module that implements its behavior. There is no equivalent operator
in Ruby.

#### YCP (fragment)

```ycp
list l = [42, 43, 44];

l[0] = [45];
l[0,0] = 42;
```

#### Ruby (fragment)

```ruby
l = [42, 43, 44]

Ops.set(l, 0, [45])
Ops.set(l, [0, 0], 42)
```

### `return` Statement

Y2R translates YCP `return` statement inside functions as Ruby `return`
statement.

#### YCP (complete code)

```ycp
{
  void f1() {
    return;
  }

  integer f2() {
    return 42;
  }
}
```

#### Ruby (complete code)

```ruby
# encoding: utf-8

# Translated by Y2R (https://github.com/yast/y2r).
#
# Original file: default.ycp

module Yast
  class DefaultClient < Client
    def f1
      return
    end

    def f2
      return 42
    end
  end
end

Yast::DefaultClient.new.main
```

Y2R translates YCP `return` statement inside block as Ruby `next` statement.

#### YCP (fragment)

```ycp
# A variable prevents translating the block as YEReturn.
maplist(integer i, [42, 43, 44], { integer j = 42; return j; });
foreach(integer i, [42, 43, 44], { integer j = 42; return; });
```

#### Ruby (fragment)

```ruby
# A variable prevents translating the block as YEReturn.
Builtins.maplist([42, 43, 44]) do |i|
  j = 42
  next j
end
Builtins.foreach([42, 43, 44]) do |i|
  j = 42
  next
end
```

### `break` Statement

Y2R translates YCP `break` statement inside a while statement as Ruby `next`
statement.

```ycp
while (true) {
  break;
}
```

#### Ruby (fragment)

```ruby
while true
  break
end
```

Y2R translates YCP `break` statement inside a repeat statement as Ruby `next`
statement.

```ycp
repeat {
  break;
} until(true);
```

#### Ruby (fragment)

```ruby
begin
  break
end until true
```

Y2R translates YCP `break` statement inside block as Ruby `raise` statement that
raises `Yast::Break`.

```ycp
foreach(integer i, [42, 43, 44], { break; });
```

#### Ruby (fragment)

```ruby
Builtins.foreach([42, 43, 44]) { |i| raise Break }
```

### `continue` Statement

Y2R translates YCP `continue` statement inside loops as Ruby `next` statement.

```ycp
while (true) {
  continue;
}
```

#### Ruby (fragment)

```ruby
while true
  next
end
```

Y2R translates YCP `continue` statement inside block as Ruby `next` statement.

```ycp
foreach(integer i, [42, 43, 44], { continue; });
```

#### Ruby (fragment)

```ruby
Builtins.foreach([42, 43, 44]) { |i| next }
```

### Function Definitions

Y2R translates toplevel function definitions as Ruby method definitions. It
maintains pass-by-value semantics for all types except `boolean`, `integer` and
`symbol`, (which are all immutable) and parameters passed by reference.

#### YCP (complete code)

```ycp
{
  integer f1() {
    return 42;
  }

  integer f2(boolean a, boolean b, boolean c) {
    return 42;
  }

  integer f3(integer a, integer b, integer c) {
    return 42;
  }

  integer f4(symbol a, symbol b, symbol c) {
    return 42;
  }

  integer f5(string a, string b, string c) {
    return 42;
  }

  integer f6(path a, path b, path c) {
    return 42;
  }

  integer f7(list& a, list& b, list& c) {
    return 42;
  }

  integer f8(list a, list b, list c) {
    return 42;
  }
}
```

#### Ruby (complete code)

```ruby
# encoding: utf-8

# Translated by Y2R (https://github.com/yast/y2r).
#
# Original file: default.ycp

module Yast
  class DefaultClient < Client
    def f1
      return 42
    end

    def f2(a, b, c)
      return 42
    end

    def f3(a, b, c)
      return 42
    end

    def f4(a, b, c)
      return 42
    end

    def f5(a, b, c)
      return 42
    end

    def f6(a, b, c)
      return 42
    end

    def f7(a, b, c)
      return 42
    end

    def f8(a, b, c)
      a = deep_copy(a)
      b = deep_copy(b)
      c = deep_copy(c)
      return 42
    end
  end
end

Yast::DefaultClient.new.main
```

Y2R translates nested YCP function definitions as Ruby lambdas. It maintains
pass-by-value semantics for all types except `boolean`, `integer` and `symbol`,
(which are all immutable) and parameters passed by reference.

#### YCP (complete code)

```ycp
{
  void outer() {
    integer f1() {
      return 42;
    }

    integer f2(boolean a, boolean b, boolean c) {
      return 42;
    }

    integer f3(integer a, integer b, integer c) {
      return 42;
    }

    integer f4(symbol a, symbol b, symbol c) {
      return 42;
    }

    integer f5(string a, string b, string c) {
      return 42;
    }

    integer f6(path a, path b, path c) {
      return 42;
    }

    integer f7(list& a, list& b, list& c) {
      return 42;
    }

    integer f8(list a, list b, list c) {
      return 42;
    }
  }

}
```

#### Ruby (complete code)

```ruby
# encoding: utf-8

# Translated by Y2R (https://github.com/yast/y2r).
#
# Original file: default.ycp

module Yast
  class DefaultClient < Client
    def outer
      f1 = lambda { return 42 }

      f2 = lambda { |a, b, c| return 42 }

      f3 = lambda { |a, b, c| return 42 }

      f4 = lambda { |a, b, c| return 42 }

      f5 = lambda { |a, b, c| return 42 }

      f6 = lambda { |a, b, c| return 42 }

      f7 = lambda { |a, b, c| return 42 }

      f8 = lambda do |a, b, c|
        a = deep_copy(a)
        b = deep_copy(b)
        c = deep_copy(c)
        return 42
      end
    end
  end
end

Yast::DefaultClient.new.main
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

#### Error Message

```ruby
# encoding: utf-8

# Translated by Y2R (https://github.com/yast/y2r).
#
# Original file: default.ycp

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

Y2R translates YCP `if` statement as Ruby `if` statement.

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

Y2R translates YCP `switch` statement as Ruby `case` statement.

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

Y2R translates YCP `switch` statement as Ruby `case` statement also when the
case/default statements are wrapped a block.

#### YCP (fragment)

```ycp
switch (42) {
  case 42: {
    y2milestone("M1");
    break;
  }

  case 43: {
    y2milestone("M2");
    break;
  }

  case 44: {
    y2milestone("M3");
    return;
  }

  default: {
    y2milestone("M4");
    break;
  }
}
```

#### Ruby (fragment)

```ruby
case 42
  when 42
    Builtins.y2milestone("M1")
  when 43
    Builtins.y2milestone("M2")
  when 44
    Builtins.y2milestone("M3")
    return
  else
    Builtins.y2milestone("M4")
end
```

Y2R does not support cases without a break or return at the end. This is mostly
because Ruby doesn't have any suitable equivalent construct.

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

Y2R does not support cases without a break or return at the end also when the
case statements are wrapped in a block.

#### YCP (fragment)

```ycp
switch (42) {
  case 42: {
    y2milestone("M1");
  }
}
```

#### Error Message

```error
Case without a break or return encountered. These are not supported.
```

### `while` Statement

Y2R translates YCP `while` statement as Ruby `while` statement.

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

Y2R translates YCP `do` statement as Ruby `while` statement.

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

Y2R translates YCP `repeat` statement as Ruby `until` statement.

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

### Clients

Y2R translates YCP clients as Ruby classes that are instantiated.

#### YCP (complete code)

```ycp
{
  import "String";

  integer i = 42;
  global integer j = 43;

  integer f() {
    return 42;
  }

  global integer g() {
    return 43;
  }
}
```

#### Ruby (complete code)

```ruby
# encoding: utf-8

# Translated by Y2R (https://github.com/yast/y2r).
#
# Original file: default.ycp

module Yast
  class DefaultClient < Client
    def main
      Yast.import "String"

      @i = 42
      @j = 43
      nil
    end
    def f
      return 42
    end

    def g
      return 43
    end
  end
end

Yast::DefaultClient.new.main
```

### Modules

Y2R translates YCP modules as Ruby classes that are instantiated.

#### YCP (complete code)

```ycp
{
  module "M";

  import "String";

  integer i = 42;
  global integer j = 43;

  integer f() {
    return 42;
  }

  global integer g() {
    return 43;
  }

  void M() {
    y2milestone("M1");
  }
}
```

#### Ruby (complete code)

```ruby
# encoding: utf-8

# Translated by Y2R (https://github.com/yast/y2r).
#
# Original file: default.ycp

require "yast"

module Yast
  class MClass < Module
    def main
      Yast.import "String"

      @i = 42
      @j = 43
      M()
    end
    def f
      return 42
    end

    def g
      return 43
    end

    def M
      Builtins.y2milestone("M1")
    end
    publish :variable => :j, :type => "integer"
    publish :function => :g, :type => "integer ()"
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

Y2R handles all kinds of comments correctly.

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
