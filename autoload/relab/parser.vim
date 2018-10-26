let s:id_map = {}
for line in readfile(printf('%s/%s', expand('<sfile>:p:h'), 'id_key.txt'))
  45DebugRELab printf('id_map -> for: line: %s', line)
  let [id, help, desc] = split(line, '\t')
  44DebugRELab printf('id_map -> for: id: %s, help: %s, desc: %s',
        \id, help, desc)
  if has_key(s:id_map, id)
    echoerr 'Duplicated key!'
  else
    let s:id_map[id] = {'help_tag': help, 'line': desc}
  endif
endfor


function! s:init(...) dict "{{{
  21DebugRELab printf('%s:', expand('<sfile>'))
  21DebugRELab printf('args: %s', a:)
  let self.magicness = 'm'
  let self.ignorecase = 0
  let self.in_collection = 0
  let self.token = ''
  let self.tokens = []
  let self.nest_stack = []
  let self.input = ''
  let self.length = 0
  let self.pos = 0
  let self.capt_groups = 0
  let self.errors = []
  let self.sequence = []
  let self.sep = a:0 ? a:1 : self.sep
  let self.input_remaining = ''

  let self.root.magicness = self.magicness
  let self.root.capt_groups = self.capt_groups
  let self.root.is_capt_group = 0
  let self.root.ignorecase = self.ignorecase
  let self.root.parent = {}
  let self.root.siblings = []
  let self.root.children = []
  let self.root.level = 0

  let self.parent = self.root
  if len(self.sep) > 1 || self.sep =~# '[a-zA-Z0-9]'
    "error
    echoerr printf('RELab: Wrong separator: %s', self.sep)
    return {}
  endif
  return self
endfunction "}}}

function! s:magic() dict "{{{
  21DebugRELab printf('%s:', expand('<sfile>'))
  21DebugRELab printf('args: %s', a:)
  if self.magicness ==# 'M'
    if self.token =~# '\m^\\[.*~[]$'
      return self.token[1:]
    elseif self.token =~# '\m^[.*~[]$'
      return '\' . self.token
    endif
  elseif self.magicness ==# 'v'
    if self.token =~# '\m^[+?{()@%<>=]'
      return '\' . self.token
    elseif self.token =~# '\m^\\[+?{()@%<>=]'
      return self.token[1:]
    endif
  elseif self.magicness ==# 'V'
    if self.token =~# '\m^\\[[.*~^$]$'
      return self.token[1:]
    elseif self.token =~# '\m^[[.*~^$]$'
      return '\' . self.token
    endif
  endif
  return self.token
endfunction "}}}

function! s:id() dict "{{{
  21DebugRELab printf('%s:', expand('<sfile>'))
  21DebugRELab printf('args: %s', a:)
  let magic_token = self.magic()
  22DebugRELab printf('to id: self.token: %s, magic_token: %s', self.token,
        \ magic_token)
  if self.in_collection
    23DebugRELab printf('to id -> collection')
    if self.token =~# '\m^\\[doxuU]'
      23DebugRELab printf('to id -> collection -> code point')
      " /[\x]
      return substitute(self.token, '\m^\(\\.\).\+', '[\1', '')
    elseif self.token =~#
          \ '\m^\%(\\[-^\]\\ebnrt]\|[^\\]\)-\%(\\[-^\]\\ebnrt]\|[^\\]\)$'
      23DebugRELab printf('to id -> collection -> range')
      " /[a-z]
      return self.ignorecase ? 'a-b' : 'A-B'
    elseif self.token =~# '\m^\[[.=].[.=]\]$'
      23DebugRELab printf('to id -> collection -> collation/equivalence')
      " /[[.a.][=a=]]
      return substitute(self.token, '\m^\(\[[.=]\).[.=]\]$', '[\1\1]', '')
    endif
  elseif magic_token =~# '\m^\\%[<>]\?\d\+[lvc]$'
    23DebugRELab printf('to id -> lcv')
    " /\%23l
    return substitute(self.token, '\m\d\+', '', '')
  elseif magic_token =~# '\m^\\%[<>]\?''.$'
    23DebugRELab printf('to id -> mark')
    " /\%'m
    return substitute(self.token, '.$', 'm', '')
  elseif magic_token =~# '\m^\\{'
    23DebugRELab printf('to id -> multi curly')
    " /.\{}
    let id = '\{'
    let id .= magic_token =~# '\m^\\{-' ? '-' : ''
    let id .= magic_token =~# '\m^\\{-\?\d' ? 'n' : ''
    let id .= magic_token =~# '\m^\\{-\?\d*,' ? ',' : ''
    let id .= magic_token =~# '\m^\\{-\?\d*,\d' ? 'm' : ''
    let id .= '}'
    return id
  elseif magic_token =~# '\m^\\%[doxuU]\d\+$'
    23DebugRELab printf('to id -> code point')
    " /\%d123
    return matchstr(self.token, '\m\C^\\%[doxuU]')
  elseif self.token =~# '\m^\\%#=.\?'
    23DebugRELab printf('to id -> engine')
    " regexp engine
    return '\%#='
  elseif magic_token =~# '\m^\\@\%([!=>]\|\d*<[!=]\)$'
    23DebugRELab printf('to id -> lookaround')
    return substitute(self.token, '\d\+', '123', '')
  elseif magic_token =~# '\m^\\[[.^$~*]$'
    23DebugRELab printf('to id -> literal')
    return magic_token
  endif
  23DebugRELab printf('to id -> else')
  return self.token
