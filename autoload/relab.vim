scriptencoding utf-8
" ToDo:
" - Live result update

function! relab#analysis(...) "{{{
  1DbgRELab printf('analysis:')
  let view = 'analysis'
  let regexp = get(a:, 1, '')
  let regexp = !empty(regexp) ? regexp : get(s:info, 'regexp', '')
  if empty(regexp)
    echohl ErrorMsg
    echom 'You need to provide a pattern!'
    echohl Normal
    return 0
  endif
  call s:update_info({'regexp': regexp, 'view': view})
  let parser = relab#parser#new()
  call parser.parse(regexp)
  let title = printf('RELab: %s', substitute(view, '^.', '\u&', ''))
  let lines = [title, regexp, '']
  let lines += parser.lines()
  return s:set_scratch(lines)
endfunction "}}}

function! relab#matches(validate, ...) "{{{
  1DbgRELab printf('show_matches:')
  let view = a:validate ? 'validate' : 'matches'
  let regexp = get(a:, 1, '')
  let regexp = !empty(regexp) ? regexp : get(s:info, 'regexp', '')
  let info = {'view': 'matches'}
  if !empty(regexp)
    let info.regexp = regexp
  endif
  call s:update_info(info)
  let parser = relab#parser#new()
  call parser.parse(regexp)
  if !s:set_scratch(s:info.lines)
    return
  endif
  let regexp = join(parser.values(), '')
  let title = printf('RELab: %s', substitute(view, '^.', '\u&', ''))
  let lines = [title, regexp, '']
  if !empty(parser.errors)
    call add(lines, regexp)
    call extend(lines, parser.lines())
  else
    let matches = s:get_matches(regexp, parser.capt_groups)
    for item in matches.lines
      if empty(item.matches) && a:validate
        call add(lines, printf('-:%s', item.line))
      else
        let matches.match_found = 1
        call extend(lines, item.matches)
      endif
    endfor
  endif
  if !has_key(matches, 'match_found') && !a:validate
    call add(lines, 'No matches found')
  endif
  silent! %delete _
  return setline(1, lines) == 0
endfunction "}}}

function! relab#set(...) "{{{
  1DbgRELab printf('set:')
  let regexp = get(a:, 1, '')
  let regexp = !empty(regexp) ? regexp : get(s:info, 'regexp', '')
  if !empty(regexp)
    call s:update_info({'regexp': regexp})
  endif
  return s:refresh()
endfunction "}}}

function! relab#get_sample(first, last, file) "{{{
  1DbgRELab printf('get_sample:')
  if empty(a:file)
    let lines = getline(a:first, a:last)
  elseif filereadable(a:file)
    let lines = readfile(a:file)
  else
    echohl ErrorMsg
    echom printf('Could not read file: %s', a:file)
    echohl Normal
    return 0
  endif
  let s:info.lines = lines
  return s:set_scratch(lines)
endfunction "}}}

function! relab#line2regexp(linenr) "{{{
  1DbgRELab printf('line2regexp:')
  let regexp = get(a:, 1, '')
  let regexp = !empty(regexp) ? regexp : get(s:info, 'regexp', '')
  let linenr = a:linenr > 0 ? a:linenr : '.'
  let regexp = getline(linenr)
  let s:info.regexp = regexp
  let parser = relab#parser#new()
  call parser.parse(regexp)
  call s:update_info({'regexp': regexp})
  return s:refresh()
endfunction "}}}

function! s:set_scratch(lines) "{{{
  let lazyredraw = &lazyredraw
  set lazyredraw
  let fname = 'scratch.relab'
  let winnr = bufwinnr(fname)
  if winnr >= 0
    execute printf('%swincmd w', winnr)
  else
    execute printf('botright silent split %s', fname)
    "setlocal filetype=relab
    setlocal buftype=nofile
    setlocal noundofile
    setlocal noswapfile
    setlocal undolevels=-1
  endif
  if bufname('%') !=# fname
    let &lazyredraw = lazyredraw
    return 1
  endif
  silent %delete _
  let lines_set = setline(1, a:lines) == 0
  let &lazyredraw = lazyredraw
  return lines_set
endfunction "}}}

