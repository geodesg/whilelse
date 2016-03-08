# Acceptance Tests

Tests the whole application as seen from the user's perspective, using a
headless browser (CasperJS/PhantomJS).

It also generates a HTML file in `guides/` for each test.

## Test runner

The `run` script does the following:

* compiles LiveScript files when they change
* runs `casperjs test` for test files when they change
* runs last or last failing test when `F2` pressed
* runs all tests in parallel when `Meta-F2` pressed
* opens screenshots

To set up the keyboard shortcuts you need to install Hammerspoon and
tell it to touch the `~/tmp/keys/f2.key` and `~/tmp/keys/m-f2.key`.
Select 'Open Config' from the Hammerspoon menu and add these
(adjust the paths):

    hs.hotkey.bind({}, "F2", function()
      hs.fs.touch("/Users/lev/tmp/keys/f2.key")
    end)

    hs.hotkey.bind({"cmd"}, "F2", function()
      hs.fs.touch("/Users/lev/tmp/keys/m-f2.key")
    end)