endfunction "}}}

function! s:help_tag(node) dict "{{{
  21DebugRELab printf('%s:', expand('<sfile>'))
  21DebugRELab printf('args: %s', a:)
  return get(get(self.id_map, a:node.id, {}), 'help_tag', '')
endfunction "}}}

function! s:line(node, ...) dict "{{{
  21DebugRELab printf('%s:', expand('<sfile>'))
  21DebugRELab printf('args: %s', a:000)
  let id = a:node.id
  23DebugRELab printf('line: %s', id)
  let line = get(self.id_map, id,
        \ {'line': 'ERROR: contact this plugin''s author'}).line
  23DebugRELab printf('line: %s', line)
  if id ==? 'x'
    23DebugRELab 'line -> literal'
    if strchars(a:node.magic) == 1
      23DebugRELab 'line -> literal -> single'
      let char = a:node.value
      let code = char2nr(char)
    elseif a:node.value =~# '\m^\\[^etrbn]'
      23DebugRELab 'line -> literal -> escaped'
      let char = strcharpart(a:node.value, 1)
      let code = char2nr(char)
    elseif a:node.value ==# '\e'
      23DebugRELab 'line -> literal -> escape'
      let char = '<Esc>'
      let code = 27
    elseif a:node.value ==# '\t'
      23DebugRELab 'line -> literal -> tab'
      let char = '<Tab>'
      let code = 9
    elseif a:node.value ==# '\node'
      23DebugRELab 'line -> literal -> car return'
      let char = '<CR>'
      let code = 13
    elseif a:node.value ==# '\b'
      23DebugRELab 'line -> literal -> backspace'
      let char = '<BS>'
      let code = 8
    else
      23DebugRELab 'line -> literal -> single'
      let char = a:node.value
      let code = char2nr(char)
    endif
    if id ==# 'X'
      23DebugRELab 'line -> literal -> match case'
      let line = printf(line, char, code)
    elseif tolower(char) ==# toupper(char)
      23DebugRELab 'line -> literal -> no case'
      let line = get(self.id_map, 'X',
            \ {'line': 'ERROR: contact this plugin''s author'}).line
      let line = printf(line, char, code)
    else
      23DebugRELab 'line -> literal -> ignore case'
      let line = printf(line, tolower(char), char2nr(tolower(char)),
            \ toupper(char), char2nr(toupper(char)))
    endif
  elseif id ==# 'A-B'
    23DebugRELab 'line -> range match case'
    let line = printf(line, a:node.first, char2nr(a:node.first),
          \ a:node.second, char2nr(a:node.second))
  elseif id ==# 'a-b'
    23DebugRELab 'line -> range ignore case'
    let line = printf(line,
          \ tolower(a:node.first), char2nr(tolower(a:node.first)),
          \ tolower(a:node.second), char2nr(tolower(a:node.second)),
          \ toupper(a:node.first), char2nr(toupper(a:node.first)),
          \ toupper(a:node.second), char2nr(toupper(a:node.second))
          \ )
  elseif id =~# '^\m\\{'
    23DebugRELab 'line -> brackets'
    if empty(a:node.min)
      23DebugRELab 'line -> brackets -> empty min'
      if empty(a:node.max)
        23DebugRELab 'line -> brackets -> empty min -> empty max'
        " nothing to do
      else
        23DebugRELab 'line -> brackets -> empty min -> non empty max'
        let line = printf(line, a:node.max)
      endif
    else
      23DebugRELab 'line -> brackets -> non empty min'
      if empty(a:node.max)
        23DebugRELab 'line -> brackets -> non empty min -> empty max'
        let line = printf(line, a:node.min)
      else
        23DebugRELab 'line -> brackets -> non empty min -> non empty max'
        let line = printf(line, a:node.min, a:node.max)
      endif
    endif
  elseif id =~# '\m^\\@123<[=!]$'
    23DebugRELab 'line -> look behind'
    let line = printf(line, matchstr(a:node.magic, '\d\+'))
  elseif id =~# '\m^\%(\[\\\|\\%\)[doxuU]'
    23DebugRELab 'line -> code point'
    let code_map = {'d': '%s', 'o': '0%s', 'x': '0x%s', 'u': '0x%s',
          \ 'U': '0x%s'}
    let key = matchstr(id, '\m^\%(\[\\\|\\%\)\zs.')
    23DebugRELab printf('line -> code point: magicness: %s, key: %s',
          \ a:node.magic, key)
    let number = matchstr(a:node.magic, '\m^\\%\?.0\?\zs.\+')
    23DebugRELab printf('line -> code point: number: %s', number)
    let code = printf(code_map[key], number)
    23DebugRELab printf('line -> code point: code: %s', code)
    let dec = eval(code)
    23DebugRELab printf('line -> code point: dec: %s', dec)
    let char = nr2char(dec)
    let char_is_lower = char =~# '\%#=2^[[:lower:]]$'
    let char2 = char_is_lower ? toupper(char) : tolower(char)
    let has_case = tolower(char) !=# toupper(char)
    if a:node.ignorecase && char !=# char2
      23DebugRELab 'line -> code point -> ignore case'
      let line = get(self.id_map, id . 'i',
            \ {'line': 'ERROR: contact this plugin''s author'}).line
      let line = printf(line, char, char2)
    else
      23DebugRELab 'line -> code point -> match case'
      let line = printf(line, char)
    endif
  elseif has_key(self.id_map, id)
    23DebugRELab 'line -> has key'
  else
    23DebugRELab 'line -> else'
  endif
  let indent = repeat(' ', (a:node.level * 2))
  let line = printf('%s%s => %s', indent, a:node.value, line)
  return line
