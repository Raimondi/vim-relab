function! s:ends_capt_group() dict "{{{
  34DebugRELab printf('%s:', expand('<sfile>'))
  " look for a matching item
  return get(self.get_left_pair(), 'magic', '') ==# '\('
        \ && self.magic ==# '\)'
endfunction "}}}

function! s:ends_collection() dict "{{{
  34DebugRELab printf('%s:', expand('<sfile>'))
  " look for a matching item
  return get(self.get_left_pair(), 'magic', '') ==# '['
        \ && self.magic ==# ']'
endfunction "}}}

function! s:ends_group() dict "{{{
  34DebugRELab printf('%s:', expand('<sfile>'))
  " either ] or \)
  return self.magic ==# ']' || self.magic ==# '\)'
endfunction "}}}

function! s:ends_non_capt_group() dict "{{{
  34DebugRELab printf('%s:', expand('<sfile>'))
  " \) after \%(
  return get(self.get_left_pair(), 'magic', '') ==# '\%('
        \ && self.magic ==# '\)'
endfunction "}}}

function! s:ends_opt_group() dict "{{{
  34DebugRELab printf('%s:', expand('<sfile>'))
  " ] after \%[
  return get(self.get_left_pair(), 'magic', '') ==# '\%['
        \ && self.magic ==# ']'
endfunction "}}}

