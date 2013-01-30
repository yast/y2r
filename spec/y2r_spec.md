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
  float f = 42.0;
}
```

#### Ruby Code

```ruby
f = 42.0
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
  list l = [42, 43, 44];
}
```

#### Ruby Code

```ruby
l = [42, 43, 44]
```

### Maps

Y2R translates YCP maps as Ruby hashes.

#### YCP Code

```ycp
{
  map m = $[`a: 42, `b: 43, `c: 44];
}
```

#### Ruby Code

```ruby
m = { :a => 42, :b => 43, :c => 44 }
```

### Terms

Y2R translates YCP terms as instances of the `YCP::Term` class

#### YCP Code

```ycp
{
  term t = `a(42, 43, 44);
}
```

#### Ruby Code

```ruby
t = Term.new(:a, 42, 43, 44)
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

### Builtin Calls

Y2R translates YCP builtin calls as calls of methods in the `YCP::Builtins`
module. These reimplement the behavior of all YCP builtins in Ruby.

#### YCP Code

```ycp
{
  y2milestone("M1");
}
```

#### Ruby Code

```ruby
Builtins.y2milestone('M1')
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

### Unary Operators

Y2R translates YCP unary operators as calls of methods in the `YCP::Ops` module
that implement their behavior. Equivalent Ruby operators can't be used because
their behavior differs from the behavior of YCP operators in some cases.

#### YCP Code

```ycp
{
  # Using a variable defeats constant propagation.
  integer i = 42;
  integer j = -i;
}
```

#### Ruby Code

```ruby
i = 42
j = Ops.unary_minus(i)
```

### Binary Operators

Y2R translates YCP binary operators as calls of methods in the `YCP::Ops` module
that implement their behavior. Equivalent Ruby operators can't be used because
their behavior differs from the behavior of YCP operators in some cases.

#### YCP Code

```ycp
{
  integer i = 42 + 43;
}
```

#### Ruby Code

```ruby
i = Ops.add(42, 43)
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
  integer f(integer a, integer b, integer c) {
    return 42;
  }
}
```

#### Ruby Code

```ruby
def f(a, b, c)
  return 42
end

```

### `if` Statement

Y2R translates YCP `if` statement as Ruby `if` statement.

#### YCP Code

```ycp
{
  if (true)
    y2milestone("abcd");
  else
    y2milestone("efgh");
}
```

#### Ruby Code

```ruby
if true
  Builtins.y2milestone('abcd')
else
  Builtins.y2milestone('efgh')
end
```

### `while` Statement

Y2R translates YCP `while` statement as Ruby `while` statement.

#### YCP Code

```ycp
{
  while (true)
    y2milestone("abcd");
}
```

#### Ruby Code

```ruby
while true
  Builtins.y2milestone('abcd')
end
```