endfunction "}}}

function! s:lines() dict "{{{
  21DebugRELab printf('%s:', expand('<sfile>'))
  21DebugRELab printf('args: %s', a:)
  let lines = []
  if !empty(self.errors)
    return extend(lines, self.errors[0].error)
  endif
  call add(lines, '')
  return extend(lines, map(copy(self.sequence), 'v:val.line'))
endfunction "}}}

function! s:match_group(line_offset, ...) dict "{{{
  21DebugRELab printf('%s:', expand('<sfile>'))
  21DebugRELab printf('args: %s', a:)
  23DebugRELab printf('match group: line_offset: %s, group: %s, regexp: %s',
        \ a:line_offset, (a:0 ? a:1 : 'all'), self.input)
  if self.capt_groups < get(a:, 1, 0)
    23DebugRELab printf('match group: arg > available groups')
    let items = []
  elseif get(a:, 1, 0) > 9
    23DebugRELab printf('match group: arg > 9')
    let items = []
  else
    " TODO Need to considers \zs and \ze inside the group
    " like in 'abc\(de\zefg\|hij\)jkl'
    23DebugRELab printf('match group: arg > 0')
    let items = ['\m\C']
    if a:line_offset
      call add(items, printf('\%%>%sl', a:line_offset))
    endif
    23DebugRELab printf('match group: capt_groups: %s', map(copy(self.sequence),
          \ 'get(v:val, ''capt_groups'', 0)'))
    for node in self.sequence
      23DebugRELab printf('match group: node.magic: %s', node.magic)
      if node.is_branch()
        23DebugRELab printf('match group -> is_branch:')
        if a:0 && node.capt_groups == a:1 && node.is_capt_group
          23DebugRELab printf('match group -> branch -> add \ze:')
          call add(items, '\ze')
        endif
        call add(items, node.magic)
        if a:0 && node.capt_groups == a:1
          23DebugRELab printf('match group -> branch -> add \zs:')
          call add(items, '\zs')
        endif
        if a:line_offset && node.level == -1
          23DebugRELab printf('match group -> is_branch -> add line nr:')
          call add(items, printf('\%%>%sl', a:line_offset))
        endif
      elseif node.starts_capt_group()
        23DebugRELab printf('match group -> starts_capt_group:')
        call add(items, node.magic)
        if a:0 && node.capt_groups == a:1
          23DebugRELab printf('match group -> starts_capt_group -> add \zs:')
          call add(items, '\zs')
        endif
      elseif node.ends_capt_group()
        23DebugRELab printf('match group -> ends_capt_group:')
        if a:0 && node.capt_groups == a:1 && node.is_capt_group
          23DebugRELab printf('match group -> ends_capt_group -> add \ze:')
          call add(items, '\ze')
        endif
        call add(items, node.magic)
      elseif node.is_boundary()
        23DebugRELab printf('match group -> is_boundary:')
        if a:0 && a:1 == 0
          23DebugRELab printf('match group -> is_boundary -> add node:')
          call add(items, node.magic)
        endif
      elseif node.id ==# '\%l'
        23DebugRELab printf('match group -> is_line_nr:')
        if a:line_offset
          let linenr = matchstr(node.magic, '\d\+') + a:line_offset
          call add(items, substitute(node.magic, '\d\+', linenr, ''))
        else
          call add(items, node.magic)
        endif
      elseif node.value ==# '\'
        23DebugRELab printf('match group -> single backspace:')
        call add(items, '\\')
      elseif node.id ==# '\%^'
        23DebugRELab printf('match group -> is_bof:')
        if a:line_offset
          call add(items, printf('\%%%sl\_^', a:line_offset))
        else
          call add(items, node.magic)
        endif
      elseif node.magic ==# '[' && node.id ==? 'x'
        23DebugRELab printf('match group -> literal [:')
        call add(items, '\[')
      else
        23DebugRELab printf('match group -> else:')
        call add(items, node.magic)
      endif
    endfor
  endif
  if len(items) - (a:line_offset > 0) > 1
    let group_re = join(filter(items, '!empty(v:val)'), '')
  else
    let group_re = ''
  endif
  23DebugRELab printf('match group: result: %s', group_re)
  return group_re
