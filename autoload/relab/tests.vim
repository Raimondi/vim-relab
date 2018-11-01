function! relab#tests#run(...) abort "{{{
  if exists('g:relab_debug')
    let debug = g:relab_debug
    unlet g:relab_debug
  endif
  let v:errors = []
  let all_test_functions = ['parser', 'views', 'node']
  if !a:0 || a:1 ==# 'all'
    let test_functions = all_test_functions
  else
    let test_functions = a:000
  endif
  for f in test_functions
    if index(test_functions, f) >= 0
      call function(printf('s:%s', f))()
    endif
  endfor
  if exists('debug')
    let g:relab_debug = debug
  endif

  if !empty(v:errors)
    echohl ErrorMsg
    echom printf('%s error(s) found:', len(v:errors))
    echohl Normal
    for e in v:errors
      let test = substitute(e, '\(.\{-}\) Expected .\{-} but got .*',
            \ '  \1', '')
      let expected = substitute(e, '.\{-} Expected \(.\{-}\) but got .*',
            \ '  expected: \1', '')
      let result = substitute(e, '.\{-} Expected .\{-} but got \(.*\)',
            \ '  but got : \1', '')
      echohl WarningMsg
      echom  'Test failed: '
      echohl Normal
      echom test
      echom expected
      echom result
    endfor
    return 0
  endif
  return 1
endfunction "}}}

