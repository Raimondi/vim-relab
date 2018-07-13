function! relab#ontextchange() "{{{
  DbgRELab printf('ontextchange:')
  let pattern = getline('1')
  if pattern ==# get(s:, 'previous_pattern', '')
    echom 'skipped'
    return
  endif
  let lazyredraw = &lazyredraw
  set lazyredraw
  let s:previous_pattern = pattern
  let time1 = reltime()
  let curpos = getpos('.')
  call g:relab.parse(pattern)
  if line('$') > 1
    2,/^^^^^^^^^^^ .\+ ^^^^^^^^^^$/d_
  endif
  let lines = g:relab.lines()
  let lines += ['', '^^^^^^^^^^ Sample text goes under this line ^^^^^^^^^^']
  call append(1, lines)
  call setpos('.', curpos)
  for id in map(filter(getmatches(), 'v:val.group =~# ''^relab'''),
        \ 'v:val.id')
    DbgRELab printf('ontextchange: id: %s', id)
    call matchdelete(id)
  endfor
  " TODO fix overlapping highlight, like searching with /\(p\).* on this text:
  " probably present
  " only the first p should be highlighted as the first capt group because .*
  " matches the rest of the line, including the second p
  for name in range(11)
    execute 'silent! syn clear relabGroupMatch' . (name ? name - 1 : 'All')
  endfor
  silent! syn clear relabError
  if !empty(g:relab.errors)
    DbgRELab printf('ontextchange: error:')
    let node = g:relab.errors[0]
    let errorpattern = printf('\%%1l\%%%sv%s', node.pos + 1,
          \ repeat('.', strchars(node.value)))
    execute printf('syn match relabError /%s/ containedin=ALL',
          \ escape(errorpattern, '/'))
  else
    DbgRELab printf('ontextchange: matches:')
    let offset = len(lines) + 1
    let group_list = g:relab.match_groups(offset)
    DbgRELab printf('ontextchange -> matches: match_list: %s', group_list)
    for i in range(len(group_list))
      if i == 0
        DbgRELab printf('ontextchange -> matches -> Group All: pattern: %s',
              \ group_list[i])
        let syn_template =
              \ 'syn match relabGroupMatchAll /%s/ containedin=relabReport'
        execute printf(syn_template, group_list[i])
      elseif i == 1
        DbgRELab printf('ontextchange -> matches -> Group 0: pattern: %s',
              \ group_list[i])
        let syn_template = 'syn match relabGroupMatch0 /%s/ '
              \ . 'containedin=relabGroupMatchAll'
        execute printf(syn_template, group_list[i])
      else
        DbgRELab printf('ontextchange -> matches -> Group %s: pattern: %s',
              \ i - 1, group_list[i])
        let syn_template = 'syn match relabGroupMatch%s /%s/ '
              \ . 'containedin=relabGroupMatch%s'
        execute printf(syn_template, i - 1, group_list[i], i - 2)
      endif
    endfor
  endif
  let &lazyredraw = lazyredraw
  let time = reltimestr(reltime(time1, reltime()))
  echom printf('Time for %s in line %s is %s', pattern, line('.'), time)
endfunction "}}}

function! relab#debug(msg) "{{{
  if get(g:, 'relab_debug', 0)
    echom printf('RELab: %s', a:msg)
  endif
endfunction "}}}

function! relab#setup(regexp) range "{{{
  let regexp = empty(a:regexp) ? @/ : a:regexp
  let sample = getline(a:firstline, a:lastline)
  let bufnr = bufnr('^RELab$')
  if bufnr >= 0
    DbgRELab printf('setup -> buffer exists: bufnr: %s', bufnr)
    let winnr = bufwinnr(bufnr)
    if winnr >= 0
      DbgRELab printf('setup -> buffer exists -> on window')
      exec printf('%swincmd w', winnr)
    else
      DbgRELab printf('setup -> buffer exists -> show it')
      if get(g:, 'relab_split', 1)
        split RELab
      endif
      exec printf('buffer %s', bufnr)
    endif
  else
    DbgRELab printf('setup -> create it')
    if get(g:, 'relab_split', 1)
      split RELab
    else
      edit RELab
    endif
  endif
  let lines = [regexp, '',
        \ '^^^^^^^^^^ Sample text goes under this line ^^^^^^^^^^']
  let lines += sample
  call setline(1, lines)
endfunction "}}}

function! relab#analyze() "{{{
endfunction "}}}

let s:autoload_dir = expand('<sfile>:p:h')
let relab = relab#parser#new()
