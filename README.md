kolumny
=======

`kolumny` - declarative multi-file column oriented command line processing engine


What is it?
-----------

It is a simple command line tool that was designed to preprocess and process
scientific data files and to be used together with `gnuplot` program.

It can be used for your various processing needs when you have text files with
numeric data, especially organized in rows. It is excellent for processing `tsv`
and `csv` files, processing outputs of other tools, time series analysis, etc. It
was initially (2010-2012) used for preprocessing and processing spectroscopic
data in biochemical research.

It augments nicely other Unix text processing tools like `grep`, `awk`, `sed`,
`cat`, `cut`, `paste`, `bc` and ad-hoc solutions with `perl` or `python`. And in
some cases completely replaces them for numerical data processing. Most notably
it is easier and more flexible to use than `awk` or `paste`, especially when
using with multiple files at the same time, that should be processes in parallel
with some computations between files need to be performed at the same time.
Usually this can't be done easily in `gnuplot` either (i.e. plot a sum of two
timeseries, with each time series coming from a different file).


Magic
-----

Here is very quick glimpse what it can do, if you are already familiar with
`gnuplot`.

Lets say two files `d1.txt` and `d2.txt`, are both a text files with some
measurement data. They do have some two line metadata header, and then they
contain 1000 rows of data with each row having 6 columns. Columns are separate by
tabs or a single space. First column being a time and rest of columns being
energy in various channels measured in the same units. Lets additionally assume
that each file correspond to a different total amount of measurements (5 and 7
respectively), and they need to be normalized first before being merged.

Something like this maybe:

d1.txt
```raw
# MESUREMENT 1, 2010-01-01 15:00
# Count 5
0.1 0.57 0.59 0.20 0.30 0.99
0.2 0.80 0.33 0.02 0.73 0.74
0.3 0.48 0.22 0.15 0.57 0.81
0.4 0.10 0.10 0.38 0.73 0.36
0.5 0.87 0.85 0.41 0.66 0.85
0.6 0.01 0.65 0.02 0.80 0.22
0.7 0.89 0.89 0.60 0.17 0.82
0.8 0.20 0.78 0.56 0.35 0.30
...
```


d2.txt
```
# MESUREMENT 1, 2010-01-01 15:00
# Count 5
0.1 0.78 0.34 0.50 0.54 0.45
0.2 0.37 0.65 0.52 0.23 0.10
0.3 0.95 0.13 0.17 0.53 0.21
0.4 0.25 0.55 0.99 0.55 0.94
0.5 0.19 1.00 0.01 0.72 0.29
0.6 0.23 0.32 0.91 0.53 0.30
0.7 0.44 0.77 0.76 0.56 0.66
0.8 0.33 0.40 0.61 0.30 0.84
...
```


If we want to merge these two independent measurement data files to obtain better
statistic, and plot it in we could do this:

```gnuplot
plot "<kolumny d1.txt skip 2 using t1:=1,~a:=2...5 d2.txt s 2 u ~t2:=1,~b:=2...5 ':~check(t1==t2)' ':sum(a)/5+sum(b)/7'" \
    using 1:2 with lines
```

where a single invocation to `kolumny` reads two files in parallel, skips 2 lines
of header of each, ensures first columns match in each line, and outputs first
column and a sum of columns 2-5 from both files as single column.


Output of the `kolumny` sub-process:

```
0.1 0.640571428571
0.2 0.628857142857
0.3 0.538285714286
0.4 0.596285714286
0.5 0.832285714286
0.6 0.580285714286
0.7 0.871428571429
0.8 0.612285714286
...
```


For simpler cases, where there is no header, and we know for sure that data is
aligned between files, and only need processing single columns, maybe this could
work too:

```gnuplot
plot "<kolumny d1.txt using 1,11 d2.txt u 11" u 1:($2+$3) w lp
```

where we use `kolumny` to extract and print column 1 and 11 from first file and
column 11 from a second file, and then use `gnuplot` to add columns 2 and 3 from
the output, effectively adding up columns 11 from both files.

```gnuplot
plot "<kolumny d1.txt using 1,~a:=11 d2.txt u ~b:=11 :a+b" u 1:2 w lp
```

would do the same, with summation happening in the `kolumny` itself using named
variables.

Arbitrary other operations are possible, including multiple variables, reordered
dependencies, vectors, scalars, string outputs, statistical operations, etc.

One can obviously also use `kolumny` as a standalone tool, or from other scripts
and use generated files for further processing.

```
kolumny d.txt u 1,~a:=2...5,x:=6,~y0:=7 :avg(a) :x*y0 > output.txt
```

`kolumny` has many optional features and shortcuts, that allow to express
processing shortly and in flexible manner. It also helps with debugging by giving
reasonable error messages, ability to comment out (and disable) any part of the
argument list, or do computations without printing them, to be used as further
input to other expressions.

The interface is heavily influenced by `gnuplot` `plot` and `fit` commands.

`kolumny` is fast and memory efficient (its memory usage is not dependent on the
size of input data).