function! s:parser() "{{{
  let input =     ''
  let expected = []
  let p = relab#parser#new()
  let output = p.parse(input).magics()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '^'
  let expected = ['^']
  let p = relab#parser#new()
  let output = p.parse(input).magics()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '^a\+'
  let expected = ['^', 'a', '\+']
  let p = relab#parser#new()
  let output = p.parse(input).magics()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '^a\+\vb+'
  let expected = ['^', 'a', '\+', '\v', 'b', '\+']
  let p = relab#parser#new()
  let output = p.parse(input).magics()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '.\{}'
  let expected = ['.', '\{}']
  let p = relab#parser#new()
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '.\{1}'
  let expected = ['.', '\{n}']
  let p = relab#parser#new()
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '.\{1,}'
  let expected = ['.', '\{n,}']
  let p = relab#parser#new()
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '.\{1,2}'
  let expected = ['.', '\{n,m}']
  let p = relab#parser#new()
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '.\{,2}'
  let expected = ['.', '\{,m}']
  let p = relab#parser#new()
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '.\{,}'
  let expected = ['.', '\{,}']
  let p = relab#parser#new()
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '.\{-}'
  let expected = ['.', '\{-}']
  let p = relab#parser#new()
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '.\{-1}'
  let expected = ['.', '\{-n}']
  let p = relab#parser#new()
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '.\{-1,}'
  let expected = ['.', '\{-n,}']
  let p = relab#parser#new()
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '.\{-1,2}'
  let expected = ['.', '\{-n,m}']
  let p = relab#parser#new()
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '.\{-,2}'
  let expected = ['.', '\{-,m}']
  let p = relab#parser#new()
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '.\{-,}'
  let expected = ['.', '\{-,}']
  let p = relab#parser#new()
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '.\?'
  let expected = ['.', '\?']
  let p = relab#parser#new()
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '.\='
  let expected = ['.', '\=']
  let p = relab#parser#new()
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '.*'
  let expected = ['.', '*']
  let p = relab#parser#new()
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '.\+'
  let expected = ['.', '\+']
  let p = relab#parser#new()
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '\v\1'
  let expected = ['\v', '\1']
  let p = relab#parser#new()
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_true(has_error, input)

  let input =     '\%x1234'
  let expected = ['\%x', 'X', 'X']
  let p = relab#parser#new()
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '\%o1234'
  let expected = ['\%o', 'X']
  let p = relab#parser#new()
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '\%o0377'
  let expected = ['\%o']
  let p = relab#parser#new()
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '\%o377'
  let expected = ['\%o']
  let p = relab#parser#new()
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '\%o400'
  let expected = ['\%o', 'X']
  let p = relab#parser#new()
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '\%o0400'
  let expected = ['\%o', 'X']
  let p = relab#parser#new()
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '\%#=0'
  let expected = ['\%#=']
  let p = relab#parser#new()
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     'a\@>'
  let expected = ['X', '\@>']
  let p = relab#parser#new()
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '\_.'
  let expected = ['\_.']
  let p = relab#parser#new()
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '\a'
  let expected = ['\a']
  let p = relab#parser#new()
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '\_a'
  let expected = ['\_a']
  let p = relab#parser#new()
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '.\@!'
  let expected = ['.', '\@!']
  let p = relab#parser#new()
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     'a\zsb'
  let expected = ['X', '\zs', 'X']
  let p = relab#parser#new()
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     'a\zeb'
  let expected = ['X', '\ze', 'X']
  let p = relab#parser#new()
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '[ab]'
  let expected = ['[', 'X', 'X', ']']
  let p = relab#parser#new()
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '[ab'
  let expected = ['X', 'X', 'X']
  let p = relab#parser#new()
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '[\d1234]'
  let expected = ['[', '[\d', ']']
  let p = relab#parser#new()
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '[\o123]'
  let expected = ['[', '[\o', ']']
  let p = relab#parser#new()
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '[\x12]'
  let expected = ['[', '[\x', ']']
  let p = relab#parser#new()
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '[\u1234]'
  let expected = ['[', '[\u', ']']
  let p = relab#parser#new()
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '[\U12345678]'
  let expected = ['[', '[\U', ']']
  let p = relab#parser#new()
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '[\U123456789]'
  let expected = ['[', '[\U', 'X', ']']
  let p = relab#parser#new()
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '[a-b]'
  let expected = ['[', 'A-B', ']']
  let p = relab#parser#new()
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '[\%]'
  let expected = ['[', 'X', 'X', ']']
  let p = relab#parser#new()
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '\V%[a]'
  let expected = ['\V', 'X', 'X', 'X', 'X']
  let p = relab#parser#new()
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '\V\%[a]'
  let expected = ['\V', '\%[', 'X', '\%]']
  let p = relab#parser#new()
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '[^a]'
  let expected = ['[', '[^', 'X', ']']
  let p = relab#parser#new()
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '[^-a]'
  let expected = ['[', '[^', 'X', 'X', ']']
  let p = relab#parser#new()
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '[-a]'
  let expected = ['[', 'X', 'X', ']']
  let p = relab#parser#new()
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '[^]'
  let expected = ['X', '^', 'X']
  let p = relab#parser#new()
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '[]'
  let expected = ['X', 'X']
  let p = relab#parser#new()
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '[^-]'
  let expected = ['[', '[^', 'X', ']']
  let p = relab#parser#new()
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '^^'
  let expected = ['^', '^']
  let p = relab#parser#new()
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '^^\|^^'
  let expected = ['^', '^', '\|', '^', '^']
  let p = relab#parser#new()
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '.\@4321<='
  let expected = ['.', '\@123<=']
  let p = relab#parser#new()
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '.\@4321<!'
  let expected = ['.', '\@123<!']
  let p = relab#parser#new()
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '\%''k'
  let expected = ['\%''m']
  let p = relab#parser#new()
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '\%4321l'
  let expected = ['\%l']
  let p = relab#parser#new()
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '\%4321c'
  let expected = ['\%c']
  let p = relab#parser#new()
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '\%4321v'
  let expected = ['\%v']
  let p = relab#parser#new()
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '\%<''k'
  let expected = ['\%<''m']
  let p = relab#parser#new()
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '\%<4321l'
  let expected = ['\%<l']
  let p = relab#parser#new()
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '\%<4321c'
  let expected = ['\%<c']
  let p = relab#parser#new()
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '\%<4321v'
  let expected = ['\%<v']
  let p = relab#parser#new()
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '\%>''k'
  let expected = ['\%>''m']
  let p = relab#parser#new()
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '\%>4321l'
  let expected = ['\%>l']
  let p = relab#parser#new()
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '\%>4321c'
  let expected = ['\%>c']
  let p = relab#parser#new()
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '\%>4321v'
  let expected = ['\%>v']
  let p = relab#parser#new()
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '[\\e]'
  let expected = ['[', '\\', 'e', ']']
  let p = relab#parser#new()
  let output = p.parse(input).values()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '[\\a]'
  let expected = ['[', 'X', 'X', ']']
  let p = relab#parser#new()
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '[\\x ]'
  let expected = ['[', 'X', 'X', 'X', ']']
  let p = relab#parser#new()
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     'a\cb'
  let expected = ['X', '\c', 'x']
  let p = relab#parser#new()
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '\%'
  let expected = ['^^', 'Error: invalid character after \%']
  let p = relab#parser#new()
  let output = p.parse(input).lines()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_true(has_error, input)

  let input =     '\)'
  let expected = ['^^', 'Error: unmatched \)']
  let p = relab#parser#new()
  let output = p.parse(input).lines()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_true(has_error, input)

  let input =     'a\zb'
  let expected = ['-^^^', 'Error: invalid character after \z']
  let p = relab#parser#new()
  let output = p.parse(input).lines()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_true(has_error, input)

  let input =     '\%['
  let expected = ['^^^', 'Error: missing ] after \%[']
  let p = relab#parser#new()
  let output = p.parse(input).lines()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_true(has_error, input)

  let input =     '\%[a*]'
  let expected = ['----^', 'Error: * is not valid inside \%[]']
  let p = relab#parser#new()
  let output = p.parse(input).lines()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_true(has_error, input)

  let input =     '\%[\(]'
  let expected = ['---^^', 'Error: \( is not valid inside \%[]']
  let p = relab#parser#new()
  let output = p.parse(input).lines()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_true(has_error, input)

  let input =     '.**'
  let expected = ['--^', 'Error: * can not follow a multi']
  let p = relab#parser#new()
  let output = p.parse(input).lines()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_true(has_error, input)

  let input =     '\%#=4'
  let expected = ['^^^^^', 'Error: \%#= can only be followed by 0, 1, or 2']
  let p = relab#parser#new()
  let output = p.parse(input).lines()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_true(has_error, input)

  let input =     '[b-a]'
  let expected = ['-^^^', 'Error: reverse range in character class']
  let p = relab#parser#new()
  let output = p.parse(input).lines()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_true(has_error, input)

  let input =     '\%[]'
  let expected = ['---^', 'Error: empty \%[]']
  let p = relab#parser#new()
  let output = p.parse(input).lines()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_true(has_error, input)

  let input =     '\1'
  let expected = ['^^', 'Error: illegal back reference']
  let p = relab#parser#new()
  let output = p.parse(input).lines()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_true(has_error, input)

  let input =     '\(\)\2'
  let expected = ['----^^', 'Error: illegal back reference']
  let p = relab#parser#new()
  let output = p.parse(input).lines()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_true(has_error, input)

  let input =     '\(\)\(\)\(\)\(\)\(\)\(\)\(\)\(\)\(\)\(\)'
  let expected = ['------------------------------------^^',
        \ 'Error: more than 9 capturing groups']
  let p = relab#parser#new()
  let output = p.parse(input).lines()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_true(has_error, input)

  let input =     '.\@x'
  let expected = ['-^^^', 'Error: invalid character after \@']
  let p = relab#parser#new()
  let output = p.parse(input).lines()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_true(has_error, input)

  let input =     '\_b'
  let expected = ['^^^', 'Error: invalid use of \_']
  let p = relab#parser#new()
  let output = p.parse(input).lines()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_true(has_error, input)

  let input =     '\+'
  let expected = ['^^', 'Error: \+ follows nothing']
  let p = relab#parser#new()
  let output = p.parse(input).lines()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_true(has_error, input)

  let input =     '\%dx'
  let expected = ['^^^^', 'Error: invalid character after \%d']
  let p = relab#parser#new()
  let output = p.parse(input).lines()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_true(has_error, input)

  let input =     '\%g'
  let expected = ['^^^', 'Error: invalid character after \%']
  let p = relab#parser#new()
  let output = p.parse(input).lines()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_true(has_error, input)

  let input =     '.\{a}'
  let expected = ['-^^^^', 'Error: syntax error in \{a}']
  let p = relab#parser#new()
  let output = p.parse(input).lines()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_true(has_error, input)

  let input =     '\@!'
  let expected = ['^^^', 'Error: \@! follows nothing']
  let p = relab#parser#new()
  let output = p.parse(input).lines()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_true(has_error, input)

  let input =    '\s\+.*'
  let expected = '\m\C\s\+.*'
  let p = relab#parser#new()
  let output = p.parse(input).match_group(0)
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =    '[[:abc:]]'
  let expected = '\m\C[[:abc:]]'
  let p = relab#parser#new()
  let output = p.parse(input).match_group(0)
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =    'abc\(def\|ghi\)jkl'
  let expected = '\m\Cabc\(def\|ghi\)jkl'
  let p = relab#parser#new()
  let output = p.parse(input).match_group(0)
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =    'abc\(def\|ghi\)jkl'
  let expected = '\m\Cabc\(def\|ghi\)jkl'
  let p = relab#parser#new()
  let output = p.parse(input).match_group(0, 0)
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =    'abc\(def\|ghi\)jkl'
  let expected = '\m\Cabc\(\zsdef\ze\|\zsghi\ze\)jkl'
  let p = relab#parser#new()
  let output = p.parse(input).match_group(0, 1)
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =    'abc\(def\|ghi\)jkl'
  let expected = ''
  let p = relab#parser#new()
  let output = p.parse(input).match_group(0, 2)
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =    'a\zsbc\(def\|ghi\)jkl\(mno\)pq\zer'
  let expected = '\m\Cabc\(\zsdef\ze\|\zsghi\ze\)jkl\(mno\)pqr'
  let p = relab#parser#new()
  let output = p.parse(input).match_group(0, 1)
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =    'a\zsbc\(def\|ghi\)jkl\(mno\)pq\zer'
  let expected = '\m\Cabc\(def\|ghi\)jkl\(\zsmno\ze\)pqr'
  let p = relab#parser#new()
  let output = p.parse(input).match_group(0, 2)
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =    '\'
  let expected = '\m\C\\'
  let p = relab#parser#new()
  let output = p.parse(input).match_group(0, 0)
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '/a/'
  let expected = ['a']
  let p = relab#parser#new('/')
  let output = p.parse(input).values()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '/a/b'
  let expected = 'b'
  let p = relab#parser#new('/')
  let output = p.parse(input).input_remaining
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '/a\/b'
  let expected = ['a', '/', 'b']
  let p = relab#parser#new('/')
  let output = p.parse(input).values()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '/a\/b/'
  let expected = ['a', '/', 'b']
  let p = relab#parser#new('/')
  let output = p.parse(input).values()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '+a\+b+'
  let expected = ['a', '\+', 'b']
  let p = relab#parser#new('+')
  let output = p.parse(input).values()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '\(\|\)\+'
  let expected = ['\(', '\|', '\)', '\+']
  let p = relab#parser#new()
  let output = p.parse(input).values()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  call assert_fails('call relab#parser#new(''a'')')

  call assert_fails('call relab#parser#new(''ab'')')

  call assert_fails('call relab#parser#new(''//'')')
