module Validator
  extend self

  def valid_filename?(s)
    return false if ! s
    s = s.to_s
    return false if s.length > 32
    return false if s.length > 32
    # Must start & end with alphanum, and may contain underscore, hyphen and periods.
    return false if s !~ /^[a-zA-Z0-9]([a-zA-Z0-9_\-\.]*[a-zA-Z0-9])?$/
    # Two special characters next to each other is a bit odd
    return false if s == /[_\-\.]{2}/
    true
  end

  def valid_subpath?(s)
    return false if ! s
    s = s.to_s
    return false if s.length == 0
    return false if s.length > 128
    elems = s.split('/')
    return false if elems.length > 6
    elems.all? { |elem|
      valid_filename?(elem)
    }
  end


  def strip_non_alphanumeric_from_ends(s)
    s[/[a-zA-Z0-9](.+[a-zA-Z0-9])?/]
  end

  def clean_element(s)
    strip_non_alphanumeric_from_ends(
      s.split(/[^a-zA-Z0-9_\-\.]+/).reject { |x| x == '' }.join('-').
        gsub(/\.+/, '.').
        sub('.', '')
    )
  end
end

if __FILE__.end_with? $0
  puts "Running tests..."

  require 'minitest/autorun'

  class TestValidator < MiniTest::Unit::TestCase
    def test_validate_filename
      assert_equal true , Validator.valid_filename?("a")
      assert_equal true , Validator.valid_filename?("a.js")
      assert_equal true , Validator.valid_filename?("a.erb.html")
      assert_equal true , Validator.valid_filename?("abc")
      assert_equal false, Validator.valid_filename?(".")
      assert_equal false, Validator.valid_filename?("/slash")
      assert_equal false, Validator.valid_filename?("../dotdot.js")
      assert_equal false, Validator.valid_filename?("$x$x$")
      assert_equal false, Validator.valid_filename?(nil)
      assert_equal false, Validator.valid_filename?(['a'])
      assert_equal false, Validator.valid_filename?({a:'a'})
      assert_equal false, Validator.valid_filename?("")
    end

    def test_validate_subpath
      assert_equal true , Validator.valid_subpath?("a")
      assert_equal true , Validator.valid_subpath?("a.js")
      assert_equal true , Validator.valid_subpath?("a.erb.html")
      assert_equal true , Validator.valid_subpath?("abc/a.erb.html")
      assert_equal true , Validator.valid_subpath?("a/b/c/d/e/a.erb.html")
      assert_equal false , Validator.valid_subpath?("a/b/c/d/e/f/a.erb.html") #max 6 elements
      assert_equal false, Validator.valid_subpath?(".")
      assert_equal false, Validator.valid_subpath?("/slash")
      assert_equal false, Validator.valid_subpath?("../dotdot.js")
      assert_equal false, Validator.valid_subpath?("$x$x$")
      assert_equal false, Validator.valid_subpath?(nil)
      assert_equal false, Validator.valid_subpath?(['a'])
      assert_equal false, Validator.valid_subpath?({a:'a'})
      assert_equal false, Validator.valid_subpath?("")
    end
  end
end
