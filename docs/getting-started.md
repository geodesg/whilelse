# Getting started with Whilelse

Please note that Whilelse is currently under development and is
incomplete and unstable.

In this guide you will learn the basics needed to start using Whilelse,
and will be guided through creating a simple application.

## Core concepts

The program is represented as a web. Each function, variable, statement,
expression is a *node*, a relationships between nodes is called a *ref*.

When you create a function call, your referencing the function node by
ID. You can change the name of a function and you don't have to worry
about breaking any of references. The same goes for variables.

Every node has a type (e.g. "function", "variable"), which is a pointer to another node,
a node with type  *node_type*. E.g. `fizzbuzz<function>` points to
`function<node_type>`, which points to `node_type<node_type>`.

A node may have a name, which can be the function name, variable name,
module name, etc. There are currently no restrictions, but you should
try to keep them unique.

A node may have attributes which maps attribute-type IDs to a scalar value
(number, string, boolean). The attribute-type points to an
`x<attr_type>` node.

A node may have outbound refs. A ref consists of source node, target
node, ref type, dependent (boolean). If the dependent is true, the
target is a *component* of the source node and it cannot exist without
its source, which in this case is its parent. An example is that an `if`
statement contains it's `then` block.
If it's false, then the source *links* to the target. An example of this
is when you reference a variable, or call a function.

There are 10 commands that can be executed on this web of nodes, e.g.
add component, add link, set attribute, set type, etc.

These commands are stored in the order they are executed, this acts
as a source code history.

The commands are currently organised into *documents*, where documents
can *include* another, e.g. the `prog` document includes `core`.
This is just a temporary system until a real source code & dependency
management system is implemented.

This should be enough info to get you started.

## Your workspace

The hosted application is at https://app.whilelse.com/

Your local installation by default is at http://localhost:8888/

The first time you start the app, you're asked to log in.
There is no real user management system. Your username is only used
for generating a document name. Enter your GitHub username.

Next, you'll be taken to your workspace, which is a new document with a
single container node. Here, you can add applications, modules, functions,
classes, data types.

## Before you start

Pressing `U` will undo your last command.

If you encounter an error message, or something doesn't seem to work,
try reloading the page.
Also, if you can reproduce the error, please report it using the issue
tracker, unless it's already there.

## Hello World

Create an application by pressing `A` then type `appl` until
`prog.application-node_type` is selected, press `Enter`, enter a name,
say `helloworld`, then `Enter`.


You now have a blank application. The red rectangle is the placeholder
for any commands. It's red because it's required. It's called a _blank_.
Press 'L' to start comp*L*eting the application.

Start typing `log` and select the `log` function (this is a wrapper for
the JavaScript `console.log`).

Next, you can enter a parameter for this function. To create a string
literal "Hello World". To invoke the "string literal" part, press `'`
(single quote), then you enter the string. Note that you don't need to
close the quote, every character entered after the `'` will be part of
the string literal, no escaping needed.
So type `'Hello World!` then press `Enter`.

Your app is now ready. Let's run it. First, select the app. Press `Y`
until the current node indicator on the bottom starts with `"helloworld"
application`. Press `Shift-J` to bring up the export menu, then press
`R` to run. If you'd like to see the generated code: `Shift-J`, `C`.

## Loops & variables

Let's create a simple loop and output `Hello 1`, `Hello 2`, `Hello 3`.

