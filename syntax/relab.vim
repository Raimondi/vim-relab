" Vim syntax plugin.
" Language:	relab
" Maintainer:	Israel Chauca F. <israelchauca@gmail.com>

" Quit when a (custom) syntax file was already loaded
if exists('b:current_syntax')
  finish
endif

" Allow use of line continuation.
let s:save_cpo = &cpoptions
set cpoptions&vim
syn case match

syn region relabVMagic start=/\%1l\\v/ skip=/\\\\/ end=/\%(\\[MmV]\)\@=\|$/ oneline
syn region relabNMagic start=/\%1l\\M/ skip=/\\\\/ end=/\%(\\[mvV]\)\@=\|$/ oneline
syn region relabVNMagic start=/\%1l\\V/ skip=/\\\\/ end=/\%(\\[Mvm]\)\@=\|$/ oneline
syn region relabMagic start=/\%1l^\%(\\[MvV]\)\@!\|\%1l\\m/ skip=/\\\\/ end=/\%(\\[MvV]\)\@=\|$/ oneline

syn match relabEscaped /\\./ contained containedin=relabMagic,relabNMagic,relabVNMagic,relabVMagic,relabOptional,relabNOptional,relabVNOptional,relabVOptional

syn match relabGroup /\\%\?(\|\\)/ contained containedin=relabMagic,relabNMagic,relabVNMagic
syn match relabGroup /%\?(\|)/ contained containedin=relabVMagic

syn match relabBranch /\\[|&]/ contained containedin=relabMagic,relabNMagic,relabVNMagic
syn match relabBranch /[|&]/ contained containedin=relabVMagic

syn match relabMulti /\\[+=?]/ contained containedin=relabMagic,relabNMagic,relabVNMagic
syn match relabMulti /[+=?]/ contained containedin=relabVMagic

syn match relabMulti /\*/ contained containedin=relabMagic,relabVMagic
syn match relabMulti /\\\*/ contained containedin=relabNMagic,relabVNMagic

syn match relabMulti /\\{-\?\d*,\?\d*\\\?}/ contained containedin=relabMagic,relabNMagic,relabVNMagic
syn match relabMulti /{-\?\d*,\?\d*\\\?}/ contained containedin=relabVMagic

syn match relabMultiDigits /\d\+/ contained containedin=relabMulti

syn match relabLookaround /\\@\%([>=!]\|\d*<[=!]\)/ contained containedin=relabMagic,relabNMagic,relabVNMagic,relabOptional,relabNOptional,relabVNOptional
syn match relabLookaround /@\%([>=!]\|\d*<[=!]\)/ contained containedin=relabVMagic,relabVOptional

syn match relabLookAroundDigits /\d\+/ contained containedin=relabLookaround

syn region relabCollection matchgroup=relabGroup start=/\%(\\_\)\?\[\^\?/ skip=/\\\\\|\\\]/ end=/\]/ contained oneline containedin=relabMagic,relabOptional
syn region relabVNCollection matchgroup=relabGroup start=/\\_\?\[\^\?/ skip=/\\\\\|\\\]/ end=/\]/ contained oneline containedin=relabVNMagic,relabVNOptional
syn region relabNCollection matchgroup=relabGroup start=/\\_\?\[\^\?/ skip=/\\\\\|\\\]/ end=/\]/ contained oneline containedin=relabNMagic,relabNOptional
syn region relabVCollection matchgroup=relabGroup start=/\%(\\_\)\?\[\^\?/ skip=/\\\\\|\\\]/ end=/\]/ contained oneline containedin=relabVMagic,relabVOptional

syn match relabCollItem /\[\%(:\a\+:\|\..\.\|=.=\)\]/ contained containedin=relabCollection,relabVNCollection,relabNCollection,relabVCollection
syn match relabCollItem /.-./ contained containedin=relabCollection,relabVNCollection,relabNCollection,relabVCollection
syn match relabCollItem /\\[-ebnrt\]^]/ contained containedin=relabCollection,relabVNCollection,relabNCollection,relabVCollection

