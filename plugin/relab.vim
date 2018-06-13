let s:file = printf('%s/relab', expand('<sfile>:p:h'))
function! RELabSetLayout() "{{{
  botright vsplit RELabResult
  let g:winresult = win_getid()
  wincmd L
  split RELabMatches
  let g:winmatches = win_getid()
  split RELab
  let g:winlab = win_getid()
endfunction "}}}

function! RELabParser() "{{{
  let p = {}
  let p.is_magic =
        \{t -> t =~# '\m^\\[mMvV]$'}

  let p.is_branch =
        \{t -> t ==# '\|' || t ==# '\&'}
  let p.starts_group =
        \{t -> t ==# '[' || t =~# '\m^\\%\?($' || t ==# '\%['}
  let p.starts_capt_group =
        \{t -> t ==# '\('}
  let p.starts_non_capt_group =
        \{t -> t ==# '\%('}
  let p.starts_opt_group =
        \{t -> t ==# '\%['}
  let p.starts_collection =
        \{t -> t ==# '['}
  let p.ends_group =
        \{t -> t ==# ']' || t ==# '\)'}
  let p.ends_capt_group =
        \{t -> t ==# '\)'}
  let p.ends_non_capt_group =
        \{t -> t ==# '\)'}
  let p.ends_opt_group =
        \{t -> t ==# ']'}
  let p.ends_collection =
        \{t -> t ==# ']'}
  let p.collection_ends =
        \{s -> strcharpart(s.input, s.pos) =~# '\m^\(\\.\|[^\]]\)*\]'}

  let p.item_or_eol =
        \{t -> t =~# '\m^\\_[$^.iIkKfFpPsSdDxXoOwWhHaAlLuU]$'}

  let p.incomplete_main =
        \{t -> t =~# '\m^\\\%(@<\?\|%[<>]\?\%(\d*\|''\)\|_\|#\|{[^}]*\|z\)\?$'}
  let p.incomplete =
        \{}
  let p.incomplete.engine =
        \{t -> t =~# '\m^\\%#=\d'}
  let p.incomplete.decimal =
        \{t -> t =~# '\m^\\%d\d\+'}
  let p.incomplete.octal =
        \{t -> t =~# '\m^\\%o\o\{1,3}'}
  let p.incomplete.hex2 =
        \{t -> t =~# '\m^\\%x\x\{1,2}'}
  let p.incomplete.hex4 =
        \{t -> t =~# '\m^\\%u\x\{1,4}'}
  let p.incomplete.hex8 =
        \{t -> t =~# '\m^\\%U\x\{1,8}'}

  let p.is_engine =
        \{t -> t ==# '\%#='}
  let p.is_multi =
        \{t -> index(['*', '\?', '\=', '\+'], t) >= 0
        \ || t=~# '\m^\\{[^}]*}$'}
  let p.is_multi_bracket =
        \{t -> t =~# '\m^\\{'}
  let p.is_valid_bracket =
        \{t -> t=~# '\m^\\{-\?\d*,\?\d*\\\?}$'}
  let p.is_look_around =
        \{t -> t =~# '\m^\\@\%([!=>]\|\d*<[!=]\)$'}
  let p.is_group =
        \{t -> index(['\(', '\%(', ')', '\|', '\&'], t) >= 0}
  let p.is_zero_width =
        \{t -> index(['^'])}
  let p.is_invalid_in_optional =
        \{t -> p.is_multi(t) || p.is_group(t)
        \ || p.is_look_around(t) || p.starts_opt_group(t)}
  let p.is_back_reference =
        \{t -> t =~# '\m^\\[1-9]$'}
  let p.starts_with_at =
        \{t -> t =~# '\m^\\@'}
  let p.has_underscore =
        \{t -> t =~# '\m^\\_.'}
  let p.is_valid_underscore =
        \{t -> t =~# '\m^\\_[iIkKfFpPsSdDxXoOwWhHaAlLuU^$[.]$'}
  let p.is_invalid_underscore =
        \{t -> t =~# '\m^\\_[^iIkKfFpPsSdDxXoOwWhHaAlLuU^$[.]$'}
  let p.is_coll_range =
        \{t -> t =~# '\m^\%(\\[-^\]\\ebnrt]\|[^\\]\)-\%(\\[-^\]\\ebnrt]\|[^\\]\)$'}
  let p.is_coll_range_id = {t -> t ==# 'a-b'}
  let p.like_code_point =
        \{t -> t =~# '\m^\\%[douUx]'}
  let p.is_code_point =
        \{t -> t =~# '\m^\\%\(d\d\+\|o0\?\o\{1,3}\|x\x\{1,2}\|u\x\{1,4}\|U\x\{1,8}\)$'}
  let p.is_invalid_percent =
        \{t -> t =~# '\m^\\%[^V#^$C]'}
  let p.is_mark =
        \{t -> t =~# '\m^\\%[<>]\?''[a-zA-Z0-9''[\]<>]$'}
  let p.is_lcv =
        \{t -> t =~# '\m^\\%[<>]\?\d*[clv]'}
  let p.is_invalid_z =
        \{t -> t =~# '\m^\\z[^se]\?$'}

  " p.id_map {{{
  let p.id_map = {
        \'\|': {'help_tag': '/bar', 'description': 'Alternation, works like a logical OR, matches either the left or right subexpressions.'},
        \'\&': {'help_tag': '/\&', 'description': 'Concatenation, works like a logical AND, matches the subexpression on the righ only if the subexpression on the left also matches.'},
        \'*': {'help_tag': '/star', 'description': 'Matches 0 or more of the preceding atom, as many as possible.'},
        \'\+': {'help_tag': '/\+', 'description': 'Matches 1 or more of the preceding atom, as many as possible.'},
        \'\=': {'help_tag': '/\=', 'description': 'Matches 0 or 1 of the preceding atom, as many as possible.'},
        \'\?': {'help_tag': '/?', 'description': 'Matches 0 or 1 of the preceding atom, as many as possible. Cannot be used when searching backwards with the "?" command.'},
        \'\{n,m}': {'help_tag': '/\{', 'description': 'Matches %s to %s of the preceding atom, as many as possible'},
        \'\{n}': {'help_tag': '/\{', 'description': 'Matches %s of the preceding atom'},
        \'\{n,}': {'help_tag': '/\{', 'description': 'Matches at least %s of the preceding atom, as many as possible'},
        \'\{,m}': {'help_tag': '/\{', 'description': 'Matches 0 to %s of the preceding atom, as many as possible'},
        \'\{}': {'help_tag': '/\{', 'description': 'Matches 0 or more of the preceding atom, as many as possible (like *)'},
        \'\{,}': {'help_tag': '/\{', 'description': 'Matches 0 or more of the preceding atom, as many as possible (like *)'},
        \'\{-n,m}': {'help_tag': '/\{-', 'description': 'Matches %s to %s of the preceding atom, as few as possible'},
        \'\{-n}': {'help_tag': '/\{-', 'description': 'Matches %s of the preceding atom'},
        \'\{-n,}': {'help_tag': '/\{-', 'description': 'Matches at least %s of the preceding atom, as few as possible'},
        \'\{-,m}': {'help_tag': '/\{-', 'description': 'Matches 0 to %s of the preceding atom, as few as possible'},
        \'\{-}': {'help_tag': '/\{-', 'description': 'Matches 0 or more of the preceding atom, as few as possible'},
        \'\{-,}': {'help_tag': '/\{-', 'description': 'Matches 0 or more of the preceding atom, as few as possible'},
        \'\@=': {'help_tag': '/\@=', 'description': 'Matches the preceding atom with zero width.'},
        \'\@!': {'help_tag': '/\@!', 'description': 'Matches with zero width if the preceding atom does NOT match at the current position.'},
        \'\@<=': {'help_tag': '/\@<=', 'description': 'Matches with zero width if the preceding atom matches just before what follows.'},
        \'\@123<=': {'help_tag': '/\@<=', 'description': 'Matches with zero width if the preceding atom matches just before what follows but only look bacl 123 bytes.'},
        \'\@<!': {'help_tag': '/\@<!', 'description': 'Matches with zero width if the preceding atom does NOT match just before what follows.'},
        \'\@123<!': {'help_tag': '/\@<!', 'description': 'Matches with zero width if the preceding atom does NOT match just before what follows but only look back 123 bytes.'},
        \'\@>': {'help_tag': '/\@>', 'description': 'Matches the preceding atom like matching a whole pattern.'},
        \'^' : {'help_tag': '/^', 'description': 'At beginning of pattern or after "\|", "\(", "\%(" or "\n": matches start-of-line with zero width; at other positions, matches literal ''^''.'},
        \'\_^': {'help_tag': '/\_^', 'description': 'Matches start-of-line. zero-width  Can be used at any position in the pattern.'},
        \'$': {'help_tag': '/$', 'description': 'At end of pattern or in front of "\|", "\)" or "\n" (''magic'' on): matches end-of-line <EOL> with zero width; at other positions, matches literal ''$''.'},
        \'\_$': {'help_tag': '/\_$', 'description': 'Matches end-of-line with zero width. Can be used at any position in the pattern.'},
        \'.': {'help_tag': '/.', 'description': 'Matches any single character, but not an end-of-line.'},
        \'\_.': {'help_tag': '/\_.', 'description': 'Matches any single character or end-of-line.'},
        \'\<': {'help_tag': '/\<', 'description': 'Matches the beginning of a word with zero width: The next char is the first char of a word.  The ''iskeyword'' option specifies what is a word character.'},
        \'\>': {'help_tag': '/\>', 'description': 'Matches the end of a word with zero width: The previous char is the last char of a word.  The ''iskeyword'' option specifies what is a word character.'},
        \'\zs': {'help_tag': '/\zs', 'description': 'Matches at any position with zero width, and sets the start of the match there: The next char is the first char of the whole match.'},
        \'\ze': {'help_tag': '/\ze', 'description': 'Matches at any position with zero width, and sets the end of the match there: The previous char is the last char of the whole match.'},
        \'\%^': {'help_tag': '/\%^', 'description': 'Matches start of the file with zero width.  When matching with a string, matches the start of the string.'},
        \'\%$': {'help_tag': '\%$', 'description': 'Matches end of the file.  When matching with a string, matches the end of the string.'},
        \'\%V': {'help_tag': '/\%V', 'description': 'Match inside the Visual area with zero width. When Visual mode has already been stopped match in the area that gv would reselect.'},
        \'\%#': {'help_tag': '/\%#', 'description': 'Matches with the cursor position with zero width.  Only works when matching in a buffer displayed in a window.'},
        \'\%''m': {'help_tag': '/\%''m', 'description': 'Matches with the position of mark m with zero width.'},
        \'\%<''m': {'help_tag': '/\%<''m', 'description': 'Matches before the position of mark m with zero width.'},
        \'\%>''m': {'help_tag': '/\%>''m', 'description': 'Matches after the position of mark m with zero width.'},
        \'\%23l': {'help_tag': '/\%l', 'description': 'Matches in a specific line with zero width.'},
        \'\%<23l': {'help_tag': '/\%>l', 'description': 'Matches above a specific line (lower line number) with zero width.'},
        \'\%>23l': {'help_tag': '/\%<l', 'description': 'Matches below a specific line (higher line number) with zero width.'},
        \'\%23c': {'help_tag': '/\%c', 'description': 'Matches in a specific column with zero width.'},
        \'\%<23c': {'help_tag': '/\%>c', 'description': 'Matches before a specific column with zero width.'},
        \'\%>23c': {'help_tag': '/\%<c', 'description': 'Matches after a specific column with zero width.'},
        \'\%23v': {'help_tag': '/\%v', 'description': 'Matches in a specific virtual column with zero width.'},
        \'\%<23v': {'help_tag': '/\%>v', 'description': 'Matches before a specific virtual column with zero width.'},
        \'\%>23v': {'help_tag': '/\%<v', 'description': 'Matches after a specific virtual column with zero width.'},
        \'\i': {'help_tag': '/\i', 'description': 'Matches an identifier character (see ''isident'' option)'},
        \'\I': {'help_tag': '/\I', 'description': 'Matches an identifier character, but excluding digits'},
        \'\k': {'help_tag': '/\k', 'description': 'Matches a keyword character (see ''iskeyword'' option)'},
        \'\K': {'help_tag': '/\K', 'description': 'Matches a keyword character, but excluding digits'},
        \'\f': {'help_tag': '/\f', 'description': 'Matches a file name character (see ''isfname'' option)'},
        \'\F': {'help_tag': '/\F', 'description': 'Matches a file name character, but excluding digits'},
        \'\p': {'help_tag': '/\p', 'description': 'Matches a printable character (see ''isprint'' option)'},
        \'\P': {'help_tag': '/\P', 'description': 'Matches a printable character, but excluding digits'},
        \'\s': {'help_tag': '/\s', 'description': 'Matches a whitespace character: <Space> and <Tab>'},
        \'\S': {'help_tag': '/\S', 'description': 'Matches a non-whitespace character; opposite of \s'},
        \'\d': {'help_tag': '/\d', 'description': 'Matches a digit: [0-9]'},
        \'\D': {'help_tag': '/\D', 'description': 'Matches a non-digit: [^0-9]'},
        \'\x': {'help_tag': '/\x', 'description': 'Matches a hex digit: [0-9A-Fa-f]'},
        \'\X': {'help_tag': '/\X', 'description': 'Matches a non-hex digit: [^0-9A-Fa-f]'},
        \'\o': {'help_tag': '/\o', 'description': 'Matches an octal digit: [0-7]'},
        \'\O': {'help_tag': '/\O', 'description': 'Matches a non-octal digit: [^0-7]'},
        \'\w': {'help_tag': '/\w', 'description': 'Matches a word character: [0-9A-Za-z_]'},
        \'\W': {'help_tag': '/\W', 'description': 'Matches a non-word character: [^0-9A-Za-z_]'},
        \'\h': {'help_tag': '/\h', 'description': 'Matches a head of word character: [A-Za-z_]'},
        \'\H': {'help_tag': '/\H', 'description': 'Matches a non-head of word character: [^A-Za-z_]'},
        \'\a': {'help_tag': '/\a', 'description': 'Matches an alphabetic character: [A-Za-z]'},
        \'\A': {'help_tag': '/\A', 'description': 'Matches a non-alphabetic character: [^A-Za-z]'},
        \'\l': {'help_tag': '/\l', 'description': 'Matches a lowercase character: [a-z]'},
        \'\L': {'help_tag': '/\L', 'description': 'Matches a non-lowercase character: [^a-z]'},
        \'\u': {'help_tag': '/\u', 'description': 'Matches an uppercase character: [A-Z]'},
        \'\U': {'help_tag': '/\U', 'description': 'Matches a non-uppercase character: [^A-Z]'},
        \'\_i': {'help_tag': '/\i', 'description': 'Matches an identifier character (see ''isident'' option) or a newline (like \n)'},
        \'\_I': {'help_tag': '/\I', 'description': 'Matches an identifier character, but excluding digits or a newline (like \n)'},
        \'\_k': {'help_tag': '/\k', 'description': 'Matches a keyword character (see ''iskeyword'' option) or a newline (like \n)'},
        \'\_K': {'help_tag': '/\K', 'description': 'Matches a keyword character, but excluding digits or a newline (like \n)'},
        \'\_f': {'help_tag': '/\f', 'description': 'Matches a file name character (see ''isfname'' option) or a newline (like \n)'},
        \'\_F': {'help_tag': '/\F', 'description': 'Matches a file name character, but excluding digits or a newline (like \n)'},
        \'\_p': {'help_tag': '/\p', 'description': 'Matches a printable character (see ''isprint'' option) or a newline (like \n)'},
        \'\_P': {'help_tag': '/\P', 'description': 'Matches a printable character, but excluding digits or a newline (like \n)'},
        \'\_s': {'help_tag': '/\s', 'description': 'Matches a whitespace character: <Space> and <Tab> or a newline (like \n)'},
        \'\_S': {'help_tag': '/\S', 'description': 'Matches a non-whitespace character; opposite of \s or a newline (like \n)'},
        \'\_d': {'help_tag': '/\d', 'description': 'Matches a digit: [0-9] or a newline (like \n)'},
        \'\_D': {'help_tag': '/\D', 'description': 'Matches a non-digit: [^0-9] or a newline (like \n)'},
        \'\_x': {'help_tag': '/\x', 'description': 'Matches a hex digit: [0-9A-Fa-f] or a newline (like \n)'},
        \'\_X': {'help_tag': '/\X', 'description': 'Matches a non-hex digit: [^0-9A-Fa-f] or a newline (like \n)'},
        \'\_o': {'help_tag': '/\o', 'description': 'Matches an octal digit: [0-7] or a newline (like \n)'},
        \'\_O': {'help_tag': '/\O', 'description': 'Matches a non-octal digit: [^0-7] or a newline (like \n)'},
        \'\_w': {'help_tag': '/\w', 'description': 'Matches a word character: [0-9A-Za-z_] or a newline (like \n)'},
        \'\_W': {'help_tag': '/\W', 'description': 'Matches a non-word character: [^0-9A-Za-z_] or a newline (like \n)'},
        \'\_h': {'help_tag': '/\h', 'description': 'Matches a head of word character: [A-Za-z_] or a newline (like \n)'},
        \'\_H': {'help_tag': '/\H', 'description': 'Matches a non-head of word character: [^A-Za-z_] or a newline (like \n)'},
        \'\_a': {'help_tag': '/\a', 'description': 'Matches an alphabetic character: [A-Za-z] or a newline (like \n)'},
        \'\_A': {'help_tag': '/\A', 'description': 'Matches a non-alphabetic character: [^A-Za-z] or a newline (like \n)'},
        \'\_l': {'help_tag': '/\l', 'description': 'Matches a lowercase character: [a-z] or a newline (like \n)'},
        \'\_L': {'help_tag': '/\L', 'description': 'Matches a non-lowercase character: [^a-z] or a newline (like \n)'},
        \'\_u': {'help_tag': '/\u', 'description': 'Matches an uppercase character: [A-Z] or a newline (like \n)'},
        \'\_U': {'help_tag': '/\U', 'description': 'Matches a non-uppercase character: [^A-Z] or a newline (like \n)'},
        \'~': {'help_tag': '/\~', 'description': 'Matches the last given substitute string.'},
        \'\(': {'help_tag': '/\(', 'description': 'Start a pattern enclosed by escaped parentheses.'},
        \'\)': {'help_tag': '/\)', 'description': 'End a pattern enclosed by escaped parentheses.'},
        \'\1': {'help_tag': '/\1', 'description': 'Matches the same string that was matched by the first sub-expression in \( and \).'},
        \'\2': {'help_tag': '/\2', 'description': 'Matches the same string that was matched by the second sub-expression in \( and \).'},
        \'\3': {'help_tag': '/\3', 'description': 'Matches the same string that was matched by the third sub-expression in \( and \).'},
        \'\4': {'help_tag': '/\4', 'description': 'Matches the same string that was matched by the fourth sub-expression in \( and \).'},
        \'\5': {'help_tag': '/\5', 'description': 'Matches the same string that was matched by the fifth sub-expression in \( and \).'},
        \'\6': {'help_tag': '/\6', 'description': 'Matches the same string that was matched by the sixth sub-expression in \( and \).'},
        \'\7': {'help_tag': '/\7', 'description': 'Matches the same string that was matched by the seventh sub-expression in \( and \).'},
        \'\8': {'help_tag': '/\8', 'description': 'Matches the same string that was matched by the eighth sub-expression in \( and \).'},
        \'\9': {'help_tag': '/\9', 'description': 'Matches the same string that was matched by the ninth sub-expression in \( and \).'},
        \'\%(': {'help_tag': '/\%(', 'description': 'Start a pattern enclosed by escaped parentheses.  Just like \(\), but without counting it as a sub-expression.'},
        \'[': {'help_tag': '/[]', 'description': 'This is a sequence of characters enclosed in brackets. It matches any single character in the collection.'},
        \'\_[': {'help_tag': '/\_[]', 'description': 'This is a sequence of characters enclosed in brackets. It matches any single character in the collection.  With "\_" prepended the collection also includes the end-of-line.'},
        \'[^': {'help_tag': 'E944', 'description': 'If the sequence begins with "^", it matches any single character NOT in the collection: "[^xyz]" matches anything but ''x'', ''y'' and ''z''.'},
        \'[-': {'help_tag': 'E944', 'description': 'If two characters in the sequence are separated by ''-'', this is shorthand for the full list of ASCII characters between them.'},
        \'[:alnum:]': {'help_tag': '[:alnum:]', 'description': 'Matches ASCII letters and digits'},
        \'[:alpha:]': {'help_tag': '[:alpha:]', 'description': 'Matches ASCII letters'},
        \'[:blank:]': {'help_tag': '[:blank:]', 'description': 'Matches space and tab'},
        \'[:cntrl:]': {'help_tag': '[:cntrl:]', 'description': 'Matches ASCII control characters'},
        \'[:digit:]': {'help_tag': '[:digit:]', 'description': 'Matches decimal digits ''0'' to ''9'''},
        \'[:graph:]': {'help_tag': '[:graph:]', 'description': 'Matches ASCII printable characters excluding space'},
        \'[:lower:]': {'help_tag': '[:lower:]', 'description': 'Matches lowercase letters (all letters when ''ignorecase'' is used)'},
        \'[:print:]': {'help_tag': '[:print:]', 'description': 'Matches printable characters including space'},
        \'[:punct:]': {'help_tag': '[:punct:]', 'description': 'Matches ASCII punctuation characters'},
        \'[:space:]': {'help_tag': '[:space:]', 'description': 'Matches whitespace characters: space, tab, CR, NL, vertical tab, form feed'},
        \'[:upper:]': {'help_tag': '[:upper:]', 'description': 'Matches uppercase letters (all letters when ''ignorecase'' is used)'},
        \'[:xdigit:]': {'help_tag': '[:xdigit:]', 'description': 'Matches hexadecimal digits: 0-9, a-f, A-F'},
        \'[:return:]': {'help_tag': '[:return:]', 'description': 'Matches the <CR> character'},
        \'[:tab:]': {'help_tag': '[:tab:]', 'description': 'Matches the <Tab> character'},
        \'[:escape:]': {'help_tag': '[:escape:]', 'description': 'Matches the <Esc> character'},
        \'[:backspace:]': {'help_tag': '[:backspace:]', 'description': 'Matches the <BS> character'},
        \'[==]': {'help_tag': '[==]', 'description': 'An equivalence class.  This means that characters are matched that have almost the same meaning, e.g., when ignoring accents.  This only works for Unicode, latin1 and latin9.  The form is: [=a=]'},
        \'[..]': {'help_tag': '[..]', 'description': 'A collation element.  This currently simply accepts a single character in the form: [.a.]'},
        \'[\e': {'help_tag': '/\]', 'description': 'Matches an <Esc>'},
        \'[\t': {'help_tag': '/\]', 'description': 'Matches a <Tab>'},
        \'[\r': {'help_tag': '/\]', 'description': 'Matches a <CR>	(NOT end-of-line!)'},
        \'[\b': {'help_tag': '/\]', 'description': 'Matches a <BS>'},
        \'[\n': {'help_tag': '/\]', 'description': 'Matches a line break, see above |/[\n]|'},
        \'[\d': {'help_tag': '/\]', 'description': 'Matches a decimal number of character'},
        \'[\o': {'help_tag': '/\]', 'description': 'Matches an octal number of character up to 0377'},
        \'[\x': {'help_tag': '/\]', 'description': 'Matches a hexadecimal number of character up to 0xff'},
        \'[\u': {'help_tag': '/\]', 'description': 'Matches a hex. number of multibyte character up to 0xffff'},
        \'[\U': {'help_tag': '/\]', 'description': 'Matches a hex. number of multibyte character up to 0xffffffff'},
        \'\%[': {'help_tag': '/\%[]', 'description': 'A sequence of optionally matched atoms.  This always matches.'},
        \'\%d': {'help_tag': '/\%d', 'description': 'Matches the character specified with a decimal number.  Must be followed by a non-digit.'},
        \'\%o': {'help_tag': '/\O', 'description': 'Matches the character specified with an octal number up to 0377.  Numbers below 040 must be followed by a non-octal digit or a non-digit.'},
        \'\%x': {'help_tag': '/\%x', 'description': 'Matches the character specified with up to two hexadecimal characters.'},
        \'\%u': {'help_tag': '/\%u', 'description' : 'Matches the character specified with up to four hexadecimal characters.'},
        \'\%U': {'help_tag': '/\%U' ,'description': 'Matches the character specified with up to eight hexadecimal characters.'},
        \'\c': {'help_tag': '/\c', 'description': 'When "\c" appears anywhere in the pattern, the whole pattern is handled like ''ignorecase'' is on.  The actual value of ''ignorecase'' and ''smartcase'' is ignored.'},
        \'\C': {'help_tag': '/\C', 'description': 'When "\C" appears anywhere in the pattern, the whole pattern is handled like ''ignorecase'' is off  The actual value of ''ignorecase'' and ''smartcase'' is ignored.'},
        \'\Z': {'help_tag': '/\Z', 'description': 'When "\Z" appears anywhere in the pattern, all composing characters are ignored.'},
        \'\%C': {'help_tag': '/\%C', 'description': 'Use "\%C" to skip any composing characters.'},
        \'\m': {'help_tag': '/\m', 'description': '''magic'' on for the following chars in the pattern'},
        \'\M': {'help_tag': '/\M', 'description': '''magic'' off for the following chars in the pattern'},
        \'\v': {'help_tag': '/\v', 'description': 'the following chars in the pattern are "very magic"'},
        \'\V': {'help_tag': '/\V', 'description': 'the following chars in the pattern are "very nomagic"'},
        \'\%#=': {'help_tag': '/\%#=', 'description': 'select regexp engine'},
        \} "}}}

  function! p.follows_nothing(node) "{{{
    return empty(a:node.previous) || self.is_branch(a:node.previous.id)
          \|| self.is_look_around(a:node.previous.id)
  endfunction "}}}

  function! p.init(...) "{{{
    let self.magic = 'm'
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

    let self.root = {}
    let self.root.value = 'root'
    let self.root.normal = 'root'
    let self.root.id = 'root'
    let self.root.magic = self.magic
    let self.root.parent = {}
    let self.root.siblings = []
    let self.root.children = []
    let self.root.help = 'pattern'

    let self.parent = self.root
    return self
  endfunction "}}}

  function! p.to_magic(token, magic) "{{{
    if a:magic ==# 'M'
      if a:token =~# '\m^\\[.*~[]$'
        return a:token[1:]
      elseif a:token =~# '\m^[.*~[]$'
        return '\' . a:token
      endif
    elseif a:magic ==# 'v'
      if a:token =~# '\m^[+?{()@%<>=]'
        return '\' . a:token
      elseif a:token =~# '\m^\\[+?{()@%<>=]'
        return a:token[1:]
      endif
    elseif a:magic ==# 'V'
      if a:token =~# '\m^\\[[.*~^$]$'
        return a:token[1:]
      elseif a:token =~# '\m^[[.*~^$]$'
        return '\' . a:token
      endif
    endif
    return a:token
  endfunction "}}}

  function! p.new_child() "{{{
    let n = copy(self.parent)
    let n.is_error = 0
    let n.error = []
    let n.magic = self.magic
    let n.parent = self.parent
    let n.siblings = self.parent.children
    let n.children = []
    let n.nesting_level = len(self.nest_stack)
    let n.previous = get(self.parent.children, -1, {})
    let n.next = {}
    let n.normal = self.to_magic(self.token, self.magic)
    let n.id = self.to_id(n.normal)
    let n.help_tag = self.help_tag(n)
    let n.value = self.token
    let n.description = self.description(n)
    let n.pos = self.pos - strchars(self.token)
    if !empty(n.previous)
      let n.previous.next = n
    endif
    call add(self.parent.children, n)
    call add(self.sequence, n)
    return n
  endfunction "}}}

  function! p.to_id(text) "{{{
    if self.in_collection
      if a:text =~# '\m^\\[doxuU]'
        " /[\x]
        return substitute(a:text, '\m^\(\\.\).\+', '[\1', '')
      elseif self.is_coll_range(a:text)
        " /[a-z]
        return 'a-b'
      elseif a:text =~# '\m^\[[.=].[.=]\]$'
        " /[[.a.][=a=]]
        return substitute(a:text, '\m^\(\[[.=]\).[.=]\]$', '[\1\1]', '')
      endif
    elseif a:text =~# '\m^\\%[<>]\?\d\+[lvc]$'
      " /\%23l
      return substitute(a:text, '\m\d\+', '', '')
    elseif a:text =~# '\m^\\%[<>]''.$'
      " /\%'m
      return a:text[0:-2] . 'm'
    elseif a:text =~# '\m^\\{'
      " /.\{}
      let id = '\{'
      let id .= a:text =~# '\m^\\{-' ? '-' : ''
      let id .= a:text =~# '\m^\\{-\?\d' ? 'n' : ''
      let id .= a:text =~# '\m^\\{-\?\d*,' ? ',' : ''
      let id .= a:text =~# '\m^\\{-\?\d*,\d' ? 'm' : ''
      let id .= '}'
      return id
    elseif a:text =~# '\m^\\%[doxuU]\d\+$'
      " /\%d123
      return matchstr(a:text, '\m\C^\\%[doxuU]')
    elseif a:text =~# '\m^\\%#=.\?'
      " regexp engine
      return '\%#='
    endif
    return a:text
  endfunction "}}}

  function! p.help_tag(node) "{{{
    return get(get(self.id_map, a:node.id, {}), 'description', '')
  endfunction "}}}

  function! p.description(node, ...) "{{{
    if a:0
      let msg = a:1
    elseif has_key(self.id_map, a:node.id)
      let msg = get(get(self.id_map, a:node.id, {}), 'description', '')
    else
      let char = a:node.id =~# '^\\.' ? a:node.id[1:] : a:node.id
      let msg = printf('Matches the character "%s"', char)
    endif
    let indent = repeat('  ', a:node.nesting_level)
    return printf('%s%s => %s', indent, a:node.value, msg)
  endfunction "}}}

  function! p.lines() "{{{
    let lines = []
    if !empty(self.errors)
      return extend(lines, self.errors[0].error)
    endif
    call add(lines, '')
    return extend(lines, map(copy(self.sequence), 'v:val.description'))
  endfunction "}}}

  function! p.in_optional_group() "{{{
    return get(get(self.nest_stack, -1, {}), 'id', '') ==# '\%['
  endfunction "}}}

  function! p.is_paired(right) "{{{
    let left = get(self.nest_stack, -1, {'id': ''}).id
    if a:right ==# '\)'
      return left ==# '\(' || left ==# '\%('
    elseif a:right ==# ']'
      return left ==# '\%[' || left ==# '['
    endif
    return 0
  endfunction "}}}

  function! p.incomplete_in_collection() "{{{
    let next = self.token . strcharpart(self.input, self.pos)
    let ahead = strcharpart(self.input, self.pos, 1)
    if self.token =~# '\m^\%(\\[\\ebnrt]\|[^\\]\)-\%(\\[\\ebnrt]\|[^\\]\)$'
      DbgRELab printf('is_incomplete_in_collection -> range done: %s', next)
      return 0
    elseif next =~# '\m^\%(\\[\\enbrt]\|[^\\]\)-\%(\\[\\ebnrt]\|[^\\]\)'
      DbgRELab printf('is_incomplete_in_collection -> range coming: %s', next)
      return 1
    elseif self.token =~# '\m^\\[-ebnrt\]^]$'
      DbgRELab printf('is_incomplete_in_collection -> escaped done: %s', next)
      return 0
    elseif self.token ==# '\' && ahead =~# '\m^[-ebnrtdoxuU\]^]$'
      DbgRELab printf('is_incomplete_in_collection -> escaped done: %s', next)
      return 1
    elseif self.token ==# '\'
      DbgRELab printf('is_incomplete_in_collection -> escaped coming: %s', next)
      return 0
    elseif self.token =~# '\m^\[\([.=]\).\1\]$'
      DbgRELab printf('is_incomplete_in_collection -> equivalence done: %s', next)
      return 0
    elseif next =~# '\m^\[\([.=]\).\1\]'
      DbgRELab printf('is_incomplete_in_collection -> equivalence coming: %s', next)
      return 1
    elseif self.token =~# '\m^\[:\a\+:\]$'
      DbgRELab printf('is_incomplete_in_collection -> collation done: %s', next)
      return 0
    elseif next =~# '\m^\[:\a\+:\]'
      DbgRELab printf('is_incomplete_in_collection -> collation coming: %s', next)
      return 1
    endif
    let next = self.token . ahead
    if next =~# '\m^\\d\d*$'
      DbgRELab printf('is_incomplete_in_collection -> dec: %s', next)
      return 1
    elseif next =~# '\m^\\o0\?\o\{,3}$'
          \&& printf('0%s', matchstr(next, '0\?\zs\o\+')) <= 0377
      DbgRELab printf('is_incomplete_in_collection -> oct: %s', next)
      return 1
    elseif next =~# '\m^\\x\x\{,2}$'
      DbgRELab printf('is_incomplete_in_collection -> hex2: %s', next)
      return 1
    elseif next =~# '\m^\\u\x\{,4}$'
      DbgRELab printf('is_incomplete_in_collection -> hex4: %s', next)
      return 1
    elseif next =~# '\m^\\U\x\{,8}$'
      DbgRELab printf('is_incomplete_in_collection -> hex8: %s', next)
      return 1
    elseif next =~# '\m^\\[duUx].$'
      DbgRELab printf('is_incomplete_in_collection -> code point: %s', next)
      return 1
    else
      return 0
    endif
  endfunction "}}}

  function! p.sequence_of(key) "{{{
    return map(copy(self.sequence), 'get(v:val, a:key, '''')')
  endfunction "}}}

  function! p.normals() "{{{
    return map(copy(self.sequence), 'get(v:val, ''normal'', '''')')
  endfunction "}}}

  function! p.values() "{{{
    return map(copy(self.sequence), 'get(v:val, ''value'', '''')')
  endfunction "}}}

  function! p.descriptions() "{{{
    return map(copy(self.sequence), 'get(v:val, ''description'', '''')')
  endfunction "}}}

  function! p.ids() "{{{
    return map(copy(self.sequence), 'get(v:val, ''id'', '''')')
  endfunction "}}}

  function! p.add_error(node, ...) "{{{
    let a:node.is_error = 1
    let error = []
    let arrow = printf('%s%s',
          \repeat('-', a:node.pos), repeat('^', strchars(a:node.value)))
    call add(error, arrow)
    call add(error, printf('Error: %s', (a:0 ? a:1 : a:node.value . ':')))
    let a:node.error = error
    call add(self.errors, a:node)
  endfunction "}}}

  function! p.is_incomplete() "{{{
    DbgRELab printf('is_incomplete')
    if self.in_collection
      return self.incomplete_in_collection()
    endif
    let token = self.to_magic(self.token, self.magic)
    if self.incomplete_main(token)
      DbgRELab printf('is_incomplete -> main: %s', token)
      return 1
    endif
    let ahead = strcharpart(self.input, self.pos, 1)
    let next = token . ahead
    if next =~# '\m^\\%d\d*$'
      DbgRELab printf('is_incomplete -> dec: %s', next)
      return 1
    elseif next =~# '\m^\\%o0\?\o\{,3}$'
          \&& printf('0%s', matchstr(next, '0\?\zs\o\+')) <= 0377
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

  function! p.next() "{{{
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

  function! p.parse(input) "{{{
    DbgRELab printf('parse: %s', a:input)
    call self.init(a:input)
    while self.next()
      let node = self.new_child()
      DbgRELab printf('parse -> token: %s, id: %s', node.value, node.id)

      if self.in_collection && self.ends_collection(node.id) "{{{
        DbgRELab  'parse -> ends collection'
        call remove(self.nest_stack, -1)
        let self.parent = node.parent.parent
        let self.in_collection = 0
        let node.nesting_level -= 1
        let node.description =
              \printf('%s%s => %s', repeat('  ', node.nesting_level), node.value,
              \  'ends collection.')
        "}}}

      elseif self.in_collection && self.is_coll_range_id(node.id) "{{{
        DbgRELab printf('parse -> collection -> range')
        if node.value[0] ==# '\'
          let first = strcharpart(node.value, 0, 2)
          let second = strcharpart(node.value, 3)
        else
          let first = strcharpart(node.value, 0, 1)
          let second = strcharpart(node.value, 2)
        endif
        let dict = {'\e': "\e", '\b': "\b", '\n': "\n", '\r': "\r", '\t': "\t",
              \'\\': '\', '\]': ']', '\^': '^', '\-': '-'}
        let first = get(dict, first, first)
        DbgRELab  printf('parse -> collection -> range: first: %s, second: %s', first, second)
        let second = get(dict, second, second)
        if first ># second
          let errormessage = 'reverse range in character class'
          call self.add_error(node, errormessage)
        else
          let description = printf('matches a character in the range from "%s" to "%s"', first, second)
          let node.description = self.description(node, description)
        endif
        "}}}

      elseif self.is_engine(node.id) "{{{
        DbgRELab  printf('parse -> engine')
        if matchstr(node.value, '^\m\\%#=\zs.\?') !~# '\m^[0-2]$'
          let errormessage =
                \'\%#= can only be followed by 0, 1, or 2'
          call self.add_error(node, errormessage)
        endif
        "}}}

      elseif self.in_optional_group() && self.is_invalid_in_optional(node.id) "{{{
        DbgRELab  printf('parse -> invalid in optional')
        let errormessage =
              \printf('%s is not valid inside \%%[]', node.value)
        call self.add_error(node, errormessage)
        "}}}

      elseif self.starts_group(node.id) "{{{
        DbgRELab  printf('parse -> starts group')
        call add(self.nest_stack, node)
        let self.parent = node
        if self.starts_collection(node.id)
          DbgRELab  printf('parse -> starts group -> collection')
          if self.collection_ends(self)
            " The collection is terminated by a ']', so treat this as the
            " start of the collection
            let self.in_collection = 1
          else
            " Treat this as a literal character
            call remove(self.nest_stack, -1)
            let node.description = printf('%s%s => Matches the character "[".',
                  \repeat('  ', node.nesting_level),
                  \node.value)
            let node.id = 'x'
          endif
        elseif self.starts_capt_group(node.id)
          DbgRELab  printf('parse -> starts group -> capturing group')
          let self.capt_groups += 1
          if self.capt_groups > 9
            let errormessage = 'more than 9 capturing groups'
            call self.add_error(node, errormessage)
          endif
        endif
        "}}}

      elseif self.ends_group(node.id) "{{{
        DbgRELab  printf('parse -> ends group')
        if self.is_paired(node.id)
          DbgRELab  printf('parse -> ends group -> is paired')
          call remove(self.nest_stack, -1)
          let self.parent = node.parent.parent
          let node.nesting_level -= 1
          if self.ends_opt_group(node.id)
            DbgRELab  printf('parse -> ends group -> is paired -> opt group')
            if empty(node.previous)
              let errormessage = printf('empty %s%s', node.parent.value, node.value)
              call self.add_error(node, errormessage)
            else
              let node.description =
                    \printf('%s%s => %s', repeat('  ', node.nesting_level), node.value,
                    \  'ends optional sequence.')
            endif
          else
            let node.description = self.description(node)
          endif
        else
          DbgRELab  printf('parse -> ends group -> is not paired')
          if empty(self.nest_stack)
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

      elseif self.has_underscore(node.id) "{{{
        DbgRELab  printf('parse -> has underscore')
        if self.is_valid_underscore(node.id)
          DbgRELab  printf('parse -> has underscore -> valid')
        elseif self.is_invalid_underscore(node.id)
          DbgRELab  printf('parse -> has underscore -> invalid')
          let char = strcharpart(node.normal, 2)
          let errormessage = 'invalid use of \_'
          call self.add_error(node, errormessage)
        endif
        "}}}

      elseif self.is_multi(node.id) "{{{
        DbgRELab  printf('parse -> multi')
        if !empty(node.previous) && self.is_multi(node.previous.id)
          DbgRELab  printf('parse -> multi -> follows multi')
          let errormessage =
                \printf('%s can not follow a multi', node.value)
          call self.add_error(node, errormessage)
        elseif self.follows_nothing(node)
          DbgRELab  printf('parse -> multi -> follows nothing')
          let errormessage =
                \printf('%s follows nothing', node.value)
          call self.add_error(node, errormessage)
        elseif self.is_multi_bracket(node.id)
          DbgRELab  printf('parse -> multi -> brackets')
          if self.is_valid_bracket(node.value)
            DbgRELab  printf('parse -> multi -> brackets -> valid')
            let min = matchstr(node.value, '\m\\{-\?\zs\d*')
            let max = matchstr(node.value, '\m\\{-\?\d*,\zs\d*')
            if empty(min)
              DbgRELab  printf('parse -> multi -> brackets -> valid -> empty min')
              if empty(max)
                DbgRELab  printf('parse -> multi -> brackets -> valid -> empty min & max')
                let description = self.id_map[node.id].description
              else
                DbgRELab  printf('parse -> multi -> brackets -> valid -> empty min, not max')
                let description = printf(self.id_map[node.id].description, max)
              endif
            else
              DbgRELab  printf('parse -> multi -> brackets -> valid -> not min')
              if empty(max)
                DbgRELab  printf('parse -> multi -> brackets -> valid -> not min & empty max')
                let description = printf(self.id_map[node.id].description, min)
              else
                DbgRELab  printf('parse -> multi -> brackets -> valid -> not min & not max')
                let description = printf(self.id_map[node.id].description, min, max)
              endif
            endif
            let node.description = self.description(node,description)
          else
            DbgRELab  printf('parse -> multi -> brackets -> invalid')
            let errormessage =
                  \printf('syntax error in %s', node.value)
            call self.add_error(node, errormessage)
          endif
        endif
        "}}}

      elseif self.is_back_reference(node.id) "{{{
        DbgRELab  printf('parse -> back reference')
        if strcharpart(node.value, 1, 1) > self.capt_groups
          DbgRELab  printf('parse -> back reference -> illegal')
          let errormessage = 'illegal back reference'
          call self.add_error(node, errormessage)
        endif
        "}}}

      elseif self.is_look_around(node.id) "{{{
        DbgRELab  printf('parse -> look around')
        if self.follows_nothing(node)
          DbgRELab  printf('parse -> look around -> illegal')
          let errormessage = printf('%s follows nothing', node.value)
          call self.add_error(node, errormessage)
        endif
        "}}}

      elseif self.starts_with_at(node.id) "{{{
        DbgRELab  printf('parse -> starts with @')
        if node.id !=# '\@>'
          let errormessage = printf('invalid character after %s',
                \(node.magic ==# 'v' ? '@' : '\@'))
          call self.add_error(node, errormessage)
        endif
        "}}}

      elseif self.like_code_point(node.id) "{{{
        DbgRELab  printf('parse -> like code point: normal: %s', node.normal)
        if self.is_code_point(node.normal)
          DbgRELab  printf('parse -> like code point -> hexadecimal 8')
        else
          DbgRELab  printf('parse -> like code point -> invalid code point')
          let errormessage = printf('invalid character after %s',
                \matchstr(node.value, '\\\?%[duUx]'))
          call self.add_error(node, errormessage)
        endif
        "}}}

      elseif self.is_mark(node.id) "{{{
        DbgRELab  printf('parse -> mark')
        "}}}

      elseif self.is_lcv(node.id) "{{{
        DbgRELab  printf('parse -> lcv')
        "}}}

      elseif self.is_invalid_percent(node.id) "{{{
        DbgRELab  printf('parse -> invalid percent')
        let errormessage = printf('invalid character after %s',
              \matchstr(node.value, '\\\?%'))
        call self.add_error(node, errormessage)
        "}}}

      elseif self.is_invalid_z(node.id) "{{{
        DbgRELab  printf('parse -> invalid percent')
        let errormessage = printf('invalid character after %s',
              \matchstr(node.value, '\\\?z'))
        call self.add_error(node, errormessage)
        "}}}

      elseif self.is_magic(node.id) "{{{
        DbgRELab  printf('parse -> magic')
        let self.magic = node.id[1]
        "}}}

      elseif has_key(self.id_map, node.id) "{{{
        DbgRELab  printf('parse -> has_key')
        "}}}

      else
        DbgRELab  printf('parse -> literal match')
        let node.id = 'x'
      endif
    endwhile
    if !empty(self.nest_stack)
      DbgRELab  printf('parse -> non-empty nest stack')
      for node in self.nest_stack
        DbgRELab  printf('parse -> non-empty nest stack -> loop: %s', node.value)
        if self.starts_opt_group(node.id)
          let errormessage = printf('missing ] after %s', node.value)
        else
          let errormessage = printf('unmatched %s', node.value)
        endif
        call self.add_error(node, errormessage)
      endfor
    endif
    return self
  endfunction "}}}

  return p.init()
endfunction "}}}

function! RELabOnTextChange() "{{{
  let pattern = getline('1')
  if pattern ==# get(s:, 'previous_pattern', '')
    echom 'skipped'
    return
  endif
  let s:previous_pattern = pattern
  let time1 = reltime()
  let curpos = getpos('.')
  call g:relab.parse(pattern)
  if line('$') > 1
    2,$d_
  endif
  let lines = g:relab.lines()
  call append(1, lines)
  call setpos('.', curpos)
  if get(s:, 'errormatchid', 0)
        \&& !empty(filter(getmatches(), 'v:val.id == s:errormatchid'))
    call matchdelete(s:errormatchid)
  endif
  if !empty(g:relab.errors)
    let node = g:relab.errors[0]
    let matchpattern = printf('\%%1l\%%%sv%s', node.pos + 1, repeat('.', strchars(node.value)))
    let s:errormatchid = matchadd('Error', matchpattern)
  endif
  let time = reltimestr(reltime(time1, reltime()))
  echom printf('Time for %s in line %s is %s', pattern, line('.'), time)
endfunction "}}}

function! RELabDebug(msg) "{{{
  if get(g:, 'relab_debug', 0)
    echom printf('RELab: %s', a:msg)
  endif
endfunction "}}}

function! RELabSetUp(regexp) "{{{
  let regexp = empty(a:regexp) ? @/ : a:regexp
  let bufnr = get(s:, 'bufnr', bufnr('relab'))
  if bufnr >= 0
    let winnr = bufwinnr(bufnr)
    if winnr >= 0
      exec printf('%swincmd w', winnr)
    else
      if get(g:, 'relab_split', 1)
        split relab
      endif
      exec printf('buffer %s', bufnr)
    endif
  else
    if get(g:, 'relab_split', 1)
      split relab
    else
      edit relab
    endif
    set filetype=relab
    set buftype=nofile
    let s:bufnr = bufnr('%')
    augroup RELab
      autocmd!
      autocmd TextChanged,TextChangedI <buffer> call RELabOnTextChange()
      autocmd BufWinLeave,WinLeave <buffer> let @/ = getline(1)
    augroup END
  endif
  call setline(1, regexp)
endfunction "}}}

function! RELabTest() "{{{
  let debug = get(g:, 'relab_debug', 0)
  let g:relab_debug = 0

  let p = RELabParser()

  let v:errors = []

  let input =     ''
  let expected = []
  let output = p.parse(input).normals()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '^'
  let expected = ['^']
  let output = p.parse(input).normals()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '^a\+'
  let expected = ['^', 'a', '\+']
  let output = p.parse(input).normals()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '^a\+\vb+'
  let expected = ['^', 'a', '\+', '\v', 'b', '\+']
  let output = p.parse(input).normals()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '.\{}'
  let expected = ['.', '\{}']
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '.\{1}'
  let expected = ['.', '\{n}']
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '.\{1,}'
  let expected = ['.', '\{n,}']
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '.\{1,2}'
  let expected = ['.', '\{n,m}']
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '.\{,2}'
  let expected = ['.', '\{,m}']
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '.\{,}'
  let expected = ['.', '\{,}']
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '.\{-}'
  let expected = ['.', '\{-}']
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '.\{-1}'
  let expected = ['.', '\{-n}']
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '.\{-1,}'
  let expected = ['.', '\{-n,}']
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '.\{-1,2}'
  let expected = ['.', '\{-n,m}']
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '.\{-,2}'
  let expected = ['.', '\{-,m}']
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '.\{-,}'
  let expected = ['.', '\{-,}']
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '.\?'
  let expected = ['.', '\?']
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '.\='
  let expected = ['.', '\=']
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '.*'
  let expected = ['.', '*']
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '.\+'
  let expected = ['.', '\+']
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '\v\1'
  let expected = ['\v', '\1']
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_true(has_error, input)

  let input =     '\%x1234'
  let expected = ['\%x', 'x', 'x']
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '\%o1234'
  let expected = ['\%o', 'x']
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '\%o0377'
  let expected = ['\%o']
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '\%o377'
  let expected = ['\%o']
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '\%o400'
  let expected = ['\%o', 'x']
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '\%o0400'
  let expected = ['\%o', 'x']
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '\%#=0'
  let expected = ['\%#=']
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     'a\@>'
  let expected = ['x', '\@>']
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '\_.'
  let expected = ['\_.']
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '\a'
  let expected = ['\a']
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '\_a'
  let expected = ['\_a']
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '.\@!'
  let expected = ['.', '\@!']
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     'a\zsb'
  let expected = ['x', '\zs', 'x']
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     'a\zeb'
  let expected = ['x', '\ze', 'x']
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '[ab]'
  let expected = ['[', 'x', 'x', ']']
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '[ab'
  let expected = ['x', 'x', 'x']
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '[\d1234]'
  let expected = ['[', '[\d', ']']
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '[\o123]'
  let expected = ['[', '[\o', ']']
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '[\x12]'
  let expected = ['[', '[\x', ']']
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '[\u1234]'
  let expected = ['[', '[\u', ']']
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '[\U12345678]'
  let expected = ['[', '[\U', ']']
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '[\U123456789]'
  let expected = ['[', '[\U', 'x', ']']
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '[a-b]'
  let expected = ['[', 'a-b', ']']
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '[\%]'
  let expected = ['[', 'x', 'x', ']']
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '\)'
  let expected = ['^^', 'Error: unmatched \)']
  let output = p.parse(input).lines()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_true(has_error, input)

  let input =     'a\zb'
  let expected = ['-^^^', 'Error: invalid character after \z']
  let output = p.parse(input).lines()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_true(has_error, input)

  let input =     '\%['
  let expected = ['^^^', 'Error: missing ] after \%[']
  let output = p.parse(input).lines()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_true(has_error, input)

  let input =     '\%[a*]'
  let expected = ['----^', 'Error: * is not valid inside \%[]']
  let output = p.parse(input).lines()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_true(has_error, input)

  let input =     '\%[\(]'
  let expected = ['---^^', 'Error: \( is not valid inside \%[]']
  let output = p.parse(input).lines()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_true(has_error, input)

  let input =     '.**'
  let expected = ['--^', 'Error: * can not follow a multi']
  let output = p.parse(input).lines()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_true(has_error, input)

  let input =     '\%#=4'
  let expected = ['^^^^^', 'Error: \%#= can only be followed by 0, 1, or 2']
  let output = p.parse(input).lines()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_true(has_error, input)

  let input =     '[b-a]'
  let expected = ['-^^^', 'Error: reverse range in character class']
  let output = p.parse(input).lines()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_true(has_error, input)

  let input =     '\%[]'
  let expected = ['---^', 'Error: empty \%[]']
  let output = p.parse(input).lines()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_true(has_error, input)

  let input =     '\1'
  let expected = ['^^', 'Error: illegal back reference']
  let output = p.parse(input).lines()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_true(has_error, input)

  let input =     '\(\)\2'
  let expected = ['----^^', 'Error: illegal back reference']
  let output = p.parse(input).lines()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_true(has_error, input)

  let input =     '\(\)\(\)\(\)\(\)\(\)\(\)\(\)\(\)\(\)\(\)'
  let expected = ['------------------------------------^^', 'Error: more than 9 capturing groups']
  let output = p.parse(input).lines()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_true(has_error, input)

  let input =     '.\@x'
  let expected = ['-^^^', 'Error: invalid character after \@']
  let output = p.parse(input).lines()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_true(has_error, input)

  let input =     '\_b'
  let expected = ['^^^', 'Error: invalid use of \_']
  let output = p.parse(input).lines()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_true(has_error, input)

  let input =     '\+'
  let expected = ['^^', 'Error: \+ follows nothing']
  let output = p.parse(input).lines()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_true(has_error, input)

  let input =     '\%dx'
  let expected = ['^^^^', 'Error: invalid character after \%d']
  let output = p.parse(input).lines()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_true(has_error, input)

  let input =     '\%g'
  let expected = ['^^^', 'Error: invalid character after \%']
  let output = p.parse(input).lines()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_true(has_error, input)

  let input =     '.\{a}'
  let expected = ['-^^^^', 'Error: syntax error in \{a}']
  let output = p.parse(input).lines()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_true(has_error, input)

  let input =     '\@!'
  let expected = ['^^^', 'Error: \@! follows nothing']
  let output = p.parse(input).lines()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_true(has_error, input)

  let g:relab_debug = 0
  for e in v:errors
    echohl WarningMsg
    echom  'Test failed: '
    echohl Normal
    echon e
  endfor
  let g:relab_debug = debug
endfunction "}}}

command! -nargs=* RELab call RELabSetUp(<q-args>)
command! -nargs=+ DbgRELab call RELabDebug(<args>)

let relab = RELabParser()
call RELabTest()
