command! -nargs=* -range=% RELab <line1>,<line2>call relab#setup(<q-args>)
command! -nargs=+ DbgRELab call relab#debug(<args>)

augroup RELab
  autocmd!
  autocmd TextChanged,TextChangedI RELab call relab#ontextchange()
  autocmd BufRead,BufNewFile RELab setlocal filetype=relab buftype=nofile
        \ noundofile noswapfile 
  autocmd BufWinLeave,WinLeave RELab if get(s:, 'relab_auto_search', 0)
        \ | let @/ = getline(1) | endif
  autocmd BufWritePost relab.vim,*relab/tests.vim if get(g:, 'relab_debug', 0)
        \ | source <afile> | call relab#tests#run() | endif
augroup END

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

let s:plugin_dir = expand('<sfile>:p:h')
