" Vim syntax plugin.
" Language:	rexplicate
" Maintainer:	Israel Chauca F. <israelchauca@gmail.com>

" Quit when a (custom) syntax file was already loaded
if exists('b:current_syntax')
  finish
endif

" Allow use of line continuation.
let s:save_cpo = &cpoptions
set cpoptions&vim
syn case match

syn region rexplicateVMagic start=/\%1l\\v/ skip=/\\\\/ end=/\%(\\[MmV]\)\@=\|$/ oneline
syn region rexplicateNMagic start=/\%1l\\M/ skip=/\\\\/ end=/\%(\\[mvV]\)\@=\|$/ oneline
syn region rexplicateVNMagic start=/\%1l\\V/ skip=/\\\\/ end=/\%(\\[Mvm]\)\@=\|$/ oneline
syn region rexplicateMagic start=/\%1l^\%(\\[MvV]\)\@!\|\%1l\\m/ skip=/\\\\/ end=/\%(\\[MvV]\)\@=\|$/ oneline

syn match rexplicateEscaped /\\./ contained containedin=rexplicateMagic,rexplicateNMagic,rexplicateVNMagic,rexplicateVMagic,rexplicateOptional,rexplicateNOptional,rexplicateVNOptional,rexplicateVOptional

syn match rexplicateGroup /\\%\?(\|\\)/ contained containedin=rexplicateMagic,rexplicateNMagic,rexplicateVNMagic
syn match rexplicateGroup /%\?(\|)/ contained containedin=rexplicateVMagic

syn match rexplicateBranch /\\[|&]/ contained containedin=rexplicateMagic,rexplicateNMagic,rexplicateVNMagic
syn match rexplicateBranch /[|&]/ contained containedin=rexplicateVMagic

syn match rexplicateMulti /\\[+=?]/ contained containedin=rexplicateMagic,rexplicateNMagic,rexplicateVNMagic
syn match rexplicateMulti /[+=?]/ contained containedin=rexplicateVMagic

syn match rexplicateMulti /\*/ contained containedin=rexplicateMagic,rexplicateVMagic
syn match rexplicateMulti /\\\*/ contained containedin=rexplicateNMagic,rexplicateVNMagic

syn match rexplicateMulti /\\{-\?\d*,\?\d*\\\?}/ contained containedin=rexplicateMagic,rexplicateNMagic,rexplicateVNMagic
syn match rexplicateMulti /{-\?\d*,\?\d*\\\?}/ contained containedin=rexplicateVMagic

syn match rexplicateMultiDigits /\d\+/ contained containedin=rexplicateMulti

syn match rexplicateLookaround /\\@\%([>=!]\|\d*<[=!]\)/ contained containedin=rexplicateMagic,rexplicateNMagic,rexplicateVNMagic,rexplicateOptional,rexplicateNOptional,rexplicateVNOptional
syn match rexplicateLookaround /@\%([>=!]\|\d*<[=!]\)/ contained containedin=rexplicateVMagic,rexplicateVOptional

syn match rexplicateLookAroundDigits /\d\+/ contained containedin=rexplicateLookaround

syn region rexplicateCollection matchgroup=rexplicateGroup start=/\%(\\_\)\?\[\^\?/ skip=/\\\\\|\\\]/ end=/\]/ contained oneline containedin=rexplicateMagic,rexplicateOptional
syn region rexplicateVNCollection matchgroup=rexplicateGroup start=/\\_\?\[\^\?/ skip=/\\\\\|\\\]/ end=/\]/ contained oneline containedin=rexplicateVNMagic,rexplicateVNOptional
syn region rexplicateNCollection matchgroup=rexplicateGroup start=/\\_\?\[\^\?/ skip=/\\\\\|\\\]/ end=/\]/ contained oneline containedin=rexplicateNMagic,rexplicateNOptional
syn region rexplicateVCollection matchgroup=rexplicateGroup start=/\%(\\_\)\?\[\^\?/ skip=/\\\\\|\\\]/ end=/\]/ contained oneline containedin=rexplicateVMagic,rexplicateVOptional