Currently the simplest way to navigate is with the mouse, but you can
also use the keyboard. In case you'd like to try that: `up`/`down`
navigates through siblings (even if they're displayed horizontally).
`Alt-up`/`Alt-down` navigates through the tree with in pre-order
traversal, think of it as navigating through a file tree explorer.
`Esc` selects the parent, `Y` selects an ancestor of major significance,
like a statement, function, application.

Select the `log` function call and press `Shift-A` to append a new
sibling, i.e. create new statement after it.

Search and select the `step` command, which is a loop for iterating a
variable between two numbers.

Next, you'll need a variable. Type `i` then, to create a variable called
`i`, press `Control-V`. Notice that the variable is now declared above.

Enter literal `1` into the _from_ slot, press `Tab` and `3` into the _to_.

Notice that the editor pauses on the literals instead of jumping right
to the next blank. This is to give you a chance to apply operators,
function calls, etc. before moving on to the next item.

Once you're on the loop body, create a function call to `log`, then
enter a string `Hello ` (with a trailing space). Remember you don't need
to close the quote. When your string literal is ready and selected,
press `+` (plus). This will bright up the search box and will search for
operators and other things that can be applied to an expression.
Press `Enter` on `operator add`.

Next, enter the second argument to the operation, which will be a
variable reference. Simply type `i` and it should bring up the variable.

When you press `Tab`, it will ask for the next statement of the loop.
Simply press `Esc`.

Run the application by selecting it (a couple of `Y` presses) and
`Shift-J`, `R`.

## Function

Let's declare a function inside this application.

Select the application node, press `A` (add child), then `D`
(declaration), then `F` (function), and you will get a blank function.

Enter the name, `square`, then parameter name `x`, select integer with
`I` (you can skip types with `Tab`). When asked for a second parameter,
press `Tab`. For the return type select integer with `I`.

In the function body, search for the `return` command, then in the
argument select variable `x`, press `*` (asterisk), then variable `x`
again.

## Unit tests

It is possible to attach a simple unit test to a function.

Select the function node and press `Shift-T` to create and switch to the
function's unit test. Press `L` to complete.

The testing UI needs more work, so make sure you do this: you can leave
the name empty, but press `Enter`, this will create the test case node.
Next enter a description, e.g. "square of 2 is 4".

You now have to enter a series of statements just like before, and you
can use `assert` with any boolean expression.

To add an assertion, search for the `assert` command. In the argument
create the following: `square(2) == 4` (`squ` `Enter` `2` `Enter` `Esc`
`=` `Enter` `4` `Enter`)

Press `Shift-J`, `T` to run the test.

You can toggle between the test and the function with `Shift-T`.

Break the function to see how the test fails: select one of the `x`
variable references, and press `Shift-W` to "unwrap" then, so you have
`return x`. You can invoke the test from within the function the same
way: `Shift-J`, `T`.

You should get "Test failed (1) square of 2 is 4: square(2) == 4;"

Press `U` a couple of times to undo your breaking change.

## Array literals, each, callback functions

Add a new statement, search for the `each` command.

In the first argument, create an array: type `[` and make sure you
select `make_array`. Then enter a couple of strings pressing `Tab` after each
one. Press an extra `Tab` when you're finished.

In the second parameter of `each` you get an automatically generated
callback function. Don't edit the signature of this function, becuase then
the callback for every `each` call will have the same signature, as the
signature is defined in `each` and all of them link there. This
obviously needs work. For now, just skip over them with tab, or delete the
whole function and create a new one.

In the body you can add a `log("Hello " + item)` to greet everyone.

## Classes

You can define classes but there is no inheritance yet, so it's
basically a struct with methods. By the way, you can define structs too,
also enums.

Classes can have properties, a name and a data type, a constructor, and
methods. You can use `this.` to reference a property or a method.

Feel free to experiment.

Here's a real example of a class, which is part of the implementation of
Whilelse: [Node class](http://app.whilelse.com/posi/frontend/acHEu1BNsqsF)
([Frontend document](http://app.whilelse.com/posi/frontend)).

You can unfold the methods and compubox properties with `F`, and open
nodes in a new view with `O`.

Also, have a look at the keyboard commands on the side panel.
They can change depending on the current node type.
Some of them have tooltips.

## Next steps

Whilelse needs a lot of work. You can help to make it a success sooner.
There are [many ways to contribute](contributing.md).

One way to help is to give feedback.

Try creating something simple but useful in Whilelse and let me know
which are the most annoying definiciencies and bugs.

### Planned features:

* versioning & dependency management
* ReactJS wrapper
* database management (modelling, query langauge)
* isomorphic coding (same code on server and client)


