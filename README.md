# RELab: A Playground for Vim Regular Expressions

Vim's regular expressions (regexp) can be a bit different from what people is
used to nowadays, RELab provides some tools to help with understanding how
they work.

There are four available views that show different aspects of the regexp. The
Description view shows every item next to a description of what it does. The
Matches view shows what text is matched by the regexp, when used on a sample
text. The Validation view shows which lines of the sample text are matched or
not by the regexp. The Sample Text view shows the provided text that is used
to match the regexp against, and eny edits to it is preserved after switching
to other view. Whenever the regexp is shown it can be edited and the result
with be automatically updated and stored for the other views.


## DESCRIPTION VIEW

Shows the description of every element of the current regexp. Get to this view
with `:RELabDescribe` or `<leader>rd`.

```
	+---------------------------------------------------------------+
	|RELab: Description						|
	|\(\w\+\)@\(\w\+\)						|
	|								|
	|  \( => Starts a capturing group.				|
	|    \w => A word character: [0-9A-Za-z_].			|
	|    \+ => 1 or more of the preceding atom, as many as possible.|
	|  \) => Ends a capturing group.				|
	|  @ => Matches the character "@" (code 64).			|
	|  \( => Starts a capturing group.				|
	|    \w => A word character: [0-9A-Za-z_].			|
	|    \+ => 1 or more of the preceding atom, as many as possible.|
	|  \) => Ends a capturing group.				|
	|~								|
	+---------------------------------------------------------------+
```

## MATCHES VIEW

Display every line of the sample text that is matched by the current regexp.
Also show the matched text for every matched line. Both `:RELabMatches` and
`<leader>rm` open this view.

```
	+---------------------------------------------------------------+
	|RELab: Matches							|
	|\(\w\+\)@\(\w\+\)						|
	|								|
	|+:email@example.com						|
	|0:email@example						|
	||\1:email							|
	| \2:example							|
	|+:firstname.lastname@example.com				|
	|0:lastname@example						|
	||\1:lastname							|
	| \2:example							|
	|+:email@subdomain.example.com					|
	|0:email@subdomain						|
	+---------------------------------------------------------------+
```

## VALIDATION VIEW	

Every line of the sample text is marked as matched (with +) or unmatched (with
x) by the current regexp. Also show the matched text for every matched line.
The command `:RELabValidate` or the mapping in `<leader>rv` bring you here.

```
	+---------------------------------------------------------------+
	|RELab: Validation						|
	|\(\w\+\)@\(\w\+\)						|
	|								|
	|x:Some email addresses to play with				|
	|x:								|
	|+:email@example.com						|
	|0:email@example						|
	||\1:email							|
	| \2:example							|
	|+:firstname.lastname@example.com				|
	|0:lastname@example						|
	||\1:lastname							|
	| \2:example							|
	+---------------------------------------------------------------+
```

## SAMPLE VIEW

Shows the sample text that will be used with the given regex. Any edits to the
text while in this view will be preserved for the other views. In order to
access the sample text, use `:RELabSample` or `<leader>rs`. `RELabGetSample` will
also open this view and get the sample text from the current buffer or read
from another file.

```
	+---------------------------------------------------------------+
	|RELab: Sample							|
	|-------------							|
	|Some email addresses to play with				|
	|								|
	|email@example.com						|
	|firstname.lastname@example.com					|
	|email@subdomain.example.com					|
	|firstname+lastname@example.com					|
	|email@123.123.123.123						|
	|email@[123.123.123.123]					|
	|~								|
	|~								|
	|~								|
	+---------------------------------------------------------------+
```