## Usage

```text
Usage: kolumny [options]... inputspec...

options:
	--begin python-code
	       : execute Python code after startup
	--end python-code
	       : execute Python code at shutdown
	--gnuplot_begin gnuplot-code
	       : execute gnuplot code after startup
	--fit fit-expression
	       : perform simplified internal fiting (linear, with weights)
	--gnuplot_plot gnuplot-plot-expressions
	       : plot using gnuplot
	--gnuplot_fit gnuplot-fit-expressions
	       : fit usign gnuplot
	--tmpdir path
	       : use path as temporary directory if needed
	--
	       : end options processing here

inputspec - one of:
	filespec [skip N] [using usingspec]
	":expression"

filespec - one of:
	"filepath"       : named file
	"-"              : standard input
	"<shell command" : spawn /bin/sh with given command and read stdout
	                   (this can be multiple commands separated using ';'
	                    or any pipe constructed using | character).
	                    Note: remember about shell escaping rules.
	""               : file from previous inputspec
	
	Note: filepath cannot begin with -, <, #, : or conflict
	      with any keyword like u, using, skip, s.

First element of inputspec (filespec or :expression) can be prefixed
with "#" to disable semantic processing of this file. It will
be not opened, readed, calculated or evaluated in any means.
Still given inputspec need to be syntactically correct.

skip N:           (can be abbreviated to s N)
	N - positive integer number of first lines to skip from input

using usingspec:  (can be abbreviated to u N)
	usingspec of the form:
		u1[,u2][,u3]...
	
	Each u of the form:
		[[~]varname:=]columnsspec
	
	Where
	
	columnspec one of the form:
		N       : positive integer indicating single column number
		          counting from 1
		L...R   : pair of positive integers indicating vector of
		          columns. L marks first column, R last, inclusive.
		          Note that when using later varname for referencing
		          vector's elements L column will be at index 0,
		          L+1 at index 1, etc (just like Python's arrays).
		(pexpr) : where pexpr is any Python expression. column(x)
		          and valid(x) functions can be used to retrieve
		          x'th column (counting from 1), or check if it
		          is valid column number and value there is float.
		          x needs to be expression evaluating to positive
		          integer.
	
	varname : unique variable name to store scalar or vector value.
	          It will be converted to floats. In case of
	          Python expression it will store value of this
	          expression. varname should be valid Python identifier.
	
	~       : do not print, only store value in variable varname
	          for further reference.

:expression of the form:
	:[~][varname:=]pexpr
	
	Where
	
	pexpr     : any Python expression to evaluate, and print.
	
	varname   : unique variable name to store value of pexpr.
	            varname should be valid Python identifier.
	
	~         : do not print pexpr value as a column

Remark: All inputspec (both filespec and :expressions) entries can be
        intermixed in any order, even in case of forward references of
        variable names. Some options can also be presented in any order,
        but relative order of some options is important (for example
        multiple --begin options will be executed in given order).

Note: Remember to escape shell meta-characters so they
      will not be interpreted, by your shell.
```

Examples
--------

In all the examples below we will be working on some hypothetical data files,
that do have rows and columns of numeric values, like this:

`data.txt`:

```text
1.1  3.0 5.0
1.3  3.1 3.0
1.5  2.3 4.0
1.61 2.1 4.0
1.75 1   2
2.0  -3  0.0
1.5  3.14 3.14
1.6  .3e7 -1e8
2.0  3 0 0 0 3 3 0 0
```

There are no arbitrary restrictions on the input values, their precision,
ordering, number of rows or columns. It is up to you what to do with this data,
and `kolumny` provides tools to deal with it.

By default columns are expected to be separate by white spaces (space or tab or
multiplies of them).

By default `kolumny` will print columns on output that are separated by a single
space (` `).

Internally numbers are handled using double precision floating point numbers 
(IEEE 754 standard). Input and output is expected to be in decimal representation
with that similar to output of C's `printf` function. In some situations
`kolumny` also accepts processing of non-float values.


### No input file mode

```
kolumny :10+27
```

Will show a single row, with number `37`.


### Cat mode

```
kolumny file1.txt
```

Will behave similar to `cat file1.txt`.

It will output all columns from file `file1.txt`, but will ensure all values are
floats (numeric values).


### Paste mode

```
kolumny file1.txt file2.txt
```

Will behave similar to `paste file1.txt file2.txt`.

It will output all columns from both files merged on each row. It will also
ensure all values are floats (numeric values).

