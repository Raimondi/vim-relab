let s:id_map = {}
for line in readfile(printf('%s/%s', expand('<sfile>:p:h'), 'id_key.txt'))
  "DbgRELab printf('id_map -> for: line: %s', line)
  let [id, help, desc] = split(line, '\t')
  "DbgRELab printf('id_map -> for: id: %s, help: %s, desc: %s',
  "      \id, help, desc)
  if has_key(s:id_map, id)
    echoerr 'Duplicated key!'
  else
    let s:id_map[id] = {'help_tag': help, 'line': desc}
  endif
endfor

function! relab#parser#new()
  let parser = {}
  let parser.id_map = s:id_map

  let node = {} "{{{

  function! node.is_magic()
    return self.magic =~? '\m^\\[mv]$'
  endfunction

  function! node.is_branch()
    return self.magic ==# '\|' || self.magic ==# '\&'
  endfunction

  function! node.starts_group()
    return self.magic ==# '[' || self.magic =~# '\m^\\%\?($'
          \ || self.magic ==# '\%['
  endfunction

  function! node.starts_capt_group()
    return self.magic ==# '\('
  endfunction

  function! node.starts_non_capt_group()
    return self.magic ==# '\%('
  endfunction

  function! node.starts_opt_group()
    return self.magic ==# '\%['
  endfunction

  function! node.starts_collection()
    return self.magic ==# '['
  endfunction

  function! node.ends_group()
    return self.magic ==# ']' || self.magic ==# '\)'
  endfunction

  function! node.ends_capt_group()
    return get(self.get_left_pair(), 'magic', '') ==# '\('
          \ && self.magic ==# '\)'
  endfunction

  function! node.ends_non_capt_group()
    return get(self.get_left_pair(), 'magic', '') ==# '\%('
          \ && self.magic ==# '\)'
  endfunction

  function! node.ends_opt_group()
    return get(self.get_left_pair(), 'magic', '') ==# '\%['
          \ && self.magic ==# ']'
  endfunction

  function! node.ends_collection()
    return get(self.get_left_pair(), 'magic', '') ==# '['
          \ && self.magic ==# ']'
  endfunction

  function! node.item_or_eol()
    return self.magic =~# '\m^\\_[$^.iIkKfFpPsSdDxXoOwWhHaAlLuU]$'
  endfunction

  function! node.is_engine()
    return self.id ==# '\%#='
  endfunction

  function! node.is_multi()
    return self.magic =~# '\m^\%(\\[?=+]\|\*\)$\|^\\{'
  endfunction

  function! node.is_multi_bracket()
    return self.magic =~# '\m^\\{'
  endfunction

  function! node.is_valid_bracket()
    return self.magic =~# '\m^\\{-\?\d*,\?\d*\\\?}$'
  endfunction

  function! node.is_look_around()
    return self.id =~# '\m^\\@\%([!=>]\|\d*<[!=]\)$'
  endfunction

  function! node.is_group()
    return index(['\(', '\%(', '\)', '\|', '\&'], self.id) >= 0
  endfunction

  function! node.is_invalid_in_optional()
    return self.is_multi() || self.is_group() || self.is_look_around()
          \ || self.starts_opt_group()
  endfunction

  function! node.is_back_reference()
    return self.id =~# '\m^\\[1-9]$'
  endfunction

  function! node.starts_with_at()
    return self.magic =~# '\m^\\@'
  endfunction

  function! node.is_boundary()
    return self.magic ==# '\zs' || self.magic ==# '\ze'
  endfunction

  function! node.has_underscore()
    return self.magic =~# '\m^\\_.'
  endfunction

  function! node.is_valid_underscore()
    return self.magic =~# '\m^\\_[iIkKfFpPsSdDxXoOwWhHaAlLuU^$[.]$'
  endfunction

  function! node.is_coll_range()
    return self.magic =~#
          \ '\m^\%(\\[-^\]\\ebnrt]\|[^\\]\)-\%(\\[-^\]\\ebnrt]\|[^\\]\)$'
  endfunction

  function! node.is_coll_range_id()
    return self.id ==? 'a-b'
  endfunction

  function! node.like_code_point()
    return self.magic =~# '\m^\\%[douUx]'
  endfunction

  function! node.is_code_point()
    return self.magic =~#
          \ '\m^\\%\(d\d\+\|o0\?\o\{1,3}\|x\x\{1,2}\|u\x\{1,4}\|U\x\{1,8}\)$'
  endfunction

  function! node.is_invalid_percent()
    return self.magic =~# '\m^\\%[^V#^$C]\?$'
  endfunction

  function! node.is_mark()
    return self.magic =~# '\m^\\%[<>]\?''[a-zA-Z0-9''[\]<>]$'
  endfunction

  function! node.is_lcv()
    return self.magic =~# '\m^\\%[<>]\?\d*[clv]'
  endfunction

  function! node.is_invalid_z()
    return self.magic =~# '\m^\\z[^se]\?$'
  endfunction

  function! node.is_case()
    return self.magic ==? '\c'
  endfunction

  function! node.follows_nothing() "{{{
    return empty(self.previous) || self.previous.is_branch()
          \ || self.previous.is_look_around()
  endfunction "}}}

  function! node.get_left_pair() "{{{
    let pairs = {}
    let pairs['\('] = '\)'
    let pairs['\%('] = '\)'
    let pairs['\%['] = ']'
    let pairs['['] = ']'
    let parent = self.parent
    while !empty(parent) && parent.id !=# 'root'
      if parent.is_branch()
        let parent = parent.previous
      elseif get(pairs, parent.id, '') ==# self.magic
        return parent
      else
        break
      endif
    endwhile
    return {}
  endfunction "}}}

  function! node.is_paired() "{{{
    return !empty(self.get_left_pair())
  endfunction "}}}

  function! node.new(token, magicness, ignorecase, magic, pos, id) "{{{
    let n = copy(self)
    let n.is_error = 0
    let n.error = []
    let n.magicness = a:magicness
    let n.ignorecase = a:ignorecase
    let n.parent = self
    let n.siblings = self.children
    let n.children = []
    let n.previous = get(self.children, -1, {})
    let n.next = {}
    let n.value = a:token
    let n.magic = a:magic
    let n.id = a:id
    let n.level += 1
    let n.line = ''
    let n.pos = a:pos - strchars(a:token)
    if !empty(n.previous)
      let n.previous.next = n
    endif
    call add(self.children, n)
    DbgRELab  printf('new: node: %s', filter(copy(n), 'type(v:val) <= 1'))
    return n
  endfunction "}}}

  let node.value = 'root'
  let node.magic = 'root'
  let node.id = 'root'
  let node.help = 'pattern'
  let parser.root = node "}}}

  function! parser.init(...) "{{{
    let self.magicness = 'm'
    let self.ignorecase = 0
    let self.in_collection = 0
    let self.token = ''
    let self.tokens = []
    let self.nest_stack = []
    let self.input = get(a:, '1', '')
    let self.length = strchars(self.input)
    let self.pos = 0
    let self.capt_groups = 0
    let self.errors = []
    let self.sequence = []

    let self.root.magicness = self.magicness
    let self.root.capt_groups = self.capt_groups
    let self.root.is_capt_group = 0
    let self.root.ignorecase = self.ignorecase
    let self.root.parent = {}
    let self.root.siblings = []
    let self.root.children = []
    let self.root.level = 0

    let self.parent = self.root
    return self
  endfunction "}}}

  function! parser.magic() "{{{
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

  function! parser.id() "{{{
    let magic_token = self.magic()
    DbgRELab printf('to id: self.token: %s, magic_token: %s', self.token,
          \ magic_token)
    if self.in_collection
      DbgRELab printf('to id -> collection')
      if self.token =~# '\m^\\[doxuU]'
        DbgRELab printf('to id -> collection -> code point')
        " /[\x]
        return substitute(self.token, '\m^\(\\.\).\+', '[\1', '')
      elseif self.token =~#
            \ '\m^\%(\\[-^\]\\ebnrt]\|[^\\]\)-\%(\\[-^\]\\ebnrt]\|[^\\]\)$'
        DbgRELab printf('to id -> collection -> range')
        " /[a-z]
        return self.ignorecase ? 'a-b' : 'A-B'
      elseif self.token =~# '\m^\[[.=].[.=]\]$'
        DbgRELab printf('to id -> collection -> collation/equivalence')
        " /[[.a.][=a=]]
        return substitute(self.token, '\m^\(\[[.=]\).[.=]\]$', '[\1\1]', '')
      endif
    elseif magic_token =~# '\m^\\%[<>]\?\d\+[lvc]$'
      DbgRELab printf('to id -> lcv')
      " /\%23l
      return substitute(self.token, '\m\d\+', '', '')
    elseif magic_token =~# '\m^\\%[<>]\?''.$'
      DbgRELab printf('to id -> mark')
      " /\%'m
      return substitute(self.token, '.$', 'm', '')
    elseif magic_token =~# '\m^\\{'
      DbgRELab printf('to id -> multi curly')
      " /.\{}
      let id = '\{'
      let id .= magic_token =~# '\m^\\{-' ? '-' : ''
      let id .= magic_token =~# '\m^\\{-\?\d' ? 'n' : ''
      let id .= magic_token =~# '\m^\\{-\?\d*,' ? ',' : ''
      let id .= magic_token =~# '\m^\\{-\?\d*,\d' ? 'm' : ''
      let id .= '}'
      return id
    elseif magic_token =~# '\m^\\%[doxuU]\d\+$'
      DbgRELab printf('to id -> code point')
      " /\%d123
      return matchstr(self.token, '\m\C^\\%[doxuU]')
    elseif self.token =~# '\m^\\%#=.\?'
      DbgRELab printf('to id -> engine')
      " regexp engine
      return '\%#='
    elseif magic_token =~# '\m^\\@\%([!=>]\|\d*<[!=]\)$'
      DbgRELab printf('to id -> lookaround')
      return substitute(self.token, '\d\+', '123', '')
    elseif magic_token =~# '\m^\\[[.^$~*]$'
      DbgRELab printf('to id -> literal')
      return magic_token
    endif
    DbgRELab printf('to id -> else')
    return self.token
  endfunction "}}}

  function! parser.help_tag(node) "{{{
    return get(get(self.id_map, a:node.id, {}), 'help_tag', '')
  endfunction "}}}

  function! parser.line(node, ...) "{{{
    let id = a:node.id
    DbgRELab printf('line: %s', id)
    let line = get(self.id_map, id,
          \ {'line': 'ERROR: contact this plugin''s author'}).line
    DbgRELab printf('line: %s', line)
    if id ==? 'x'
      DbgRELab 'line -> literal'
      if strchars(a:node.magic) == 1
        DbgRELab 'line -> literal -> single'
        let char = a:node.value
        let code = char2nr(char)
      elseif a:node.value =~# '\m^\\[^etrbn]'
        DbgRELab 'line -> literal -> escaped'
        let char = strcharpart(a:node.value, 1)
        let code = char2nr(char)
      elseif a:node.value ==# '\e'
        DbgRELab 'line -> literal -> escape'
        let char = '<Esc>'
        let code = 27
      elseif a:node.value ==# '\t'
        DbgRELab 'line -> literal -> tab'
        let char = '<Tab>'
        let code = 9
      elseif a:node.value ==# '\node'
        DbgRELab 'line -> literal -> car return'
        let char = '<CR>'
        let code = 13
      elseif a:node.value ==# '\b'
        DbgRELab 'line -> literal -> backspace'
        let char = '<BS>'
        let code = 8
      else
        DbgRELab 'line -> literal -> single'
        let char = a:node.value
        let code = char2nr(char)
      endif
      if id ==# 'X'
        DbgRELab 'line -> literal -> match case'
        let line = printf(line, char, code)
      elseif tolower(char) ==# toupper(char)
        DbgRELab 'line -> literal -> no case'
        let line = get(self.id_map, 'X',
              \ {'line': 'ERROR: contact this plugin''s author'}).line
        let line = printf(line, char, code)
      else
        DbgRELab 'line -> literal -> ignore case'
        let line = printf(line, tolower(char), char2nr(tolower(char)),
              \ toupper(char), char2nr(toupper(char)))
      endif
    elseif id ==# 'A-B'
      DbgRELab 'line -> range match case'
      let line = printf(line, a:node.first, char2nr(a:node.first),
            \ a:node.second, char2nr(a:node.second))
    elseif id ==# 'a-b'
      DbgRELab 'line -> range ignore case'
      let line = printf(line,
            \ tolower(a:node.first), char2nr(tolower(a:node.first)),
            \ tolower(a:node.second), char2nr(tolower(a:node.second)),
            \ toupper(a:node.first), char2nr(toupper(a:node.first)),
            \ toupper(a:node.second), char2nr(toupper(a:node.second))
            \ )
    elseif id =~# '^\m\\{'
      DbgRELab 'line -> brackets'
      if empty(a:node.min)
        DbgRELab 'line -> brackets -> empty min'
        if empty(a:node.max)
          DbgRELab 'line -> brackets -> empty min -> empty max'
          " nothing to do
        else
          DbgRELab 'line -> brackets -> empty min -> non empty max'
          let line = printf(line, a:node.max)
        endif
      else
        DbgRELab 'line -> brackets -> non empty min'
        if empty(a:node.max)
          DbgRELab 'line -> brackets -> non empty min -> empty max'
          let line = printf(line, a:node.min)
        else
          DbgRELab 'line -> brackets -> non empty min -> non empty max'
          let line = printf(line, a:node.min, a:node.max)
        endif
      endif
    elseif id =~# '\m^\\@123<[=!]$'
      DbgRELab 'line -> look behind'
      let line = printf(line, matchstr(a:node.magic, '\d\+'))
    elseif id =~# '\m^\%(\[\\\|\\%\)[doxuU]'
      DbgRELab 'line -> code point'
      let code_map = {'d': '%s', 'o': '0%s', 'x': '0x%s', 'u': '0x%s',
            \ 'U': '0x%s'}
      let key = matchstr(id, '\m^\%(\[\\\|\\%\)\zs.')
      DbgRELab printf('line -> code point: magicness: %s, key: %s',
            \ a:node.magic, key)
      let number = matchstr(a:node.magic, '\m^\\%\?.0\?\zs.\+')
      DbgRELab printf('line -> code point: number: %s', number)
      let code = printf(code_map[key], number)
      DbgRELab printf('line -> code point: code: %s', code)
      let dec = eval(code)
      DbgRELab printf('line -> code point: dec: %s', dec)
      let char = nr2char(dec)
      let char_is_lower = char =~# '\%#=2^[[:lower:]]$'
      let char2 = char_is_lower ? toupper(char) : tolower(char)
      let has_case = tolower(char) !=# toupper(char)
      if a:node.ignorecase && char !=# char2
        DbgRELab 'line -> code point -> ignore case'
        let line = get(self.id_map, id . 'i',
              \ {'line': 'ERROR: contact this plugin''s author'}).line
        let line = printf(line, char, char2)
      else
        DbgRELab 'line -> code point -> match case'
        let line = printf(line, char)
      endif
    elseif has_key(self.id_map, id)
      DbgRELab 'line -> has key'
    else
      DbgRELab 'line -> else'
    endif
    let indent = repeat(' ', (a:node.level * 2))
    let line = printf('%s%s => %s', indent, a:node.value, line)
    return line
  endfunction "}}}

  function! parser.lines() "{{{
    let lines = []
    if !empty(self.errors)
      return extend(lines, self.errors[0].error)
    endif
    call add(lines, '')
    return extend(lines, map(copy(self.sequence), 'v:val.line'))
  endfunction "}}}

  function! parser.match_group(offset, ...) "{{{
    DbgRELab printf('match group: offset: %s, group: %s, regexp: %s',
          \ a:offset, (a:0 ? a:1 : 'all'), self.input)
    if self.capt_groups < get(a:, 1, 0)
      DbgRELab printf('match group: arg > available groups')
      let items = []
    elseif get(a:, 1, 0) > 9
      DbgRELab printf('match group: arg > 9')
      let items = []
    else
      " TODO Need to considers \zs and \ze inside the group
      " like in 'abc\(de\zefg\|hij\)jkl'
      DbgRELab printf('match group: arg > 0')
      let items = ['\m\C']
      if a:offset
        call add(items, printf('\%%>%sl', a:offset))
      endif
      DbgRELab printf('match group: capt_groups: %s', map(copy(self.sequence),
            \ 'get(v:val, ''capt_groups'', 0)'))
      for node in self.sequence
        DbgRELab printf('match group: node.magic: %s', node.magic)
        if node.is_branch()
          DbgRELab printf('match group -> is_branch:')
          if a:0 && node.capt_groups == a:1 && node.is_capt_group
            DbgRELab printf('match group -> branch -> add \ze:')
            call add(items, '\ze')
          endif
          call add(items, node.magic)
          if a:0 && node.capt_groups == a:1
            DbgRELab printf('match group -> branch -> add \zs:')
            call add(items, '\zs')
          endif
          if a:offset && node.level == -1
            DbgRELab printf('match group -> is_branch -> add line nr:')
            call add(items, printf('\%%>%sl', a:offset))
          endif
        elseif node.starts_capt_group()
          DbgRELab printf('match group -> starts_capt_group:')
          call add(items, node.magic)
          if a:0 && node.capt_groups == a:1
            DbgRELab printf('match group -> starts_capt_group -> add \zs:')
            call add(items, '\zs')
          endif
        elseif node.ends_capt_group()
          DbgRELab printf('match group -> ends_capt_group:')
          if a:0 && node.capt_groups == a:1 && node.is_capt_group
            DbgRELab printf('match group -> ends_capt_group -> add \ze:')
            call add(items, '\ze')
          endif
          call add(items, node.magic)
        elseif node.is_boundary()
          DbgRELab printf('match group -> is_boundary:')
          if a:0 && a:1 == 0
            DbgRELab printf('match group -> is_boundary -> add node:')
            call add(items, node.magic)
          endif
        elseif node.id ==# '\%l'
          DbgRELab printf('match group -> is_line_nr:')
          if a:offset
            let linenr = matchstr(node.magic, '\d\+') + a:offset
            call add(items, substitute(node.magic, '\d\+', linenr, ''))
          else
            call add(items, node.magic)
          endif
        elseif node.value ==# '\'
          DbgRELab printf('match group -> single backspace:')
          call add(items, '\\')
        elseif node.id ==# '\%^'
          DbgRELab printf('match group -> is_bof:')
          if a:offset
            call add(items, printf('\%%%sl\_^', a:offset))
          else
            call add(items, node.magic)
          endif
        elseif node.magic ==# '[' && node.id ==? 'x'
          DbgRELab printf('match group -> literal [:')
          call add(items, '\[')
        else
          DbgRELab printf('match group -> else:')
          call add(items, node.magic)
        endif
      endfor
    endif
    if len(items) - (a:offset > 0) > 1
      let group_re = join(filter(items, '!empty(v:val)'), '')
    else
      let group_re = ''
    endif
    DbgRELab printf('match group: result: %s', group_re)
    return group_re
  endfunction "}}}

  function! parser.match_groups(...) "{{{
    DbgRELab printf('match group: regexp: %s', self.input)
    let offset = get(a:, 1, 0)
    let groups = []
    call add(groups, self.match_group(offset))
    for group in range(0, self.capt_groups)
      call add(groups, self.match_group(offset, group))
    endfor
    return filter(groups, '!empty(v:val)')
  endfunction "}}}

  function! parser.in_optional_group() "{{{
    return get(get(self.nest_stack, -1, {}), 'id', '') ==# '\%['
  endfunction "}}}

  function! parser.map(key) "{{{
    return map(copy(self.sequence), 'get(v:val, a:key, '''')')
  endfunction "}}}

  function! parser.magics() "{{{
    return map(copy(self.sequence), 'v:val.magic')
  endfunction "}}}

  function! parser.values() "{{{
    return map(copy(self.sequence), 'get(v:val, ''value'', '''')')
  endfunction "}}}

  function! parser.ids() "{{{
    return map(copy(self.sequence), 'get(v:val, ''id'', '''')')
  endfunction "}}}

  function! parser.collection_ends() "{{{
    let ahead = strcharpart(self.input, self.pos)
    if ahead[0] ==# '^'
      return ahead =~# '\m^\^\%(\\[-ebrtndoxuU^$\]]\|[^\]]\)\+]'
    else
      return ahead =~# '\m^\%(\\[-ebrtndoxuU^$\]]\|[^\]]\)\+]'
    endif
  endfunction "}}}

  function! parser.add_error(node, ...) "{{{
    let a:node.is_error = 1
    let error = []
    let arrow = printf('%s%s',
          \ repeat('-', a:node.pos), repeat('^', strchars(a:node.value)))
    call add(error, arrow)
    call add(error, printf('Error: %s', (a:0 ? a:1 : a:node.value . ':')))
    let a:node.error = error
    call add(self.errors, a:node)
  endfunction "}}}

  function! parser.incomplete_in_coll() "{{{
    let next = self.token . strcharpart(self.input, self.pos)
    let ahead = strcharpart(self.input, self.pos, 1)
    if empty(self.parent.children) && self.token ==# '^'
      DbgRELab printf('incomplete_in_coll -> negate: %s', next)
      return 0
    elseif self.token =~#
          \ '\m^\%(\\[\\ebnrt]\|[^\\]\)-\%(\\[\\ebnrt]\|[^\\]\)$'
      DbgRELab printf('incomplete_in_coll -> range done: %s', next)
      return 0
    elseif next =~# '\m^\%(\\[\\enbrt]\|[^\\]\)-\%(\\[\\ebnrt]\|[^\\]\)'
      DbgRELab printf('incomplete_in_coll -> range coming: %s', next)
      return 1
    elseif self.token =~# '\m^\\[-\\ebnrt\]^]$'
      DbgRELab printf('incomplete_in_coll -> escaped done: %s', next)
      return 0
    elseif self.token ==# '\' && ahead =~# '\m^[-\\ebnrtdoxuU\]^]$'
      DbgRELab printf('incomplete_in_coll -> escaped done: %s', next)
      return 1
    elseif self.token ==# '\'
      DbgRELab
            \ printf('incomplete_in_coll -> escaped coming: %s', next)
      return 0
    elseif self.token =~# '\m^\[\([.=]\).\1\]$'
      DbgRELab printf('incomplete_in_coll -> equivalence done: %s', next)
      return 0
    elseif next =~# '\m^\[\([.=]\).\1\]'
      DbgRELab printf('incomplete_in_coll -> equivalence coming: %s', next)
      return 1
    elseif self.token =~# '\m^\[:\a\+:\]$'
      DbgRELab printf('incomplete_in_coll -> collation done: %s', next)
      return 0
    elseif next =~# '\m^\[:\a\+:\]'
      DbgRELab printf('incomplete_in_coll -> collation coming: %s', next)
      return 1
    endif
    let next = self.token . ahead
    if next =~# '\m^\\d\d*$'
      DbgRELab printf('incomplete_in_coll -> dec: %s', next)
      return 1
    elseif next =~# '\m^\\o0\?\o\{,3}$'
          \ && printf('0%s', matchstr(next, '0\?\zs\o\+')) <= 0377
      DbgRELab printf('incomplete_in_coll -> oct: %s', next)
      return 1
    elseif next =~# '\m^\\x\x\{,2}$'
      DbgRELab printf('incomplete_in_coll -> hex2: %s', next)
      return 1
    elseif next =~# '\m^\\u\x\{,4}$'
      DbgRELab printf('incomplete_in_coll -> hex4: %s', next)
      return 1
    elseif next =~# '\m^\\U\x\{,8}$'
      DbgRELab printf('incomplete_in_coll -> hex8: %s', next)
      return 1
    elseif next =~# '\m^\\[duUx].$'
      DbgRELab printf('incomplete_in_coll -> code point: %s', next)
      return 1
    else
      return 0
    endif
  endfunction "}}}

  function! parser.is_incomplete() "{{{
    DbgRELab printf('is_incomplete')
    if self.in_collection
      return self.incomplete_in_coll()
    endif
    let token = self.magic()
    if token =~# '\m^\\\%(@\%(\d*\%(<\?\)\)\)$'
          \ || token =~# '\m^\\\%(%[<>]\?\%(\d*\|''\)$\)'
          \ || token =~# '\m^\\\%(_\|#\|{[^}]*\|z\)\?$'
      DbgRELab printf('is_incomplete -> main: %s', token)
      return 1
    endif
    let ahead = strcharpart(self.input, self.pos, 1)
    let next = token . ahead
    if next =~# '\m^\\%d\d*$'
      DbgRELab printf('is_incomplete -> dec: %s', next)
      return 1
    elseif next =~# '\m^\\%o0\?\o\{,3}$'
          \ && printf('0%s', matchstr(next, '0\?\zs\o\+')) <= 0377
      DbgRELab printf('is_incomplete -> oct: %s', next)
      return 1
    elseif next =~# '\m^\\%x\x\{,2}$'
      DbgRELab printf('is_incomplete -> hex2: %s', next)
      return 1
    elseif next =~# '\m^\\%u\x\{,4}$'
      DbgRELab printf('is_incomplete -> hex4: %s', next)
      return 1
    elseif next =~# '\m^\\%U\x\{,8}$'
      DbgRELab printf('is_incomplete -> hex8: %s', next)
      return 1
    elseif next =~# '\m^\\%[duUx].$'
      DbgRELab printf('is_incomplete -> code point: %s', next)
      return 1
    endif
    DbgRELab printf('is_incomplete -> else: next: %s', next)
    return 0
  endfunction "}}}

  function! parser.next() "{{{
    if self.pos == 0 && !empty(matchstr(self.input, '^\\%#=.\?'))
      " \%#= must be the first thing
      let self.token = matchstr(self.input, '^\\%#=.\?')
      let self.pos = strchars(self.token)
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

  function! parser.parse(input) "{{{
    DbgRELab printf('')
    DbgRELab printf('parse: %s', a:input)
    call self.init(a:input)
    while self.next()
      let token = self.token
      let magicness = self.magicness
      let ignorecase = self.ignorecase
      let magic = self.magic()
      let pos = self.pos
      let id = self.id()
      let node = self.parent.new(token, magicness, ignorecase, magic, pos, id)
      call add(self.sequence, node)
      DbgRELab printf('parse -> token: %s, magicness: %s, ignorecase: %s, '
            \ . 'magic: %s, pos: %s, id: %s', token, magicness, ignorecase,
            \ magic, pos, id)

      if self.in_collection && node.ends_collection() "{{{
        DbgRELab  'parse -> ends collection'
        call remove(self.nest_stack, -1)
        let self.parent = node.parent.parent
        let self.in_collection = 0
        let node.level -= 1
        "}}}

      elseif self.in_collection && node.id ==# '^' "{{{
        DbgRELab printf('parse -> collection -> negate')
        if empty(node.previous)
          DbgRELab printf('parse -> collection -> negate -> special')
          let node.id = '[^'
        else
          DbgRELab printf('parse -> collection -> negate -> literal')
          let node.id = node.ignorecase ? 'x' : 'X'
        endif
        "}}}

      elseif self.in_collection && node.is_coll_range_id() "{{{
        DbgRELab printf('parse -> collection -> range')
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
        DbgRELab printf('parse -> collection -> range: first: %s, second: %s',
              \ node.first, node.second)
        let node.second = get(dict, node.second, node.second)
        if node.first ># node.second
          let errormessage = 'reverse range in character class'
          call self.add_error(node, errormessage)
        endif
        "}}}

      elseif node.is_engine() "{{{
        DbgRELab  printf('parse -> engine')
        if matchstr(node.value, '^\m\\%#=\zs.\?') !~# '\m^[0-2]$'
          let errormessage =
                \ '\%#= can only be followed by 0, 1, or 2'
          call self.add_error(node, errormessage)
        endif
        "}}}

      elseif node.is_branch() "{{{
        DbgRELab  printf('parse -> is_branch')
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
        DbgRELab  printf('parse -> invalid in optional')
        let errormessage =
              \ printf('%s is not valid inside \%%[]', node.value)
        call self.add_error(node, errormessage)
        "}}}

      elseif node.starts_group() "{{{
        DbgRELab  printf('parse -> starts group')
        call add(self.nest_stack, node)
        let self.parent = node
        if node.starts_collection()
          DbgRELab  printf('parse -> starts group -> collection')
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
          DbgRELab  printf('parse -> starts group -> capt group')
          let self.capt_groups += 1
          let node.capt_groups = self.capt_groups
          let node.is_capt_group = 1
          DbgRELab  printf('parse -> starts group -> capt group: '
                \ . 'node.capt_groups: %s', node.capt_groups)
          if self.capt_groups > 9
            let errormessage = 'more than 9 capturing groups'
            call self.add_error(node, errormessage)
          endif
        else
          DbgRELab  printf('parse -> starts group -> non capturing group')
          let node.is_capt_group = 0
        endif
        "}}}

      elseif node.ends_group() "{{{
        DbgRELab  printf('parse -> ends group')
        if node.is_paired()
          DbgRELab  printf('parse -> ends group -> is paired')
          call remove(self.nest_stack, -1)
          let self.parent = node.parent.parent
          let node.level -= 1
          if node.ends_opt_group()
            DbgRELab  printf('parse -> ends group -> is paired -> opt group')
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
          DbgRELab  printf('parse -> ends group -> is not paired')
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
        DbgRELab  printf('parse -> has underscore')
        if node.is_valid_underscore()
          DbgRELab  printf('parse -> has underscore -> valid')
        elseif !node.is_valid_underscore()
          DbgRELab  printf('parse -> has underscore -> invalid')
          let char = strcharpart(node.magic, 2)
          let errormessage = 'invalid use of \_'
          call self.add_error(node, errormessage)
        endif
        "}}}

      elseif node.is_multi() "{{{
        DbgRELab  printf('parse -> multi')
        if !empty(node.previous) && node.previous.is_multi()
          DbgRELab  printf('parse -> multi -> follows multi')
          let errormessage =
                \ printf('%s can not follow a multi', node.value)
          call self.add_error(node, errormessage)
        elseif node.follows_nothing()
          DbgRELab  printf('parse -> multi -> follows nothing')
          let errormessage =
                \ printf('%s follows nothing', node.value)
          call self.add_error(node, errormessage)
        elseif node.is_multi_bracket()
          DbgRELab  printf('parse -> multi -> brackets')
          if node.is_valid_bracket()
            DbgRELab  printf('parse -> multi -> brackets -> valid')
            let node.min = matchstr(node.value, '\m\\{-\?\zs\d*')
            let node.max = matchstr(node.value, '\m\\{-\?\d*,\zs\d*')
          else
            DbgRELab  printf('parse -> multi -> brackets -> invalid')
            let errormessage =
                  \ printf('syntax error in %s', node.value)
            call self.add_error(node, errormessage)
          endif
        endif
        "}}}

      elseif node.is_back_reference() "{{{
        DbgRELab  printf('parse -> back reference')
        if strcharpart(node.value, 1, 1) > self.capt_groups
          DbgRELab  printf('parse -> back reference -> illegal')
          let errormessage = 'illegal back reference'
          call self.add_error(node, errormessage)
        endif
        "}}}

      elseif node.is_look_around() "{{{
        DbgRELab  printf('parse -> look around')
        if node.follows_nothing()
          DbgRELab  printf('parse -> look around -> illegal')
          let errormessage = printf('%s follows nothing', node.value)
          call self.add_error(node, errormessage)
        endif
        "}}}

      elseif node.starts_with_at() "{{{
        DbgRELab  printf('parse -> starts with @')
        if node.id !=# '\@>'
          let errormessage = printf('invalid character after %s',
                \ (node.magicness ==# 'v' ? '@' : '\@'))
          call self.add_error(node, errormessage)
        endif
        "}}}

      elseif node.like_code_point() "{{{
        DbgRELab  printf('parse -> like code point: magicness: %s',
              \ node.magic)
        if node.is_code_point()
          DbgRELab  printf('parse -> like code point -> hexadecimal 8')
        else
          DbgRELab  printf('parse -> like code point -> invalid code point')
          let errormessage = printf('invalid character after %s',
                \ matchstr(node.value, '\\\?%[duUx]'))
          call self.add_error(node, errormessage)
        endif
        "}}}

      elseif node.is_mark() "{{{
        DbgRELab  printf('parse -> mark')
        "}}}

      elseif node.is_lcv() "{{{
        DbgRELab  printf('parse -> lcv')
        "}}}

      elseif node.is_invalid_percent() "{{{
        DbgRELab  printf('parse -> invalid percent')
        let errormessage = printf('invalid character after %s',
              \ matchstr(node.value, '\\\?%'))
        call self.add_error(node, errormessage)
        "}}}

      elseif node.is_invalid_z() "{{{
        DbgRELab  printf('parse -> invalid percent')
        let errormessage = printf('invalid character after %s',
              \ matchstr(node.value, '\\\?z'))
        call self.add_error(node, errormessage)
        "}}}

      elseif node.is_case() "{{{
        let self.ignorecase = node.id ==# '\c'
        DbgRELab  printf('parse -> case: %s', self.ignorecase)
        "}}}

      elseif node.is_magic() "{{{
        DbgRELab  printf('parse -> magicness')
        let self.magicness = node.id[1]
        "}}}

      elseif node.value !=? 'x' && has_key(self.id_map, node.id) "{{{
        DbgRELab  printf('parse -> has_key: node.id: %s', node.id)
        "}}}

      else
        DbgRELab  printf('parse -> literal match')
        let node.id = node.ignorecase ? 'x' : 'X'
      endif
      let node.line = node.is_error ? '' : self.line(node)
    endwhile
    if !empty(self.nest_stack)
      DbgRELab  printf('parse -> non-empty nest stack')
      for node in self.nest_stack
        DbgRELab  printf('parse -> non-empty nest stack -> loop: %s',
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

  return parser.init()
endfunction
