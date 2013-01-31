Y2R Compiler Specification
==========================

This document specifies how [Y2R](https://github.com/yast/y2r) translates
various YCP constructs into Ruby. It serves both as a human-readable
documentation and as an executable specification. Technically, this is
implemented by translating the document from
[Markdown](http://daringfireball.net/projects/markdown/) into
[RSpec](http://rspec.info/).

Values
------

Y2R translates most YCP values into their Ruby eqivalents. Those that don't have
any are translated as instances of special classes.

### Voids

Y2R translates YCP `nil` as Ruby `nil`.

#### YCP Code

```ycp
{
  void v = nil;
}
```

#### Ruby Code

```ruby
v = nil
```

### Booleans

Y2R translates YCP booleans as Ruby booelans.

#### YCP Code

```ycp
{
  boolean t = true;
  boolean f = false;
}
```

#### Ruby Code

```ruby
t = true
f = false
```

### Integers

Y2R translates YCP integers as `Fixnum`s. It ignores the issue of overflow (YCP
integers can overflow while `Fixnum`s are just converted into `Bignum`s).

#### YCP Code

```ycp
{
  integer i = 42;
}
```

#### Ruby Code

```ruby
i = 42
```

### Floats

Y2R translates YCP floats as Ruby floats. Both are stored as `double` on the C
level so the conversion is lossless.

#### YCP Code

```ycp
{
  float f1 = 42.;
  float f2 = 42.1;
}
```

#### Ruby Code

```ruby
f1 = 42.0
f2 = 42.1
```

### Symbols

Y2R translates YCP symbols as Ruby symbols. YCP symbols are always composed of
alphanumeric characters and uderscores, which means the equivalent Ruby symbols
will always have US-ASCII encoding.

#### YCP Code

```ycp
{
  symbol s = `abcd;
}
```

#### Ruby Code

```ruby
s = :abcd
```

### Strings

Y2R translates YCP strings as Ruby strings. YCP strings use UTF-8 internally so
the conversion is lossless. TODO: Add encoding header to translated files,
explain a bit more.

#### YCP Code

```ycp
{
  string s = "abcd";
}
```

#### Ruby Code

```ruby
s = 'abcd'
```

### Paths

Y2R translates YCP paths as instances of the `YCP::Path` class. TODO: What about
encoding?

#### YCP Code

```ycp
{
  path p = .abcd;
}
```

#### Ruby Code

```ruby
p = Path.new('.abcd')
```

### Lists

Y2R translates YCP lists as Ruby arrays.

#### YCP Code

```ycp
{
  list l1 = [];
  list l2 = [42, 43, 44];
}
```

#### Ruby Code

```ruby
l1 = []
l2 = [42, 43, 44]
```

### Maps

Y2R translates YCP maps as Ruby hashes.

#### YCP Code

```ycp
{
  map m1 = $[];
  map m2 = $[`a: 42, `b: 43, `c: 44];
}
```

#### Ruby Code

```ruby
m1 = {}
m2 = { :a => 42, :b => 43, :c => 44 }
```

### Terms

Y2R translates YCP terms as instances of the `YCP::Term` class

#### YCP Code

```ycp
{
  term t1 = `a();
  term t2 = `a(42, 43, 44);
}
```

#### Ruby Code

```ruby
t1 = Term.new(:a)
t2 = Term.new(:a, 42, 43, 44)
```

Expressions
-----------

Y2R translates YCP expressions into Ruby expressions.

### Variables

Y2R translates YCP variables as Ruby local variables.

#### YCP Code

```ycp
{
  integer i = 42;
  integer j = i;
}
```

#### Ruby Code

```ruby
i = 42
j = i
```

### Conversion

Y2R translates YCP conversion calls to ruby Convert utility. It handles both,
explicit and implicit calls.

#### YCP Code

```ycp
{
  integer i = 42;
  float   j = (float) i;
  list<any> m = [1];
  integer l = m[0]:-1;
}
```

#### Ruby Code

```ruby
i = 42
j = Convert.convert(i, :from => 'integer', :to => 'float')
m = [1]
l = Convert.convert(Ops.index(m, [0], -1), :from => 'any', :to => 'integer')
```


### Builtin Calls

Y2R translates YCP builtin calls as calls of methods in the `YCP::Builtins`
module. These reimplement the behavior of all YCP builtins in Ruby.

#### YCP Code

```ycp
{
  time();
  random(100);
}
```

#### Ruby Code

```ruby
Builtins.time()
Builtins.random(100)
```

### `_` Calls

Y2R translates YCP `_` calls as calls of FastGettext's `_` method.

#### YCP Code

```ycp
{
  textdomain "helloworld";

  string s = _("Hello, world!");
}
```

#### Ruby Code

```ruby
FastGettext.text_domain = 'helloworld'

s = _('Hello, world!')
```

### Function Calls

Y2R translates YCP function calls as Ruby method calls.

#### YCP Code

```ycp
{
  UI::OpenDialog(`Label("Hello, world!"));
}
```

#### Ruby Code

```ruby
YCP.import('UI')

UI.OpenDialog(Term.new(:Label, 'Hello, world!'))
```

### Comparison Operators

Y2R translates YCP comparison operators as calls of methods in the `YCP::Ops`
module that implement their behavior. Equivalent Ruby operators can't be used
because their behavior differs from the behavior of YCP operators in some cases.

#### YCP Code

```ycp
{
  boolean b1 = 42 == 43;
  boolean b2 = 42 != 43;
  boolean b3 = 42 < 43;
  boolean b4 = 42 > 43;
  boolean b5 = 42 <= 43;
  boolean b6 = 42 >= 43;
}
```

#### Ruby Code

```ruby
b1 = Ops.equal(42, 43)
b2 = Ops.not_equal(42, 43)
b3 = Ops.less_than(42, 43)
b4 = Ops.greater_than(42, 43)
b5 = Ops.less_or_equal(42, 43)
b6 = Ops.greater_or_equal(42, 43)
```

### Arithmetic Operators

Y2R translates YCP arithmetic operators as calls of methods in the `YCP::Ops`
module that implement their behavior. Equivalent Ruby operators can't be used
because their behavior differs from the behavior of YCP operators in some cases.

#### YCP Code

```ycp
{
  # Using a variable defeats constant propagation.
  integer i  = 42;

  integer i1 = -i;
  integer i2 = 42 + 43;
  integer i3 = 42 - 43;
  integer i4 = 42 * 43;
  integer i5 = 42 / 43;
  integer i6 = 42 % 43;
}
```

#### Ruby Code

```ruby
i = 42
i1 = Ops.unary_minus(i)
i2 = Ops.add(42, 43)
i3 = Ops.subtract(42, 43)
i4 = Ops.multiply(42, 43)
i5 = Ops.divide(42, 43)
i6 = Ops.modulo(42, 43)
```

### Bitwise Operators

Y2R translates YCP bitwise operators as calls of methods in the `YCP::Ops`
module that implement their behavior. Equivalent Ruby operators can't be used
because their behavior differs from the behavior of YCP operators in some cases.

#### YCP Code

```ycp
{
  integer i1 = ~42;
  integer i2 = 42 & 43;
  integer i3 = 42 | 43;
  integer i4 = 42 ^ 43;
  integer i5 = 42 << 43;
  integer i6 = 42 >> 43;
}
```

#### Ruby Code

```ruby
i1 = Ops.bitwise_not(42)
i2 = Ops.bitwise_and(42, 43)
i3 = Ops.bitwise_or(42, 43)
i4 = Ops.bitwise_xor(42, 43)
i5 = Ops.shift_left(42, 43)
i6 = Ops.shift_right(42, 43)
```

### Logical Operators

Y2R translates YCP logical operators as calls of methods in the `YCP::Ops`
module that implement their behavior. Equivalent Ruby operators can't be used
because their behavior differs from the behavior of YCP operators in some cases.

#### YCP Code

```ycp
{
  # Using a variable defeats constant propagation.
  boolean b = true;

  boolean b1 = !b;
  boolean b2 = true && false;
  boolean b3 = true || false;
}
```

#### Ruby Code

```ruby
b = true
b1 = Ops.logical_not(b)
b2 = Ops.logical_and(true, false)
b3 = Ops.logical_or(true, false)
```

### Ternary Operator

Y2R translates YCP ternary operator as Ruby ternary operator.

#### YCP Code

```ycp
{
  # Using a variable defeats constant propagation.
  boolean b = true;
  integer i = b ? 42 : 43;
}
```

#### Ruby Code

```ruby
b = true
i = b ? 42 : 43
```

### Index Operator

Y2R translates YCP index operator as a call of a method in the `YCP::Ops` module
that implements its behavior. There is no equivalent operator in Ruby.

#### YCP Code

```ycp
{
  integer i = [42, 43, 44][1]:0;
}
```

#### Ruby Code

```ruby
i = Ops.index([42, 43, 44], [1], 0)
```

Statements
----------

Y2R translates YCP statements into Ruby statements.

### `import` Statement

Y2R translates YCP `import` statement as a `YCP.import` call.

#### YCP Code

```ycp
{
  import "String";
}
```

#### Ruby Code

```ruby
YCP.import('String')

```

### `textdomain` Statement

Y2R translates YCP `textdomain` statement as an assignment to
`FastGettext.text_domain`.

#### YCP Code

```ycp
{
  textdomain "users";
}
```

#### Ruby Code

```ruby
FastGettext.text_domain = 'users'

```

### Function Definitions

Y2R translates YCP function definitions as Ruby method definitions.

#### YCP Code

```ycp
{
  integer f1() {
    return 42;
  }

  integer f2(integer a, integer b, integer c) {
    return 42;
  }
}
```

#### Ruby Code

```ruby
def f1()
  return 42
end

def f2(a, b, c)
  return 42
end

```

### `if` Statement

Y2R translates YCP `if` statement as Ruby `if` statement.

#### YCP Code

```ycp
{
  if (true)
    y2milestone("M1");

  if (true)
    y2milestone("M2");
  else
    y2milestone("M3");
}
```

#### Ruby Code

```ruby
if true
  Builtins.y2milestone('M1')
end
if true
  Builtins.y2milestone('M2')
else
  Builtins.y2milestone('M3')
end
```

### `while` Statement

Y2R translates YCP `while` statement as Ruby `while` statement.

#### YCP Code

```ycp
{
  while (true)
    y2milestone("M1");
}
```

#### Ruby Code

```ruby
while true
  Builtins.y2milestone('M1')
end
```