syn region relabOptional matchgroup=relabGroup start=/\\%\[/ skip=/\\\\\|\\\]/ end=/\]/ contained oneline containedin=relabMagic
syn region relabVNOptional matchgroup=relabGroup start=/\\%\[/ skip=/\\\\\|\\\]/ end=/\]/ contained oneline containedin=relabVNMagic
syn region relabNOptional matchgroup=relabGroup start=/\\%\[/ skip=/\\\\\|\\\]/ end=/\]/ contained oneline containedin=relabNMagic
syn region relabVOptional matchgroup=relabGroup start=/%\[/ skip=/\\\\\|\\\]/ end=/\]/ contained oneline containedin=relabVMagic

syn match relabError /\\[|&()+=?]\|\*\|\\{-\?\d*,\?\d*\\\?}/ contained containedin=relabOptional
syn match relabError /\\[|&()+=?*]\|\\{-\?\d*,\?\d*\\\?}/ contained containedin=relabVNOptional,relabNOptional
syn match relabError /[|&()+=?*]\|{-\?\d*,\?\d*\\\?}/ contained containedin=relabVOptional

syn match relabCharClass /\\_\?[ADFHIKLOPSUWXadfhiklopsuwx]/ contained containedin=relabMagic,relabNMagic,relabVNMagic,relabVMagic,relabOptional,relabNOptional,relabVNOptional,relabVOptional

syn match relabBEOL /\%(\\_\)\?[$^]/ contained containedin=relabMagic,relabVMagic,relabOtional,relabVOptional
syn match relabBEOL /\\_\?[$^]/ contained containedin=relabNMagic,relabVNMagic,relabNOptional,relabVNOptional

syn match relabLastSubst /\~/ contained containedin=relabMagic,relabVMagic,relabOtional,relabVOptional
syn match relabLastSubst /\\\~/ contained containedin=relabNMagic,relabVNMagic,relabNOptional,relabVNOptional

syn match relabBEOF /\\%[$^]/ contained containedin=relabMagic,relabNMagic,relabVNMagic,relabOptional,relabNOptional,relabVNOptional
syn match relabBEOF /%[$^]/ contained containedin=relabVMagic,relabVOptional

syn match relabAny /\(\\_\)\?\./ contained containedin=relabMagic,relabVMagic,relabOptional,relabVOptional
syn match relabAny /\\_\?\./ contained containedin=relabNMagic,relabVNMagic,relabNOptional,relabVNOptional

syn match relabStartEnd /\\z[se]/ contained containedin=relabMagic,relabNMagic,relabVNMagic,relabVMagic,relabOptional,relabNOptional,relabVNOptional,relabVOptional

