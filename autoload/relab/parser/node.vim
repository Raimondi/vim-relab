function! s:is_magic() dict "{{{
  return self.magic =~? '\m^\\[mv]$'
endfunction "}}}

function! s:is_branch() dict "{{{
  return self.magic ==# '\|' || self.magic ==# '\&'
endfunction "}}}

function! s:starts_group() dict "{{{
  return self.magic ==# '[' || self.magic =~# '\m^\\%\?($'
        \ || self.magic ==# '\%['
endfunction "}}}

function! s:starts_capt_group() dict "{{{
  return self.magic ==# '\('
endfunction "}}}

function! s:starts_non_capt_group() dict "{{{
  return self.magic ==# '\%('
endfunction "}}}

function! s:starts_opt_group() dict "{{{
  return self.magic ==# '\%['
endfunction "}}}

function! s:starts_collection() dict "{{{
  return self.magic ==# '['
endfunction "}}}

function! s:ends_group() dict "{{{
  return self.magic ==# ']' || self.magic ==# '\)'
endfunction "}}}

function! s:ends_capt_group() dict "{{{
  return get(self.get_left_pair(), 'magic', '') ==# '\('
        \ && self.magic ==# '\)'
endfunction "}}}

function! s:ends_non_capt_group() dict "{{{
  return get(self.get_left_pair(), 'magic', '') ==# '\%('
        \ && self.magic ==# '\)'
endfunction "}}}

function! s:ends_opt_group() dict "{{{
  return get(self.get_left_pair(), 'magic', '') ==# '\%['
        \ && self.magic ==# ']'
endfunction "}}}

function! s:ends_collection() dict "{{{
  return get(self.get_left_pair(), 'magic', '') ==# '['
        \ && self.magic ==# ']'
endfunction "}}}

function! s:item_or_eol() dict "{{{
  return self.magic =~# '\m^\\_[$^.iIkKfFpPsSdDxXoOwWhHaAlLuU]$'
endfunction "}}}

function! s:is_engine() dict "{{{
  return self.id ==# '\%#='
endfunction "}}}

function! s:is_multi() dict "{{{
  return self.magic =~# '\m^\%(\\[?=+]\|\*\)$\|^\\{'
endfunction "}}}

function! s:is_multi_bracket() dict "{{{
  return self.magic =~# '\m^\\{'
endfunction "}}}

function! s:is_valid_bracket() dict "{{{
  return self.magic =~# '\m^\\{-\?\d*,\?\d*\\\?}$'
endfunction "}}}

function! s:is_look_around() dict "{{{
  return self.id =~# '\m^\\@\%([!=>]\|\d*<[!=]\)$'
endfunction "}}}

function! s:is_group() dict "{{{
  return index(['\(', '\%(', '\)', '\|', '\&'], self.id) >= 0
endfunction "}}}

function! s:is_invalid_in_optional() dict "{{{
  return self.is_multi() || self.is_group() || self.is_look_around()
        \ || self.starts_opt_group()
endfunction "}}}

function! s:is_back_reference() dict "{{{
  return self.id =~# '\m^\\[1-9]$'
endfunction "}}}

function! s:starts_with_at() dict "{{{
  return self.magic =~# '\m^\\@'
endfunction "}}}

function! s:is_boundary() dict "{{{
  return self.magic ==# '\zs' || self.magic ==# '\ze'
endfunction "}}}

function! s:has_underscore() dict "{{{
  return self.magic =~# '\m^\\_.'
endfunction "}}}

function! s:is_valid_underscore() dict "{{{
  return self.magic =~# '\m^\\_[iIkKfFpPsSdDxXoOwWhHaAlLuU^$[.]$'
endfunction "}}}

function! s:is_coll_range() dict "{{{
  return self.magic =~#
        \ '\m^\%(\\[-^\]\\ebnrt]\|[^\\]\)-\%(\\[-^\]\\ebnrt]\|[^\\]\)$'
endfunction "}}}

function! s:is_coll_range_id() dict "{{{
  return self.id ==? 'a-b'
endfunction "}}}