endfunction "}}}

function! s:node() "{{{
endfunction "}}}

function! s:views() "{{{
  let g:relab_no_file = 1
  if !&lazyredraw
    let nolazyredraw = 1
  endif
  silent tabnew
  let bufnr = bufnr('%')

  call s:reset()
  RELab

  let got = bufname('%')
  let expected = 'RELab'
  let msg = 'Not the right buffer'
  if !assert_equal(expected, got, msg)

    let got = line('$')
    let expected = 148
    let msg = 'Wrong number of lines'
    if !assert_equal(expected, got, msg)

      let got = getline(1)
      let expected =  'RELab: Validation'
      let msg = 'Not the right title'
      call assert_equal(expected, got, msg)

      let got = getline(2)
      let expected =  '^\(\%(\S\|\\.\)\+\)@\(\S\+\.\S\+\)$'
      let msg = 'Not the right regexp'
      call assert_equal(expected, got, msg)

      let got = getline('$')
      let expected =  ' \2:example.com'
      call assert_equal(expected, got)

    endif

    RELabDescribe

    let got = line('$')
    let expected = 22
    let msg = 'Wrong number of lines'
    if !assert_equal(expected, got, msg)

      let got = getline(1)
      let expected =  'RELab: Description'
      let msg = 'Not the right title'
      call assert_equal(expected, got, msg)

      let got = getline(2)
      let expected =  '^\(\%(\S\|\\.\)\+\)@\(\S\+\.\S\+\)$'
      let msg = 'Not the right regexp'
      call assert_equal(expected, got, msg)

      let got = getline(21)
      let expected =  '  \) => Ends a capturing group.'
      call assert_equal(expected, got)

    endif

    RELabMatches

    let got = line('$')
    let expected = 127
    let msg = 'Wrong number of lines'
    if !assert_equal(expected, got, msg)

      let got = getline(1)
      let expected =  'RELab: Matches'
      let msg = 'Not the right title'
      call assert_equal(expected, got, msg)

      let got = getline(2)
      let expected =  '^\(\%(\S\|\\.\)\+\)@\(\S\+\.\S\+\)$'
      let msg = 'Not the right regexp'
      call assert_equal(expected, got, msg)

      let got = getline('$')
      let expected =  ' \2:example.com'
      call assert_equal(expected, got)

    endif

    RELabSample

    let got = line('$')
    let expected = 52
    let msg = 'Wrong number of lines'
    if !assert_equal(expected, got, msg)

      let got = getline(1)
      let expected =  'This is some text to play with your regular '
            \ . 'expressions'
      let msg = 'Wrong line content'
      call assert_equal(expected, got, msg)

      let got = getline(2)
      let expected =  'Read :help relab'
      let msg = 'Wrong line content'
      call assert_equal(expected, got, msg)

      let got = getline('$')
      let expected =  'this\ is"really"not\allowed@example.com'
      let msg = 'Wrong line content'
      call assert_equal(expected, got, msg)

    endif

    RELabValidate

    let got = line('$')
    let expected = 148
    let msg = 'Wrong number of lines'
    if !assert_equal(expected, got, msg)

      let got = getline(1)
      let expected =  'RELab: Validation'
      let msg = 'Not the right title'
      call assert_equal(expected, got, msg)

      let got = getline(2)
      let expected =  '^\(\%(\S\|\\.\)\+\)@\(\S\+\.\S\+\)$'
      let msg = 'Not the right regexp'
      call assert_equal(expected, got, msg)

      let got = getline('$')
      let expected =  ' \2:example.com'
      call assert_equal(expected, got)

    endif

  endif

  call s:reset()
  RELabDescribe

  let got = bufname('%')
  let expected = 'RELab'
  let msg = 'Not the right buffer'
  if !assert_equal(expected, got, msg)

    let got = line('$')
    let expected = 22
    let msg = 'Wrong number of lines'
    if !assert_equal(expected, got, msg)

      let got = getline(1)
      let expected =  'RELab: Description'
      let msg = 'Not the right title'
      call assert_equal(expected, got, msg)

      let got = getline(2)
      let expected =  '^\(\%(\S\|\\.\)\+\)@\(\S\+\.\S\+\)$'
      let msg = 'Not the right regexp'
      call assert_equal(expected, got, msg)

      let got = getline(21)
      let expected =  '  \) => Ends a capturing group.'
      call assert_equal(expected, got)

    endif

    RELabSample

    let got = line('$')
    let expected = 52
    let msg = 'Wrong number of lines'
    if !assert_equal(expected, got, msg)

      let got = getline(1)
      let expected =  'This is some text to play with your regular '
            \ . 'expressions'
      let msg = 'Wrong line content'
      call assert_equal(expected, got, msg)

      let got = getline(2)
      let expected =  'Read :help relab'
      let msg = 'Wrong line content'
      call assert_equal(expected, got, msg)

      let got = getline('$')
      let expected =  'this\ is"really"not\allowed@example.com'
      let msg = 'Wrong line content'
      call assert_equal(expected, got, msg)

    endif

    RELabValidate

    let got = line('$')
    let expected = 148
    let msg = 'Wrong number of lines'
    if !assert_equal(expected, got, msg)

      let got = getline(1)
      let expected =  'RELab: Validation'
      let msg = 'Not the right title'
      call assert_equal(expected, got, msg)

      let got = getline(2)
      let expected =  '^\(\%(\S\|\\.\)\+\)@\(\S\+\.\S\+\)$'
      let msg = 'Not the right regexp'
      call assert_equal(expected, got, msg)

      let got = getline('$')
      let expected =  ' \2:example.com'
      call assert_equal(expected, got)

    endif

    RELabMatches

    let got = line('$')
    let expected = 127
    let msg = 'Wrong number of lines'
    if !assert_equal(expected, got, msg)

      let got = getline(1)
      let expected =  'RELab: Matches'
      let msg = 'Not the right title'
      call assert_equal(expected, got, msg)

      let got = getline(2)
      let expected =  '^\(\%(\S\|\\.\)\+\)@\(\S\+\.\S\+\)$'
      let msg = 'Not the right regexp'
      call assert_equal(expected, got, msg)

      let got = getline('$')
      let expected =  ' \2:example.com'
      call assert_equal(expected, got)

    endif

  endif

  call s:reset()
  RELabSample

  let got = bufname('%')
  let expected = 'RELab'
  let msg = 'Not the right buffer'
  if !assert_equal(expected, got, msg)

    let got = line('$')
    let expected = 52
    let msg = 'Wrong number of lines'
    if !assert_equal(expected, got, msg)

      let got = getline(1)
      let expected =  'This is some text to play with your regular '
            \ . 'expressions'
      let msg = 'Wrong line content'
      call assert_equal(expected, got, msg)

      let got = getline(2)
      let expected =  'Read :help relab'
      let msg = 'Wrong line content'
      call assert_equal(expected, got, msg)

      let got = getline('$')
      let expected =  'this\ is"really"not\allowed@example.com'
      let msg = 'Wrong line content'
      call assert_equal(expected, got, msg)

    endif

    RELabValidate

    let got = line('$')
    let expected = 148
    let msg = 'Wrong number of lines'
    if !assert_equal(expected, got, msg)

      let got = getline(1)
      let expected =  'RELab: Validation'
      let msg = 'Not the right title'
      call assert_equal(expected, got, msg)

      let got = getline(2)
      let expected =  '^\(\%(\S\|\\.\)\+\)@\(\S\+\.\S\+\)$'
      let msg = 'Not the right regexp'
      call assert_equal(expected, got, msg)

      let got = getline('$')
      let expected =  ' \2:example.com'
      call assert_equal(expected, got)

    endif

    RELabMatches

    let got = line('$')
    let expected = 127
    let msg = 'Wrong number of lines'
    if !assert_equal(expected, got, msg)

      let got = getline(1)
      let expected =  'RELab: Matches'
      let msg = 'Not the right title'
      call assert_equal(expected, got, msg)

      let got = getline(2)
      let expected =  '^\(\%(\S\|\\.\)\+\)@\(\S\+\.\S\+\)$'
      let msg = 'Not the right regexp'
      call assert_equal(expected, got, msg)

      let got = getline('$')
      let expected =  ' \2:example.com'
      call assert_equal(expected, got)

    endif

    RELabValidate

    let got = line('$')
    let expected = 148
    let msg = 'Wrong number of lines'
    if !assert_equal(expected, got, msg)

      let got = getline(1)
      let expected =  'RELab: Validation'
      let msg = 'Not the right title'
      call assert_equal(expected, got, msg)

      let got = getline(2)
      let expected =  '^\(\%(\S\|\\.\)\+\)@\(\S\+\.\S\+\)$'
      let msg = 'Not the right regexp'
      call assert_equal(expected, got, msg)

      let got = getline('$')
      let expected =  ' \2:example.com'
      call assert_equal(expected, got)

    endif

  endif

  call s:reset()
  RELabMatches

  let got = bufname('%')
  let expected = 'RELab'
  let msg = 'Not the right buffer'
  if !assert_equal(expected, got, msg)

    let got = line('$')
    let expected = 127
    let msg = 'Wrong number of lines'
    if !assert_equal(expected, got, msg)

      let got = getline(1)
      let expected =  'RELab: Matches'
      let msg = 'Not the right title'
      call assert_equal(expected, got, msg)

      let got = getline(2)
      let expected =  '^\(\%(\S\|\\.\)\+\)@\(\S\+\.\S\+\)$'
      let msg = 'Not the right regexp'
      call assert_equal(expected, got, msg)

      let got = getline('$')
      let expected =  ' \2:example.com'
      call assert_equal(expected, got)

    endif

    RELabDescribe

    let got = line('$')
    let expected = 22
    let msg = 'Wrong number of lines'
    if !assert_equal(expected, got, msg)

      let got = getline(1)
      let expected =  'RELab: Description'
      let msg = 'Not the right title'
      call assert_equal(expected, got, msg)

      let got = getline(2)
      let expected =  '^\(\%(\S\|\\.\)\+\)@\(\S\+\.\S\+\)$'
      let msg = 'Not the right regexp'
      call assert_equal(expected, got, msg)

      let got = getline(21)
      let expected =  '  \) => Ends a capturing group.'
      call assert_equal(expected, got)

    endif

    RELabSample

    let got = line('$')
    let expected = 52
    let msg = 'Wrong number of lines'
    if !assert_equal(expected, got, msg)

      let got = getline(1)
      let expected =  'This is some text to play with your regular '
            \ . 'expressions'
      let msg = 'Wrong line content'
      call assert_equal(expected, got, msg)

      let got = getline(2)
      let expected =  'Read :help relab'
      let msg = 'Wrong line content'
      call assert_equal(expected, got, msg)

      let got = getline('$')
      let expected =  'this\ is"really"not\allowed@example.com'
      let msg = 'Wrong line content'
      call assert_equal(expected, got, msg)

    endif

    RELabValidate

    let got = line('$')
    let expected = 148
    let msg = 'Wrong number of lines'
    if !assert_equal(expected, got, msg)

      let got = getline(1)
      let expected =  'RELab: Validation'
      let msg = 'Not the right title'
      call assert_equal(expected, got, msg)

      let got = getline(2)
      let expected =  '^\(\%(\S\|\\.\)\+\)@\(\S\+\.\S\+\)$'
      let msg = 'Not the right regexp'
      call assert_equal(expected, got, msg)

      let got = getline('$')
      let expected =  ' \2:example.com'
      call assert_equal(expected, got)

    endif

  endif

  call s:reset()
  RELabValidate

  let got = bufname('%')
  let expected = 'RELab'
  let msg = 'Not the right buffer'
  if !assert_equal(expected, got, msg)

    let got = line('$')
    let expected = 148
    let msg = 'Wrong number of lines'
    if !assert_equal(expected, got, msg)

      let got = getline(1)
      let expected =  'RELab: Validation'
      let msg = 'Not the right title'
      call assert_equal(expected, got, msg)

      let got = getline(2)
      let expected =  '^\(\%(\S\|\\.\)\+\)@\(\S\+\.\S\+\)$'
      let msg = 'Not the right regexp'
      call assert_equal(expected, got, msg)

      let got = getline('$')
      let expected =  ' \2:example.com'
      call assert_equal(expected, got)

    endif

    RELabDescribe

    let got = line('$')
    let expected = 22
    let msg = 'Wrong number of lines'
    if !assert_equal(expected, got, msg)

      let got = getline(1)
      let expected =  'RELab: Description'
      let msg = 'Not the right title'
      call assert_equal(expected, got, msg)

      let got = getline(2)
      let expected =  '^\(\%(\S\|\\.\)\+\)@\(\S\+\.\S\+\)$'
      let msg = 'Not the right regexp'
      call assert_equal(expected, got, msg)

      let got = getline(21)
      let expected =  '  \) => Ends a capturing group.'
      call assert_equal(expected, got)

    endif

    RELabMatches

    let got = line('$')
    let expected = 127
    let msg = 'Wrong number of lines'
    if !assert_equal(expected, got, msg)

      let got = getline(1)
      let expected =  'RELab: Matches'
      let msg = 'Not the right title'
      call assert_equal(expected, got, msg)

      let got = getline(2)
      let expected =  '^\(\%(\S\|\\.\)\+\)@\(\S\+\.\S\+\)$'
      let msg = 'Not the right regexp'
      call assert_equal(expected, got, msg)

      let got = getline('$')
      let expected =  ' \2:example.com'
      call assert_equal(expected, got)

    endif

    RELabSample

    let got = line('$')
    let expected = 52
    let msg = 'Wrong number of lines'
    if !assert_equal(expected, got, msg)

      let got = getline(1)
      let expected =  'This is some text to play with your regular '
            \ . 'expressions'
      let msg = 'Wrong line content'
      call assert_equal(expected, got, msg)

      let got = getline(2)
      let expected =  'Read :help relab'
      let msg = 'Wrong line content'
      call assert_equal(expected, got, msg)

      let got = getline('$')
      let expected =  'this\ is"really"not\allowed@example.com'
      let msg = 'Wrong line content'
      call assert_equal(expected, got, msg)

    endif

  endif

  call s:reset()
  RELabValidate

  let got = bufname('%')
  let expected = 'RELab'
  let msg = 'Not the right buffer'
  if !assert_equal(expected, got, msg)

    let got = line('$')
    let expected = 148
    let msg = 'Wrong number of lines'
    if !assert_equal(expected, got, msg)

      let got = getline(1)
      let expected =  'RELab: Validation'
      let msg = 'Not the right title'
      call assert_equal(expected, got, msg)

      let got = getline(2)
      let expected =  '^\(\%(\S\|\\.\)\+\)@\(\S\+\.\S\+\)$'
      let msg = 'Not the right regexp'
      call assert_equal(expected, got, msg)

      let got = getline('$')
      let expected =  ' \2:example.com'
      call assert_equal(expected, got)

    endif

    call setline(2, 'a\+')
    doau TextChanged
    let got = getline(5)
    let expected =  '0:a'
    call assert_equal(expected, got)

    "call setline(2, 'a\+')
    let got = getline(6)
    let expected =  '0:a'
    call assert_equal(expected, got)

  endif

  silent tabclose!
  silent execute printf('bwipe! %s', bufnr)
  unlet! g:relab_no_file
  call s:reset()
  if exists('nolazyredraw')
    set nolazyredraw
  endif
endfunction "}}}

function! s:reset() "{{{
  call relab#test_helper()
  unlet! g:relab_view
  silent! bwipe! RELab
endfunction "}}}