endfunction "}}}

function! s:match_groups(...) dict "{{{
  21DebugRELab printf('%s:', expand('<sfile>'))
  21DebugRELab printf('args: %s', a:)
  23DebugRELab printf('match group: regexp: %s', self.input)
  let offset = get(a:, 1, 0)
  let groups = []
  call add(groups, self.match_group(offset))
  for group in range(0, self.capt_groups)
    call add(groups, self.match_group(offset, group))
  endfor
  return filter(groups, '!empty(v:val)')
endfunction "}}}

function! s:in_optional_group() dict "{{{
  return get(get(self.nest_stack, -1, {}), 'id', '') ==# '\%['
endfunction "}}}

function! s:map(key) dict "{{{
  return map(copy(self.sequence), 'get(v:val, a:key, '''')')
endfunction "}}}

function! s:magics() dict "{{{
  21DebugRELab printf('%s:', expand('<sfile>'))
  21DebugRELab printf('args: %s', a:)
  return map(copy(self.sequence), 'v:val.magic')
endfunction "}}}

function! s:values() dict "{{{
  21DebugRELab printf('%s:', expand('<sfile>'))
  21DebugRELab printf('args: %s', a:)
  return map(copy(self.sequence), 'get(v:val, ''value'', '''')')
endfunction "}}}

