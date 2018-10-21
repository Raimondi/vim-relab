function! relab#setup() "{{{
  1DbgRELab printf('setup:')
  let data_dir = s:relab_dir . '/relab'
  execute printf('tabedit %s/regexp.relab', data_dir)
  execute printf('split %s/sample.relab', data_dir)
  let win_width = (winwidth('.') - 1) * 33 / 100
  vsplit analysis.relab
  setlocal buftype=nofile
  execute printf('vertical resize %s', win_width)
  wincmd j
  vsplit results.relab
  setlocal buftype=nofile
  execute printf('vertical resize %s', win_width)
endfunction "}}}

function! relab#parse_line(linenr) "{{{
  1DbgRELab printf('parse_line:')
  let linenr = a:linenr > 0 ? a:linenr : '.'
  let pattern = getline(linenr)
  let parser = relab#parser#new('/')
  call parser.parse(pattern)
  let matches = {}
  let matches.lines = []
  let matches.capt_groups = parser.capt_groups
  function matches.get(...)
    for group in range(self.capt_groups + 1)
      let indent = group == 0 ? '' : '  '
      let line = printf('%s%s: %s', indent, group,
            \ get(a:, group + 1, ''))
      call add(self.lines, line)
    endfor
    return
  endfunction
  let sample_path = printf('%s/%s', s:relab_dir, 'sample.relab')
  let regexp_path = expand('%:p')
  let analysis_path = 'analysis.relab'
  let results_path = 'results.relab'
  let lazyredraw = &lazyredraw
  set lazyredraw
  if !s:switch_buffer(results_path)
    DbgRELab printf('ontextchange: could not switch to "%s"',
          \ results_path)
    " Error
    return
  endif
  let sample_lines = getbufline(sample_path, 1, '$')
  %delete _
  call setline(1, sample_lines)
  let submatches =
        \ join(map(range(10), {key, val -> 'submatch('.val.')'}), ',')
  execute printf('%%s/%s/\=matches.get(%s)/',
        \ escape(join(parser.values(), ''), '/'), submatches)
  if !s:switch_buffer(analysis_path)
    DbgRELab printf('ontextchange: could not switch to "%s"',
          \ analysis_path)
    " Error
    return
  endif
  %delete _
  call setline(parser.lines, 1)
  if !s:switch_buffer(regexp_path)
    DbgRELab printf('ontextchange: could not switch to "%s"',
          \ regexp_path)
    " Error
    return
  endif
  let &lazyredraw = lazyredraw
endfunction "}}}

function! relab#show_analysis(regexp) "{{{
  1DbgRELab printf('show_analysis:')
  call s:get_info('analysis')
  let parser = relab#parser#new()
  call parser.parse(a:regexp)
  let lines = ['RegExp Analysis', a:regexp]
  let lines += parser.lines()
  return s:set_scratch(lines)
endfunction "}}}

function! relab#show_matches(regexp) "{{{
  1DbgRELab printf('show_matches:')
  let info = s:get_info('matches')
  let matches = {}
  let matches.lines = []
  function matches.get(groups, ...)
    for group in range(a:groups + 1)
      let indent = group == 0 ? '' : '  '
      let line = printf('%s%s: %s', indent, group,
            \ get(a:, group + 1, ''))
      call add(self.lines, line)
    endfor
    return a:1
  endfunction
  let parser = relab#parser#new()
  call parser.parse(a:regexp)
  if !s:set_scratch(info.lines)
    return
  endif
  let regexp = join(parser.values(), '')
  let lines = ['RegExp Matches', regexp, '']
  if !empty(parser.errors)
    call add(lines, regexp)
    call extend(lines, parser.lines())
  elseif search(regexp, 'cnw')
    let submatches =
          \ join(map(range(10), {key, val -> 'submatch('.val.')'}), ',')
    let command = 'silent! %%s/%s/\=matches.get(parser.capt_groups, %s)/'
    execute printf(command, escape(regexp, '/'),
          \ submatches)
    call extend(lines, matches.lines)
  else
    call add(lines, 'No matches found')
  endif
  %delete _
  return setline(1, lines) == 0
endfunction "}}}

function! s:set_scratch(lines) "{{{
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
    return 1
  endif
  %delete _
  return setline(1, a:lines) == 0
endfunction "}}}

function! s:get_info(wintype) "{{{
  1DbgRELab printf('get_info:')
  let info = get(g:, 'relab_info', {})
  if bufname('%') !=# 'scratch.relab'
    let info.lines = getline(1, '$')
    if get(info, 'previous', '') ==# a:wintype
      let info.previous = a:wintype
    endif
  endif
  let g:relab_info = info
  return g:relab_info
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
