scriptencoding utf-8

function! relab#describe(...) "{{{
  11DebugRELab printf('%s:', expand('<sfile>'))
  11DebugRELab printf('args: %s', a:)
  let view = 'description'
  let regexp = get(a:, 1, '')
  let info = {'view': view}
  if !empty(regexp)
    " Only change info.regexp if it's not empty
    let info.regexp = regexp
  endif
  " Show analysis view
  return s:update_info(info, 0)
endfunction "}}}

function! relab#sample() "{{{
  11DebugRELab printf('%s:', expand('<sfile>'))
  11DebugRELab printf('args: %s', a:)
  let view = 'sample'
  " Show sample view
  return s:update_info({'view': view}, 0)
endfunction "}}}

function! relab#matches(validate, ...) "{{{
  11DebugRELab printf('%s:', expand('<sfile>'))
  11DebugRELab printf('args: %s', a:)
  let view = a:validate ? 'validation' : 'matches'
  let regexp = get(a:, 1, '')
  let info = {'view': view}
  if !empty(regexp)
    " Only change info.regexp if it's not empty
    let info.regexp = regexp
  endif
  return s:update_info(info, 0)
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
  return s:update_info(info, 0)
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
  call s:update_info(info, 0)
endfunction "}}}

function! relab#use_line(linenr) "{{{
  11DebugRELab printf('%s:', expand('<sfile>'))
  11DebugRELab printf('args: %s', a:)
  let regexp = get(a:, 1, '')
  " use the count if it was given
  let linenr = a:linenr > 0 ? a:linenr : '.'
  let regexp = getline(linenr)
  return s:update_info({'regexp': regexp}, 0)
endfunction "}}}

function! s:set_scratch(lines, undojoin) "{{{
  11DebugRELab printf('%s:', expand('<sfile>'))
  11DebugRELab printf('args: %s', a:)
  let lazyredraw = &lazyredraw
  set lazyredraw
  let fname = 'RELab'
  let winnr = bufwinnr(printf('^%s$', fname))
  let bufnr = bufnr(printf('^%s$', fname))
  12DebugRELab printf('winnr: %s', winnr)
  if bufname('%') ==# fname
    12DebugRELab printf('Currently in %s nothing to do', fname)
    " buffer is already in the current window
  elseif winnr >= 0
    12DebugRELab printf('Jump to %s''s window', fname)
    " buffer is in a window in this tab
    execute printf('%swincmd w', winnr)
  elseif bufnr >= 0
    12DebugRELab printf('Split to show %s', fname)
    " buffer exists but it isn't in any window in the current tab
    execute printf('botright silent split %s', fname)
  else
    12DebugRELab printf('Create a new buffer for %s', fname)
    " the buffer doesn't exists, we need to create it
    silent botright silent new
    execute printf('silent file %s', fname)
    set filetype=relab
    if empty(&buftype)
      setlocal buftype=nofile
      setlocal noundofile
      setlocal noswapfile
      setlocal nonumber
      setlocal norelativenumber
      "setlocal undolevels=-1
    endif
  endif
  if a:lines == getline(1, '$')
    12DebugRELab printf('No need to change the lines')
    " The current lines in the buffer are the ones we need, probably undo was
    " used. Let's leave things as they are.
    return
  elseif get(g:, 'relab_debug', 0)
    let i = 0
    while i < len(a:lines) && i < line('$')
      if a:lines[i] != getline(i)
        13DebugRELab printf('%s:%s', i + 1, getline(i))
        13DebugRELab printf('%s:%s', i + 1, a:lines[i])
      endif
      let i += 1
    endwhile
  endif
  12DebugRELab printf('Currently in %s', bufname('%'))
  if a:undojoin
    undojoin
  endif
  if line('$') > 1 || !empty(getline(1))
    silent noautocmd %delete _
    undojoin
  endif
  noautocmd let lines_set = setline(1, a:lines) == 0
  let &lazyredraw = lazyredraw
  return lines_set
endfunction "}}}

function! s:set_temp(lines) "{{{
  11DebugRELab printf('%s:', expand('<sfile>'))
  11DebugRELab printf('args: %s', a:)
  let lazyredraw = &lazyredraw
  set lazyredraw
  let fname = 'RELab_temp'
  let winnr = bufwinnr(printf('^%s$', fname))
  let bufnr = bufnr(printf('^%s$', fname))
  12DebugRELab printf('winnr: %s', winnr)
  if bufname('%') ==# fname
    12DebugRELab printf('Currently in %s nothing to do', fname)
    " buffer is already in the current window
  else
    12DebugRELab printf('Create a new buffer for %s', fname)
    " the buffer doesn't exists, we need to create it
    if bufname('%') ==# 'RELab'
      execute printf('silent edit! %s', fname)
    else
      execute printf('silent split! %s', fname)
    endif
    if empty(&buftype)
      setlocal buftype=nofile
      setlocal noundofile
      setlocal noswapfile
      setlocal nonumber
      setlocal norelativenumber
      setlocal undolevels=-1
    endif
  endif
  if a:lines == getline(1, '$')
    12DebugRELab printf('No need to change the lines')
    " The current lines in the buffer are the ones we need, probably undo was
    " used. Let's leave things as they are.
    return
  endif
  12DebugRELab printf('Currently in %s', bufname('%'))
  silent noautocmd %delete _
  noautocmd let lines_set = setline(1, a:lines) == 0
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
  call s:set_temp(s:info.lines)
  silent! g/^/call matches.run(escape(s:info.regexp, '/'))
  silent bdelete! RELab_temp
  return matches
endfunction "}}}

function! s:update_info(info, undojoin) "{{{
  11DebugRELab printf('%s:', expand('<sfile>'))
  11DebugRELab printf('args: %s', a:)
  let file = get(g:, 'relab_file_path', '')
  if !exists('s:info') "{{{
    " open the RELab buffer, so opening RELab_temp doesn't affect other
    " buffers.
    call s:set_scratch([], 0)
    " set up s:info
    let first = 1
    let data = filereadable(file) ? readfile(file) : []
    if get(g:, 'relab_no_file', 0) || len(data) < 2
      " if testing or there is incomplete data, then set it up from scratch
      let s:info = get(s:, 'info', {})
      let s:info.view = 'validation'
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
      " otherwise set it up from the file
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
  return s:refresh(a:undojoin)
endfunction "}}}

function! s:refresh(undojoin) "{{{
  11DebugRELab printf('%s:', expand('<sfile>'))
  11DebugRELab printf('args: %s', a:)
  runtime! syntax/relab.vim
  let view = s:info.view
  if view ==# 'validation' || view ==# 'matches'
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
        if empty(item.matches) && view ==# 'validation'
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
    return s:set_scratch(lines, a:undojoin)
  elseif view ==# 'description'
    12DebugRELab printf('View: %s', view)
    let title = printf('RELab: %s', substitute(view, '^.', '\u&', ''))
    let lines = [title, s:info.regexp]
    let lines += s:info.parser.lines()
    return s:set_scratch(lines, a:undojoin)
  elseif view ==# 'sample'
    12DebugRELab printf('View: %s', view)
    syntax clear
    syntax match relabComment /^\%2l-\+/
    let title = printf('RELab: %s', substitute(view, '^.', '\u&', ''))
    let lines = [title, substitute(title, '.', '-', 'g')]
    let lines += s:info.lines
    " set buffer contents to sample lines
    return s:set_scratch(lines, a:undojoin)
  else
    12DebugRELab printf('View: %s', view)
    echoerr printf('RELab error 1: invalid view: %s', view)
    return 0
  endif
endfunction "}}}

function! relab#ontextchange(event) "{{{
  11DebugRELab printf('%s:', expand('<sfile>'))
  11DebugRELab printf('args: %s', a:)
  let info = filter(copy(s:info), 'v:key !=# ''parser''')
  11DebugRELab printf('s:info: %s', info)
  " only use :undojoin when a new change has been made to avoid errors during
  " undo/redo
  let undotree = undotree()
  let last_seq = get(undotree.entries, -1, {})
  let is_new_seq = undotree.seq_cur == get(last_seq, 'seq', -1)
  let undojoin = a:event ==? 'textchangedi' || is_new_seq
  let header = getline(1,2)
  let view = tolower(matchstr(get(header, 0, ''), '^RELab: \zs\w\+$'))
  12DebugRELab printf('View: %s', view)
  let info = {}
  let info.view = view
  if view !~? '\m^\%(validation\|matches\|description\|sample\)$'
    " last change broke the first line
    stopinsert
    if undotree.seq_cur > 0
      12DebugRELab printf('Undo!')
      " unroll last change
      silent undo
      echohl ErrorMsg
      echom 'RELab: do not change the header!'
      echohl Normal
    else
      12DebugRELab printf('Redo!')
      " we were undone all the way to the original empty buffer and that's not
      " a good look, let's go forward
      silent redo
    endif
    if exists('nolazyredraw')
      set nolazyredraw
    endif
    return
  endif
  if view ==? 'sample'
    if getline(2) !=# '-------------'
      stopinsert
      undo
      echohl ErrorMsg
      echom 'RELab: do not change the header!'
      echohl Normal
      if exists('nolazyredraw')
        set nolazyredraw
      endif
      return
    endif
    let info.lines = getline(3, '$')
  else
    let info.regexp = get(header, 1, '')
  endif
  if !&lazyredraw
    let nolazyredraw
    set lazyredraw
  endif
  let curpos = getcurpos()
  call s:update_info(info, undojoin)
  if exists('nolazyredraw')
    set nolazyredraw
  endif
  return setpos('.', curpos)
endfunction "}}}

function! relab#test_helper(...) "{{{
  if !a:0
    unlet! s:info
  elseif type(a:1) == v:t_dict
    call s:update_info(a:1, get(a:, 2, 1))
  endif
endfunction "}}}