function! s:ids() dict "{{{
  return map(copy(self.sequence), 'get(v:val, ''id'', '''')')
endfunction "}}}

function! s:collection_ends() dict "{{{
  21DebugRELab printf('%s:', expand('<sfile>'))
  21DebugRELab printf('args: %s', a:)
  let ahead = strcharpart(self.input, self.pos)
  if ahead[0] ==# '^'
    return ahead =~# '\m^\^\%(\\[-ebrtndoxuU^$\]]\|[^\]]\)\+]'
  else
    return ahead =~# '\m^\%(\\[-ebrtndoxuU^$\]]\|[^\]]\)\+]'
  endif
endfunction "}}}

function! s:add_error(node, ...) dict "{{{
  21DebugRELab printf('%s:', expand('<sfile>'))
  21DebugRELab printf('args: %s', a:)
  let a:node.is_error = 1
  let error = []
  let arrow = printf('%s%s',
        \ repeat('-', a:node.pos), repeat('^', strchars(a:node.value)))
  call add(error, arrow)
  call add(error, printf('Error: %s', (a:0 ? a:1 : a:node.value . ':')))
  let a:node.error = error
  call add(self.errors, a:node)
endfunction "}}}

function! s:incomplete_in_coll() dict "{{{
  21DebugRELab printf('%s:', expand('<sfile>'))
  21DebugRELab printf('args: %s', a:)
  let next = self.token . strcharpart(self.input, self.pos)
  let ahead = strcharpart(self.input, self.pos, 1)
  if empty(self.parent.children) && self.token ==# '^'
    23DebugRELab printf('incomplete_in_coll -> negate: %s', next)
    return 0
  elseif self.token =~#
        \ '\m^\%(\\[\\ebnrt]\|[^\\]\)-\%(\\[\\ebnrt]\|[^\\]\)$'
    23DebugRELab printf('incomplete_in_coll -> range done: %s', next)
    return 0
  elseif next =~# '\m^\%(\\[\\enbrt]\|[^\\]\)-\%(\\[\\ebnrt]\|[^\\]\)'
    23DebugRELab printf('incomplete_in_coll -> range coming: %s', next)
    return 1
  elseif self.token =~# '\m^\\[-\\ebnrt\]^]$'
    23DebugRELab printf('incomplete_in_coll -> escaped done: %s', next)
    return 0
  elseif self.token ==# '\' && ahead =~# '\m^[-\\ebnrtdoxuU\]^]$'
    23DebugRELab printf('incomplete_in_coll -> escaped done: %s', next)
    return 1
  elseif self.token ==# '\'
    23DebugRELab
          \ printf('incomplete_in_coll -> escaped coming: %s', next)
    return 0
  elseif self.token =~# '\m^\[\([.=]\).\1\]$'
    23DebugRELab printf('incomplete_in_coll -> equivalence done: %s', next)
    return 0
  elseif next =~# '\m^\[\([.=]\).\1\]'
    23DebugRELab printf('incomplete_in_coll -> equivalence coming: %s', next)
    return 1
  elseif self.token =~# '\m^\[:\a\+:\]$'
    23DebugRELab printf('incomplete_in_coll -> collation done: %s', next)
    return 0
  elseif next =~# '\m^\[:\a\+:\]'
    23DebugRELab printf('incomplete_in_coll -> collation coming: %s', next)
    return 1
  endif
  let next = self.token . ahead
  if next =~# '\m^\\d\d*$'
    23DebugRELab printf('incomplete_in_coll -> dec: %s', next)
    return 1
  elseif next =~# '\m^\\o0\?\o\{,3}$'
        \ && printf('0%s', matchstr(next, '0\?\zs\o\+')) <= 0377
    23DebugRELab printf('incomplete_in_coll -> oct: %s', next)
    return 1
  elseif next =~# '\m^\\x\x\{,2}$'
    23DebugRELab printf('incomplete_in_coll -> hex2: %s', next)
    return 1
  elseif next =~# '\m^\\u\x\{,4}$'
    23DebugRELab printf('incomplete_in_coll -> hex4: %s', next)
    return 1
  elseif next =~# '\m^\\U\x\{,8}$'
    23DebugRELab printf('incomplete_in_coll -> hex8: %s', next)
    return 1
  elseif next =~# '\m^\\[duUx].$'
    23DebugRELab printf('incomplete_in_coll -> code point: %s', next)
    return 1
  else
    return 0
  endif
endfunction "}}}

function! s:is_incomplete() dict "{{{
  21DebugRELab printf('%s:', expand('<sfile>'))
  21DebugRELab printf('args: %s', a:)
  23DebugRELab printf('is_incomplete')
  if self.in_collection
    return self.incomplete_in_coll()
  endif
  let token = self.magic()
  if token =~# '\m^\\\%(@\%(\d*\%(<\?\)\)\)$'
        \ || token =~# '\m^\\\%(%[<>]\?\%(\d*\|''\)$\)'
        \ || token =~# '\m^\\\%(_\|#\|{[^}]*\|z\)\?$'
    23DebugRELab printf('is_incomplete -> main: %s', token)
    return 1
  endif
  let ahead = strcharpart(self.input, self.pos, 1)
  let next = token . ahead
  if next =~# '\m^\\%d\d*$'
    23DebugRELab printf('is_incomplete -> dec: %s', next)
    return 1
  elseif next =~# '\m^\\%o0\?\o\{,3}$'
        \ && printf('0%s', matchstr(next, '0\?\zs\o\+')) <= 0377
    23DebugRELab printf('is_incomplete -> oct: %s', next)
    return 1
  elseif next =~# '\m^\\%x\x\{,2}$'
    23DebugRELab printf('is_incomplete -> hex2: %s', next)
    return 1
  elseif next =~# '\m^\\%u\x\{,4}$'
    23DebugRELab printf('is_incomplete -> hex4: %s', next)
    return 1
  elseif next =~# '\m^\\%U\x\{,8}$'
    23DebugRELab printf('is_incomplete -> hex8: %s', next)
    return 1
  elseif next =~# '\m^\\%[duUx].$'
    23DebugRELab printf('is_incomplete -> code point: %s', next)
    return 1
  endif
  23DebugRELab printf('is_incomplete -> else: next: %s', next)
  return 0
endfunction "}}}

function! s:next() dict "{{{
  21DebugRELab printf('%s:', expand('<sfile>'))
  21DebugRELab printf('args: %s', a:)
  if self.pos == 0 && !empty(matchstr(self.input, '^\\%#=.\?'))
    " \%#= must be the first thing
    let self.token = matchstr(self.input, '^\\%#=.\?')
    let self.pos = strchars(self.token)
  elseif !empty(self.sep)
        \ && strcharpart(self.input, self.pos, 1) ==# self.sep
    let self.token = ''
    let self.pos += 1
    let self.input_remaining = self.input[self.pos : ]
  else
    let self.token = strcharpart(self.input, self.pos, 1)
    let self.pos += 1
    while (self.pos < self.length) && self.is_incomplete()
      let self.token .= strcharpart(self.input, self.pos, 1)
      let self.pos += 1
    endwhile
  endif
  if !empty(self.token)
    call add(self.tokens, self.token)
  endif
  return !empty(self.token)
endfunction "}}}

function! s:parse(input) dict "{{{
  21DebugRELab printf('%s:', expand('<sfile>'))
  21DebugRELab printf('args: %s', a:)
  23DebugRELab printf('')
  23DebugRELab printf('parse: %s', a:input)
  let input = empty(self.sep) ? a:input : a:input[1:]
  let self.input = input
  let self.length = strchars(input)
  while self.next()
    let token = self.token
    let magicness = self.magicness
    let ignorecase = self.ignorecase
    let magic = self.magic()
    let pos = self.pos
    let id = self.id()
    let node = self.parent.new(token, magicness, ignorecase, magic, pos, id)
    call add(self.sequence, node)
    23DebugRELab printf('parse -> token: %s, magicness: %s, ignorecase: %s, '
          \ . 'magic: %s, pos: %s, id: %s', token, magicness, ignorecase,
          \ magic, pos, id)

    if self.in_collection && node.ends_collection() "{{{
      23DebugRELab  'parse -> ends collection'
      call remove(self.nest_stack, -1)
      let self.parent = node.parent.parent
      let self.in_collection = 0
      let node.level -= 1
      "}}}

    elseif self.in_collection && node.id ==# '^' "{{{
      23DebugRELab printf('parse -> collection -> negate')
      if empty(node.previous)
        23DebugRELab printf('parse -> collection -> negate -> special')
        let node.id = '[^'
      else
        23DebugRELab printf('parse -> collection -> negate -> literal')
        let node.id = node.ignorecase ? 'x' : 'X'
      endif
      "}}}

    elseif self.in_collection && node.is_coll_range_id() "{{{
      23DebugRELab printf('parse -> collection -> range')
      if node.value[0] ==# '\'
        let node.first = strcharpart(node.value, 0, 2)
        let node.second = strcharpart(node.value, 3)
      else
        let node.first = strcharpart(node.value, 0, 1)
        let node.second = strcharpart(node.value, 2)
      endif
      let dict = {'\e': "\e", '\b': "\b", '\n': "\n",
            \ '\node': "\node", '\t': "\t",
            \ '\\': '\', '\]': ']', '\^': '^', '\-': '-'}
      let node.first = get(dict, node.first, node.first)
      23DebugRELab printf('parse -> collection -> range: first: %s, second: %s',
            \ node.first, node.second)
      let node.second = get(dict, node.second, node.second)
      if node.first ># node.second
        let errormessage = 'reverse range in character class'
        call self.add_error(node, errormessage)
      endif
      "}}}

    elseif node.is_engine() "{{{
      23DebugRELab  printf('parse -> engine')
      if matchstr(node.value, '^\m\\%#=\zs.\?') !~# '\m^[0-2]$'
        let errormessage =
              \ '\%#= can only be followed by 0, 1, or 2'
        call self.add_error(node, errormessage)
      endif
      "}}}

    elseif node.is_branch() "{{{
      23DebugRELab  printf('parse -> is_branch')
      " Move node one level up in the hierarchy
      call remove(node.siblings, -1)
      call add(node.parent.siblings, node)
      let node.parent.next = node
      let node.previous = node.parent
      let node.siblings = node.parent.siblings
      let node.parent = node.parent.parent
      let node.level -= 1
      let self.parent = node
      "}}}

    elseif self.in_optional_group() && node.is_invalid_in_optional() "{{{
      23DebugRELab  printf('parse -> invalid in optional')
      let errormessage =
            \ printf('%s is not valid inside \%%[]', node.value)
      call self.add_error(node, errormessage)
      "}}}

    elseif node.starts_group() "{{{
      23DebugRELab  printf('parse -> starts group')
      call add(self.nest_stack, node)
      let self.parent = node
      if node.starts_collection()
        23DebugRELab  printf('parse -> starts group -> collection')
        if self.collection_ends()
          " The collection is terminated by a ']', so treat this as the
          " start of the collection
          let self.in_collection = 1
        else
          " Treat this as a literal character
          call remove(self.nest_stack, -1)
          let self.parent = node.parent
          let node.id = node.ignorecase ? 'x' : 'X'
        endif
      elseif node.starts_capt_group()
        23DebugRELab  printf('parse -> starts group -> capt group')
        let self.capt_groups += 1
        let node.capt_groups = self.capt_groups
        let node.is_capt_group = 1
        23DebugRELab  printf('parse -> starts group -> capt group: '
              \ . 'node.capt_groups: %s', node.capt_groups)
        if self.capt_groups > 9
          let errormessage = 'more than 9 capturing groups'
          call self.add_error(node, errormessage)
        endif
      else
        23DebugRELab  printf('parse -> starts group -> non capturing group')
        let node.is_capt_group = 0
      endif
      "}}}

    elseif node.ends_group() "{{{
      23DebugRELab  printf('parse -> ends group')
      if node.is_paired()
        23DebugRELab  printf('parse -> ends group -> is paired')
        call remove(self.nest_stack, -1)
        let self.parent = node.parent.parent
        let node.level -= 1
        if node.ends_opt_group()
          23DebugRELab  printf('parse -> ends group -> is paired -> opt group')
          if empty(node.previous)
            let errormessage = printf('empty %s%s', node.parent.value,
                  \ node.value)
            call self.add_error(node, errormessage)
          else
            let node.id = '\%]'
          endif
        elseif node.is_capt_group
        else
          let node.id = '\%)'
        endif
      else
        23DebugRELab  printf('parse -> ends group -> is not paired')
        if node.id ==# ']'
          let node.id = node.ignorecase ? 'x' : 'X'
        elseif empty(self.nest_stack)
          " /\)
          let errormessage = printf('unmatched %s', node.value)
          call self.add_error(node, errormessage)
        else
          " /\%[\)
          let errormessage = printf('unmatched %s', node.value)
          call self.add_error(node, errormessage)
        endif
      endif
      "}}}

    elseif node.has_underscore() "{{{
      23DebugRELab  printf('parse -> has underscore')
      if node.is_valid_underscore()
        23DebugRELab  printf('parse -> has underscore -> valid')
      elseif !node.is_valid_underscore()
        23DebugRELab  printf('parse -> has underscore -> invalid')
        let char = strcharpart(node.magic, 2)
        let errormessage = 'invalid use of \_'
        call self.add_error(node, errormessage)
      endif
      "}}}

    elseif node.is_multi() "{{{
      23DebugRELab  printf('parse -> multi')
      if !empty(node.previous) && node.previous.is_multi()
        23DebugRELab  printf('parse -> multi -> follows multi')
        let errormessage =
              \ printf('%s can not follow a multi', node.value)
        call self.add_error(node, errormessage)
      elseif node.follows_nothing()
        23DebugRELab  printf('parse -> multi -> follows nothing')
        let errormessage =
              \ printf('%s follows nothing', node.value)
        call self.add_error(node, errormessage)
      elseif node.is_multi_bracket()
        23DebugRELab  printf('parse -> multi -> brackets')
        if node.is_valid_bracket()
          23DebugRELab  printf('parse -> multi -> brackets -> valid')
          let node.min = matchstr(node.value, '\m\\{-\?\zs\d*')
          let node.max = matchstr(node.value, '\m\\{-\?\d*,\zs\d*')
        else
          23DebugRELab  printf('parse -> multi -> brackets -> invalid')
          let errormessage =
                \ printf('syntax error in %s', node.value)
          call self.add_error(node, errormessage)
        endif
      endif
      "}}}

    elseif node.is_back_reference() "{{{
      23DebugRELab  printf('parse -> back reference')
      if strcharpart(node.value, 1, 1) > self.capt_groups
        23DebugRELab  printf('parse -> back reference -> illegal')
        let errormessage = 'illegal back reference'
        call self.add_error(node, errormessage)
      endif
      "}}}

    elseif node.is_look_around() "{{{
      23DebugRELab  printf('parse -> look around')
      if node.follows_nothing()
        23DebugRELab  printf('parse -> look around -> illegal')
        let errormessage = printf('%s follows nothing', node.value)
        call self.add_error(node, errormessage)
      endif
      "}}}

    elseif node.starts_with_at() "{{{
      23DebugRELab  printf('parse -> starts with @')
      if node.id !=# '\@>'
        let errormessage = printf('invalid character after %s',
              \ (node.magicness ==# 'v' ? '@' : '\@'))
        call self.add_error(node, errormessage)
      endif
      "}}}

    elseif node.like_code_point() "{{{
      23DebugRELab  printf('parse -> like code point: magicness: %s',
            \ node.magic)
      if node.is_code_point()
        23DebugRELab  printf('parse -> like code point -> hexadecimal 8')
      else
        23DebugRELab  printf('parse -> like code point -> invalid code point')
        let errormessage = printf('invalid character after %s',
              \ matchstr(node.value, '\\\?%[duUx]'))
        call self.add_error(node, errormessage)
      endif
      "}}}

    elseif node.is_mark() "{{{
      23DebugRELab  printf('parse -> mark')
      "}}}

    elseif node.is_lcv() "{{{
      23DebugRELab  printf('parse -> lcv')
      "}}}

    elseif node.is_invalid_percent() "{{{
      23DebugRELab  printf('parse -> invalid percent')
      let errormessage = printf('invalid character after %s',
            \ matchstr(node.value, '\\\?%'))
      call self.add_error(node, errormessage)
      "}}}

    elseif node.is_invalid_z() "{{{
      23DebugRELab  printf('parse -> invalid percent')
      let errormessage = printf('invalid character after %s',
            \ matchstr(node.value, '\\\?z'))
      call self.add_error(node, errormessage)
      "}}}

    elseif node.is_case() "{{{
      let self.ignorecase = node.id ==# '\c'
      23DebugRELab  printf('parse -> case: %s', self.ignorecase)
      "}}}

    elseif node.is_magic() "{{{
      23DebugRELab  printf('parse -> magicness')
      let self.magicness = node.id[1]
      "}}}

    elseif node.value !=? 'x' && has_key(self.id_map, node.id) "{{{
      23DebugRELab  printf('parse -> has_key: node.id: %s', node.id)
      "}}}

    else
      if !empty(self.sep) && node.value ==# '\' . self.sep
        let node.value = self.sep
      endif
      23DebugRELab  printf('parse -> literal match')
      let node.id = node.ignorecase ? 'x' : 'X'
    endif
    let node.line = node.is_error ? '' : self.line(node)
  endwhile
  if !empty(self.nest_stack)
    23DebugRELab  printf('parse -> non-empty nest stack')
    for node in self.nest_stack
      23DebugRELab  printf('parse -> non-empty nest stack -> loop: %s',
            \ node.value)
      if node.starts_opt_group()
        let errormessage = printf('missing ] after %s', node.value)
      else
        let errormessage = printf('unmatched %s', node.value)
      endif
      call self.add_error(node, errormessage)
    endfor
  endif
  return self
endfunction "}}}

function! relab#parser#new(...) "{{{
  21DebugRELab printf('%s:', expand('<sfile>'))
  21DebugRELab printf('args: %s', a:)
  let parser = {}
  let parser.id_map = s:id_map
  let parser.sep = a:0 ? a:1 : ''
  let parser.root = relab#parser#node#new()
  let parser.init = function('s:init')
  let parser.magic = function('s:magic')
  let parser.id = function('s:id')
  let parser.help_tag = function('s:help_tag')
  let parser.line = function('s:line')
  let parser.in_optional_group = function('s:in_optional_group')
  let parser.map = function('s:map')
  let parser.collection_ends = function('s:collection_ends')
  let parser.add_error = function('s:add_error')
  let parser.incomplete_in_coll = function('s:incomplete_in_coll')
  let parser.is_incomplete = function('s:is_incomplete')
  let parser.next = function('s:next')
  let parser.parse = function('s:parse')
  let parser.match_group = function('s:match_group')
  let parser.match_groups = function('s:match_groups')
  let parser.magics = function('s:magics')
  let parser.values = function('s:values')
  let parser.lines = function('s:lines')
  let parser.ids = function('s:ids')
  return parser.init(get(a:, '1', ''))
endfunction "}}}
