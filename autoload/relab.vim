scriptencoding utf-8

function! relab#analysis(...) "{{{
  11DebugRELab printf('%s:', expand('<sfile>'))
  11DebugRELab printf('args: %s', a:)
  let view = 'analysis'
  let regexp = get(a:, 1, '')
  let info = {'view': view}
  if !empty(regexp)
    " Only change info.regexp if it's not empty
    let info.regexp = regexp
  endif
  " Show analysis view
  return s:update_info({'regexp': regexp, 'view': view})
endfunction "}}}

function! relab#sample() "{{{
  11DebugRELab printf('%s:', expand('<sfile>'))
  11DebugRELab printf('args: %s', a:)
  let view = 'sample'
  " Show sample view
  return s:update_info({'view': view})
endfunction "}}}

function! relab#matches(validate, ...) "{{{
  11DebugRELab printf('%s:', expand('<sfile>'))
  11DebugRELab printf('args: %s', a:)
  let view = a:validate ? 'validate' : 'matches'
  let regexp = get(a:, 1, '')
  let info = {'view': view}
  if !empty(regexp)
    " Only change info.regexp if it's not empty
    let info.regexp = regexp
  endif
  return s:update_info(info)
endfunction "}}}

function! relab#set(...) "{{{
  11DebugRELab printf('%s:', expand('<sfile>'))
  11DebugRELab printf('args: %s', a:)
  let regexp = get(a:, 1, '')
  let info = {}
  if !empty(regexp)
    " Only change info.regexp if it's not empty
    let info.regexp = regexp
  endif
  return s:update_info(info)
endfunction "}}}

function! relab#get_sample(first, last, file) "{{{
  11DebugRELab printf('%s:', expand('<sfile>'))
  11DebugRELab printf('args: %s', a:)
  if empty(a:file)
    " use current buffer if no filename given
    let lines = getline(a:first, a:last)
  elseif filereadable(a:file)
    let lines = readfile(a:file)
  else
    echohl ErrorMsg
    echom printf('RELab error 2: Could not read file: %s', a:file)
    echohl Normal
    return 0
  endif
  " update with new info
  let info = {}
  let info.view = 'sample'
  let info.lines = lines
  call s:update_info(info)
endfunction "}}}

function! relab#line2regexp(linenr) "{{{
  11DebugRELab printf('%s:', expand('<sfile>'))
  11DebugRELab printf('args: %s', a:)
  let regexp = get(a:, 1, '')
  " use the count if it was given
  let linenr = a:linenr > 0 ? a:linenr : '.'
  let regexp = getline(linenr)
  return s:update_info({'regexp': regexp})
endfunction "}}}

function! s:set_scratch(lines) "{{{
  11DebugRELab printf('%s:', expand('<sfile>'))
  11DebugRELab printf('args: %s', a:)
  let lazyredraw = &lazyredraw
  set lazyredraw
  let fname = 'scratch.relab'
  let winnr = bufwinnr(fname)
  if bufname('%') ==# fname
    " buffer is already in the current window
  elseif winnr >= 0
    " buffer is in a window in this tab
    execute printf('%swincmd w', winnr)
  else
    " buffer is not in any window in the current tab
    execute printf('botright silent split %s', fname)
    if empty(&buftype)
      setlocal buftype=nofile
      setlocal noundofile
      setlocal noswapfile
      setlocal nonumber
      setlocal norelativenumber
      "setlocal undolevels=-1
    endif
  endif
  silent noautocmd %delete _
  undojoin
  noautocmd let lines_set = setline(1, a:lines) == 0
  if lines_set
    undojoin
  endif
  let &lazyredraw = lazyredraw
  return lines_set
endfunction "}}}

