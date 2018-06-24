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
  let p = {} " {{{
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

  let p.item_or_eol =
        \{t -> t =~# '\m^\\_[$^.iIkKfFpPsSdDxXoOwWhHaAlLuU]$'}
  let p.incomplete_main =
        \{t -> t =~# '\m^\\\%(@\%(\d*\%(<\?\)\)\|%[<>]\?\%(\d*\|''\)\|_\|#\|{[^}]*\|z\)\?$'}
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
  let p.is_boundary =
        \{t -> t ==# '\zs' || t ==# '\ze'}
  let p.has_underscore =
        \{t -> t =~# '\m^\\_.'}
  let p.is_valid_underscore =
        \{t -> t =~# '\m^\\_[iIkKfFpPsSdDxXoOwWhHaAlLuU^$[.]$'}
  let p.is_invalid_underscore =
        \{t -> t =~# '\m^\\_[^iIkKfFpPsSdDxXoOwWhHaAlLuU^$[.]$'}
  let p.is_coll_range =
        \{t -> t =~# '\m^\%(\\[-^\]\\ebnrt]\|[^\\]\)-\%(\\[-^\]\\ebnrt]\|[^\\]\)$'}
  let p.is_coll_range_id = {t -> t ==? 'a-b'}
  let p.like_code_point =
        \{t -> t =~# '\m^\\%[douUx]'}
  let p.is_code_point =
        \{t -> t =~# '\m^\\%\(d\d\+\|o0\?\o\{1,3}\|x\x\{1,2}\|u\x\{1,4}\|U\x\{1,8}\)$'}
  let p.is_invalid_percent =
        \{t -> t =~# '\m^\\%[^V#^$C]\?$'}
  let p.is_mark =
        \{t -> t =~# '\m^\\%[<>]\?''[a-zA-Z0-9''[\]<>]$'}
  let p.is_lcv =
        \{t -> t =~# '\m^\\%[<>]\?\d*[clv]'}
  let p.is_invalid_z =
        \{t -> t =~# '\m^\\z[^se]\?$'}
  let p.is_case =
        \{t -> t ==? '\c'} " }}}

  " p.id_map {{{
  let p.id_map = {
        \'\|': {'help_tag': '/bar', 'line': 'Alternation, works like a logical OR, matches either the left or right subexpressions.'},
        \'\&': {'help_tag': '/\&', 'line': 'Concatenation, works like a logical AND, matches the subexpression on the righ only if the subexpression on the left also matches.'},
        \'*': {'help_tag': '/star', 'line': 'Matches 0 or more of the preceding atom, as many as possible.'},
        \'\+': {'help_tag': '/\+', 'line': 'Matches 1 or more of the preceding atom, as many as possible.'},
        \'\=': {'help_tag': '/\=', 'line': 'Matches 0 or 1 of the preceding atom, as many as possible.'},
        \'\?': {'help_tag': '/?', 'line': 'Matches 0 or 1 of the preceding atom, as many as possible. Cannot be used when searching backwards with the "?" command.'},
        \'\{n,m}': {'help_tag': '/\{', 'line': 'Matches %s to %s of the preceding atom, as many as possible'},
        \'\{n}': {'help_tag': '/\{', 'line': 'Matches %s of the preceding atom'},
        \'\{n,}': {'help_tag': '/\{', 'line': 'Matches at least %s of the preceding atom, as many as possible'},
        \'\{,m}': {'help_tag': '/\{', 'line': 'Matches 0 to %s of the preceding atom, as many as possible'},
        \'\{}': {'help_tag': '/\{', 'line': 'Matches 0 or more of the preceding atom, as many as possible (like *)'},
        \'\{,}': {'help_tag': '/\{', 'line': 'Matches 0 or more of the preceding atom, as many as possible (like *)'},
        \'\{-n,m}': {'help_tag': '/\{-', 'line': 'Matches %s to %s of the preceding atom, as few as possible'},
        \'\{-n}': {'help_tag': '/\{-', 'line': 'Matches %s of the preceding atom'},
        \'\{-n,}': {'help_tag': '/\{-', 'line': 'Matches at least %s of the preceding atom, as few as possible'},
        \'\{-,m}': {'help_tag': '/\{-', 'line': 'Matches 0 to %s of the preceding atom, as few as possible'},
        \'\{-}': {'help_tag': '/\{-', 'line': 'Matches 0 or more of the preceding atom, as few as possible'},
        \'\{-,}': {'help_tag': '/\{-', 'line': 'Matches 0 or more of the preceding atom, as few as possible'},
        \'\@=': {'help_tag': '/\@=', 'line': 'Matches the preceding atom with zero width.'},
        \'\@!': {'help_tag': '/\@!', 'line': 'Matches with zero width if the preceding atom does NOT match at the current position.'},
        \'\@<=': {'help_tag': '/\@<=', 'line': 'Matches with zero width if the preceding atom matches just before what follows.'},
        \'\@123<=': {'help_tag': '/\@<=', 'line': 'Matches with zero width if the preceding atom matches just before what follows but only look bacl %s bytes.'},
        \'\@<!': {'help_tag': '/\@<!', 'line': 'Matches with zero width if the preceding atom does NOT match just before what follows.'},
        \'\@123<!': {'help_tag': '/\@<!', 'line': 'Matches with zero width if the preceding atom does NOT match just before what follows but only look back %s bytes.'},
        \'\@>': {'help_tag': '/\@>', 'line': 'Matches the preceding atom like matching a whole pattern.'},
        \'^' : {'help_tag': '/^', 'line': 'At beginning of pattern or after "\|", "\(", "\%(" or "\n": matches start-of-line with zero width; at other positions, matches literal ''^''.'},
        \'\_^': {'help_tag': '/\_^', 'line': 'Matches start-of-line. zero-width  Can be used at any position in the pattern.'},
        \'$': {'help_tag': '/$', 'line': 'At end of pattern or in front of "\|", "\)" or "\n" (''magic'' on): matches end-of-line <EOL> with zero width; at other positions, matches literal ''$''.'},
        \'\_$': {'help_tag': '/\_$', 'line': 'Matches end-of-line with zero width. Can be used at any position in the pattern.'},
        \'.': {'help_tag': '/.', 'line': 'Matches any single character, but not an end-of-line.'},
        \'\_.': {'help_tag': '/\_.', 'line': 'Matches any single character or end-of-line.'},
        \'\<': {'help_tag': '/\<', 'line': 'Matches the beginning of a word with zero width: The next char is the first char of a word.  The ''iskeyword'' option specifies what is a word character.'},
        \'\>': {'help_tag': '/\>', 'line': 'Matches the end of a word with zero width: The previous char is the last char of a word.  The ''iskeyword'' option specifies what is a word character.'},
        \'\zs': {'help_tag': '/\zs', 'line': 'Matches at any position with zero width, and sets the start of the match there: The next char is the first char of the whole match.'},
        \'\ze': {'help_tag': '/\ze', 'line': 'Matches at any position with zero width, and sets the end of the match there: The previous char is the last char of the whole match.'},
        \'\%^': {'help_tag': '/\%^', 'line': 'Matches start of the file with zero width.  When matching with a string, matches the start of the string.'},
        \'\%$': {'help_tag': '\%$', 'line': 'Matches end of the file.  When matching with a string, matches the end of the string.'},
        \'\%V': {'help_tag': '/\%V', 'line': 'Match inside the Visual area with zero width. When Visual mode has already been stopped match in the area that gv would reselect.'},
        \'\%#': {'help_tag': '/\%#', 'line': 'Matches with the cursor position with zero width.  Only works when matching in a buffer displayed in a window.'},
        \'\%''m': {'help_tag': '/\%''m', 'line': 'Matches with the position of mark m with zero width.'},
        \'\%<''m': {'help_tag': '/\%<''m', 'line': 'Matches before the position of mark m with zero width.'},
        \'\%>''m': {'help_tag': '/\%>''m', 'line': 'Matches after the position of mark m with zero width.'},
        \'\%l': {'help_tag': '/\%l', 'line': 'Matches in a specific line with zero width.'},
        \'\%<l': {'help_tag': '/\%>l', 'line': 'Matches above a specific line (lower line number) with zero width.'},
        \'\%>l': {'help_tag': '/\%<l', 'line': 'Matches below a specific line (higher line number) with zero width.'},
        \'\%c': {'help_tag': '/\%c', 'line': 'Matches in a specific column with zero width.'},
        \'\%<c': {'help_tag': '/\%>c', 'line': 'Matches before a specific column with zero width.'},
        \'\%>c': {'help_tag': '/\%<c', 'line': 'Matches after a specific column with zero width.'},
        \'\%v': {'help_tag': '/\%v', 'line': 'Matches in a specific virtual column with zero width.'},
        \'\%<v': {'help_tag': '/\%>v', 'line': 'Matches before a specific virtual column with zero width.'},
        \'\%>v': {'help_tag': '/\%<v', 'line': 'Matches after a specific virtual column with zero width.'},
        \'\i': {'help_tag': '/\i', 'line': 'Matches an identifier character (see ''isident'' option)'},
        \'\I': {'help_tag': '/\I', 'line': 'Matches an identifier character, but excluding digits'},
        \'\k': {'help_tag': '/\k', 'line': 'Matches a keyword character (see ''iskeyword'' option)'},
        \'\K': {'help_tag': '/\K', 'line': 'Matches a keyword character, but excluding digits'},
        \'\f': {'help_tag': '/\f', 'line': 'Matches a file name character (see ''isfname'' option)'},
        \'\F': {'help_tag': '/\F', 'line': 'Matches a file name character, but excluding digits'},
        \'\p': {'help_tag': '/\p', 'line': 'Matches a printable character (see ''isprint'' option)'},
        \'\P': {'help_tag': '/\P', 'line': 'Matches a printable character, but excluding digits'},
        \'\s': {'help_tag': '/\s', 'line': 'Matches a whitespace character: <Space> and <Tab>'},
        \'\S': {'help_tag': '/\S', 'line': 'Matches a non-whitespace character; opposite of \s'},
        \'\d': {'help_tag': '/\d', 'line': 'Matches a digit: [0-9]'},
        \'\D': {'help_tag': '/\D', 'line': 'Matches a non-digit: [^0-9]'},
        \'\x': {'help_tag': '/\x', 'line': 'Matches a hex digit: [0-9A-Fa-f]'},
        \'\X': {'help_tag': '/\X', 'line': 'Matches a non-hex digit: [^0-9A-Fa-f]'},
        \'\o': {'help_tag': '/\o', 'line': 'Matches an octal digit: [0-7]'},
        \'\O': {'help_tag': '/\O', 'line': 'Matches a non-octal digit: [^0-7]'},
        \'\w': {'help_tag': '/\w', 'line': 'Matches a word character: [0-9A-Za-z_]'},
        \'\W': {'help_tag': '/\W', 'line': 'Matches a non-word character: [^0-9A-Za-z_]'},
        \'\h': {'help_tag': '/\h', 'line': 'Matches a head of word character: [A-Za-z_]'},
        \'\H': {'help_tag': '/\H', 'line': 'Matches a non-head of word character: [^A-Za-z_]'},
        \'\a': {'help_tag': '/\a', 'line': 'Matches an alphabetic character: [A-Za-z]'},
        \'\A': {'help_tag': '/\A', 'line': 'Matches a non-alphabetic character: [^A-Za-z]'},
        \'\l': {'help_tag': '/\l', 'line': 'Matches a lowercase character: [a-z]'},
        \'\L': {'help_tag': '/\L', 'line': 'Matches a non-lowercase character: [^a-z]'},
        \'\u': {'help_tag': '/\u', 'line': 'Matches an uppercase character: [A-Z]'},
        \'\U': {'help_tag': '/\U', 'line': 'Matches a non-uppercase character: [^A-Z]'},
        \'\_i': {'help_tag': '/\i', 'line': 'Matches an identifier character (see ''isident'' option) or a newline (like \n)'},
        \'\_I': {'help_tag': '/\I', 'line': 'Matches an identifier character, but excluding digits or a newline (like \n)'},
        \'\_k': {'help_tag': '/\k', 'line': 'Matches a keyword character (see ''iskeyword'' option) or a newline (like \n)'},
        \'\_K': {'help_tag': '/\K', 'line': 'Matches a keyword character, but excluding digits or a newline (like \n)'},
        \'\_f': {'help_tag': '/\f', 'line': 'Matches a file name character (see ''isfname'' option) or a newline (like \n)'},
        \'\_F': {'help_tag': '/\F', 'line': 'Matches a file name character, but excluding digits or a newline (like \n)'},
        \'\_p': {'help_tag': '/\p', 'line': 'Matches a printable character (see ''isprint'' option) or a newline (like \n)'},
        \'\_P': {'help_tag': '/\P', 'line': 'Matches a printable character, but excluding digits or a newline (like \n)'},
        \'\_s': {'help_tag': '/\s', 'line': 'Matches a whitespace character: <Space> and <Tab> or a newline (like \n)'},
        \'\_S': {'help_tag': '/\S', 'line': 'Matches a non-whitespace character; opposite of \s or a newline (like \n)'},
        \'\_d': {'help_tag': '/\d', 'line': 'Matches a digit: [0-9] or a newline (like \n)'},
        \'\_D': {'help_tag': '/\D', 'line': 'Matches a non-digit: [^0-9] or a newline (like \n)'},
        \'\_x': {'help_tag': '/\x', 'line': 'Matches a hex digit: [0-9A-Fa-f] or a newline (like \n)'},
        \'\_X': {'help_tag': '/\X', 'line': 'Matches a non-hex digit: [^0-9A-Fa-f] or a newline (like \n)'},
        \'\_o': {'help_tag': '/\o', 'line': 'Matches an octal digit: [0-7] or a newline (like \n)'},
        \'\_O': {'help_tag': '/\O', 'line': 'Matches a non-octal digit: [^0-7] or a newline (like \n)'},
        \'\_w': {'help_tag': '/\w', 'line': 'Matches a word character: [0-9A-Za-z_] or a newline (like \n)'},
        \'\_W': {'help_tag': '/\W', 'line': 'Matches a non-word character: [^0-9A-Za-z_] or a newline (like \n)'},
        \'\_h': {'help_tag': '/\h', 'line': 'Matches a head of word character: [A-Za-z_] or a newline (like \n)'},
        \'\_H': {'help_tag': '/\H', 'line': 'Matches a non-head of word character: [^A-Za-z_] or a newline (like \n)'},
        \'\_a': {'help_tag': '/\a', 'line': 'Matches an alphabetic character: [A-Za-z] or a newline (like \n)'},
        \'\_A': {'help_tag': '/\A', 'line': 'Matches a non-alphabetic character: [^A-Za-z] or a newline (like \n)'},
        \'\_l': {'help_tag': '/\l', 'line': 'Matches a lowercase character: [a-z] or a newline (like \n)'},
        \'\_L': {'help_tag': '/\L', 'line': 'Matches a non-lowercase character: [^a-z] or a newline (like \n)'},
        \'\_u': {'help_tag': '/\u', 'line': 'Matches an uppercase character: [A-Z] or a newline (like \n)'},
        \'\_U': {'help_tag': '/\U', 'line': 'Matches a non-uppercase character: [^A-Z] or a newline (like \n)'},
        \'~': {'help_tag': '/\~', 'line': 'Matches the last given substitute string.'},
        \'\(': {'help_tag': '/\(', 'line': 'Start a pattern enclosed by escaped parentheses.'},
        \'\)': {'help_tag': '/\)', 'line': 'End a pattern enclosed by escaped parentheses.'},
        \'\1': {'help_tag': '/\1', 'line': 'Matches the same string that was matched by the first sub-expression in \( and \).'},
        \'\2': {'help_tag': '/\2', 'line': 'Matches the same string that was matched by the second sub-expression in \( and \).'},
        \'\3': {'help_tag': '/\3', 'line': 'Matches the same string that was matched by the third sub-expression in \( and \).'},
        \'\4': {'help_tag': '/\4', 'line': 'Matches the same string that was matched by the fourth sub-expression in \( and \).'},
        \'\5': {'help_tag': '/\5', 'line': 'Matches the same string that was matched by the fifth sub-expression in \( and \).'},
        \'\6': {'help_tag': '/\6', 'line': 'Matches the same string that was matched by the sixth sub-expression in \( and \).'},
        \'\7': {'help_tag': '/\7', 'line': 'Matches the same string that was matched by the seventh sub-expression in \( and \).'},
        \'\8': {'help_tag': '/\8', 'line': 'Matches the same string that was matched by the eighth sub-expression in \( and \).'},
        \'\9': {'help_tag': '/\9', 'line': 'Matches the same string that was matched by the ninth sub-expression in \( and \).'},
        \'\%(': {'help_tag': '/\%(', 'line': 'Start a pattern enclosed by escaped parentheses.  Just like \(\), but without counting it as a sub-expression.'},
        \'\%[': {'help_tag': '/\%[]', 'line': 'A sequence of optionally matched atoms.  This always matches.'},
        \'\%]': {'help_tag': '/\%[]', 'line': 'Ends optional group'},
        \'[': {'help_tag': '/[]', 'line': 'This is a sequence of characters enclosed in brackets. It matches any single character in the collection.'},
        \']': {'help_tag': '/[]', 'line': 'Ends the collection'},
        \'\_[': {'help_tag': '/\_[]', 'line': 'This is a sequence of characters enclosed in brackets. It matches any single character in the collection.  With "\_" prepended the collection also includes the end-of-line.'},
        \'[^': {'help_tag': 'E944', 'line': 'If the sequence begins with "^", it matches any single character NOT in the collection: "[^xyz]" matches anything but ''x'', ''y'' and ''z''.'},
        \'A-B': {'help_tag': 'E944', 'line': 'Matches a character in the range from %s (code %s) to %s code(%s)'},
        \'a-b': {'help_tag': 'E944', 'line': 'Matches a character in the range from %s (code %s) to %s code(%s) or in the range from %s (code %s) to %s code(%s)'},
        \'[:alnum:]': {'help_tag': '[:alnum:]', 'line': 'Matches ASCII letters and digits'},
        \'[:alpha:]': {'help_tag': '[:alpha:]', 'line': 'Matches ASCII letters'},
        \'[:blank:]': {'help_tag': '[:blank:]', 'line': 'Matches space and tab'},
        \'[:cntrl:]': {'help_tag': '[:cntrl:]', 'line': 'Matches ASCII control characters'},
        \'[:digit:]': {'help_tag': '[:digit:]', 'line': 'Matches decimal digits ''0'' to ''9'''},
        \'[:graph:]': {'help_tag': '[:graph:]', 'line': 'Matches ASCII printable characters excluding space'},
        \'[:lower:]': {'help_tag': '[:lower:]', 'line': 'Matches lowercase letters (all letters when ''ignorecase'' is used)'},
        \'[:print:]': {'help_tag': '[:print:]', 'line': 'Matches printable characters including space'},
        \'[:punct:]': {'help_tag': '[:punct:]', 'line': 'Matches ASCII punctuation characters'},
        \'[:space:]': {'help_tag': '[:space:]', 'line': 'Matches whitespace characters: space, tab, CR, NL, vertical tab, form feed'},
        \'[:upper:]': {'help_tag': '[:upper:]', 'line': 'Matches uppercase letters (all letters when ''ignorecase'' is used)'},
        \'[:xdigit:]': {'help_tag': '[:xdigit:]', 'line': 'Matches hexadecimal digits: 0-9, a-f, A-F'},
        \'[:return:]': {'help_tag': '[:return:]', 'line': 'Matches the <CR> character'},
        \'[:tab:]': {'help_tag': '[:tab:]', 'line': 'Matches the <Tab> character'},
        \'[:escape:]': {'help_tag': '[:escape:]', 'line': 'Matches the <Esc> character'},
        \'[:backspace:]': {'help_tag': '[:backspace:]', 'line': 'Matches the <BS> character'},
        \'[==]': {'help_tag': '[==]', 'line': 'An equivalence class.  This means that characters are matched that have almost the same meaning, e.g., when ignoring accents.  This only works for Unicode, latin1 and latin9.  The form is: [=a=]'},
        \'[..]': {'help_tag': '[..]', 'line': 'A collation element.  This currently simply accepts a single character in the form: [.a.]'},
        \'\n': {'help_tag': '/\]', 'line': 'Matches an end-of-line'},
        \'[\d': {'help_tag': '/\]', 'line': 'Matches the character "%s" as specified with the decimal number %s. Must be followed by a non-digit.'},
        \'[\o': {'help_tag': '/\]', 'line': 'Matches the character "%s" as specified with the octal number %s. Numbers can be up to 0377. Numbers below 040 must be followed by a non-octal digit or a non-digit.'},
        \'[\x': {'help_tag': '/\]', 'line': 'Matches the character "%s" as specified with the hexadecimal nuber %s. Takes up to two hexadecimal characters.'},
        \'[\u': {'help_tag': '/\]', 'line': 'Matches the character "%s" as specified with the hexadecimal number %s. Takes up to four hexadecimal characters.'},
        \'[\U': {'help_tag': '/\]', 'line': 'Matches the character "%s" as specified with the hexadecimal number %s. Takes up to eight hexadecimal characters.'},
        \'[\di': {'help_tag': '/\]', 'line': 'Matches the character "%s" as specified with the decimal number %s or the character "%s". Must be followed by a non-digit.'},
        \'[\oi': {'help_tag': '/\]', 'line': 'Matches the character "%s" as specified with the octal number %s or the character "%s". Numbers can be up to 0377. Numbers below 040 must be followed by a non-octal digit or a non-digit.'},
        \'[\xi': {'help_tag': '/\]', 'line': 'Matches the character "%s" as specified with the hexadecimal nuber %s or the character "%s". Takes up to two hexadecimal characters.'},
        \'[\ui': {'help_tag': '/\]', 'line': 'Matches the character "%s" as specified with the hexadecimal number %s or the character "%s". Takes up to four hexadecimal characters.'},
        \'[\Ui': {'help_tag': '/\]', 'line': 'Matches the character "%s" as specified with the hexadecimal number %s or the character "%s". Takes up to eight hexadecimal characters.'},
        \'\%d': {'help_tag': '/\%d', 'line': 'Matches the character "%s" as specified with the decimal number %s. Must be followed by a non-digit.'},
        \'\%o': {'help_tag': '/\%o', 'line': 'Matches the character "%s" as specified with the octal number %s. Numbers can be up to 0377. Numbers below 040 must be followed by a non-octal digit or a non-digit.'},
        \'\%x': {'help_tag': '/\%x', 'line': 'Matches the character "%s" as specified with the hexadecimal nuber %s. Takes up to two hexadecimal characters.'},
        \'\%u': {'help_tag': '/\%u', 'line': 'Matches the character "%s" as specified with the hexadecimal number %s. Takes up to four hexadecimal characters.'},
        \'\%U': {'help_tag': '/\%U' ,'line': 'Matches the character "%s" as specified with the hexadecimal number %s. Takes up to eight hexadecimal characters.'},
        \'\%di': {'help_tag': '/\%d', 'line': 'Matches the character "%s" as specified with the decimal number %s or the character "%s". Must be followed by a non-digit.'},
        \'\%oi': {'help_tag': '/\%o', 'line': 'Matches the character "%s" as specified with the octal number %s or the character "%s". Numbers can be up to 0377. Numbers below 040 must be followed by a non-octal digit or a non-digit.'},
        \'\%xi': {'help_tag': '/\%x', 'line': 'Matches the character "%s" as specified with the hexadecimal nuber %s or the character "%s". Takes up to two hexadecimal characters.'},
        \'\%ui': {'help_tag': '/\%u', 'line': 'Matches the character "%s" as specified with the hexadecimal number %s or the character "%s". Takes up to four hexadecimal characters.'},
        \'\%Ui': {'help_tag': '/\%U' ,'line': 'Matches the character "%s" as specified with the hexadecimal number %s or the character "%s". Takes up to eight hexadecimal characters.'},
        \'\c': {'help_tag': '/\c', 'line': 'When "\c" appears anywhere in the pattern, the whole pattern is handled like ''ignorecase'' is on.  The actual value of ''ignorecase'' and ''smartcase'' is ignored.'},
        \'\C': {'help_tag': '/\C', 'line': 'When "\C" appears anywhere in the pattern, the whole pattern is handled like ''ignorecase'' is off  The actual value of ''ignorecase'' and ''smartcase'' is ignored.'},
        \'\Z': {'help_tag': '/\Z', 'line': 'When "\Z" appears anywhere in the pattern, all composing characters are ignored.'},
        \'\%C': {'help_tag': '/\%C', 'line': 'Use "\%C" to skip any composing characters.'},
        \'\m': {'help_tag': '/\m', 'line': '''magic'' on for the following chars in the pattern'},
        \'\M': {'help_tag': '/\M', 'line': '''magic'' off for the following chars in the pattern'},
        \'\v': {'help_tag': '/\v', 'line': 'the following chars in the pattern are "very magic"'},
        \'\V': {'help_tag': '/\V', 'line': 'the following chars in the pattern are "very nomagic"'},
        \'\%#=': {'help_tag': '/\%#=', 'line': 'select regexp engine'},
        \'x': {'help_tag': '/\%#=', 'line': 'Matches the character "%s" (code %s) or character "%s" (code %s)'},
        \'X': {'help_tag': '/\%#=', 'line': 'Matches the character "%s" (code %s)'},
        \} "}}}

  function! p.follows_nothing(node) "{{{
    return empty(a:node.previous) || self.is_branch(a:node.previous.id)
          \|| self.is_look_around(a:node.previous.id)
  endfunction "}}}

  function! p.init(...) "{{{
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

    let r = {}
    let r.value = 'root'
    let r.id = 'root'
    let r.magicness = self.magicness
    let r.capt_groups = self.capt_groups
    let r.is_capt_group = 0
    let r.ignorecase = self.ignorecase
    let r.parent = {}
    let r.siblings = []
    let r.children = []
    let r.help = 'pattern'
    let r.level = 0

    let self.root = r
    let self.parent = self.root
    return self
  endfunction "}}}

  function! p.node2magic(node) "{{{
    if a:node.magicness ==# 'M'
      if a:node.value =~# '\m^\\[.*~[]$'
        return a:node.value[1:]
      elseif a:node.value =~# '\m^[.*~[]$'
        return '\' . a:node.value
      endif
    elseif a:node.magicness ==# 'v'
      if a:node.value =~# '\m^[+?{()@%<>=]'
        return '\' . a:node.value
      elseif a:node.value =~# '\m^\\[+?{()@%<>=]'
        return a:node.value[1:]
      endif
    elseif a:node.magicness ==# 'V'
      if a:node.value =~# '\m^\\[[.*~^$]$'
        return a:node.value[1:]
      elseif a:node.value =~# '\m^[[.*~^$]$'
        return '\' . a:node.value
      endif
    endif
    return a:node.value
  endfunction "}}}

  function! p.new_child() "{{{
    let n = copy(self.parent)
    let n.is_error = 0
    let n.error = []
    let n.magicness = self.magicness
    let n.ignorecase = self.ignorecase
    let n.parent = self.parent
    let n.siblings = self.parent.children
    let n.children = []
    let n.previous = get(self.parent.children, -1, {})
    let n.next = {}
    let n.value = self.token
    let n.magic = self.node2magic(n)
    let n.id = self.to_id(n.magic)
    let n.level += 1
    let n.line = ''
    let n.pos = self.pos - strchars(self.token)
    if !empty(n.previous)
      let n.previous.next = n
    endif
    call add(self.parent.children, n)
    call add(self.sequence, n)
    return n
  endfunction "}}}

  function! p.to_id(text) "{{{
    DbgRELab printf('to_id: %s', a:text)
    let text = self.node2magic({'value': a:text, 'magicness': self.magicness})
    if self.in_collection
        DbgRELab printf('to_id -> collection')
      if a:text =~# '\m^\\[doxuU]'
        DbgRELab printf('to_id -> collection -> code point')
        " /[\x]
        return substitute(a:text, '\m^\(\\.\).\+', '[\1', '')
      elseif self.is_coll_range(a:text)
        DbgRELab printf('to_id -> collection -> range')
        " /[a-z]
        return self.ignorecase ? 'a-b' : 'A-B'
      elseif a:text =~# '\m^\[[.=].[.=]\]$'
        DbgRELab printf('to_id -> collection -> collation/equivalence')
        " /[[.a.][=a=]]
        return substitute(a:text, '\m^\(\[[.=]\).[.=]\]$', '[\1\1]', '')
      endif
    elseif text =~# '\m^\\%[<>]\?\d\+[lvc]$'
      DbgRELab printf('to_id -> lcv')
      " /\%23l
      return substitute(a:text, '\m\d\+', '', '')
    elseif text =~# '\m^\\%[<>]\?''.$'
      DbgRELab printf('to_id -> mark')
      " /\%'m
      return substitute(a:text, '.$', 'm', '')
    elseif text =~# '\m^\\{'
      " /.\{}
      let id = '\{'
      let id .= text =~# '\m^\\{-' ? '-' : ''
      let id .= text =~# '\m^\\{-\?\d' ? 'n' : ''
      let id .= text =~# '\m^\\{-\?\d*,' ? ',' : ''
      let id .= text =~# '\m^\\{-\?\d*,\d' ? 'm' : ''
      let id .= '}'
      return id
    elseif text =~# '\m^\\%[doxuU]\d\+$'
      " /\%d123
      return matchstr(a:text, '\m\C^\\%[doxuU]')
    elseif a:text =~# '\m^\\%#=.\?'
      " regexp engine
      return '\%#='
    elseif self.is_look_around(text)
      return substitute(a:text, '\d\+', '123', '')
    endif
    return a:text
  endfunction "}}}

  function! p.help_tag(node) "{{{
    return get(get(self.id_map, a:node.id, {}), 'help_tag', '')
  endfunction "}}}

  function! p.line(node, ...) "{{{
    let id = a:node.id
    DbgRELab printf('line: %s', id)
    let line = get(self.id_map, id,
          \{'line': 'ERROR: contact this plugin''s author'}).line
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
      elseif a:node.value ==# '\r'
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
              \{'line': 'ERROR: contact this plugin''s author'}).line
        let line = printf(line, char, code)
      else
        DbgRELab 'line -> literal -> ignore case'
        let line = printf(line, tolower(char), char2nr(tolower(char)),
              \toupper(char), char2nr(toupper(char)))
      endif
    elseif id ==# 'A-B'
      DbgRELab 'line -> range match case'
      let line = printf(line, a:node.first, char2nr(a:node.first), a:node.second,
            \char2nr(a:node.second))
    elseif id ==# 'a-b'
      DbgRELab 'line -> range ignore case'
      let line = printf(line,
            \tolower(a:node.first), char2nr(tolower(a:node.first)),
            \tolower(a:node.second), char2nr(tolower(a:node.second)),
            \toupper(a:node.first), char2nr(toupper(a:node.first)),
            \toupper(a:node.second), char2nr(toupper(a:node.second))
            \)
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
      let code_map = {'d': '%s', 'o': '0%s', 'x': '0x%s', 'u': '0x%s', 'U': '0x%s'}
      let key = matchstr(id, '\m^\%(\[\\\|\\%\)\zs.')
      DbgRELab printf('line -> code point: magicness: %s, key: %s',
            \a:node.magic, key)
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
              \{'line': 'ERROR: contact this plugin''s author'}).line
        let line = printf(line, char, code, char2)
      else
        DbgRELab 'line -> code point -> match case'
        let line = printf(line, char, code)
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

  function! p.lines() "{{{
    let lines = []
    if !empty(self.errors)
      return extend(lines, self.errors[0].error)
    endif
    call add(lines, '')
    return extend(lines, map(copy(self.sequence), 'v:val.line'))
  endfunction "}}}

  function! p.match_group(offset, ...) "{{{
    DbgRELab printf('match group: offset: %s, group: %s, regexp: %s', a:offset, (a:0 ? a:1 : 'all'), self.input)
    if self.capt_groups < get(a:, 1, 0)
      DbgRELab printf('match group: arg > available groups')
      let items = []
    elseif get(a:, 1, 0) > 9
      DbgRELab printf('match group: arg > 9')
      let items = []
    else
      " TODO Need to find an approach that considers \zs and \ze inside the group
      " like in 'abc\(de\zefg\|hij\)jkl'
      DbgRELab printf('match group: arg > 0')
      let items = ['\m\C']
      if a:offset
        call add(items, printf('\%%>%sl', a:offset))
      endif
      DbgRELab printf('match group: capt_groups: %s', map(copy(self.sequence), 'get(v:val, ''capt_groups'', 0)'))
      for node in self.sequence
        DbgRELab printf('match group: node.magic: %s', node.magic)
        if self.is_branch(node.id)
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
        elseif self.starts_capt_group(node.id)
          DbgRELab printf('match group -> starts_capt_group:')
          call add(items, node.magic)
          if a:0 && node.capt_groups == a:1
            DbgRELab printf('match group -> starts_capt_group -> add \zs:')
            call add(items, '\zs')
          endif
        elseif self.ends_capt_group(node.id)
          DbgRELab printf('match group -> ends_capt_group:')
          if a:0 && node.capt_groups == a:1 && node.is_capt_group
            DbgRELab printf('match group -> ends_capt_group -> add \ze:')
            call add(items, '\ze')
          endif
          call add(items, node.magic)
        elseif self.is_boundary(node.id)
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
        elseif node.id ==# '\%^'
          DbgRELab printf('match group -> is_bof:')
          if a:offset
            call add(items, printf('\%%%sl\_^', a:offset))
          else
            call add(items, node.magic)
          endif
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

  function! p.match_groups(...) "{{{
    DbgRELab printf('match group: regexp: %s', self.input)
    let offset = get(a:, 1, 0)
    let groups = []
    call add(groups, self.match_group(offset))
    for group in range(0, self.capt_groups)
      call add(groups, self.match_group(offset, group))
    endfor
    return filter(groups, '!empty(v:val)')
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

  function! p.map(key) "{{{
    return map(copy(self.sequence), 'get(v:val, a:key, '''')')
  endfunction "}}}

  function! p.magics() "{{{
    return map(copy(self.sequence), 'v:val.magic')
  endfunction "}}}

  function! p.values() "{{{
    return map(copy(self.sequence), 'get(v:val, ''value'', '''')')
  endfunction "}}}

  function! p.ids() "{{{
    return map(copy(self.sequence), 'get(v:val, ''id'', '''')')
  endfunction "}}}

  function! p.collection_ends() "{{{
    let ahead = strcharpart(self.input, self.pos)
    if ahead[0] ==# '^'
      return ahead =~# '\m^\^\%(\\[-ebrtndoxuU^$\]]\|[^\]]\)\+]'
    else
      return ahead =~# '\m^\%(\\[-ebrtndoxuU^$\]]\|[^\]]\)\+]'
    endif
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

  function! p.incomplete_in_collection() "{{{
    let next = self.token . strcharpart(self.input, self.pos)
    let ahead = strcharpart(self.input, self.pos, 1)
    if empty(self.parent.children) && self.token ==# '^'
      DbgRELab printf('is_incomplete_in_collection -> negate: %s', next)
      return 0
    elseif self.token =~# '\m^\%(\\[\\ebnrt]\|[^\\]\)-\%(\\[\\ebnrt]\|[^\\]\)$'
      DbgRELab printf('is_incomplete_in_collection -> range done: %s', next)
      return 0
    elseif next =~# '\m^\%(\\[\\enbrt]\|[^\\]\)-\%(\\[\\ebnrt]\|[^\\]\)'
      DbgRELab printf('is_incomplete_in_collection -> range coming: %s', next)
      return 1
    elseif self.token =~# '\m^\\[-\\ebnrt\]^]$'
      DbgRELab printf('is_incomplete_in_collection -> escaped done: %s', next)
      return 0
    elseif self.token ==# '\' && ahead =~# '\m^[-\\ebnrtdoxuU\]^]$'
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

  function! p.is_incomplete() "{{{
    DbgRELab printf('is_incomplete')
    if self.in_collection
      return self.incomplete_in_collection()
    endif
    let token = self.node2magic({'value': self.token, 'magicness': self.magicness})
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
    DbgRELab printf('')
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

      elseif self.in_collection && self.is_coll_range_id(node.id) "{{{
        DbgRELab printf('parse -> collection -> range')
        if node.value[0] ==# '\'
          let node.first = strcharpart(node.value, 0, 2)
          let node.second = strcharpart(node.value, 3)
        else
          let node.first = strcharpart(node.value, 0, 1)
          let node.second = strcharpart(node.value, 2)
        endif
        let dict = {'\e': "\e", '\b': "\b", '\n': "\n", '\r': "\r", '\t': "\t",
              \'\\': '\', '\]': ']', '\^': '^', '\-': '-'}
        let node.first = get(dict, node.first, node.first)
        DbgRELab printf('parse -> collection -> range: first: %s, second: %s', node.first, node.second)
        let node.second = get(dict, node.second, node.second)
        if node.first ># node.second
          let errormessage = 'reverse range in character class'
          call self.add_error(node, errormessage)
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

      elseif self.is_branch(node.id) "{{{
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
          if self.collection_ends()
            " The collection is terminated by a ']', so treat this as the
            " start of the collection
            let self.in_collection = 1
          else
            " Treat this as a literal character
            call remove(self.nest_stack, -1)
            let node.id = node.ignorecase ? 'x' : 'X'
          endif
        elseif self.starts_capt_group(node.id)
          DbgRELab  printf('parse -> starts group -> capturing group')
          let self.capt_groups += 1
          let node.capt_groups = self.capt_groups
          let node.is_capt_group = 1
          DbgRELab  printf('parse -> starts group -> capturing group: node.capt_groups: %s', node.capt_groups)
          if self.capt_groups > 9
            let errormessage = 'more than 9 capturing groups'
            call self.add_error(node, errormessage)
          endif
        else
          DbgRELab  printf('parse -> starts group -> non capturing group')
          let node.is_capt_group = 0
        endif
        "}}}

      elseif self.ends_group(node.id) "{{{
        DbgRELab  printf('parse -> ends group')
        if self.is_paired(node.id)
          DbgRELab  printf('parse -> ends group -> is paired')
          call remove(self.nest_stack, -1)
          let self.parent = node.parent.parent
          let node.level -= 1
          if self.ends_opt_group(node.id)
            DbgRELab  printf('parse -> ends group -> is paired -> opt group')
            if empty(node.previous)
              let errormessage = printf('empty %s%s', node.parent.value, node.value)
              call self.add_error(node, errormessage)
            else
              let node.id = '\%]'
            endif
          else
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

      elseif self.has_underscore(node.id) "{{{
        DbgRELab  printf('parse -> has underscore')
        if self.is_valid_underscore(node.id)
          DbgRELab  printf('parse -> has underscore -> valid')
        elseif self.is_invalid_underscore(node.id)
          DbgRELab  printf('parse -> has underscore -> invalid')
          let char = strcharpart(node.magic, 2)
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
            let node.min = matchstr(node.value, '\m\\{-\?\zs\d*')
            let node.max = matchstr(node.value, '\m\\{-\?\d*,\zs\d*')
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
                \(node.magicness ==# 'v' ? '@' : '\@'))
          call self.add_error(node, errormessage)
        endif
        "}}}

      elseif self.like_code_point(node.id) "{{{
        DbgRELab  printf('parse -> like code point: magicness: %s', node.magic)
        if self.is_code_point(node.magic)
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

      elseif self.is_case(node.id) "{{{
        let self.ignorecase = node.id ==# '\c'
        DbgRELab  printf('parse -> case: %s', self.ignorecase)
        "}}}

      elseif self.is_magic(node.id) "{{{
        DbgRELab  printf('parse -> magicness')
        let self.magicness = node.id[1]
        "}}}

      elseif node.value !=? 'x' && has_key(self.id_map, node.id) "{{{
        DbgRELab  printf('parse -> has_key')
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
  DbgRELab printf('OnTextChange:')
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
        \'v:val.id')
    DbgRELab printf('OnTextChange: id: %s', id)
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
    DbgRELab printf('OnTextChange: error:')
    let node = g:relab.errors[0]
    let errorpattern = printf('\%%1l\%%%sv%s', node.pos + 1, repeat('.', strchars(node.value)))
    execute printf('syn match relabError /%s/ containedin=ALL', escape(errorpattern, '/'))
  else
    DbgRELab printf('OnTextChange: matches:')
    let offset = len(lines) + 1
    let group_list = g:relab.match_groups(offset)
    DbgRELab printf('OnTextChange -> matches: match_list: %s', group_list)
    for i in range(len(group_list))
      if i == 0
        DbgRELab printf('OnTextChange -> matches -> Group All: pattern: %s', group_list[i])
        let syn_template =
              \'syn match relabGroupMatchAll /%s/ containedin=relabReport keepend'
        execute printf(syn_template, group_list[i])
      elseif i == 1
        DbgRELab printf('OnTextChange -> matches -> Group 0: pattern: %s', group_list[i])
        let syn_template =
              \'syn match relabGroupMatch0 /%s/ containedin=relabGroupMatchAll keepend'
        execute printf(syn_template, group_list[i])
      else
        DbgRELab printf('OnTextChange -> matches -> Group %s: pattern: %s', i - 1, group_list[i])
        let syn_template =
              \'syn match relabGroupMatch%s /%s/ containedin=relabGroupMatch%s keepend'
        execute printf(syn_template, i - 1, group_list[i], i - 2)
      endif
    endfor
  endif
  let &lazyredraw = lazyredraw
  let time = reltimestr(reltime(time1, reltime()))
  echom printf('Time for %s in line %s is %s', pattern, line('.'), time)
endfunction "}}}

function! RELabDebug(msg) "{{{
  if get(g:, 'relab_debug', 0)
    echom printf('RELab: %s', a:msg)
  endif
endfunction "}}}

function! RELabSetUp(regexp) range "{{{
  let regexp = empty(a:regexp) ? @/ : a:regexp
  let sample = getline(a:firstline, a:lastline)
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
  endif
  "if !exists(s:bufnr)
    let s:bufnr = bufnr('%')
    setlocal filetype=relab buftype=nofile noundofile noswapfile 
    augroup RELab
      autocmd!
      autocmd TextChanged,TextChangedI <buffer> call RELabOnTextChange()
      "autocmd BufWinLeave,WinLeave <buffer> let @/ = getline(1)
    augroup END
  "endif
  let lines = [regexp, '', '^^^^^^^^^^ Sample text goes under this line ^^^^^^^^^^']
  let lines += sample
  call setline(1, lines)
endfunction "}}}

function! RELabTest(...) abort "{{{
  let debug = get(g:, 'relab_debug', 0)
  let g:relab_debug = get(a:, 1, 0)

  let p = RELabParser()

  let v:errors = []

  let input =     ''
  let expected = []
  let output = p.parse(input).magics()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '^'
  let expected = ['^']
  let output = p.parse(input).magics()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '^a\+'
  let expected = ['^', 'a', '\+']
  let output = p.parse(input).magics()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '^a\+\vb+'
  let expected = ['^', 'a', '\+', '\v', 'b', '\+']
  let output = p.parse(input).magics()
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
  let expected = ['\%x', 'X', 'X']
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '\%o1234'
  let expected = ['\%o', 'X']
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
  let expected = ['\%o', 'X']
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '\%o0400'
  let expected = ['\%o', 'X']
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
  let expected = ['X', '\@>']
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
  let expected = ['X', '\zs', 'X']
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     'a\zeb'
  let expected = ['X', '\ze', 'X']
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '[ab]'
  let expected = ['[', 'X', 'X', ']']
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '[ab'
  let expected = ['X', 'X', 'X']
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
  let expected = ['[', '[\U', 'X', ']']
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '[a-b]'
  let expected = ['[', 'A-B', ']']
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '[\%]'
  let expected = ['[', 'X', 'X', ']']
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '\V%[a]'
  let expected = ['\V', 'X', 'X', 'X', 'X']
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '\V\%[a]'
  let expected = ['\V', '\%[', 'X', '\%]']
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '[^a]'
  let expected = ['[', '[^', 'X', ']']
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '[^-a]'
  let expected = ['[', '[^', 'X', 'X', ']']
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '[-a]'
  let expected = ['[', 'X', 'X', ']']
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '[^]'
  let expected = ['X', '^', 'X']
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '[]'
  let expected = ['X', 'X']
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '[^-]'
  let expected = ['[', '[^', 'X', ']']
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '^^'
  let expected = ['^', '^']
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '^^\|^^'
  let expected = ['^', '^', '\|', '^', '^']
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '.\@4321<='
  let expected = ['.', '\@123<=']
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '.\@4321<!'
  let expected = ['.', '\@123<!']
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '\%''k'
  let expected = ['\%''m']
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '\%4321l'
  let expected = ['\%l']
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '\%4321c'
  let expected = ['\%c']
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '\%4321v'
  let expected = ['\%v']
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '\%<''k'
  let expected = ['\%<''m']
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '\%<4321l'
  let expected = ['\%<l']
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '\%<4321c'
  let expected = ['\%<c']
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '\%<4321v'
  let expected = ['\%<v']
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '\%>''k'
  let expected = ['\%>''m']
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '\%>4321l'
  let expected = ['\%>l']
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '\%>4321c'
  let expected = ['\%>c']
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '\%>4321v'
  let expected = ['\%>v']
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '[\\e]'
  let expected = ['[', '\\', 'e', ']']
  let output = p.parse(input).values()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '[\\a]'
  let expected = ['[', 'X', 'X', ']']
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '[\\x ]'
  let expected = ['[', 'X', 'X', 'X', ']']
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     'a\cb'
  let expected = ['X', '\c', 'x']
  let output = p.parse(input).ids()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_false(has_error, input)

  let input =     '\%'
  let expected = ['^^', 'Error: invalid character after \%']
  let output = p.parse(input).lines()
  call assert_equal(expected, output, input)
  let has_error = !empty(p.errors)
  call assert_true(has_error, input)

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

  let input =    '\s\+.*'
  let expected = '\m\C\s\+.*'
  let output = p.parse(input).match_group(0)
  call assert_equal(expected, output, input)
  "let has_error = !empty(p.errors)
  "call assert_true(has_error, input)

  let input =    'abc\(def\|ghi\)jkl'
  let expected = '\m\Cabc\(def\|ghi\)jkl'
  let output = p.parse(input).match_group(0)
  call assert_equal(expected, output, input)
  "let has_error = !empty(p.errors)
  "call assert_true(has_error, input)

  let input =    'abc\(def\|ghi\)jkl'
  let expected = '\m\Cabc\(def\|ghi\)jkl'
  let output = p.parse(input).match_group(0, 0)
  call assert_equal(expected, output, input)
  "let has_error = !empty(p.errors)
  "call assert_true(has_error, input)

  let input =    'abc\(def\|ghi\)jkl'
  let expected = '\m\Cabc\(\zsdef\ze\|\zsghi\ze\)jkl'
  let output = p.parse(input).match_group(0, 1)
  call assert_equal(expected, output, input)
  "let has_error = !empty(p.errors)
  "call assert_true(has_error, input)

  let input =    'abc\(def\|ghi\)jkl'
  let expected = ''
  let output = p.parse(input).match_group(0, 2)
  call assert_equal(expected, output, input)
  "let has_error = !empty(p.errors)
  "call assert_true(has_error, input)

  let input =    'a\zsbc\(def\|ghi\)jkl\(mno\)pq\zer'
  let expected = '\m\Cabc\(\zsdef\ze\|\zsghi\ze\)jkl\(mno\)pqr'
  let output = p.parse(input).match_group(0, 1)
  call assert_equal(expected, output, input)
  "let has_error = !empty(p.errors)
  "call assert_true(has_error, input)

  let input =    'a\zsbc\(def\|ghi\)jkl\(mno\)pq\zer'
  let expected = '\m\Cabc\(def\|ghi\)jkl\(\zsmno\ze\)pqr'
  let output = p.parse(input).match_group(0, 2)
  call assert_equal(expected, output, input)
  "let has_error = !empty(p.errors)
  "call assert_true(has_error, input)

  if !empty(v:errors)
    let g:relab_debug = 0
    echohl ErrorMsg
    echom printf('%s error(s) found:', len(v:errors))
    echohl Normal
    for e in v:errors
      echohl WarningMsg
      echom  'Test failed: '
      echohl Normal
      echon e
    endfor
  endif
  let g:relab_debug = debug
endfunction "}}}

command! -nargs=* -range=% RELab <line1>,<line2>call RELabSetUp(<q-args>)
command! -nargs=+ DbgRELab call RELabDebug(<args>)

" TODO find nicer colors
hi default relabGroupMatchAll guibg=#000000 guifg=#dddddd ctermbg=0   ctermfg=252
hi default relabGroupMatch0   guibg=#804000 guifg=#dddddd ctermbg=94  ctermfg=252
hi default relabGroupMatch1   guibg=#800040 guifg=#dddddd ctermbg=89  ctermfg=252
hi default relabGroupMatch2   guibg=#008040 guifg=#dddddd ctermbg=29  ctermfg=252
hi default relabGroupMatch3   guibg=#400080 guifg=#dddddd ctermbg=54  ctermfg=252
hi default relabGroupMatch4   guibg=#0080a0 guifg=#dddddd ctermbg=31  ctermfg=252
hi default relabGroupMatch5   guibg=#a000a0 guifg=#dddddd ctermbg=127 ctermfg=252
hi default relabGroupMatch6   guibg=#b09000 guifg=#dddddd ctermbg=136 ctermfg=252
hi default relabGroupMatch7   guibg=#008000 guifg=#dddddd ctermbg=2   ctermfg=252
hi default relabGroupMatch8   guibg=#000080 guifg=#dddddd ctermbg=4   ctermfg=252
hi default relabGroupMatch9   guibg=#800000 guifg=#dddddd ctermbg=1   ctermfg=252

let relab = RELabParser()
call RELabTest()
