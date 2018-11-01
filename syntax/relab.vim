" Vim syntax plugin.
" Language:	relab
" Maintainer:	Israel Chauca F. <israelchauca@gmail.com>

" Quit when a (custom) syntax file was already loaded or not needed
if exists('b:current_syntax') || get(g:, 'relab_view', '') ==# 'sample'
  finish
endif

" Allow use of line continuation.
let s:save_cpo = &cpoptions
set cpoptions&vim
syn case match

let s:is_scratch = expand('%') ==? 'RELab'
if s:is_scratch
  " anchor the match to the second line in the scratch buffer
  syn match relabRegExp /^\%2l.*$/ 
else
  syn match relabRegExp /^.*$/ 
endif

" magic regions {{{
syn region relabVMagic start=/\\v/ skip=/\\\\/ end=/\%(\\[MmV]\)\@=\|$/ oneline contained containedin=relabRegExp
syn region relabNMagic start=/\\M/ skip=/\\\\/ end=/\%(\\[mvV]\)\@=\|$/ oneline contained containedin=relabRegExp
syn region relabVNMagic start=/\\V/ skip=/\\\\/ end=/\%(\\[Mvm]\)\@=\|$/ oneline contained containedin=relabRegExp
syn region relabMagic start=/^\%(\\[MvV]\)\@!\|\\m/ skip=/\\\\/ end=/\%(\\[MvV]\)\@=\|$/ oneline contained containedin=relabRegExp
" an escaped character
syn match relabEscaped /\\./ contained containedin=relabMagic,relabNMagic,relabVNMagic,relabVMagic,relabOptional,relabNOptional,relabVNOptional,relabVOptional
" capturing and non-capturing group delimiters
syn match relabGroup /\\%\?(\|\\)/ contained containedin=relabMagic,relabNMagic,relabVNMagic
syn match relabGroup /%\?(\|)/ contained containedin=relabVMagic
" \| or \&
syn match relabBranch /\\[|&]/ contained containedin=relabMagic,relabNMagic,relabVNMagic
syn match relabBranch /[|&]/ contained containedin=relabVMagic
" \?, \= or \+
syn match relabMulti /\\[+=?]/ contained containedin=relabMagic,relabNMagic,relabVNMagic
syn match relabMulti /[+=?]/ contained containedin=relabVMagic
" *
syn match relabMulti /\*/ contained containedin=relabMagic,relabVMagic
syn match relabMulti /\\\*/ contained containedin=relabNMagic,relabVNMagic
" \{...}
syn match relabMulti /\\{-\?\d*,\?\d*\\\?}/ contained containedin=relabMagic,relabNMagic,relabVNMagic
syn match relabMulti /{-\?\d*,\?\d*\\\?}/ contained containedin=relabVMagic
" the digits inside \{...}
syn match relabMultiDigits /\d\+/ contained containedin=relabMulti
" look around
syn match relabLookaround /\\@\%([>=!]\|\d*<[=!]\)/ contained containedin=relabMagic,relabNMagic,relabVNMagic,relabOptional,relabNOptional,relabVNOptional
syn match relabLookaround /@\%([>=!]\|\d*<[=!]\)/ contained containedin=relabVMagic,relabVOptional
" the digits ina look around
syn match relabLookAroundDigits /\d\+/ contained containedin=relabLookaround
" a collection
syn region relabCollection matchgroup=relabGroup start=/\%(\\_\)\?\[\^\?/ skip=/\\\\\|\\\]/ end=/\]/ contained oneline containedin=relabMagic,relabOptional
syn region relabVNCollection matchgroup=relabGroup start=/\\_\?\[\^\?/ skip=/\\\\\|\\\]/ end=/\]/ contained oneline containedin=relabVNMagic,relabVNOptional
syn region relabNCollection matchgroup=relabGroup start=/\\_\?\[\^\?/ skip=/\\\\\|\\\]/ end=/\]/ contained oneline containedin=relabNMagic,relabNOptional
syn region relabVCollection matchgroup=relabGroup start=/\%(\\_\)\?\[\^\?/ skip=/\\\\\|\\\]/ end=/\]/ contained oneline containedin=relabVMagic,relabVOptional
" [:xxxxx:], [=x=] or [.x.]
syn match relabCollItem /\[\%(:\a\+:\|\..\.\|=.=\)\]/ contained containedin=relabCollection,relabVNCollection,relabNCollection,relabVCollection
syn match relabCollItem /.-./ contained containedin=relabCollection,relabVNCollection,relabNCollection,relabVCollection
syn match relabCollItem /\\[-ebnrt\\\]^]/ contained containedin=relabCollection,relabVNCollection,relabNCollection,relabVCollection
" collection code point
syn match relabCollCodePoint /\\d\d\+/ contained containedin=relabCollection contains=relabCodePointDecDigits
syn match relabCollCodePoint /\\o0\?\%([1-3]\o\{2}\|\o\{,2}\)/ contained containedin=relabCollection contains=relabCodePointOctDigits
syn match relabCollCodePoint /\\x\x\{,2}/ contained containedin=relabCollection contains=relabCodePointHexDigits
syn match relabCollCodePoint /\\u\x\{,4}/ contained containedin=relabCollection contains=relabCodePointHexDecDigits
syn match relabCollCodePoint /\\U\x\{,8}/ contained containedin=relabCollection contains=relabCodePointHexDecDigits
" \%[...]
syn region relabOptional matchgroup=relabGroup start=/\\%\[/ skip=/\\\\\|\\\]/ end=/\]/ contained oneline containedin=relabMagic
syn region relabVNOptional matchgroup=relabGroup start=/\\%\[/ skip=/\\\\\|\\\]/ end=/\]/ contained oneline containedin=relabVNMagic
syn region relabNOptional matchgroup=relabGroup start=/\\%\[/ skip=/\\\\\|\\\]/ end=/\]/ contained oneline containedin=relabNMagic
syn region relabVOptional matchgroup=relabGroup start=/%\[/ skip=/\\\\\|\\\]/ end=/\]/ contained oneline containedin=relabVMagic
" an item that is not valid inside an optional group
syn match relabError /\\[|&()+=?]\|\*\|\\{-\?\d*,\?\d*\\\?}/ contained containedin=relabOptional
syn match relabError /\\[|&()+=?*]\|\\{-\?\d*,\?\d*\\\?}/ contained containedin=relabVNOptional,relabNOptional
syn match relabError /[|&()+=?*]\|{-\?\d*,\?\d*\\\?}/ contained containedin=relabVOptional
" a character class
syn match relabCharClass /\\_\?[ADFHIKLOPSUWXadfhiklopsuwx]/ contained containedin=relabMagic,relabNMagic,relabVNMagic,relabVMagic,relabOptional,relabNOptional,relabVNOptional,relabVOptional
" \_^ or \_$
syn match relabBEOL /\%(\\_\)\?[$^]/ contained containedin=relabMagic,relabVMagic,relabOtional,relabVOptional
syn match relabBEOL /\\_\?[$^]/ contained containedin=relabNMagic,relabVNMagic,relabNOptional,relabVNOptional
" ~
syn match relabLastSubst /\~/ contained containedin=relabMagic,relabVMagic,relabOtional,relabVOptional
syn match relabLastSubst /\\\~/ contained containedin=relabNMagic,relabVNMagic,relabNOptional,relabVNOptional
" \%^ or \%$
syn match relabBEOF /\\%[$^]/ contained containedin=relabMagic,relabNMagic,relabVNMagic,relabOptional,relabNOptional,relabVNOptional
syn match relabBEOF /%[$^]/ contained containedin=relabVMagic,relabVOptional
" \_. or .
syn match relabAny /\(\\_\)\?\./ contained containedin=relabMagic,relabVMagic,relabOptional,relabVOptional
syn match relabAny /\\_\?\./ contained containedin=relabNMagic,relabVNMagic,relabNOptional,relabVNOptional
" \zs or \ze
syn match relabStartEnd /\\z[se]/ contained containedin=relabMagic,relabNMagic,relabVNMagic,relabVMagic,relabOptional,relabNOptional,relabVNOptional,relabVOptional
" \<, \>, \%# or \%V
syn match relabZeroWidth /\\[<>]\|\\%[#V]/ contained containedin=relabMagic,relabNMagic,relabVNMagic,relabOptional,relabNOptional,relabVNOptional
syn match relabZeroWidth /[<>]\|%[#V^$]/ contained containedin=relabVMagic,relabVOptional
" \%'<something>
syn match relabMark /\\%'[0-9a-zA-Z'`\[\]<>]/ contained containedin=relabMagic,relabNMagic,relabVNMagic,relabOptional,relabNOptional,relabVNOptional
syn match relabMark /%'[0-9a-zA-Z'`\[\]<>]/ contained containedin=relabVMagic,relabVOptional
" \%l, \%c, 0%v or any of their variants
syn match relabLCV /\\%[<>]\?\d*[lcv]/ contained containedin=relabMagic,relabNMagic,relabVNMagic,relabOptional,relabNOptional,relabVNOptional
syn match relabLCV /%[<>]\?\d*[lcv]/ contained containedin=relabVMagic,relabVOptional
" \1 to \9
syn match relabBackRef /\\z\?[1-9]/ contained containedin=relabMagic,relabNMagic,relabVNMagic,relabVMagic,relabOptional,relabNOptional,relabVNOptional,relabVOptional
" magic or case matching items
syn match relabSynMod /\\[cCZmMvV]/ contained containedin=relabMagic,relabNMagic,relabVNMagic,relabVMagic,relabOptional,relabNOptional,relabVNOptional,relabVOptional
" regexp engine
syn match relabEngine /^\\%#=\d/ contained containedin=relabMagic,relabNMagic,relabVNMagic,relabVMagic,relabOptional,relabNOptional,relabVNOptional,relabVOptional
" \%C
syn match relabCompChar /\\%C/ contained containedin=relabMagic,relabNMagic,relabVNMagic,relabOptional,relabNOptional,relabVNOptional
syn match relabCompChar /%C/ contained containedin=relabVMagic,relabVOptional
" decimal code point
syn match relabCodePoint /\\%d\d\+/ contained containedin=relabMagic,relabNMagic,relabVNMagic,relabOptional,relabNOptional,relabVNOptional contains=relabCodePointDecDigits
syn match relabCodePoint /%d\d\+/ contained containedin=relabVMagic,relabVOptional contains=relabCodePointDecDigits
" octal code point
syn match relabCodePoint /\\%o0\?\%([1-3]\o\{2}\|\o\{,2}\)/ contained containedin=relabMagic,relabNMagic,relabVNMagic,relabOptional,relabNOptional,relabVNOptional contains=relabCodePointOctDigits
syn match relabCodePoint /%o0\?\%([1-3]\o\{2}\|\o\{,2}\)/ contained containedin=relabVMagic,relabVOptional contains=relabCodePointOctDigits
" two digit hexadecimal code point
syn match relabCodePoint /\\%x\x\{,2}/ contained containedin=relabMagic,relabNMagic,relabVNMagic,relabOptional,relabNOptional,relabVNOptional contains=relabCodePointHexDigits
syn match relabCodePoint /%x\x\{,2}/ contained containedin=relabVMagic,relabVOptional contains=relabCodePointHexDigits
" four digit hexadecimal code point
syn match relabCodePoint /\\%u\x\{,4}/ contained containedin=relabMagic,relabNMagic,relabVNMagic,relabOptional,relabNOptional,relabVNOptional contains=relabCodePointHexDigits
syn match relabCodePoint /%u\x\{,4}/ contained containedin=relabVMagic,relabVOptional contains=relabCodePointHexDigits
" eigth digit hexadecimal code point
syn match relabCodePoint /\\%U\x\{,8}/ contained containedin=relabMagic,relabNMagic,relabVNMagic,relabOptional,relabNOptional,relabVNOptional contains=relabCodePointHexDigits
syn match relabCodePoint /%U\x\{,8}/ contained containedin=relabVMagic,relabVOptional contains=relabCodePointHexDigits
" the digits in a code point
syn match relabCodePointDecDigits /\d/ contained containedin=relabCodePoint
syn match relabCodePointOctDigits /\o/ contained containedin=relabCodePoint
syn match relabCodePointHexDigits /\x/ contained containedin=relabCodePoint
" an escaped backslash
syn match relabBackslash /\\\\/ contained containedin=relabMagic,relabNMagic,relabVNMagic,relabVMagic,relabOptional,relabNOptional,relabVNOptional,relabVOptional
"}}}

if s:is_scratch
  " regexp item description
  syn match relabReportItem  /^\%>3l\%(\s*\S\+\)\?\s\+=>/
  syn match relabReportPiece /^\%>3l\s*\zs\S\+/ contained containedin=relabReportItem
  syn match relabReportArrow /\%>3l=>/ contained containedin=relabReportItem
  " match or validation report
  syn match relabSubMatch /^\%>3l[^:]*\d:/
  syn match relabNoMatch  /^\%>3lx:.*/
  syn match relabMatch    /^\%>3l+:.*/
  " an error report
  syn region relabReportError matchgroup=relabWarning start=/\%3l^-*\^\+$/ end=/^Error:.*/
else
  syn match relabComment /^ .*/
endif

" Define the default highlighting.
" Only used when an item doesn't have highlighting yet
hi default link relabGroup		Statement
hi default link relabBranch		Statement
hi default link relabMulti		Special
hi default link relabMultiDigits	Constant
hi default link relabLookaround		Special
hi default link relabLookaroundDigits	Constant
hi default link relabCollItem		Constant
hi default link relabCollCodePoint	Constant
hi default link relabCharClass		Constant
hi default link relabBEOL		Special
hi default link relabBEOF		Special
hi default link relabLastSubst		Special
hi default link relabAny		Special
hi default link relabStartEnd		Special
hi default link relabZeroWidth		Special
hi default link relabMark		Special
hi default link relabLCV		Special
hi default link relabBackRef		Special
hi default link relabSynMod		Type
hi default link relabEngine		Type
hi default link relabCompChar		Constant
hi default link relabCodePoint		Special
hi default link relabCodePointDecDigits	Constant
hi default link relabCodePointOctDigits	Constant
hi default link relabCodePointHexDigits	Constant
hi default link relabEscaped		Constant
hi default link relabError		Error
hi default link relabWarning		WarningMsg
hi default link relabReportPiece	Identifier
hi default link relabReportArrow	Special
hi default link relabMatch		Type
hi default link relabSubMatch		Type
hi default link relabNoMatch		WarningMsg
hi default link relabComment		Comment

let b:current_syntax = 'relab'

let &cpoptions = s:save_cpo
unlet s:save_cpo

" vim: set sw=2 sts=2 et fdm=marker:
