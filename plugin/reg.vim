function! RexSetLayout() "{{{
  botright split
  vsplit
  split
endfunction "}}}

function! RexParser() "{{{
  let p = {}
  let p.is_magic = {t -> t =~# '\m^\\[mMvV]$'}

  let p.starts_group = {t -> t ==# '[' || t =~# '\m^\\%\?($' || t ==# '\%['}
  let p.starts_capt_group = {t -> t ==# '\('}
  let p.starts_non_capt_group = {t -> t ==# '\%('}
  let p.starts_opt_group = {t -> t ==# '\%['}
  let p.starts_collection = {t -> t ==# '['}
  let p.ends_group = {t -> t ==# ']' || t ==# '\)'}
  let p.ends_capt_group = {t -> t ==# '\)'}
  let p.ends_non_capt_group = {t -> t ==# '\)'}
  let p.ends_opt_group = {t -> t ==# ']'}
  let p.ends_collection = {t -> t ==# ']'}

  let p.item_or_eol = {t -> t =~# '\m^\\_[$^.iIkKfFpPsSdDxXoOwWhHaAlLuU]$'}
  let p.with_underscore = {t -> t ==# '\_'}

  let p.incomplete_main = {m -> (m !=# 'v' ? '\m^\\' : '\m^') .
        \'\%(@<\?\|%[<>]\?\%(\d*\|''\)\|_\|#\|{\%(-\?\d*\%(,\d*\)\?\)\?\)\?$'}
  let p.incomplete_in_collection =
        \'\m^\%(\\\|\[\%(\%[\..\.]\|\%[=.=]\)\)$\|^\[\%(:\%(\a\+\(:\)\?\)\?\)\?$'
  let p.incomplete = {}
  let p.incomplete.engine = {m -> '\m^'.(m !=# 'v' ? '\\' : '').'%#=\d'}
  let p.incomplete.decimal = {m -> '\m^'.(m !=# 'v' ? '\\' : '').'%d\d\+'}
  let p.incomplete.octal = {m -> '\m^'.(m !=# 'v' ? '\\' : '').'%o\o\{1,3}'}
  let p.incomplete.hex2 = {m -> '\m^'.(m !=# 'v' ? '\\' : '').'%x\x\{1,2}'}
  let p.incomplete.hex4 = {m -> '\m^'.(m !=# 'v' ? '\\' : '').'%u\x\{1,4}'}
  let p.incomplete.hex8 = {m -> '\m^'.(m !=# 'v' ? '\\' : '').'%U\x\{1,8}'}

  let p.is_multi = {t -> index(['*', '\?', '\=', '\+'], t) >= 0
        \ || t=~# '\m^\\{-\?n\?,\?m\?}$'}
  let p.is_look_around = {t -> t =~# '\m^\\@\%([!=]\|\d*<[!=]\)$'}
  let p.is_group = {t -> index(['\(', '\%(', ')', '\|', '\&'], t) >= 0}
  let p.is_zero_width = {t -> index(['^'])}
  let p.is_invalid_in_optional = {t -> p.is_multi(t) || p.is_group(t)
        \ || p.is_look_around(t) || p.starts_opt_group(t)}

  let p.root = {}
  let p.root.value = 'regular expression'
  let p.root.normal = 'regular expression'
  let p.root.id = ''
  let p.root.parent = {}
  let p.root.siblings = []
  let p.root.children = []
  let p.root.help = 'pattern'

  let p.parent = p.root

  " p.id_map {{{
  let p.id_map = {
        \'\|': {'help_tag': '/bar', 'description': 'Alternation, works like a logical OR, matches either the left or right subexpressions.'},
        \'\&': {'help_tag': '/\&', 'description': 'Concatenation, works like a logical AND, matches the subexpression on the righ only if the subexpression on the left also matches.'},
        \'*': {'help_tag': '/star', 'description': 'Matches 0 or more of the preceding atom, as many as possible.'},
        \'\+': {'help_tag': '/\+', 'description': 'Matches 1 or more of the preceding atom, as many as possible.'},
        \'\=': {'help_tag': '/\=', 'description': 'Matches 0 or 1 of the preceding atom, as many as possible.'},
        \'\?': {'help_tag': '/?', 'description': 'Matches 0 or 1 of the preceding atom, as many as possible. Cannot be used when searching backwards with the "?" command.'},
        \'\{n,m}': {'help_tag': '/\{', 'description': 'Matches n to m of the preceding atom, as many as possible'},
        \'\{n}': {'help_tag': '/\{', 'description': 'Matches n of the preceding atom'},
        \'\{n,}': {'help_tag': '/\{', 'description': 'Matches at least n of the preceding atom, as many as possible'},
        \'\{,m}': {'help_tag': '/\{', 'description': 'Matches 0 to m of the preceding atom, as many as possible'},
        \'\{}': {'help_tag': '/\{', 'description': 'Matches 0 or more of the preceding atom, as many as possible (like *)'},
        \'\{-n,m}': {'help_tag': '/\{-', 'description': 'Matches n to m of the preceding atom, as few as possible'},
        \'\{-n}': {'help_tag': '/\{-', 'description': 'Matches n of the preceding atom'},
        \'\{-n,}': {'help_tag': '/\{-', 'description': 'Matches at least n of the preceding atom, as few as possible'},
        \'\{-,m}': {'help_tag': '/\{-', 'description': 'Matches 0 to m of the preceding atom, as few as possible'},
        \'\{-}': {'help_tag': '/\{-', 'description': 'Matches 0 or more of the preceding atom, as few as possible'},
        \'\@=': {'help_tag': '/\@=', 'description': 'Matches the preceding atom with zero width.'},
        \'\@!': {'help_tag': '/\@!', 'description': 'Matches with zero width if the preceding atom does NOT match at the current position.'},
        \'\@<=': {'help_tag': '/\@<=', 'description': 'Matches with zero width if the preceding atom matches just before what follows.'},
        \'\@123<=': {'help_tag': '/\@<=', 'description': 'Matches with zero width if the preceding atom matches just before what follows but only look bacl 123 bytes.'},
        \'\@<!': {'help_tag': '/\@<!', 'description': 'Matches with zero width if the preceding atom does NOT match just before what follows.'},
        \'\@123<!': {'help_tag': '/\@<!', 'description': 'Matches with zero width if the preceding atom does NOT match just before what follows but only look back 123 bytes.'},
        \'\@>': {'help_tag': '/\@>', 'description': 'Matches the preceding atom like matching a whole pattern.'},
        \'^' : {'help_tag': '/^', 'description': 'At beginning of pattern or after "\|", "\(", "\%(" or "\n": matches start-of-line with zero width; at other positions, matches literal ''^''.'},
        \'\^': {'help_tag': '/\^', 'description': 'Matches literal ''^''.  Can be used at any position in the pattern.'},
        \'\_^': {'help_tag': '/\_^', 'description': 'Matches start-of-line. zero-width  Can be used at any position in the pattern.'},
        \'$': {'help_tag': '/$', 'description': 'At end of pattern or in front of "\|", "\)" or "\n" (''magic'' on): matches end-of-line <EOL> with zero width; at other positions, matches literal ''$''.'},
        \'\$': {'help_tag': '/\$', 'description': 'Matches literal ''$''.  Can be used at any position in the pattern.'},
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
        \'\_x': {'help_tag': '/\_', 'description': 'Where "x" is any of the characters above: The character class with end-of-line added'},
        \'\e': {'help_tag': '/\e', 'description': 'Matches <Esc>'},
        \'\t': {'help_tag': '/\t', 'description': 'Matches <Tab>'},
        \'\r': {'help_tag': '/\r', 'description': 'Matches <CR>'},
        \'\b': {'help_tag': '/\b', 'description': 'Matches <BS>'},
        \'\n': {'help_tag': '/\n', 'description': 'Matches an end-of-line'},
        \'~': {'help_tag': '/\~', 'description': 'Matches the last given substitute string.'},
        \'\(': {'help_tag': '/\(', 'description': 'A pattern enclosed by escaped parentheses.'},
        \'\)': {'help_tag': '/\)', 'description': 'A pattern enclosed by escaped parentheses.'},
        \'\1': {'help_tag': '/\1', 'description': 'Matches the same string that was matched by the first sub-expression in \( and \).'},
        \'\2': {'help_tag': '/\2', 'description': 'Matches the same string that was matched by the second sub-expression in \( and \).'},
        \'\3': {'help_tag': '/\3', 'description': 'Matches the same string that was matched by the third sub-expression in \( and \).'},
        \'\4': {'help_tag': '/\4', 'description': 'Matches the same string that was matched by the fourth sub-expression in \( and \).'},
        \'\5': {'help_tag': '/\5', 'description': 'Matches the same string that was matched by the fifth sub-expression in \( and \).'},
        \'\6': {'help_tag': '/\6', 'description': 'Matches the same string that was matched by the sixth sub-expression in \( and \).'},
        \'\7': {'help_tag': '/\7', 'description': 'Matches the same string that was matched by the seventh sub-expression in \( and \).'},
        \'\8': {'help_tag': '/\8', 'description': 'Matches the same string that was matched by the eighth sub-expression in \( and \).'},
        \'\9': {'help_tag': '/\9', 'description': 'Matches the same string that was matched by the ninth sub-expression in \( and \).'},
        \'\%(': {'help_tag': '/\%(', 'description': 'A pattern enclosed by escaped parentheses.  Just like \(\), but without counting it as a sub-expression.'},
        \'[': {'help_tag': '/[]', 'description': 'This is a sequence of characters enclosed in brackets. It matches any single character in the collection.'},
        \'\_[': {'help_tag': '/\_[]', 'description': 'This is a sequence of characters enclosed in brackets. It matches any single character in the collection.  With "\_" prepended the collection also includes the end-of-line.'},
        \'\[^': {'help_tag': 'E944', 'description': 'If the sequence begins with "^", it matches any single character NOT in the collection: "[^xyz]" matches anything but ''x'', ''y'' and ''z''.'},
        \'\[-': {'help_tag': 'E944', 'description': 'If two characters in the sequence are separated by ''-'', this is shorthand for the full list of ASCII characters between them.'},
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
        \'\%#=1': {'help_tag': '/\%#=', 'description': 'select regexp engine |/zero-width|'},
        \} "}}}

  function! p.init(...) "{{{
    let self.magic = 'm'
    let self.root.magic = self.magic
    let self.in_collection = 0
    let self.token = ''
    let self.tokens = []
    let self.nest_stack = []
    let self.input = a:0 ? a:1 : ''
    let self.length = strchars(self.input)
    let self.pos = 0
    let self.errors = []
    let self.root.children = []
    let self.sequence = []
    return self
  endfunction "}}}

  function! p.normalize(token, magic) "{{{
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
    let n.normal = self.normalize(self.token, self.magic)
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
    if self.in_collection && a:text =~# '\m^\\[doxuU]'
      " /[\x]
      return substitute(a:text, '\m^\\\(.\).\+', '[\\\1', '')
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
      let id .= a:text =~# '\m^\\{-\?\d*,\?\d' ? 'm' : ''
      let id .= '}'
      return id
    elseif a:text =~# '\m^\\%[doxuU]\d\+$'
      " /\%d123
      return matchstr(a:text, '\m\C^\\%[doxuU]')
    elseif a:text =~# '\m^\[[.=].[.=]\]$'
      " /[[.a.][=a=]]
      return substitute(a:text, '\m^\(\[[.=]\).[.=]\]$', '[\1\1]', '')
    elseif a:text =~# '\m^.-.$'
      " /[a-z]
      return 'char set'
    elseif a:text =~# '\m^\\_.$'
      return '\_'
    endif
    return a:text
  endfunction "}}}

  function! p.is_incomplete() "{{{
    if self.in_collection
      if self.token =~# self.incomplete_in_collection
        return 1
      endif
      return 0
    endif
    if self.token =~# self.incomplete_main(self.magic)
      return 1
    endif
    let current = self.token . strcharpart(self.input, 1)
    if !empty(filter(values(self.incomplete),
          \'current =~# call(v:val, [self.magic])'))
      return 1
    endif
    return 0
  endfunction "}}}

  function! p.help_tag(node) "{{{
    return get(get(self.id_map, a:node.id, {}), 'description', '')
  endfunction "}}}

  function! p.description(node) "{{{
    if has_key(self.id_map, a:node.id)
      let msg = get(get(self.id_map, a:node.id, {}), 'description', '')
    else
      let char = a:node.id =~# '^\\.' ? a:node.id[1:] : a:node.id
      let msg = printf('Matches the character "%s"', char)
    endif
    let indent = repeat('  ', a:node.nesting_level)
    return printf('%s%s => %s', indent, a:node.value, msg)
  endfunction "}}}

  function! p.get_lines() "{{{
    if !empty(self.errors)
      return copy(self.errors)
    endif
    return map(copy(self.sequence), 'v:val.description')
  endfunction "}}}

  function! p.print_lines() "{{{
    for line in self.get_lines()
      echon printf("\n%s", line)
    endfor
  endfunction "}}}

  function! p.collection_ends() "{{{
    let pattern = '\m^\(\\.\|[^\]]\)*\]'
    let ahead = strcharpart(self.input, self.pos)
    return ahead =~# pattern
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

  function! p.sequence_of(key) "{{{
    return map(copy(self.sequence), 'get(v:val, a:key, '''')')
  endfunction "}}}

  function! p.add_error(node, ...) "{{{
    let error = (a:0 ? a:1 : a:node.value . ':')
    let error = printf('Error: %s', error)
    let a:node.is_error = 1
    let errormsg = [error, self.input]
    let arrow = printf('%s^', repeat('-', a:node.pos))
    call add(errormsg, arrow)
    let a:node.error = errormsg
    let self.errors += errormsg
  endfunction "}}}

  function! p.in_opt_group(node) "{{{
    return get(get(self.nest_stack, -1, {}), 'normal', '') ==# '\%['
  endfunction "}}}

  function! p.in_collection(node) "{{{
    return get(get(self.nest_stack, -1, {}), 'normal', '') ==# '['
  endfunction "}}}

  function! p.next() "{{{
    let self.token = strcharpart(self.input, self.pos, 1)
    let self.pos += 1
    while (self.pos < self.length) && self.is_incomplete()
      let self.token .= strcharpart(self.input, self.pos, 1)
      let self.pos += 1
    endwhile
    if !empty(self.token)
      call add(self.tokens, self.token)
    endif
    return !empty(self.token)
  endfunction "}}}

  function! p.parse(input) "{{{
    call self.init(a:input)
    while self.next()
      let node = self.new_child()

      " process token
      if self.in_collection
        if self.ends_collection(node.id)
          call remove(self.nest_stack, -1)
          let self.parent = node.parent.parent
          let self.in_collection = 0
          let node.nesting_level -= 1
          let node.description =
                \printf('%s%s => %s', repeat('  ', node.nesting_level), node.value,
                \  'ends collection.')
        else
        endif

      elseif self.in_optional_group() && self.is_invalid_in_optional(node.id)
        let errormessage =
              \printf('%s is not valid inside \%%[]', node.value)
        call self.add_error(node, errormessage)

      elseif self.starts_group(node.id)
        call add(self.nest_stack, node)
        let self.parent = node
        if self.starts_collection(node.id)
          if self.collection_ends()
            " The collection is terminated by a ']', so treat this as the
            " start of the collection
            let self.in_collection = 1
          else
            " Treat this as a literal character
            call remove(self.nest_stack, -1)
            let node.description = printf('%s%s => Matches the character "[".',
                  \repeat('  ', node.nesting_level),
                  \node.value)
          endif
        endif

      elseif self.ends_group(node.id)
        if self.is_paired(node.id)
          call remove(self.nest_stack, -1)
          let self.parent = node.parent.parent
          let node.nesting_level -= 1
          if self.ends_opt_group(node.id)
            let node.description =
                  \printf('%s%s => %s', repeat('  ', node.nesting_level), node.value,
                  \  'ends optional sequence.')
          else
            let node.description = self.description(node)
          endif
        else
          " handle error here
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

      elseif self.with_underscore(node.id)
        if self.item_or_eol(node.normal)

        else
          " /\_=
          let char = strcharpart(node.normal, 2)
          let errormessage = printf('invalid character class: %s', char)
          call self.add_error(node, errormessage)
        endif

      elseif self.is_magic(node.id)
        let self.magic = node.id[1]

      else
      endif
    endwhile
    if !empty(self.nest_stack)
      for node in self.nest_stack
        " handle errors
        " /\(
        let errormessage = printf('unmatched %s', node.value)
        call self.add_error(node, errormessage)
      endfor
    endif
    return self
  endfunction "}}}

  return p
endfunction "}}}

function! RexTest() "{{{
  let p = RexParser()

  let v:errors = []

  let input = ''
  let expected = []
  let output = p.parse(input).sequence_of('normal')
  call assert_equal(expected, output, input)

  let input = '^'
  let expected = ['^']
  let output = p.parse(input).sequence_of('normal')
  call assert_equal(expected, output, input)

  let input = '^a\+'
  let expected = ['^', 'a', '\+']
  let output = p.parse(input).sequence_of('normal')
  call assert_equal(expected, output, input)

  let input = '^a\+\vb+'
  let expected = ['^', 'a', '\+', '\v', 'b', '\+']
  let output = p.parse(input).sequence_of('normal')
  call assert_equal(expected, output, input)

  let input = '\)'
  let expected = ['Error: unmatched \)', '\)', '^']
  let output = p.parse(input).get_lines()
  call assert_equal(expected, output, input)

  let input = '\%[a*]'
  let expected = ['Error: * is not valid inside \%[]', '\%[a*]', '----^']
  let output = p.parse(input).get_lines()
  call assert_equal(expected, output, input)

  let input = '\%[\(]'
  let expected = ['Error: \( is not valid inside \%[]', '\%[\(]', '---^']
  let output = p.parse(input).get_lines()
  call assert_equal(expected, output, input)

  for e in v:errors
    echohl WarningMsg
    echo 'Test failed: '
    echohl Normal
    echon e
  endfor
  "let pattern = '^\(ab\%[cd*e\(\)]\)'
  "echo pattern
  "echo
  "echo join(p.parse(pattern).get_lines(), "\n")
  ""for e in  p.parse(pattern).get_lines() | echo e | endfor
endfunction "}}}

call RexTest()
let p = RexParser()

finish
[abA-Z[:alpha:][.c.][=f=]askjh\]\-gd][^alksjhd][-alkshd][^-ioasug]