syn match rexplicateCollItem /\[\%(:\a\+:\|\..\.\|=.=\)\]/ contained containedin=rexplicateCollection,rexplicateVNCollection,rexplicateNCollection,rexplicateVCollection
syn match rexplicateCollItem /.-./ contained containedin=rexplicateCollection,rexplicateVNCollection,rexplicateNCollection,rexplicateVCollection
syn match rexplicateCollItem /\\[-ebnrt\\\]^]/ contained containedin=rexplicateCollection,rexplicateVNCollection,rexplicateNCollection,rexplicateVCollection

syn match rexplicateCollCodePoint /\\d\d\+/ contained containedin=rexplicateCollection contains=rexplicateCodePointDecDigits
syn match rexplicateCollCodePoint /\\o0\?\%([1-3]\o\{2}\|\o\{,2}\)/ contained containedin=rexplicateCollection contains=rexplicateCodePointOctDigits
syn match rexplicateCollCodePoint /\\x\x\{,2}/ contained containedin=rexplicateCollection contains=rexplicateCodePointHexDigits
syn match rexplicateCollCodePoint /\\u\x\{,4}/ contained containedin=rexplicateCollection contains=rexplicateCodePointHexDecDigits
syn match rexplicateCollCodePoint /\\U\x\{,8}/ contained containedin=rexplicateCollection contains=rexplicateCodePointHexDecDigits

syn region rexplicateOptional matchgroup=rexplicateGroup start=/\\%\[/ skip=/\\\\\|\\\]/ end=/\]/ contained oneline containedin=rexplicateMagic
syn region rexplicateVNOptional matchgroup=rexplicateGroup start=/\\%\[/ skip=/\\\\\|\\\]/ end=/\]/ contained oneline containedin=rexplicateVNMagic
syn region rexplicateNOptional matchgroup=rexplicateGroup start=/\\%\[/ skip=/\\\\\|\\\]/ end=/\]/ contained oneline containedin=rexplicateNMagic
syn region rexplicateVOptional matchgroup=rexplicateGroup start=/%\[/ skip=/\\\\\|\\\]/ end=/\]/ contained oneline containedin=rexplicateVMagic

syn match rexplicateError /\\[|&()+=?]\|\*\|\\{-\?\d*,\?\d*\\\?}/ contained containedin=rexplicateOptional
syn match rexplicateError /\\[|&()+=?*]\|\\{-\?\d*,\?\d*\\\?}/ contained containedin=rexplicateVNOptional,rexplicateNOptional
syn match rexplicateError /[|&()+=?*]\|{-\?\d*,\?\d*\\\?}/ contained containedin=rexplicateVOptional

syn match rexplicateCharClass /\\_\?[ADFHIKLOPSUWXadfhiklopsuwx]/ contained containedin=rexplicateMagic,rexplicateNMagic,rexplicateVNMagic,rexplicateVMagic,rexplicateOptional,rexplicateNOptional,rexplicateVNOptional,rexplicateVOptional

syn match rexplicateBEOL /\%(\\_\)\?[$^]/ contained containedin=rexplicateMagic,rexplicateVMagic,rexplicateOtional,rexplicateVOptional
syn match rexplicateBEOL /\\_\?[$^]/ contained containedin=rexplicateNMagic,rexplicateVNMagic,rexplicateNOptional,rexplicateVNOptional

syn match rexplicateLastSubst /\~/ contained containedin=rexplicateMagic,rexplicateVMagic,rexplicateOtional,rexplicateVOptional
syn match rexplicateLastSubst /\\\~/ contained containedin=rexplicateNMagic,rexplicateVNMagic,rexplicateNOptional,rexplicateVNOptional

syn match rexplicateBEOF /\\%[$^]/ contained containedin=rexplicateMagic,rexplicateNMagic,rexplicateVNMagic,rexplicateOptional,rexplicateNOptional,rexplicateVNOptional
syn match rexplicateBEOF /%[$^]/ contained containedin=rexplicateVMagic,rexplicateVOptional