syn match relabZeroWidth /\\[<>]\|\\%[#V^$]/ contained containedin=relabMagic,relabNMagic,relabVNMagic,relabOptional,relabNOptional,relabVNOptional
syn match relabZeroWidth /[<>]\|%[#V^$]/ contained containedin=relabVMagic,relabVOptional

syn match relabMark /\\%'[0-9a-zA-Z'`\[\]<>]/ contained containedin=relabMagic,relabNMagic,relabVNMagic,relabOptional,relabNOptional,relabVNOptional
syn match relabMark /%'[0-9a-zA-Z'`\[\]<>]/ contained containedin=relabVMagic,relabVOptional

syn match relabLCV /\\%[<>]\?\d*[lcv]/ contained containedin=relabMagic,relabNMagic,relabVNMagic,relabOptional,relabNOptional,relabVNOptional
syn match relabLCV /%[<>]\?\d*[lcv]/ contained containedin=relabVMagic,relabVOptional

syn match relabBackRef /\\z\?[1-9]/ contained containedin=relabMagic,relabNMagic,relabVNMagic,relabVMagic,relabOptional,relabNOptional,relabVNOptional,relabVOptional

syn match relabSynMod /\\[cCZmMvV]/ contained containedin=relabMagic,relabNMagic,relabVNMagic,relabVMagic,relabOptional,relabNOptional,relabVNOptional,relabVOptional

syn match relabEngine /^\\%#=\d/ contained containedin=relabMagic,relabNMagic,relabVNMagic,relabVMagic,relabOptional,relabNOptional,relabVNOptional,relabVOptional

syn match relabCompChar /\\%C/ contained containedin=relabMagic,relabNMagic,relabVNMagic,relabOptional,relabNOptional,relabVNOptional
syn match relabCompChar /%C/ contained containedin=relabVMagic,relabVOptional

syn match relabCodePoint /\\%d\d\+/ contained containedin=relabMagic,relabNMagic,relabVNMagic,relabOptional,relabNOptional,relabVNOptional contains=relabCodePointDecDigits
syn match relabCodePoint /%d\d\+/ contained containedin=relabVMagic,relabVOptional contains=relabCodePointDecDigits

syn match relabCodePoint /\\%o0\?\%([1-3]\o\{2}\|\o\{,2}\)/ contained containedin=relabMagic,relabNMagic,relabVNMagic,relabOptional,relabNOptional,relabVNOptional contains=relabCodePointOctDigits
syn match relabCodePoint /%o0\?\%([1-3]\o\{2}\|\o\{,2}\)/ contained containedin=relabVMagic,relabVOptional contains=relabCodePointOctDigits

syn match relabCodePoint /\\%x\x\{,2}/ contained containedin=relabMagic,relabNMagic,relabVNMagic,relabOptional,relabNOptional,relabVNOptional contains=relabCodePointHexDigits
syn match relabCodePoint /%x\x\{,2}/ contained containedin=relabVMagic,relabVOptional contains=relabCodePointHexDigits

syn match relabCodePoint /\\%u\x\{,4}/ contained containedin=relabMagic,relabNMagic,relabVNMagic,relabOptional,relabNOptional,relabVNOptional contains=relabCodePointHexDigits
syn match relabCodePoint /%u\x\{,4}/ contained containedin=relabVMagic,relabVOptional contains=relabCodePointHexDigits

syn match relabCodePoint /\\%U\x\{,8}/ contained containedin=relabMagic,relabNMagic,relabVNMagic,relabOptional,relabNOptional,relabVNOptional contains=relabCodePointHexDigits
syn match relabCodePoint /%U\x\{,8}/ contained containedin=relabVMagic,relabVOptional contains=relabCodePointHexDigits

syn match relabCodePointDecDigits /%\@1<!\d/ contained containedin=relabCodePoint
syn match relabCodePointOctDigits /%\@1<!\o/ contained containedin=relabCodePoint
syn match relabCodePointHexDigits /%\@1<!\x/ contained containedin=relabCodePoint

syn match relabBackslash /\\\\/ contained containedin=relabMagic,relabNMagic,relabVNMagic,relabVMagic,relabOptional,relabNOptional,relabVNOptional,relabVOptional,relabCollection,relab.NCollection,relabVNCollection,relabVCollection

syn region relabReport start=/\%2l/ end=/\%$/
syn region relabReportError matchgroup=relabError start=/^-*\^\+$/ end=/^Error:.*/ contained containedin=relabReport
syn match relabReportItem /^\%(\s*\S\+\)\?\s\+=>/ contained containedin=relabReport
syn match relabReportPiece /^\s*\zs\S\+/ contained containedin=relabReportItem
syn match relabReportArrow /=>/ contained containedin=relabReportItem

" Define the default highlighting.
" Only used when an item doesn't have highlighting yet
hi def link relabGroup			Statement
hi def link relabBranch			Statement
hi def link relabMulti			Special
hi def link relabMultiDigits		Constant
hi def link relabLookaround		Special
hi def link relabLookaroundDigits	Constant
hi def link relabCollItem		Constant
hi def link relabCharClass		Constant
hi def link relabBEOL			Special
hi def link relabBEOF			Special
hi def link relabLastSubst		Special
hi def link relabAny			Special
hi def link relabStartEnd		Special
hi def link relabZeroWidth		Special
hi def link relabMark			Special
hi def link relabLCV			Special
hi def link relabBackRef		Special
hi def link relabSynMod			Type
hi def link relabEngine			Type
hi def link relabCompChar		Constant
hi def link relabCodePoint		Special
hi def link relabCodePointDecDigits	Constant
hi def link relabCodePointOctDigits	Constant
hi def link relabCodePointHexDigits	Constant
hi def link relabEscaped		Constant
hi def link relabError			Error
hi def link relabReportPiece		Identifier
hi def link relabReportArrow		Special

let b:current_syntax = 'relab'

let &cpoptions = s:save_cpo
unlet s:save_cpo

" vim: set sw=2 sts=2 et fdm=marker:
