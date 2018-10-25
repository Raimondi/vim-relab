scriptencoding utf-8

function! relab#analysis(...) "{{{
  1DbgRELab printf('analysis: %s', a:000)
  let view = 'analysis'
  let regexp = get(a:, 1, '')
  let regexp = !empty(regexp) ? regexp :
        \ get(get(s:, 'info', {}), 'regexp', '')
  if empty(regexp)
    echohl ErrorMsg
    echom 'You need to provide a pattern!'
    echohl Normal
    return 0
  endif
  return s:update_info({'regexp': regexp, 'view': view})
endfunction "}}}

function! relab#sample() "{{{
  1DbgRELab printf('analysis: %s', a:000)
  let view = 'sample'
  return s:update_info({'view': view})
endfunction "}}}

function! relab#matches(validate, ...) "{{{
  let view = a:validate ? 'validate' : 'matches'
  1DbgRELab printf('show_matches: %s', view)
  let regexp = get(a:, 1, '')
  let info = {'view': view}
  if !empty(regexp)
    let info.regexp = regexp
  endif
  return s:update_info(info)
endfunction "}}}

function! relab#set(...) "{{{
  1DbgRELab printf('set:')
  let regexp = get(a:, 1, '')
  let regexp = !empty(regexp) ? regexp : get(s:info, 'regexp', '')
  if !empty(regexp)
    return s:update_info({'regexp': regexp})
  endif
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
  call s:update_info({'lines': lines})
  return relab#sample()
endfunction "}}}

function! relab#line2regexp(linenr) "{{{
  1DbgRELab printf('line2regexp:')
  let regexp = get(a:, 1, '')
  let regexp = !empty(regexp) ? regexp : get(s:info, 'regexp', '')
  let linenr = a:linenr > 0 ? a:linenr : '.'
  let regexp = getline(linenr)
  return s:update_info({'regexp': regexp})
endfunction "}}}

function! s:set_scratch(lines) "{{{
  1DbgRELab printf('set_scratch:')
  let lazyredraw = &lazyredraw
  set lazyredraw
  let fname = 'scratch.relab'
  let winnr = bufwinnr(fname)
  if winnr == bufwinnr('%')
    " nothing to do
  elseif winnr >= 0
    execute printf('%swincmd w', winnr)
  else
    execute printf('botright silent split %s', fname)
    if empty(&buftype)
      setlocal buftype=nofile
      setlocal noundofile
      setlocal noswapfile
      "setlocal undolevels=-1
    endif
  endif
  if bufname('%') !=# fname
    let &lazyredraw = lazyredraw
    return 1
  endif
  silent %delete _
  undojoin
  let lines_set = setline(1, a:lines) == 0
  if lines_set
    undojoin
  endif
  let &lazyredraw = lazyredraw
  return lines_set
endfunction "}}}

function! s:get_matches() "{{{
  1DbgRELab printf('get_matches:')
  let matches = {}
  let matches.lines = []
  let matches.submatches = join(map(range(s:info.parser.capt_groups + 1),
        \ {key, val -> 'submatch('.val.')'}), ',')
  function matches.get(...)
    let self.current.matches += map(copy(a:000),
          \ {key, val -> printf('\%s: %s', key, val)})
    return get(a:, 1, '')
  endfunction
  function matches.run(regexp)
    let self.current = {}
    let self.current.linenr = line('.')
    let self.current.line = getline('.')
    let self.current.matches = []
    execute printf('silent! s/%s/\=self.get(%s)/g', a:regexp, self.submatches)
    call add(self.lines, self.current)
  endfunction
  call s:set_scratch(s:info.lines)
  silent! g/^/call matches.run(escape(s:info.regexp, '/'))
  return matches
endfunction "}}}

function! relab#debug(verbose, msg) "{{{
  if a:verbose <= get(g:, 'relab_debug', 0)
    echom printf('%sRELab: %s', a:verbose, a:msg)
  endif
endfunction "}}}

function! s:update_info(dict) "{{{
  1DbgRELab printf('update_info: %s', a:dict)
  let file = get(g:, 'relab_filepath', '')
  if !exists('s:info') "{{{
    let data = filereadable(file) ? readfile(file) : []
    if len(data) < 2
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
      let s:info = {}
      let [s:info.view, s:info.regexp; s:info.lines] = data
    endif
  endif "}}}
  let info = extend(copy(a:dict), s:info, 'keep')
  DbgRELab printf('Updating info and saving it into: %s', file)
  if !has_key(s:info, 'parser') || info.regexp !=# s:info.regexp
    let info.parser = relab#parser#new()
    call info.parser.parse(info.regexp)
  endif
  if info == s:info
    return s:info
  endif
  let s:info = info
  let g:relab_view = s:info.view
  let data = [info.view, info.regexp] + info.lines
  call writefile(data, file, 's')
  return s:refresh()
endfunction "}}}

function! s:refresh() "{{{
  1DbgRELab printf('refresh')
  runtime! syntax/relab.vim
  if s:info.view ==# 'validate' || s:info.view ==# 'matches'
    let title = printf('RELab: %s', substitute(s:info.view, '^.', '\u&', ''))
    if !empty(s:info.parser.errors)
      let lines = [title]
      call add(lines, s:info.regexp)
      call extend(lines, s:info.parser.lines())
    else
      let lines = [title, s:info.regexp, '']
      let matches = s:get_matches()
      for item in matches.lines
        if empty(item.matches) && s:info.view ==# 'validate'
          call add(lines, printf('-:%s', item.line))
        else
          let matches.match_found = 1
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
    let s:info = s:update_info({'view': s:info.view})
    return s:set_scratch(s:info.lines)
  else
    return 0
  endif
endfunction "}}}

function! relab#ontextchange() "{{{
  1DbgRELab printf('ontextchange')
  if s:info.view ==# 'sample'
    let lines = getline(1, '$')
    return s:update_info({'lines': lines})
  endif
  if line('$') < 2
    return
  endif
  let curpos = getcurpos()
  let regexp = getline(2)
  call s:update_info({'regexp': regexp})
  return setpos('.', curpos)
endfunction "}}}