function! s:get_matches(regexp, groupnr) "{{{
  1DbgRELab printf('get_matches:')
  let matches = {}
  let matches.lines = []
  let matches.submatches = join(map(range(a:groupnr + 1),
        \ {key, val -> 'submatch('.val.')'}), ',')
  function matches.get(...)
    let self.current.matches = map(copy(a:000),
          \ {key, val -> printf('%s%s: %s', (key ? '  ' : ''), key, val)})
    return get(a:, 1, '')
  endfunction
  function matches.run(regexp)
    let self.current = {}
    let self.current.linenr = line('.')
    let self.current.line = getline('.')
    let self.current.matches = []
    execute printf('silent! s/%s/\=self.get(%s)/', a:regexp, self.submatches)
    call add(self.lines, self.current)
  endfunction
  silent! %delete _
  call setline(1, s:info.lines)
  silent! g/^/call matches.run(a:regexp)
  return matches
endfunction "}}}

function! relab#debug(verbose, msg) "{{{
  if a:verbose <= get(g:, 'relab_debug', 0)
    echom printf('%sRELab: %s', a:verbose, a:msg)
  endif
endfunction "}}}

function! s:update_info(dict) "{{{
  let info = extend(copy(a:dict), s:info, 'keep')
  if info == s:info
    return s:info
  endif
  DbgRELab 'Updating info and saving it to: ' . s:file
  let s:info = info
  let data = [info.view, info.regexp] + info.lines
  call writefile(data, s:file, 's')
  return s:info
endfunction "}}}

function! s:refresh() "{{{
  let info = s:update_info({})
  if info.view ==# 'validate'
    return relab#matches(1, info.regexp)
  elseif info.view ==# 'matches'
    return relab#matches(0, info.regexp)
  elseif info.view ==# 'analysis'
    return relab#analysis(info.regexp)
  else
    return
  endif
endfunction "}}}

let relab = relab#parser#new() "{{{
let s:file = get(g:, 'relab_path',
      \ printf('%s/data.txt', expand('<sfile>:p:h:h')))
let s:data = filereadable(s:file) ? readfile(s:file) : []
if exists('s:info') || len(s:data) < 2
  let s:info = get(s:, 'info', {})
  let s:info.view = 'validate'
  let s:info.regexp = get(s:info, 'regexp',
        \ '^\(\%(\S\|\\.\)\+\)@\(\S\+\.\S\+\)$')
  let s:info.lines = get(s:info, 'lines', [
        \ 'This is some text to play with your regular expressions',
        \ 'Read :help relab',
        \ '',
        \ 'Some emails from http://codefool.tumblr.com/post/15288874550/'
        \ . 'list-of-valid-and-invalid-email-addresses',
        \ 'List of Valid Email Addresses',
        \ '',
        \ 'email@example.com',
        \ 'firstname.lastname@example.com',
        \ 'email@subdomain.example.com',
        \ 'firstname+lastname@example.com',
        \ 'email@123.123.123.123',
        \ 'email@[123.123.123.123]',
        \ '“email”@example.com',
        \ '1234567890@example.com',
        \ 'email@example-one.com',
        \ '_______@example.com',
        \ 'email@example.name',
        \ 'email@example.museum',
        \ 'email@example.co.jp',
        \ 'firstname-lastname@example.com',
        \ '',
        \ 'List of Strange Valid Email Addresses',
        \ '',
        \ 'much.“more\ unusual”@example.com',
        \ 'very.unusual.“@”.unusual.com@example.com',
        \ 'very.“(),:;<>[]”.VERY.“very@\\ "very”.unusual@strange.example.com',
        \ '',
        \ 'List of Invalid Email Addresses',
        \ '',
        \ 'plainaddress',
        \ '#@%^%#$@#$@#.com',
        \ '@example.com',
        \ 'Joe Smith <email@example.com>',
        \ 'email.example.com',
        \ 'email@example@example.com',
        \ '.email@example.com',
        \ 'email.@example.com',
        \ 'email..email@example.com',
        \ 'あいうえお@example.com',
        \ 'email@example.com (Joe Smith)',
        \ 'email@example',
        \ 'email@-example.com',
        \ 'email@example.web',
        \ 'email@111.222.333.44444',
        \ 'email@example..com',
        \ 'Abc..123@example.com',
        \ '',
        \ 'List of Strange Invalid Email Addresses',
        \ '',
        \ '“(),:;<>[\]@example.com',
        \ 'just"not"right@example.com',
        \ 'this\ is"really"not\allowed@example.com',
        \ ])
else
  let s:info = {}
  let [s:info.view, s:info.regexp; s:info.lines] = s:data
endif
unlet! s:data