function! s:like_code_point() dict "{{{
  return self.magic =~# '\m^\\%[douUx]'
endfunction "}}}

function! s:is_code_point() dict "{{{
  return self.magic =~#
        \ '\m^\\%\(d\d\+\|o0\?\o\{1,3}\|x\x\{1,2}\|u\x\{1,4}\|U\x\{1,8}\)$'
endfunction "}}}

function! s:is_invalid_percent() dict "{{{
  return self.magic =~# '\m^\\%[^V#^$C]\?$'
endfunction "}}}

function! s:is_mark() dict "{{{
  return self.magic =~# '\m^\\%[<>]\?''[a-zA-Z0-9''[\]<>]$'
endfunction "}}}

function! s:is_lcv() dict "{{{
  return self.magic =~# '\m^\\%[<>]\?\d*[clv]'
endfunction "}}}

function! s:is_invalid_z() dict "{{{
  return self.magic =~# '\m^\\z[^se]\?$'
endfunction "}}}

function! s:is_case() dict "{{{
  return self.magic ==? '\c'
endfunction "}}}

function! s:follows_nothing() dict "{{{
  return empty(self.previous) || (self.previous.is_branch()
        \ && !get(self.previous.children, -1, self.previous).magic ==# '\)')
        \ || self.previous.is_look_around()
endfunction "}}}

function! s:get_left_pair() dict "{{{
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

function! s:is_paired() dict "{{{
  return !empty(self.get_left_pair())
endfunction "}}}

function! s:new(token, magicness, ignorecase, magic, pos, id) dict "{{{
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

function! relab#parser#node#new() "{{{
  let node = {}
  let node.value = 'root'
  let node.magic = 'root'
  let node.id = 'root'
  let node.help = 'pattern'
  let node.magicness = ''
  let node.capt_groups = -1
  let node.is_capt_group = 0
  let node.ignorecase = 0
  let node.parent = {}
  let node.siblings = []
  let node.children = []
  let node.level = 0
  let node.is_magic = function('s:is_magic')
  let node.is_branch = function('s:is_branch')
  let node.starts_group = function('s:starts_group')
  let node.starts_capt_group = function('s:starts_capt_group')
  let node.starts_non_capt_group = function('s:starts_non_capt_group')
  let node.starts_opt_group = function('s:starts_opt_group')
  let node.starts_collection = function('s:starts_collection')
  let node.ends_group = function('s:ends_group')
  let node.ends_capt_group = function('s:ends_capt_group')
  let node.ends_non_capt_group = function('s:ends_non_capt_group')
  let node.ends_opt_group = function('s:ends_opt_group')
  let node.ends_collection = function('s:ends_collection')
  let node.item_or_eol = function('s:item_or_eol')
  let node.is_engine = function('s:is_engine')
  let node.is_multi = function('s:is_multi')
  let node.is_multi_bracket = function('s:is_multi_bracket')
  let node.is_valid_bracket = function('s:is_valid_bracket')
  let node.is_look_around = function('s:is_look_around')
  let node.is_group = function('s:is_group')
  let node.is_invalid_in_optional = function('s:is_invalid_in_optional')
  let node.is_back_reference = function('s:is_back_reference')
  let node.starts_with_at = function('s:starts_with_at')
  let node.is_boundary = function('s:is_boundary')
  let node.has_underscore = function('s:has_underscore')
  let node.is_valid_underscore = function('s:is_valid_underscore')
  let node.is_coll_range = function('s:is_coll_range')
  let node.is_coll_range_id = function('s:is_coll_range_id')
  let node.like_code_point = function('s:like_code_point')
  let node.is_code_point = function('s:is_code_point')
  let node.is_invalid_percent = function('s:is_invalid_percent')
  let node.is_mark = function('s:is_mark')
  let node.is_lcv = function('s:is_lcv')
  let node.is_invalid_z = function('s:is_invalid_z')
  let node.is_case = function('s:is_case')
  let node.follows_nothing = function('s:follows_nothing')
  let node.get_left_pair = function('s:get_left_pair')
  let node.is_paired = function('s:is_paired')
  let node.new = function('s:new')
  return node
endfunction "}}}
