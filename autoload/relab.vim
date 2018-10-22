function! relab#analyze_line(linenr) "{{{
  1DbgRELab printf('analyze_line:')
  let regexp = get(a:, 1, '')
  let regexp = !empty(regexp) ? regexp : get(s:info, 'regexp', '')
  let linenr = a:linenr > 0 ? a:linenr : '.'
  let regexp = getline(linenr)
  if empty(regexp)
    echohl ErrorMsg
    echom 'You need to provide a pattern!'
    echohl Normal
    return 0
  endif
  let s:info.regexp = regexp
  let parser = relab#parser#new()
  call parser.parse(regexp)
  let lines = ['RegExp Analysis', regexp]
  let lines += parser.lines()
  return s:set_scratch(lines)
endfunction "}}}

function! relab#show_analysis(...) "{{{
  1DbgRELab printf('show_analysis:')
  let regexp = get(a:, 1, '')
  let regexp = !empty(regexp) ? regexp : get(s:info, 'regexp', '')
  if empty(regexp)
    echohl ErrorMsg
    echom 'You need to provide a pattern!'
    echohl Normal
    return 0
  endif
  let s:info.regexp = regexp
  let parser = relab#parser#new()
  call parser.parse(regexp)
  let lines = ['RegExp Analysis', regexp]
  let lines += parser.lines()
  return s:set_scratch(lines)
endfunction "}}}

function! relab#show_matches(validate, ...) "{{{
  1DbgRELab printf('show_matches:')
  let regexp = get(a:, 1, '')
  let regexp = !empty(regexp) ? regexp : get(s:info, 'regexp', '')
  if empty(regexp)
    echohl ErrorMsg
    echom 'You need to provide a pattern!'
    echohl Normal
    return 0
  endif
  let s:info.regexp = regexp
  let parser = relab#parser#new()
  call parser.parse(regexp)
  if !s:set_scratch(s:info.lines)
    return
  endif
  let regexp = join(parser.values(), '')
  let lines = ['RegExp Matches', regexp, '']
  if !empty(parser.errors)
    call add(lines, regexp)
    call extend(lines, parser.lines())
  elseif search(regexp, 'cnw')
    let matches = s:get_matches(regexp, parser.capt_groups)
    for item in matches.lines
      if empty(item.matches) && a:validate
        call add(lines, item.line)
      else
        call extend(lines, item.matches)
      endif
    endfor
  else
    call add(lines, 'No matches found')
  endif
  %delete _
  1DbgRELab string(lines)
  return setline(1, lines) == 0
endfunction "}}}

function! relab#get_sample(first, last) "{{{
  1DbgRELab printf('get_sample:')
  let lines = getline(a:first, a:last)
  if empty(lines)
    echohl ErrorMsg
    echom 'The buffer is empty!'
    echohl Normal
    return 0
  endif
  let s:info.lines = lines
  return 1
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
    execute printf('s/%s/\=self.get(%s)/', a:regexp, self.submatches)
    call add(self.lines, self.current)
  endfunction
  if !search(a:regexp, 'cnw')
    return {}
  endif
  let regexp = escape(a:regexp, '/')
  %delete _
  call setline(1, s:info.lines)
  g/^/call matches.run(regexp)
  return matches
endfunction "}}}

function! s:set_scratch(lines) "{{{
  let lazyredraw = &lazyredraw
  set lazyredraw
  let fname = 'scratch.relab'
  let winnr = bufwinnr(fname)
  if winnr >= 0
    execute printf('%swincmd w', winnr)
  else
    execute printf('botright split %s', fname)
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
  %delete _
  let lines_set = setline(1, a:lines) == 0
  let &lazyredraw = lazyredraw
  return lines_set
endfunction "}}}

function! s:switch_buffer(buf) "{{{
  1DbgRELab printf('switch_buffer:')
  let bufnr = bufnr(a:buf)
  if bufnr == bufnr('%')
    return 1
  endif
  if bufnr < 0
    return 0
  endif
  execute printf('buffer %s', bufnr)
  return bufnr == bufnr('%')
endfunction "}}}

function! relab#debug(verbose, msg) "{{{
  if a:verbose <= get(g:, 'relab_debug', 0)
    echom printf('%sRELab: %s', a:verbose, a:msg)
  endif
endfunction "}}}

let s:relab_dir = printf('%s', expand('<sfile>:p:h:h'))
let relab = relab#parser#new()
let s:info = get(s:, 'info', {})
let s:info.lines = get(s:info, 'lines', [])
let s:info.regexp = get(s:info, 'regexp', '')
let g:relab_info = s:info