function! s:get_matches() "{{{
  11DebugRELab printf('%s:', expand('<sfile>'))
  11DebugRELab printf('args: %s', a:)
  let matches = {}
  let matches.lines = []
  let matches.submatches = join(map(range(s:info.parser.capt_groups + 1),
        \ {key, val -> 'submatch('.val.')'}), ',')
  function matches.get(...)
    " append matches
    let self.current.matches += map(copy(a:000),
          \ {key, val -> printf('%s%s:%s', (key == 0 ? '' : '|\'), key, val)})
    return get(a:, 1, '')
  endfunction
  function matches.run(regexp)
    let self.current = {}
    " save some extra info
    let self.current.linenr = line('.')
    let self.current.line = getline('.')
    let self.current.matches = []
    " get matches for this line
    execute printf('silent! s/%s/\=self.get(%s)/g', a:regexp, self.submatches)
    call add(self.lines, self.current)
  endfunction
  " set buffer to the sample lines
  call s:set_scratch(s:info.lines)
  silent! g/^/call matches.run(escape(s:info.regexp, '/'))
  return matches
endfunction "}}}

function! s:update_info(info) "{{{
  11DebugRELab printf('%s:', expand('<sfile>'))
  11DebugRELab printf('args: %s', a:)
  let file = get(g:, 'relab_filepath', '')
  if !exists('s:info') "{{{
    " set up s:info
    let first = 1
    let data = filereadable(file) ? readfile(file) : []
    if len(data) < 2
      " from scratch
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
            \ 'very.“(),:;<>[]”.VERY.“very@\\ "very”.unusual@lol.domain.com',
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
      " from the file
      let s:info = {}
      let [s:info.view, s:info.regexp; s:info.lines] = data
    endif
  endif "}}}
  let info = filter(copy(s:info), 'v:key !=# ''parser''')
  11DebugRELab printf('a:info: %s', a:info)
  11DebugRELab printf('s:info: %s', info)
  11DebugRELab printf('Updating info and saving it into: %s', file)
  call extend(s:info, copy(a:info), 'force')
  if !has_key(s:info, 'parser')
        \ || get(a:info, 'regexp', s:info.regexp) !=# s:info.regexp
    " No parser or new regexp, use it
    let s:info.parser = relab#parser#new()
    call s:info.parser.parse(s:info.regexp)
  endif
  " let the syntax script what view is on
  let g:relab_view = s:info.view
  let data = [s:info.view, s:info.regexp] + s:info.lines
  call writefile(data, file, 's')
  return s:refresh()
endfunction "}}}

function! s:refresh() "{{{
  11DebugRELab printf('%s:', expand('<sfile>'))
  11DebugRELab printf('args: %s', a:)
  runtime! syntax/relab.vim
  if s:info.view ==# 'validate' || s:info.view ==# 'matches'
    let title = printf('RELab: %s', substitute(s:info.view, '^.', '\u&', ''))
    if !empty(s:info.parser.errors)
      " the regexp has errors, report them
      let lines = [title]
      call add(lines, s:info.regexp)
      call extend(lines, s:info.parser.lines())
    else
      " show report
      let lines = [title, s:info.regexp, '']
      let matches = s:get_matches()
      for item in matches.lines
        if empty(item.matches) && s:info.view ==# 'validate'
          " add not matched line
          call add(lines, printf('-:%s', item.line))
        else
          " add matched line
          call add(lines, printf('+:%s', item.line))
          " we need to know if there was a match
          let matches.match_found = 1
          " add matches
          call extend(lines, item.matches)
        endif
      endfor
      if !has_key(matches, 'match_found') && s:info.view ==# 'matches'
        call add(lines, 'No matches found')
      endif
    endif
    return s:set_scratch(lines)
  elseif s:info.view ==# 'analysis'
    let title = printf('RELab: %s', substitute(s:info.view, '^.', '\u&', ''))
    let lines = [title, s:info.regexp]
    let lines += s:info.parser.lines()
    return s:set_scratch(lines)
  elseif s:info.view ==# 'sample'
    syntax clear
    " set buffer contents to sample lines
    return s:set_scratch(s:info.lines)
  else
    echoerr printf('RELab error 1: invalid view: %s', s:info.view)
    return 0
  endif
endfunction "}}}

function! relab#ontextchange() "{{{
  11DebugRELab printf('%s:', expand('<sfile>'))
  11DebugRELab printf('args: %s', a:)
  if s:info.view ==# 'sample'
    let lines = getline(1, '$')
    if lines == s:info.lines
      " nothing to update
      return
    endif
    return s:update_info({'lines': lines})
  endif
  if line('$') < 2
    " regexp should be on line 2, nothing to update
    return
  endif
  let regexp = getline(2)
  if regexp ==# s:info.regexp
    " nothing to update
    return
  endif
  let curpos = getcurpos()
  call s:update_info({'regexp': regexp})
  return setpos('.', curpos)
endfunction "}}}