Note: In this form it will not verify if the number of columns in each file is
consistent between each row. If the first row has 3 values in each file, and
second row has 4 values in first file, and 5 values in a second file, `kolumny`
will output 6 and 9 values in the output rows. To get more consistent results and
check for conditions like that automatically, read the next section
([using option](#using-option)).


### using option

```
kolumny "file1" using 1,4
```

Will output 2 columns: column 1 and 4 from file `file1`.

```
kolumny "data.txt" u 1,4,3,1
```

Will output 4 columns: column 1, 4, 3 and 1 (in this order) from file `data.txt`.

In this respect it is similar to this usage of `awk`:

```
awk '{ print $1, $4, $3, $1; }' data.txt
```

But the main benefit over `awk` is ability to process many files at the same time
in even shorter form:

```
kolumny data1.txt u 1,3 data2.txt u 1,3
```

Will output 4 columns: column 1 and 3 from file `data1.txt` and column 1 and 3
from file `data2.txt`.

For comparison, and assuming `data1.txt` has 5 columns on every row, this could
be achived with this complex `awk` script:

```
paste data1.txt data2.txt | awk '{print $1, $3, $6, $8;}'
```

If the number of columns is not consistent, not known a priori, or changes later
to other number, the `awk` script must be rewritten and error prone mental
arithmetic of column numbering must be repeated (or some extra automation must be
created). This scales very poorly, especially if processing many files, and only
one of them changes column ordering or number of columns.

Note: There must be no spaces around commas or in any other part of `using`.

```
kolumny "data.txt" u 1, 2
```

will NOT output columns 1 and 2 from `data.txt`, and most likely end in execution
error (stray comma in `using`, filename `2` not found, or empty using spec)


```
kolumny "data.txt" u "1, 2"
```

will NOT work either (at least right now), and will result in execution error.

Info: `using` is influenced by `gnuplot` syntax.


### Variables in using and expressions on them

After reading the data in `using` file and using `:=` operator that define
variables, one can process data in arbitary way on per line basis, by writing an
expression and prefixing them with colon (`:`).

```
kolumny "file.dat" using 1,a:=2,b:=3 :a+b
```

Will produce 4 columns: Original columns 1, 2, 3 from `file.dat`, and an extra
4th column that is a sum of column 2 and 3.

Note that `a:=2` in above `using` doesn't mean for variable to have value `2`, it
means to read value from column 2 into `a`. Read the next section
([Variables in expressions](#variables-in-expressions)) for some extra
explanation.

Info: colon (`:`) was selected, because it is unlikely to be encountered as a
first character of a file name. In case you want to actually open such file name
simply prepend it with `./`, like `kolumny "./:i.txt"`. Usage of other characters
or no character at all, could make it error prone, require special and fragile
autodetection, or make the interface too more verbose (like keyword print,
expression, or making file be opened with keyword, like open, input, would make
entire invocation unecassarily long).

Info: `:=` was selected, because of it showing directionality of assignment
better and the fact that in `kolumny` it is illegal to reassign variable. More on
that later (in section [Variable reuse](#variable-reuse)).


### Variables in expressions

Just like `using` can introduce variables, expressions can do so too:

```
kolumny "file.dat" using a:=1,b:=2 :s:=a+b :z:=s**2
```

Will show 4 columns: Original columns 1 and 2 from `file.dat` and extra two
columns: column `s` that is a sum of column 1 and 2, and column `z`, that is a
square of column `s`.

Note that, the meaning of numbers on the right side of the variable definition
is different in using and in expressions:

```
kolumny "file.dat" using a:=1 ":b:=1"
```

In this case `a` will be a value of the first column, and `b` will always be a
numerical value `1.0`.

If you are confused with this, you can convert `using` to use `column` function
and expression itself:

```
kolumny "file.dat" using "a:=(column(1))" ":b:=1"
```

which is more self descriptive.

On the other hand:

```
kolumny "file.dat" using "a:=(1)" ":b:=1"
```

Will produce two columns of ones (`1.0 1.0`) for each input row, and basically
ignore input columns. Read more in further sections
([Expressions in using](#expressions-in-using)).


### Variable reuse

It is not legal to have the same variable assigned multiple times:

```
kolumny "file.dat" using t:=1,t:=2
```

or

```
kolumny "file1.dat" using t:=1,x:=2 \
	"file2.dat" using t:=1,y:=2
	":x+y"
```

Will result in an error (`t` defined twice), because of the ambiguity of variable
`t`.

Similarly in expressions it is illegal:

```
kolumny "file.dat" using x:=1
	:y:=2*x
	:y:=3*x
	:y:=y+x
```

Will result in an error (`y` redefined), because it makes the results depend on
the order of evaluation, and by design `kolumny` tries not to specify order of
evaluation (it only specifies order of printing).


### Hiding results of expressions or using with `~` prefix.

By default when specifying columns in `using` or expressions with `:` the results
are also printed as a new column (from left to right).

Often one wants to simply read some columns and assign value temporary
expressions into auxilary variables, and print only some columns with end
results. This can be done with `~` prefix.

```
kolumny "file.dat" using ~a:=1,~b:=2 :~s:=a+b :~z:=s**2 :z
```

Will output only single column, a square of the sum of first and second column
from the `file.dat`.


```
kolumny "file1.dat" using `~x:=2` \
	"file2.dat" using `~y:=2`
	:x+y
```

Will only output one column that is a sum of column two from both input files.

This form is NOT supported currently:

```
kolumny "file.dat" using `~1,2,~5`
```

It will emit an error, but in principle it would only output column number 2. The
input file must have at least 5 columns in each row tho, and columns 1, 2 and 5
must contain numbers.


### Vectors and column ranges

It is possible to read range of columns (specified with `...`) as a vector that
can later be used in expressions.


```
kolumny "file1.tsv" using 1,~c:=2...8 ":sum(c)"
```

Will output 2 columns: column 1 from file `file1.tsv`, and a sum of values in
columns 2...8.


```
kolumny "file.dat" using 1,~c:=2...4 ":c[2-2]+c[3-2]+c[4-2]"
```

or

```
kolumny "file.dat" using 1,~c:=2...4 ":c[0]+c[1]+c[2]"
```

Same as above. Note that indexing of `c` starts from 0 just like in Python.
`c[0]` is a value of column 2, `c[1]` is a value of column 3, etc.


Vector inputs can be overlapping and assigned to different variables arbitrarily:

```
kolumny "file.dat" using 1,~a:=2...10,b:=5...15 ":sum(a) / sum(b)"
```


### Expressions in using

One can also put expression in `using` by wrapping them in brackets.

```
kolumny "file.dat" using "1,(42)"
```

Will output 2 columns: 1st same as input, and 2nd showing always number `42`.

This is more useful with `column` function explained below.

Note: The brackets are mandatory:

```
kolumny "file.dat" using "3+4"
```

will not produce number `7` as output.

Note: This behaviour is influenced by `gnuplot` `using`.


### `column(N)` function access

```
kolumny "file.dat" using "1,(column(2)+column(3)+column(4))"
```

Will output 2 columns: 1st same as input, 2nd being a sum of columns 2, 3 and 4
from the input. It is functionally equivalent to:

```
kolumny "file.dat" using "1,~a:=column(2),~b:=column(3),~c:=column(4)" :a+b+c
```

but without introducing any actual variables.


One can thing of standard `using`:

```
kolumny "file.dat" using "1,2"
```

to be equivalent and shortcut of

```
kolumny "file.dat" using "(column(1)),(column(2))"
```

Expressions can be combined with variable assignments:

```
kolumny "file.dat" using "1,b:=(column(2)/column(4))" ":sqrt(b)"
```

or

```
kolumny "file.dat" using "1,~b:=(column(2)/column(4))" ":sqrt(b)"
```

It is up to the user of `kolumny` to decide which parts of data processing should
be done in `using` expression or in normal expressions.

In general it is recommended to only do most simple processing in `using`
expressions, and these expressions are only limited to accessing data from a
single file.

Note: The brackets are mandatory:

```
kolumny "file.dat" using "column(1)"
```

will not work and produce an error.

Note: Current `using` parser is rather primitive, so you can't use commas
inside functions in `using` expressions:

```
kolumny "file.dat" using "(max(column(1), column(2))"
```

Will unfortunately not work.

Note: A general behaviour of `column` is influenced by `gnuplot` `using` and `column` function.


### `column(0)` function

`column(0)` returns a current line number of the file.

```
kolumny "file.dat" using "(column(0)),2"
```

will output 2 columns: 1st with a line number, and 2nd being a copy from the
input.

Note: This behaviour is influenced by `gnuplot` `using` and `column` function.


### Available functions and operators

Operators available out of the box for operations on numbers: `+`, `-`, `*`, `/`, `%`, `//`, `**`, `<<`, `>>`.

Additional integer bit operators: `&`, `|`, `^`, `~`

Comparison operators: `==`, `!=`, `>`, `>=`, `<`, `<=`, `<>`

Additional operators: `[]`.

Logic operators: `and`, `or`, `not`.

Parantheese: `()`

Data conversion functions:
 * `int`
 * `float`
 * `complex`

Math functions and constants:
 * `sqrt`
 * `sin`, `cos`, `tan`, `asin`, `acos`, `atan`
 * `atan2`, `hypot`
 * `cosh`, `sinh`, `tanh`, `acosh`, `asinh`, `atanh`
 * `pow`, `exp`, `expm1`, `log`, `log10`, `log2`, `log1p`, `ldexp`
 * `erf`, `erfc`, `gamma`, `lgamma`, `factorial`
 * `gcd`
 *  `isinf`, `isnan`, `isfinite`
 * `pi`, `e`, `tau`, `inf`
 * `floor`, `ceil`, `trunc`, `fabs`, `fmod`, `frexp`, `modf`
 * `fabs`, `copysign`
 * `degrees`, `radians`
 * `fsum`

See a [documentation of Python math module](https://docs.python.org/3/library/math.html)
for details.

Additional functions:
 * `sum`
 * `avg`, `stddev`
 * `eq`
 * `vec_add`
 * `min`, `max`, `count`

Numbers can have underscores for grouping, for example: `12_345`,
`1.131_411e+33`.

Hexedecimal integers are supported, for example: `0xdeadbeef`.


Chained comparisons, like `a < b < c` are guaranteed to work. Note that `1 != 2
!= 1` is true and is guaranteed to work in future version. Note that strange
comparisons like `1 < 3 > 2` will work, but are not guaranteed to continue
working the same way (or even work at all) in future major versions of `kolumny`.

### Python compatibility notes

In general the entire power of Python is available in `kolumny`. However, some
features are not guaranteed to work in feature versions, as indicated below.

Other Python operators, data types and functions are available, but are not
guaranteed to work in the future new major versions of `kolumny`. For these
reasons try to keep any custom complex processing to minimum. Including use of
`map`, `filter`, `reduce`, `zip` and custom `lambda` expressions. But these are
useful in many applications, and makes `kolumny` extremally powerful tool, so use
your good judgment.

Note: Array/vector concatenation operator (`+`) is not guaranteed to work in
future new major versions of `kolumny`.

Note: Use of tuples (like `(1,2,3)`) is discouraged, and tuples are not
guaranteed to work in  future new major versions of `kolumny`.

Note: Use of complex numbers (like `1+2j`) is supported, and in general will be
preserved in future new major versions of `kolumny`.

Note: Octal and binary literals, like `0o377` or `0b11001110101`, will work, but
are not guaranteed to work in future major versions of `kolumny` (binary ones are
more likely to be supported for longer time).

Note: `Decimal` and `str` conversions are generally available, if used together
with `--import`, but are not guaranteed to work in new major versions of
`kolumny`.

Note: Use of functions that modify variables (especially vectors) in-place (like
`append`, `sort`, `extend`, `reverse`) is strongly discouraged, and can break,
change behaviour or not work even between minor versions of `kolumny`.

Note: These rules are mainly here to be able to port `kolumny` to different
programming language if needed, without re-implementing all quirks of Python in
it. Depending on user feedback of used features, different priorities will be
assigned to what make supported and what to drop without big user impact.

Note: Comments inside expressions are generally supported, for example
`":a:=sum(x) # Add all columns."` will work.


### No input - command line calculator with variables / spreadsheet

If no input files are specified at all, `kolumny` will process all the expressions
one time and print results as requested:

```
kolumny :x:=sin(pi/7) :y:=cos(pi/7) :x*x+y*y
```

Will display `0.433883739118 0.900968867902 1.0`.


### Dependencies

As seen previously, expressions can use variables defined by other expressions or
`using` variables.

```
kolumny "file.txt" using "a:=1,b:=(column(2)+column(3))" \
	":~x:=a/b"
	":~y:=b/a"
	":x+y"
```


### Reordering

Variables in all modes, can be defined in arbitrary order.

This enables you to use `kolumny` as a calculator or a spreadsheet.

```
kolumny ":x:=3" ":y+x*100" ":y:=4*z" ":z:=100000"
```

Will display `3 400300 400000 100000`, despite `y` using `z` that is defined only
further in the command line.

Note that only one line will be printed, and expressions can be provided in any
order. Values printed will be printed in the exact order specified by the user.


```
kolumny \
	":x+y" \
	":~x:=a/b" \
	":~y:=b/a" \
	"file1.txt" using "~a:=1,~b:=(column(2)+column(3)"
```

Is perfectly valid too, equivalent and will produce exactly same output as the
example in the previous section ([Dependencies](#dependencies)).


### Cycles

Cyclic dependencies are an error:

```
kolumny ":x:=3" ":y:=z+1" ":z:=y+1"
```

Will result in an error becasue `y` and `z` reference each another.


### Shell preprocessing / generation

```
kolumny "<tr ',' ' ' data.csv" using 1,3
```

Will run a Unix `tr` command to convert commas into spaces, and then output
columns 1 and 2 for each row.



### Vector processing and statistics across columns of single row

There are few built in functions to process vectors or ranges of columns.

```
kolumny "file1.txt" using ~x:=2...11 ":sum(x)/len(x)" ":max(x)"
```

will show average and maximal value of columns 2 to 11 for each row.

Available vector processing functions:

  * `len`
  * `sum`
  * `min`
  * `max`
  * `avg`
  * `stdavg`
  * `add_vec`

More vector procssing functions will be added in the future, most notably
functions related to statistics.

In the meantime arbitrary Python operations can be done, like `sorted()`, `find`,
`map`, `filter`, `reduce`, `in`, `count`, `reversed()`, `all`, `any`,
`enumerate`. For example `sorted(x)[len(x)//2]` can be used to compute median,
and `reduce(lambda v,p:v*p, x)` to compute product of all values.


### Merging multiple input files


### Skipping initial lines from input

If the input files has some header at the beggining of the file, specified amount
of lines can be ignored and skipped using `skip` command.

```
kolumny "file.dat" skip 5 using 1,2
```

Will completly ignore first 5 lines of the `file.dat`. They must exist, otherwise
skipping can't be performed.

This can be combined with reading multiple files and each having different `skip`
values.


### Tail mode

```
kolumny "file.dat" skip 10
```

will operate similar to `tail -n +10 file.dat`.


### Checking input or conditions

A built in function `check` can be used to verify that the input data conform to
some conditions.

```
kolumny "file.dat" using a:=1,b:=2 \
	":~check(a < b)"
```

Will output columns 1 and 2, but it will also perform a silent check that the on
each row column 1 is smaller than column 2. `~` is used to not print result of
the check comment itself, otherwise it will show `None`. If the check fails
`kolumny` will crash, report an error of failed check, and stop processing all
input files. `check` is done on every line (row) separately, so if `check` fails
only on some further line, already processed lines will be printed.

```
kolumny "file.dat" using ~a:=1 \
	":~check(a >= 0)"
	":sqrt(a)"
```

Will check that first column is non-negative, and then perform a square root
operation on it and print the result.


### Checking multiple inputs

When combining multiple files it might be beneficial to make sure that they are
matched correctly for parallel processing.

```
kolumy \
	"file1.txt" using t1:=1,x1:=2 \
	"file2.txt" using t2:=1,x2:=2 \
	":~check(t1==t2)" \
	":t1" \
	":x1" ":x2"
```

Will output 3 columns, a first column (`t1`) from `file1.txt`, and second columns
(`x1`, `x2`) from both input files. It will also make sure that first column
(`t1`) is identical in both input files.

This is a good way to check that multiple files we are combining conform to the
same form (i.e. they were exported from other software the same way, or
measurement equipements to capture data was set up the same way).


### Combining skip and check

Especially when dealing with complex headers, or data that do not have rows
correctly aligned, one would use `skip` and `check`

```
kolumy \
	"file1.txt" skip 11 using t1:=1,x1:=2 \
	"file2.txt" skip 9 using t2:=1,x2:=2 \
	":~check(t1==t2)" \
	":t1" \
	":x1" ":x2"
```

Will do the same as previous example, but initially will skip first 11 and first
9 lines from `file1.txt` and `file2.txt` respectively. This can be useful when
data produced are not consistently starting at the same value.

In many processing scenarios some other code (for example in Bash script) will
determine a correct value of a skip and pass it to `kolumny`.

This example can't be simply recreated using `tail`, `paste` and `awk`, without
creating additional temporary files.


### Termination

`kolumny` will terminate when its input file have no more rows to process.

When using multiple input files `kolumny` will terminate processing as soon as
one of the files finishes, or it can not be processed correctly any longer (i.e.
no more correct columns to be used via `using`).

TODO(baryluk): Add a feature, to allow continuing processing until all input
files finish, and use implicit column values for already finished files.


### Complex numbers

`1j` an imaginary unit. Example of complex number: `3+4j`.

When reading data, one can easily create complex numbers and use them in
expressions:

```
kolumny "data1.txt" u z:=(column(1)+1j*column(2)) ":z**2
```

Will form a complex number from real and imaginary part from column 1 and 2,
display this complex number (like this `(1.2+3.4j)`), and its square.

Standard mathematical functions with support for complex arguments can be
accessed via cmath module using `--import` option (see [Importing Python
modules](#importing-python-modules) section for details).


### Custom initalization

Arbitrary Python code can be executed on the start of the `kolumny` with the use
of `--begin` options, and the results of these execution can be used in
processing stages:

```
kolumny --begin a=3 "file1.txt" u ~x:=1 ":x*a"
```

or

```
kolumny --begin a=3 "file1.txt" u "(a*column(1))"
```

Will both output first column multiplied by a constant `a`, which is equal to 3.

Multiple `--begin` can be specified, and they will be executed in order:

```
kolumny --begin a=3 --begin a=a*a "file1.txt" u "(a*column(1))"
```

Will output first column multiplied by 9.

One can also use semicolons and comments, as in normal Python code:

```
kolumny --begin "a=3; b=4 # Init" "file1.txt" u "(a*column(1)+b)"
```

Or use statments with side effect:

```
kolumny --begin "print('Processing...')" "file1.txt" u 1
```

This feature might be useful with ability to modify global variables defined by
`--begin` in expressions:

```
kolumny --begin "a=0.0" "file1.txt" u "~x:=1" ":x" ":~a+=x" ":a"
```

Will output two columns. First a copy from the input, and second with a running
(cummulative) sum of the first one.


### Importing Python modules

Arbitrary Python modules can be imported to be used in expressions.


### Accumulators and other statistical operations across rows

```
kolumny \
	--begin 'maximum1=float("-inf")' \
	--begin 'maximum2=float("-inf")' \
	"file1" using 1,v1:=4,~v2:=5 \
	":maximum1=max(maximum1, v1)" \
	":~maximum2=max(maximum2, v2)" \
	--end   'print("MAX: %f %f" % (maximum1, maximum2))'
```

Will output 3 columns from file "file1" (column 1, 4 and so far accumulated
maximal value of column 5). At the end it will additionally print maximal values
of the 4th and 5th column.


### Empty file name `""`

A special empty filename instructs `kolumny` to read the previous file again.
In most shells this can be done using `""`.

```
kolumny "file1.txt" using 1,2 "" using 1,3
```

Is essentially the shortcut to:

```
kolumny "file1.txt" using 1,2 "file1.txt" using 1,3
```

And that is essentially similar to:

```
kolumny "file1.txt" using 1,2,1,3
```


### Standard input file name `"-"`

A special filename `-` can be used to read data from standard input:

```
seq 10 | ./kolumny '-' using "~x:=1" ":x" ":x*x"
```

Will output 10 columns with consecutive numbers and their squares.

```
seq 10 | ./kolumny --import random '-' using "~x:=1" ":'%.3f'%random.random()" ":'%.3f'%random.random()"
```

Will output 10 columns with 2 random values (with just 3 decimal digits after a
decimal point) in each row.


### Commenting out files

A file can be skipped from processing by prepending it with `#`:

```text
kolumny "#file1.txt" using 1,3 "file2.txt" using 1,3
```

Will only show 2 columns. column 1 and 3 from `file2.txt`. `kolumny` will ignore
`file1.txt` and its `using` statements. The file doesn't even need to exist. The
`using` must be syntactically correct tho.

```text
kolumny "#file1.txt" using foo "file2.txt" using 1,3
```

will produce an error.

### Commenting out expressions

Similarly expressions can be skipped from processing by prepending it with `#`:

```text
kolumny ":7" "#:8"
```

Will only show one column with value `7`.

The expression can be malformed and will still be ignored:

```text
kolumny ":7" "#:foo"
```

Will only show one column with value `7`.


Commenting out the expression, disables evaluation of this expression and
assignment to variables defined by it, so the variables can't used anymore in
other expressions.


```text
kolumny "#:a:=7" ":2*a"
```

Will result in evaluation error and produce no results, because `a` is undefined.

### Commenting in the expressions

It is possible to add custom comments in expressions:

```text
./kolumny ":a:=1 # One" :2*a
```

Will print `1 2`.

`#` and anything after it in any given expression will be ignored.

This style of commenting is not supported in using or using expressions, but can
be emulated using disabled expressions:

```text
./kolumny "file1.txt" using 1,3 "#: Read first and third column" \
	"file2.txt" using 2,4 "#: Read two columns"
```

The text in these expressions is not a valid expression, but because it is
disabled it doesn't really matter.

A different form:

```text
./kolumny "file1.txt" using 1,3 "# Two columns" \
	"file2.txt" using 2,4 "# Extra two other columns"
```

Will also work, but is strongly discouraged, because this is interpreted as
disabled input file name, and even for them the `using` statement are processed,
and that can lead to nasty surprises:

```text
./kolumny "file.txt" "# Two columns" using 1,3
```

Will output all columns of `file.txt`, not just columns 1 and 3. The `using 1,3`
is attached to a hypothetical input file `" Two columns"` (starting with space
and having spaces) and is being ignored.


### Quoting

In many cases quotes around arguments are not needed:

```
kolumny :42*123
```

Will show `5166`.

```
kolumny :a:=2**13 :~b:=a/3 :a*b
```

Will show `8192 22364160`.


The interface was designed to limit use of special characters that could
interfere with the the standard Unix shell.

```
kolumny myfiles/file.txt using ~a:=1,~b:=2 :a :b/a :b*a
```

In general quoting is only needed, in conventional interactive shell and script
when:
 * spaces or brackets in file paths (or file names or paths comes from unknown
   sources)
 * using commenting feature (`#` in input spec or expression)
 * using brackets in `using` or in expressions.
 * referencing some other special characters (i.e. `$`, in such case single
   quotes are recommended).

Below each quoted argument must be quoted as presented, when executed from Bash
and other shells and script.

```
kolumny "My Documents/some data(1).txt" using "1,~b:=(column(3)+column(5))" "#:b*2" ":sqrt(b)"
```

Quotes itself are not passed to the `kolumny`, and `kolumny` is not handling them
in the above example. It is just a feature of most shells to also interpret `#`
as comment, space as a argument separator, and brackets for various features.

Of course various techniques can be use to combine shell scripting capabilities
to pass information between shell and `kolumny`. For example the filename,
special (per-file) constants to expressions or to skip.

### Time related values handling

`kolumny` doesn't support handling of time values (i.e. timestamps, ISO 8601 dates,
or time periods like `2h`), but these can be mostly handled using Python functions
like these from [datetime module](https://docs.python.org/3/library/datetime.html).


### Using kolumny as input to gnuplot

### Using kolumny to generate fits and plots via gnuplot

```
kolumny \
	--gnuplot_begin 'set terminal png' \
	--gnuplot1_begin 'set output "chart1.png"' \
	--gnuplot2_begin 'set output "chart2.png"' \
	--gnuplot_begin 'f(x) = k1*x + k2' \
	--gnuplot_begin 'g(x) = A*x + B' \
	"file1" using y1a:=3,y2a:=4,~xa:=1 \
	"file2" using y1b:=3,y2b:=4,xb:=1 \
	":~check(xa==xb)" \
	":diff1=y1a-y1b" \
	":diff2=y2a-y2b" \
	--gnuplot1_fit ":xa,y1"     'f(x)" via "k1,k2" \
	--gnuplot2_fit ":xa,diff1"  'g(x)" via "A,B" \
	--gnuplot1_plot "f(x)" ":xa,y2b" ":xa,y1a" ";" \
	--gnuplot2_plot ":xa,diff2" title "Data2" "g(x)" title 'Fit2' ";" \
	--end 'print "A: %f  B: %f " % (A, B)'
```

Perform some fitting and plotting on multiple files.


### Performance

`kolumny` can process about 450000 lines per second on modern desktop class CPU,
when using only simple features, and processing files only with few columns.

When using more complex processing, complex expressions, vectors and dozens of
total columns (across all files), this will usually drop to about 25000-50000
lines per second in practical scenarios.

So, having each file with 500 rows of data, one can process about 50-100 files
per second. Just an example.

The memory usage shouldn't exceed few megabytes, even when processing extremally
large files (~10 gigabytes and more).

There is plenty of room for performance improvements in `kolumny`, and it is
belived it can process more than 1 million lines per second with suitable
optimizations, without switching to other programming language.

`kolumny` is single threaded, and will only use at most one CPU core on your
processor. If you are processing massive amounts of data, either split input
data into multiple smaller files and process them in parallel, and then join
 them back using `cat`. Or if you are processing many data sets to begin
with, that take hours to process, process them in parallel instead. Good
tool for doing so is [GNU parallel](https://www.gnu.org/software/parallel/),
`xargs`, `make`, `fine -exec`, or simply `&` operator in shell, for small
number of files. See
[parallel alternative](https://www.gnu.org/software/parallel/parallel_alternatives.html#DIFFERENCES-BETWEEN-pyargs-AND-GNU-Parallel)
for some more (but not all) alternatives (be aware of possible bias in this
document, as it is written by GNU parallel developers)


### Crazy

```
kolumny \
	"file1" using a:=1,~c:=3...7 \
	"file2" s 11 u ~b:=1,d:=2 \
	"#file3" skip 21 using ~e:=1,g:=2 \
	"<generate.py 44 1.41 | egrep -v '^$'" skip 11 using h:=4,~cg:=1 \
	":~check(a==b)" \
	"#:~check(a==e)" \
	":~check(a==cg)" \
	":~check(a==x)" \
	":S:=sum(c)" \
	":d+g*h" \
	":sqrt(d)-c[3]*S" \
	"file4" skip 11 u ~x:=1,~y:=2,z:=4 \
	":S >= 10" \
	":'somestring'" \
	":1e3*xy" \
	":4,5,b" \
	":4,5,c" \
	":~xy:=x+y" \
	"file4" skip 11 u 3
```

Will output lines of the form:

```
a d g h S=sum(c) d+g*h sqrt(d)-c[3]*S z True/False somestring 1e3*xy=1000*(x+y) (4,5,b) (4,5,[c1,...]) column-3-of-file4
```

Notes:

 - order of files and expressions intermixed
 - multiple columns and files read at once
 - silent checks (asserts) that some columns between input files are equal
 - not printed columns using `~` both in expressions and file inputs
 - forward reference of variable `x` and `xy` before they are defined
 - comments (disabled files and expressions) using `#`
 - Python expressions, including math operations, checks, tuple/array printing
 - vector columns like `c:=3...7`. `c[3]` means 3+3+1=7th column from "file1"
 - usage of subcommands to generate data and remove empty lines using `grep`
 - usage of the same file multiple times
 - short forms of `using` (`u`) and `skip` (`s`)


Installing
----------

Either clone this git repository (`git clone
https://github.com/baryluk/kolumny.git`) and add it to your `PATH` (for example
using `export PATH=~/kolumny:$PATH` at the end of your `~/.bashrc` file).

Or [download the main
executable](https://raw.githubusercontent.com/baryluk/kolumny/master/kolumny) and
put for example in your `~/bin/` directory (make sure it is in your `PATH`).

The only required dependency is Python 3. If you are running Linux you already
probably have it installed.

To test quickly if it works, execute in terminal:

```
kolumny :x:=3 :y:=x**x
```

You should see this output:

```
3 27
```


Future work
-----------

The majority of future work on `kolumny` will focus on bug fixing, tests and
adding some additional features like:

* automatic row alignment, to eliminate manual `skip` and `check`.
* row interpolation
* subsampling similar to `set sample` and `every` in `gnuplot`
* computations of statistics across rows
* multi-pass algorithms and data caching from sub-processes


Contributing
------------

Simply open an issue (bug, feature request) or a pull request via this GitHub
project. If possible please provide all input files and command line to reproduce
the problem, and try to keep it as minimal as possible.


Authors and License
-------------------

* Witold Baryluk

This project is licensed under [BSD License](https://choosealicense.com/licenses/bsd-3-clause/).

Copyright, Witold Baryluk - 2010, 2012, 2018.
