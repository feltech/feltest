# feltest - pure Lua BDD style unit testing library
feltest provides a [jasmine](https://jasmine.github.io/)/[busted](https://olivinelabs.com/busted/)
style `describe`/`it` BDD-style testing framework for Lua. It is written in pure Lua with no
dependencies, and is especially designed around support for asynchronous tests.

## Motivation
I really wanted to use [busted](https://olivinelabs.com/busted/) for my tests, but it doesn't work
with Lua embedded in a game engine (specifically in my case the excellent
[Urho3D](https://urho3d.github.io/)). [lua-bdd4tap](https://github.com/henry4k/lua-bdd4tap) was
the closest I could find, but did not support nested blocks nor asynchronous tests, and has
too many dependencies for my liking.  So feltest was born.

# Quick start
The following examples are taken and modified from the `spec.moon` test file.  See that file for
some more detail. feltest is written in [MoonScript](http://moonscript.org/) and transpiled to Lua,
so all examples will be shown in MoonScript.

## Preamble
feltest does not add any additional assertions.  A test is considered a success if there are no
calls to the built-in `error()` function (or timeouts).  You can just use the built-in `assert`, or
you can use a 3rd-party assertion library, like the excellent
[luassert](https://github.com/Olivine-Labs/luassert), which is part of
[busted](https://olivinelabs.com/busted/) but can be used independently.

```MoonScript
lassert = require 'luassert' -- not provided by feltest
Runner = require 'feltest'

run = Runner()
```
In the above I have imported `luassert` and the `Runner` class and constructed a new `Runner`
instance called `run`.

Once tests have been defined you need to call `runTests()` on the `Runner` instance.  The return
value is `true` for success, `false` for failure, or `nil` if tests have not yet completed
(asynchronous).  If tests are not yet complete, you can resume them (internally,
`coroutine.resume`) with `resumeTests()`.
```MoonScript
success = run\runTests()

while success == nil
	success = run\resumeTests()

os.exit(success and 0 or 1)
```
In practice, the while loop above is likely to be replaced with the update/tick/timestep function
of a game engine, or similar.

## Output
As mentioned above, the `runTests`/`resumeTests` methods will tell you if tests finished without
error.  It's up to you how to report that.  In the above example `os.exit` is used to specify a
unix-style exit code, which could be used in a continuous integration test runner, for example.

The text output looks like (using the `spec.moon` from this repo, with a test purposely broken)
```
Running 8 tests
[1] feltests does a test, inline ...
... PASSED

[2] feltests does a second test, inline ...
... PASSED

[3] feltests does a test, appended ...
... PASSED

[4] feltests does a second test, appended ...
... PASSED

[5] nested tests has run a test ...
... FAILED
Expected objects to be the same.
Passed in:
(nil)
Expected:
(boolean) true

[6] nested tests second level has run a test ...
... PASSED

[7] async tests runs a test async ...
... PASSED

[8] async tests has run a test async ...
... PASSED
```

## Test structure
The outermost `describe`s are called on the `Runner` instance.  Nested `describes`, as well
as `beforeEach` (setup), `afterEach` (teardown) and `it` (test case) methods, are called on
`self`.  The `self` object can also store values that are acessible within the current a test case
(and only the current test case) - useful for setting variables in a `beforeEach` that are
accessible in the `it`s.

```MoonScript
run\describe "nested tests", =>
	@beforeEach =>	@before_ran_lvl1 = true

	@describe "second level", =>
		@beforeEach => @before_ran_lvl2 = true

		@it "has run a test", =>
			lassert.is_true(@before_ran_lvl1)
			lassert.is_true(@before_ran_lvl2)

	@it "has run a test", =>
		lassert.is_true(@before_ran_lvl1)
		lassert.is_nil(@before_ran_lvl2)
```

## Async tests
`beforeEach`, `afterEach` and `it` functions are wrapped in coroutines, so that at any point during
a test you can `yield` and test execution will pause.  Then call `resumeTests` on the `Runner`
instance to continue.

```MoonScript
before_ran = 0
after_ran = 0
it_ran = 0

run\describe("async tests", =>
	@beforeEach( ()=>
		coroutine.yield()
		before_ran += 1
	)
	@afterEach( ()=>
		coroutine.yield()
		after_ran += 1
	)

	@it("runs a test async", ()=>
		coroutine.yield()
		it_ran += 1
	)

	@it("has run a test async", ()=>
		lassert.are.equal(before_ran, 2)
		lassert.are.equal(after_ran, 1)
		lassert.are.equal(it_ran, 1)
	)
)
```
There is a default timeout of 5 seconds for asynchronous tests.  This can be controlled by the
`Runner` class variable `TIMEOUT`
```MoonScript
Runner.TIMEOUT = 120
```
In the above the timeout has been set to 120 seconds.

## Debugging tests
Usually when writing or debugging tests you want to be able to just run one or two of them and
skip the rest.  This is done as in [jasmine](https://jasmine.github.io/), by prefixin the `it` with
an `f` to give `fit`.  Note that, unlike jasmine, feltest does not support `fdescribe`, only
`fit`.

```MoonScript
high_prio = 0
low_prio = 0

run\describe "high priority", =>

	@describe "second level", =>
		@it "doesn't run a low priority test", => low_prio += 1

		@fit "runs a high priority test", =>
			high_prio += 1

	@it "doesn't run a low priority test", => low_prio += 1

	@fit "has run a high priority test but not a low priorty test", =>
		lassert.is_equal(high_prio, 1, "high priority test should be run")
		lassert.is_equal(low_prio, 0, "low priority test should not be run")

```
