function! relab#tests#run(...) abort
  let debug = get(g:, 'relab_debug', 0)
  let g:relab_debug = get(a:, 1, 0)

  let p = relab#parser#new()

  let v:errors = []

  let input =     ''
  let expected = []
  let output = p.parse(input).magics()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '^'
  let expected = ['^']
  let output = p.parse(input).magics()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '^a\+'
  let expected = ['^', 'a', '\+']
  let output = p.parse(input).magics()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '^a\+\vb+'
  let expected = ['^', 'a', '\+', '\v', 'b', '\+']
  let output = p.parse(input).magics()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '.\{}'
  let expected = ['.', '\{}']
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '.\{1}'
  let expected = ['.', '\{n}']
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '.\{1,}'
  let expected = ['.', '\{n,}']
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '.\{1,2}'
  let expected = ['.', '\{n,m}']
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '.\{,2}'
  let expected = ['.', '\{,m}']
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '.\{,}'
  let expected = ['.', '\{,}']
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '.\{-}'
  let expected = ['.', '\{-}']
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '.\{-1}'
  let expected = ['.', '\{-n}']
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '.\{-1,}'
  let expected = ['.', '\{-n,}']
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '.\{-1,2}'
  let expected = ['.', '\{-n,m}']
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '.\{-,2}'
  let expected = ['.', '\{-,m}']
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '.\{-,}'
  let expected = ['.', '\{-,}']
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '.\?'
  let expected = ['.', '\?']
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '.\='
  let expected = ['.', '\=']
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '.*'
  let expected = ['.', '*']
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '.\+'
  let expected = ['.', '\+']
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '\v\1'
  let expected = ['\v', '\1']
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_true(has_error, input)

  let input =     '\%x1234'
  let expected = ['\%x', 'X', 'X']
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '\%o1234'
  let expected = ['\%o', 'X']
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '\%o0377'
  let expected = ['\%o']
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '\%o377'
  let expected = ['\%o']
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '\%o400'
  let expected = ['\%o', 'X']
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '\%o0400'
  let expected = ['\%o', 'X']
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '\%#=0'
  let expected = ['\%#=']
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     'a\@>'
  let expected = ['X', '\@>']
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '\_.'
  let expected = ['\_.']
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '\a'
  let expected = ['\a']
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '\_a'
  let expected = ['\_a']
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '.\@!'
  let expected = ['.', '\@!']
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     'a\zsb'
  let expected = ['X', '\zs', 'X']
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     'a\zeb'
  let expected = ['X', '\ze', 'X']
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '[ab]'
  let expected = ['[', 'X', 'X', ']']
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '[ab'
  let expected = ['X', 'X', 'X']
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '[\d1234]'
  let expected = ['[', '[\d', ']']
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '[\o123]'
  let expected = ['[', '[\o', ']']
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '[\x12]'
  let expected = ['[', '[\x', ']']
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '[\u1234]'
  let expected = ['[', '[\u', ']']
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '[\U12345678]'
  let expected = ['[', '[\U', ']']
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '[\U123456789]'
  let expected = ['[', '[\U', 'X', ']']
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '[a-b]'
  let expected = ['[', 'A-B', ']']
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '[\%]'
  let expected = ['[', 'X', 'X', ']']
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '\V%[a]'
  let expected = ['\V', 'X', 'X', 'X', 'X']
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '\V\%[a]'
  let expected = ['\V', '\%[', 'X', '\%]']
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '[^a]'
  let expected = ['[', '[^', 'X', ']']
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '[^-a]'
  let expected = ['[', '[^', 'X', 'X', ']']
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '[-a]'
  let expected = ['[', 'X', 'X', ']']
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '[^]'
  let expected = ['X', '^', 'X']
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '[]'
  let expected = ['X', 'X']
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '[^-]'
  let expected = ['[', '[^', 'X', ']']
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '^^'
  let expected = ['^', '^']
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '^^\|^^'
  let expected = ['^', '^', '\|', '^', '^']
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '.\@4321<='
  let expected = ['.', '\@123<=']
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '.\@4321<!'
  let expected = ['.', '\@123<!']
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '\%''k'
  let expected = ['\%''m']
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '\%4321l'
  let expected = ['\%l']
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '\%4321c'
  let expected = ['\%c']
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '\%4321v'
  let expected = ['\%v']
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '\%<''k'
  let expected = ['\%<''m']
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '\%<4321l'
  let expected = ['\%<l']
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '\%<4321c'
  let expected = ['\%<c']
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '\%<4321v'
  let expected = ['\%<v']
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '\%>''k'
  let expected = ['\%>''m']
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '\%>4321l'
  let expected = ['\%>l']
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '\%>4321c'
  let expected = ['\%>c']
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '\%>4321v'
  let expected = ['\%>v']
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '[\\e]'
  let expected = ['[', '\\', 'e', ']']
  let output = p.parse(input).values()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '[\\a]'
  let expected = ['[', 'X', 'X', ']']
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '[\\x ]'
  let expected = ['[', 'X', 'X', 'X', ']']
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     'a\cb'
  let expected = ['X', '\c', 'x']
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '\%'
  let expected = ['^^', 'Error: invalid character after \%']
  let output = p.parse(input).lines()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_true(has_error, input)

  let input =     '\)'
  let expected = ['^^', 'Error: unmatched \)']
  let output = p.parse(input).lines()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_true(has_error, input)

  let input =     'a\zb'
  let expected = ['-^^^', 'Error: invalid character after \z']
  let output = p.parse(input).lines()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_true(has_error, input)

  let input =     '\%['
  let expected = ['^^^', 'Error: missing ] after \%[']
  let output = p.parse(input).lines()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_true(has_error, input)

  let input =     '\%[a*]'
  let expected = ['----^', 'Error: * is not valid inside \%[]']
  let output = p.parse(input).lines()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_true(has_error, input)

  let input =     '\%[\(]'
  let expected = ['---^^', 'Error: \( is not valid inside \%[]']
  let output = p.parse(input).lines()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_true(has_error, input)

  let input =     '.**'
  let expected = ['--^', 'Error: * can not follow a multi']
  let output = p.parse(input).lines()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_true(has_error, input)

  let input =     '\%#=4'
  let expected = ['^^^^^', 'Error: \%#= can only be followed by 0, 1, or 2']
  let output = p.parse(input).lines()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_true(has_error, input)

  let input =     '[b-a]'
  let expected = ['-^^^', 'Error: reverse range in character class']
  let output = p.parse(input).lines()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_true(has_error, input)

  let input =     '\%[]'
  let expected = ['---^', 'Error: empty \%[]']
  let output = p.parse(input).lines()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_true(has_error, input)

  let input =     '\1'
  let expected = ['^^', 'Error: illegal back reference']
  let output = p.parse(input).lines()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_true(has_error, input)

  let input =     '\(\)\2'
  let expected = ['----^^', 'Error: illegal back reference']
  let output = p.parse(input).lines()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_true(has_error, input)

  let input =     '\(\)\(\)\(\)\(\)\(\)\(\)\(\)\(\)\(\)\(\)'
  let expected = ['------------------------------------^^', 'Error: more than 9 capturing groups']
  let output = p.parse(input).lines()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_true(has_error, input)

  let input =     '.\@x'
  let expected = ['-^^^', 'Error: invalid character after \@']
  let output = p.parse(input).lines()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_true(has_error, input)

  let input =     '\_b'
  let expected = ['^^^', 'Error: invalid use of \_']
  let output = p.parse(input).lines()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_true(has_error, input)

  let input =     '\+'
  let expected = ['^^', 'Error: \+ follows nothing']
  let output = p.parse(input).lines()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_true(has_error, input)

  let input =     '\%dx'
  let expected = ['^^^^', 'Error: invalid character after \%d']
  let output = p.parse(input).lines()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_true(has_error, input)

  let input =     '\%g'
  let expected = ['^^^', 'Error: invalid character after \%']
  let output = p.parse(input).lines()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_true(has_error, input)

  let input =     '.\{a}'
  let expected = ['-^^^^', 'Error: syntax error in \{a}']
  let output = p.parse(input).lines()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_true(has_error, input)

  let input =     '\@!'
  let expected = ['^^^', 'Error: \@! follows nothing']
  let output = p.parse(input).lines()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_true(has_error, input)

  let input =    '\s\+.*'
  let expected = '\m\C\s\+.*'
  let output = p.parse(input).match_group(0)
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =    '[[:abc:]]'
  let expected = '\m\C[[:abc:]]'
  let output = p.parse(input).match_group(0)
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =    'abc\(def\|ghi\)jkl'
  let expected = '\m\Cabc\(def\|ghi\)jkl'
  let output = p.parse(input).match_group(0)
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =    'abc\(def\|ghi\)jkl'
  let expected = '\m\Cabc\(def\|ghi\)jkl'
  let output = p.parse(input).match_group(0, 0)
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =    'abc\(def\|ghi\)jkl'
  let expected = '\m\Cabc\(\zsdef\ze\|\zsghi\ze\)jkl'
  let output = p.parse(input).match_group(0, 1)
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =    'abc\(def\|ghi\)jkl'
  let expected = ''
  let output = p.parse(input).match_group(0, 2)
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =    'a\zsbc\(def\|ghi\)jkl\(mno\)pq\zer'
  let expected = '\m\Cabc\(\zsdef\ze\|\zsghi\ze\)jkl\(mno\)pqr'
  let output = p.parse(input).match_group(0, 1)
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =    'a\zsbc\(def\|ghi\)jkl\(mno\)pq\zer'
  let expected = '\m\Cabc\(def\|ghi\)jkl\(\zsmno\ze\)pqr'
  let output = p.parse(input).match_group(0, 2)
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =    '\'
  let expected = '\m\C\\'
  let output = p.parse(input).match_group(0, 0)
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let g:relab_debug = debug
  if !empty(v:errors)
    let g:relab_debug = 0
    echohl ErrorMsg
    echom printf('%s error(s) found:', len(v:errors))
    echohl Normal
    for e in v:errors
      echohl WarningMsg
      echom  'Test failed: '
      echohl Normal
      echon e
    endfor
    let g:relab_debug = debug
    return 0
  endif
  return 1
endfunction
