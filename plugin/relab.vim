function! s:hi_colors()
  " TODO find nicer colors
  hi def relabGrpMatchAll guibg=#000000 guifg=#dddddd ctermbg=0   ctermfg=252
  hi def relabGrpMatch0   guibg=#804000 guifg=#dddddd ctermbg=94  ctermfg=252
  hi def relabGrpMatch1   guibg=#800040 guifg=#dddddd ctermbg=89  ctermfg=252
  hi def relabGrpMatch2   guibg=#008040 guifg=#dddddd ctermbg=29  ctermfg=252
  hi def relabGrpMatch3   guibg=#400080 guifg=#dddddd ctermbg=54  ctermfg=252
  hi def relabGrpMatch4   guibg=#0080a0 guifg=#dddddd ctermbg=31  ctermfg=252
  hi def relabGrpMatch5   guibg=#a000a0 guifg=#dddddd ctermbg=127 ctermfg=252
  hi def relabGrpMatch6   guibg=#b09000 guifg=#dddddd ctermbg=136 ctermfg=252
  hi def relabGrpMatch7   guibg=#008000 guifg=#dddddd ctermbg=2   ctermfg=252
  hi def relabGrpMatch8   guibg=#000080 guifg=#dddddd ctermbg=4   ctermfg=252
  hi def relabGrpMatch9   guibg=#800000 guifg=#dddddd ctermbg=1   ctermfg=252
endfunction

command! -nargs=* RELab call relab#set(<q-args>)
command! -bar -range=% RELabGetSample
      \ call relab#get_sample(<line1>, <line2>)
command! -count -bar RELabAnalyzeLine call relab#analyze_line(<count>)
command! -nargs=* RELabAnalyze call relab#show_analysis(<q-args>)
command! -nargs=* RELabGetMatches call relab#show_matches(0, <q-args>)
command! -nargs=* RELabValidate call relab#show_matches(1, <q-args>)

if get(g:, 'relab_debug', 0)
  command! -count=1 -nargs=+ DbgRELab call relab#debug(<count>, <args>)
else
  command! -count=1 -nargs=+ DbgRELab :
endif

augroup RELab
  autocmd!
  "autocmd TextChanged,InsertLeave regexp.relab call relab#ontextchange()
  autocmd BufRead,BufNewFile RELab setlocal filetype=relab buftype=nofile
        \ noundofile noswapfile
  "autocmd BufWinLeave,WinLeave RELab if get(s:, 'relab_auto_search', 0)
  "      \ | let @/ = getline(1) | endif
  autocmd ColorScheme * call s:hi_colors()

  if exists('g:relab_debug') "get(g:, 'relab_debug', 0)
    autocmd BufWritePost relab.vim,*/relab/*.vim source <afile>
          \ | call relab#tests#run() | let relab = relab#parser#new()
    autocmd BufWritePost */autoload/relab/id_key.txt
          \ | execute printf('source %s/parser.vim', expand('<afile>:p:h'))
          \ | call relab#tests#run() | let relab = relab#parser#new()
  endif
augroup END

call s:hi_colors()