function! s:follows_nothing() dict "{{{
  34DebugRELab printf('%s:', expand('<sfile>'))
  " if the previous item exists and it's a \& or \| and it's last children isn't a \) or it's a look around
  return empty(self.previous) || (self.previous.is_branch()
        \ && !get(self.previous.children, -1, self.previous).magic ==# '\)')
        \ || self.previous.is_look_around()
endfunction "}}}

function! s:get_left_pair() dict "{{{
  34DebugRELab printf('%s:', expand('<sfile>'))
  " look back for the matching item
  let pairs = {}
  let pairs['\('] = '\)'
  let pairs['\%('] = '\)'
  let pairs['\%['] = ']'
  let pairs['['] = ']'
  let parent = self.parent
  while !empty(parent) && parent.id !=# 'root'
    if parent.is_branch()
      " keep looking back
      let parent = parent.previous
    elseif get(pairs, parent.id, '') ==# self.magic
      " found!
      return parent
    else
      " There isn't one
      break
    endif
  endwhile
  return {}
endfunction "}}}

function! s:has_underscore() dict "{{{
  34DebugRELab printf('%s:', expand('<sfile>'))
  " \_<something>
  return self.magic =~# '\m^\\_.'
endfunction "}}}

function! s:is_back_reference() dict "{{{
  34DebugRELab printf('%s:', expand('<sfile>'))
  " \1 to \9
  return self.id =~# '\m^\\[1-9]$'
endfunction "}}}

function! s:is_boundary() dict "{{{
  34DebugRELab printf('%s:', expand('<sfile>'))
  " either \zs or \ze
  return self.magic ==# '\zs' || self.magic ==# '\ze'
endfunction "}}}

function! s:is_branch() dict "{{{
  34DebugRELab printf('%s:', expand('<sfile>'))
  " either \& or \|
  return self.magic ==# '\|' || self.magic ==# '\&'
endfunction "}}}

function! s:is_case() dict "{{{
  34DebugRELab printf('%s:', expand('<sfile>'))
  " either \c or \C
  return self.magic ==? '\c'
endfunction "}}}

function! s:is_code_point() dict "{{{
  34DebugRELab printf('%s:', expand('<sfile>'))
  " a valid code point
  return self.magic =~#
        \ '\m^\\%\(d\d\+\|o0\?\o\{1,3}\|x\x\{1,2}\|u\x\{1,4}\|U\x\{1,8}\)$'
endfunction "}}}

function! s:is_coll_range() dict "{{{
  34DebugRELab printf('%s:', expand('<sfile>'))
  " a range in a collection
  return self.magic =~#
        \ '\m^\%(\\[-^\]\\ebnrt]\|[^\\]\)-\%(\\[-^\]\\ebnrt]\|[^\\]\)$'
endfunction "}}}

function! s:is_coll_range_id() dict "{{{
  34DebugRELab printf('%s:', expand('<sfile>'))
  " is the id a-b or A-B ?
  return self.id ==? 'a-b'
endfunction "}}}

function! s:is_engine() dict "{{{
  34DebugRELab printf('%s:', expand('<sfile>'))
  " is the id \%#= ?
  return self.id ==# '\%#='
endfunction "}}}

function! s:is_group() dict "{{{
  34DebugRELab printf('%s:', expand('<sfile>'))
  " one of \(, \%(, \), \|, \&
  return index(['\(', '\%(', '\)', '\|', '\&'], self.id) >= 0
endfunction "}}}

function! s:is_invalid_in_optional() dict "{{{
  34DebugRELab printf('%s:', expand('<sfile>'))
  " is it an invalid item when inside \%[...] ?
  return self.is_multi() || self.is_group() || self.is_look_around()
        \ || self.starts_opt_group()
endfunction "}}}

function! s:is_invalid_percent() dict "{{{
  34DebugRELab printf('%s:', expand('<sfile>'))
  " does it start with \% but is invalid?
  return self.magic =~# '\m^\\%[^V#^$C]\?$'
endfunction "}}}

function! s:is_invalid_z() dict "{{{
  34DebugRELab printf('%s:', expand('<sfile>'))
  " does it start with \z but is invalid?
  return self.magic =~# '\m^\\z[^se]\?$'
endfunction "}}}

function! s:is_lcv() dict "{{{
  34DebugRELab printf('%s:', expand('<sfile>'))
  " is it one of \%l, \%c or \%v or any variant?
  return self.magic =~# '\m^\\%[<>]\?\d*[clv]'
endfunction "}}}

function! s:is_look_around() dict "{{{
  34DebugRELab printf('%s:', expand('<sfile>'))
  " is it a propper look around?
  return self.id =~# '\m^\\@\%([!=>]\|\d*<[!=]\)$'
endfunction "}}}

function! s:is_magic() dict "{{{
  34DebugRELab printf('%s:', expand('<sfile>'))
  " is it a magic item?
  return self.magic =~? '\m^\\[mv]$'
endfunction "}}}

function! s:is_mark() dict "{{{
  34DebugRELab printf('%s:', expand('<sfile>'))
  " is it a mark?
  return self.magic =~# '\m^\\%[<>]\?''[a-zA-Z0-9''[\]<>]$'
endfunction "}}}

function! s:is_multi() dict "{{{
  34DebugRELab printf('%s:', expand('<sfile>'))
  " maybe a multi?
  return self.magic =~# '\m^\%(\\[?=+]\|\*\)$\|^\\{'
endfunction "}}}

function! s:is_multi_bracket() dict "{{{
  34DebugRELab printf('%s:', expand('<sfile>'))
  " \{...}
  return self.magic =~# '\m^\\{'
endfunction "}}}

function! s:is_paired() dict "{{{
  34DebugRELab printf('%s:', expand('<sfile>'))
  " does it have a pair?
  return !empty(self.get_left_pair())
endfunction "}}}

function! s:is_valid_bracket() dict "{{{
  34DebugRELab printf('%s:', expand('<sfile>'))
  " do we have a valid curly multi?
  return self.magic =~# '\m^\\{-\?\d*,\?\d*\\\?}$'
endfunction "}}}

function! s:is_valid_underscore() dict "{{{
  34DebugRELab printf('%s:', expand('<sfile>'))
  " does it start with \_ and is valid?
  return self.magic =~# '\m^\\_[iIkKfFpPsSdDxXoOwWhHaAlLuU^$[.]$'
endfunction "}}}

function! s:item_or_eol() dict "{{{
  34DebugRELab printf('%s:', expand('<sfile>'))
  " is it a propper atom extended to match an eol?
  return self.magic =~# '\m^\\_[$^.iIkKfFpPsSdDxXoOwWhHaAlLuU]$'
endfunction "}}}

function! s:like_code_point() dict "{{{
  34DebugRELab printf('%s:', expand('<sfile>'))
  " maybe a code point?
  return self.magic =~# '\m^\\%[douUx]'
endfunction "}}}

function! s:new(token, magicness, ignorecase, magic, pos, id) dict "{{{
  31DebugRELab printf('%s:', expand('<sfile>'))
  31DebugRELab printf('args: %s', a:)
  " return a new child node
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
  32DebugRELab  printf('new: node: %s', filter(copy(n), 'type(v:val) <= 1'))
  return n
endfunction "}}}

function! s:starts_capt_group() dict "{{{
  34DebugRELab printf('%s:', expand('<sfile>'))
  " is it a \(
  return self.magic ==# '\('
endfunction "}}}

function! s:starts_collection() dict "{{{
  34DebugRELab printf('%s:', expand('<sfile>'))
  " is it a [
  return self.magic ==# '['
endfunction "}}}

function! s:starts_group() dict "{{{
  34DebugRELab printf('%s:', expand('<sfile>'))
  " is it one of \(, \%( or \%[
  return self.magic ==# '[' || self.magic =~# '\m^\\%\?($'
        \ || self.magic ==# '\%['
endfunction "}}}

function! s:starts_non_capt_group() dict "{{{
  34DebugRELab printf('%s:', expand('<sfile>'))
  " is it \%(
  return self.magic ==# '\%('
endfunction "}}}

function! s:starts_opt_group() dict "{{{
  34DebugRELab printf('%s:', expand('<sfile>'))
  " is it \%[
  return self.magic ==# '\%['
endfunction "}}}

function! s:starts_with_at() dict "{{{
  34DebugRELab printf('%s:', expand('<sfile>'))
  " does it start with \@ ?
  return self.magic =~# '\m^\\@'
endfunction "}}}

function! relab#parser#node#new() "{{{
  31DebugRELab printf('%s:', expand('<sfile>'))
  31DebugRELab printf('args: %s', a:)
  let node = {}
  let node.value = ''
  let node.magic = ''
  let node.id = ''
  let node.help = ''
  let node.magicness = ''
  let node.capt_groups = -1
  let node.is_capt_group = 0
  let node.ignorecase = 0
  let node.parent = {}
  let node.siblings = []
  let node.children = []
  let node.level = 0
  " defining the dict functions this way makes debugging easier because we
  " avoid numbered functions in errors and when expanding <sfile>
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
