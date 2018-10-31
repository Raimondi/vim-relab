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
  return s:update_info(info)
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

function! s:get_matches(groups) "{{{
  11DebugRELab printf('%s:', expand('<sfile>'))
  11DebugRELab printf('args: %s', a:)
  let matches = {}
  let matches.lines = []
  let matches.submatches = join(map(range(a:groups + 1),
        \ {key, val -> 'submatch('.val.')'}), ',')
  function matches.get(...)
    14DebugRELab printf('%s:', expand('<sfile>'))
    14DebugRELab printf('args: %s', a:)
    " append matches
    let i = 0
    while i < a:0
      if i == 0
        let prefix = ''
      elseif i < a:0 - 1
        let prefix = '|\'
      else
        let prefix = ' \'
      endif
      let amatch = printf('%s%s:%s', prefix, i, a:000[i])
      call add(self.current.matches, amatch)
      let i += 1
    endwhile
    return get(a:, 1, '')
  endfunction
  function matches.run(regexp)
    13DebugRELab printf('%s:', expand('<sfile>'))
    13DebugRELab printf('args: %s', a:)
    let self.current = {}
    " save some extra info
    let self.current.linenr = line('.')
    let self.current.line = getline('.')
    let self.current.matches = []
    " get matches for this line
    execute printf('silent! s/%s/\=self.get(%s)/g', a:regexp, self.submatches)
    14DebugRELab printf('current: %s', self.current)
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
    if get(g:, 'relab_no_file', 0) || len(data) < 2
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
  if !has_key(s:info, 'parser')
    11DebugRELab printf('Get new parser:')
    " No parser, add one
    let s:info.parser = relab#parser#new()
    call s:info.parser.parse(s:info.regexp)
  endif
  if has_key(a:info, 'regexp') && a:info.regexp != s:info.regexp
    11DebugRELab printf('Updating regexp: %s', a:info.regexp)
    " new regexp, parse it
    call s:info.parser.parse(a:info.regexp)
    let s:info.regexp = a:info.regexp
  endif
  if has_key(a:info, 'view')
    11DebugRELab printf('Updating view: %s', a:info.view)
    " new view
    let s:info.view = a:info.view
  endif
  if has_key(a:info, 'lines')
    11DebugRELab printf('Updating lines: %s', a:info.lines)
    " new lines
    let s:info.lines = a:info.lines
  endif
  let info = filter(copy(s:info), 'v:key !=# ''parser''')
  11DebugRELab printf('updated s:info: %s', info)
  " let the syntax script know what view is on
  let g:relab_view = s:info.view
  let data = [s:info.view, s:info.regexp] + s:info.lines
  if !get(g:, 'relab_no_file', 0)
    11DebugRELab printf('saving info into: %s', file)
    " write info to file if enabled
    call writefile(data, file, 's')
  endif
  return s:refresh()
endfunction "}}}

function! s:refresh() "{{{
  11DebugRELab printf('%s:', expand('<sfile>'))
  11DebugRELab printf('args: %s', a:)
  runtime! syntax/relab.vim
  let view = s:info.view
  if view ==# 'validate' || view ==# 'matches'
    12DebugRELab printf('View: %s', view)
    let title = printf('RELab: %s', substitute(view, '^.', '\u&', ''))
    if !empty(s:info.parser.errors)
      12DebugRELab printf('We have errors:')
      " the regexp has errors, report them
      let lines = [title]
      call add(lines, s:info.regexp)
      call extend(lines, s:info.parser.lines())
    else
      12DebugRELab printf('No errors:')
      " show report
      let lines = [title, s:info.regexp, '']
      let matches = s:get_matches(s:info.parser.capt_groups)
      for item in matches.lines
        13DebugRELab printf('item: %s', item)
        if empty(item.matches) && view ==# 'validate'
          13DebugRELab printf('add unmatched line: %s', item.line)
          " add not matched line
          call add(lines, printf('x:%s', item.line))
        elseif !empty(item.matches)
          13DebugRELab printf('add matched line: %s', item.line)
          " add matched line
          call add(lines, printf('+:%s', item.line))
          " we need to know if there was a match
          let matches.match_found = 1
          " add matches
          call extend(lines, item.matches)
        endif
      endfor
      if !has_key(matches, 'match_found') && view ==# 'matches'
        12DebugRELab printf('No matches found:')
        " add notice
        call add(lines, 'No matches found')
      endif
    endif
    return s:set_scratch(lines)
  elseif view ==# 'analysis'
    12DebugRELab printf('View: %s', view)
    let title = printf('RELab: %s', substitute(view, '^.', '\u&', ''))
    let lines = [title, s:info.regexp]
    let lines += s:info.parser.lines()
    return s:set_scratch(lines)
  elseif view ==# 'sample'
    12DebugRELab printf('View: %s', view)
    syntax clear
    " set buffer contents to sample lines
    return s:set_scratch(s:info.lines)
  else
    12DebugRELab printf('View: %s', view)
    echoerr printf('RELab error 1: invalid view: %s', view)
    return 0
  endif
endfunction "}}}

function! relab#ontextchange() "{{{
  11DebugRELab printf('%s:', expand('<sfile>'))
  11DebugRELab printf('args: %s', a:)
  let info = filter(copy(s:info), 'v:key !=# ''parser''')
  11DebugRELab printf('s:info: %s', info)
  let mode = mode()
  echom 'mode: ' .mode
  if mode ==# 'i'
    12DebugRELab printf('DO nothing while on insert mode')
    return
  endif
  if s:info.view ==# 'sample'
    12DebugRELab printf('View: sample')
    let lines = getline(1, '$')
    if lines == s:info.lines
      " nothing to update
      return
    endif
    return s:update_info({'lines': lines})
  endif
  12DebugRELab printf('View: not in sample')
  if line('$') < 2
    12DebugRELab printf('There is no regexp to be found')
    " regexp should be on line 2, nothing to update
    return
  endif
  let regexp = getline(2)
  if regexp ==# s:info.regexp
    12DebugRELab printf('The new regexp is the same: %s', regexp)
    " nothing to update
    return
  endif
  let curpos = getcurpos()
  call s:update_info({'regexp': regexp})
  return setpos('.', curpos)
endfunction "}}}

function! relab#test_helper(...) "{{{
  if !a:0
    unlet! s:info
  elseif type(a:1) == v:t_dict
    call s:update_info(a:1)
  endif
endfunction "}}}