syn match rexplicateAny /\(\\_\)\?\./ contained containedin=rexplicateMagic,rexplicateVMagic,rexplicateOptional,rexplicateVOptional
syn match rexplicateAny /\\_\?\./ contained containedin=rexplicateNMagic,rexplicateVNMagic,rexplicateNOptional,rexplicateVNOptional

syn match rexplicateStartEnd /\\z[se]/ contained containedin=rexplicateMagic,rexplicateNMagic,rexplicateVNMagic,rexplicateVMagic,rexplicateOptional,rexplicateNOptional,rexplicateVNOptional,rexplicateVOptional

syn match rexplicateZeroWidth /\\[<>]\|\\%[#V^$]/ contained containedin=rexplicateMagic,rexplicateNMagic,rexplicateVNMagic,rexplicateOptional,rexplicateNOptional,rexplicateVNOptional
syn match rexplicateZeroWidth /[<>]\|%[#V^$]/ contained containedin=rexplicateVMagic,rexplicateVOptional

syn match rexplicateMark /\\%'[0-9a-zA-Z'`\[\]<>]/ contained containedin=rexplicateMagic,rexplicateNMagic,rexplicateVNMagic,rexplicateOptional,rexplicateNOptional,rexplicateVNOptional
syn match rexplicateMark /%'[0-9a-zA-Z'`\[\]<>]/ contained containedin=rexplicateVMagic,rexplicateVOptional

syn match rexplicateLCV /\\%[<>]\?\d*[lcv]/ contained containedin=rexplicateMagic,rexplicateNMagic,rexplicateVNMagic,rexplicateOptional,rexplicateNOptional,rexplicateVNOptional
syn match rexplicateLCV /%[<>]\?\d*[lcv]/ contained containedin=rexplicateVMagic,rexplicateVOptional

syn match rexplicateBackRef /\\z\?[1-9]/ contained containedin=rexplicateMagic,rexplicateNMagic,rexplicateVNMagic,rexplicateVMagic,rexplicateOptional,rexplicateNOptional,rexplicateVNOptional,rexplicateVOptional

syn match rexplicateSynMod /\\[cCZmMvV]/ contained containedin=rexplicateMagic,rexplicateNMagic,rexplicateVNMagic,rexplicateVMagic,rexplicateOptional,rexplicateNOptional,rexplicateVNOptional,rexplicateVOptional

syn match rexplicateEngine /^\\%#=\d/ contained containedin=rexplicateMagic,rexplicateNMagic,rexplicateVNMagic,rexplicateVMagic,rexplicateOptional,rexplicateNOptional,rexplicateVNOptional,rexplicateVOptional

syn match rexplicateCompChar /\\%C/ contained containedin=rexplicateMagic,rexplicateNMagic,rexplicateVNMagic,rexplicateOptional,rexplicateNOptional,rexplicateVNOptional
syn match rexplicateCompChar /%C/ contained containedin=rexplicateVMagic,rexplicateVOptional

syn match rexplicateCodePoint /\\%d\d\+/ contained containedin=rexplicateMagic,rexplicateNMagic,rexplicateVNMagic,rexplicateOptional,rexplicateNOptional,rexplicateVNOptional contains=rexplicateCodePointDecDigits
syn match rexplicateCodePoint /%d\d\+/ contained containedin=rexplicateVMagic,rexplicateVOptional contains=rexplicateCodePointDecDigits

syn match rexplicateCodePoint /\\%o0\?\%([1-3]\o\{2}\|\o\{,2}\)/ contained containedin=rexplicateMagic,rexplicateNMagic,rexplicateVNMagic,rexplicateOptional,rexplicateNOptional,rexplicateVNOptional contains=rexplicateCodePointOctDigits
syn match rexplicateCodePoint /%o0\?\%([1-3]\o\{2}\|\o\{,2}\)/ contained containedin=rexplicateVMagic,rexplicateVOptional contains=rexplicateCodePointOctDigits

syn match rexplicateCodePoint /\\%x\x\{,2}/ contained containedin=rexplicateMagic,rexplicateNMagic,rexplicateVNMagic,rexplicateOptional,rexplicateNOptional,rexplicateVNOptional contains=rexplicateCodePointHexDigits
syn match rexplicateCodePoint /%x\x\{,2}/ contained containedin=rexplicateVMagic,rexplicateVOptional contains=rexplicateCodePointHexDigits

syn match rexplicateCodePoint /\\%u\x\{,4}/ contained containedin=rexplicateMagic,rexplicateNMagic,rexplicateVNMagic,rexplicateOptional,rexplicateNOptional,rexplicateVNOptional contains=rexplicateCodePointHexDigits
syn match rexplicateCodePoint /%u\x\{,4}/ contained containedin=rexplicateVMagic,rexplicateVOptional contains=rexplicateCodePointHexDigits

syn match rexplicateCodePoint /\\%U\x\{,8}/ contained containedin=rexplicateMagic,rexplicateNMagic,rexplicateVNMagic,rexplicateOptional,rexplicateNOptional,rexplicateVNOptional contains=rexplicateCodePointHexDigits
syn match rexplicateCodePoint /%U\x\{,8}/ contained containedin=rexplicateVMagic,rexplicateVOptional contains=rexplicateCodePointHexDigits

syn match rexplicateCodePointDecDigits /\d/ contained containedin=rexplicateCodePoint
syn match rexplicateCodePointOctDigits /\o/ contained containedin=rexplicateCodePoint
syn match rexplicateCodePointHexDigits /\x/ contained containedin=rexplicateCodePoint

syn match rexplicateBackslash /\\\\/ contained containedin=rexplicateMagic,rexplicateNMagic,rexplicateVNMagic,rexplicateVMagic,rexplicateOptional,rexplicateNOptional,rexplicateVNOptional,rexplicateVOptional

syn region rexplicateReport start=/\%2l^/re=s-1 end=/\_^^^^^^^^^^^ .\+ ^^^^^^^^^^$/
syn region rexplicateReportError matchgroup=rexplicateWarning start=/^-*\^\+$/ end=/^Error:.*/ contained containedin=rexplicateReport
syn match rexplicateReportItem /^\%(\s*\S\+\)\?\s\+=>/ contained containedin=rexplicateReport
syn match rexplicateReportPiece /^\s*\zs\S\+/ contained containedin=rexplicateReportItem
syn match rexplicateReportArrow /=>/ contained containedin=rexplicateReportItem
syn match rexplicateSampleLine /^^^^^^^^^^^ .\+ ^^^^^^^^^^$/ contained containedin=rexplicateReport

" Define the default highlighting.
" Only used when an item doesn't have highlighting yet
hi default link rexplicateGroup			Statement
hi default link rexplicateBranch		Statement
hi default link rexplicateMulti			Special
hi default link rexplicateMultiDigits		Constant
hi default link rexplicateLookaround		Special
hi default link rexplicateLookaroundDigits	Constant
hi default link rexplicateCollItem		Constant
hi default link rexplicateCollCodePoint		Constant
hi default link rexplicateCharClass		Constant
hi default link rexplicateBEOL			Special
hi default link rexplicateBEOF			Special
hi default link rexplicateLastSubst		Special
hi default link rexplicateAny			Special
hi default link rexplicateStartEnd		Special
hi default link rexplicateZeroWidth		Special
hi default link rexplicateMark			Special
hi default link rexplicateLCV			Special
hi default link rexplicateBackRef		Special
hi default link rexplicateSynMod		Type
hi default link rexplicateEngine		Type
hi default link rexplicateCompChar		Constant
hi default link rexplicateCodePoint		Special
hi default link rexplicateCodePointDecDigits	Constant
hi default link rexplicateCodePointOctDigits	Constant
hi default link rexplicateCodePointHexDigits	Constant
hi default link rexplicateEscaped		Constant
hi default link rexplicateError			Error
hi default link rexplicateWarning		WarningMsg
hi default link rexplicateReportPiece		Identifier
hi default link rexplicateReportArrow		Special
hi default link rexplicateSampleLine		Special

let b:current_syntax = 'rexplicate'

let &cpoptions = s:save_cpo
unlet s:save_cpo

" vim: set sw=2 sts=2 et fdm=marker:
