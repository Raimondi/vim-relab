let g:relab_filepath = get(g:, 'relab_filepath',
      \ printf('%s/data.txt', expand('<sfile>:p:h:h')))

command! -nargs=* RELab call relab#set(<q-args>)
command! -nargs=* -range=% -complete=file RELabGetSample
      \ call relab#get_sample(<line1>, <line2>, <q-args>)
command! -count RELabLine2Regexp call relab#line2regexp(<count>)
command! -nargs=* RELabAnalyze call relab#analysis(<q-args>)
command! -nargs=* RELabMatches call relab#matches(0, <q-args>)
command! -nargs=* RELabValidate call relab#matches(1, <q-args>)
command! -bang TestRELab call relab#tests#run(<bang>0)
if exists('g:relab_debug')
  command! -count=1 -nargs=+ DbgRELab call relab#debug(<count>, <args>)
else
  command! -count=1 -nargs=+ DbgRELab :
endif

augroup RELab
  autocmd!
  autocmd TextChanged scratch.relab echom 'Changed!' | call relab#ontextchange()
  autocmd InsertLeave scratch.relab echom 'InsertLeave!' | call relab#ontextchange()
  autocmd BufRead,BufNewFile RELab setlocal filetype=relab buftype=nofile
        \ noundofile noswapfile
  autocmd ColorScheme * call s:hi_colors()

  if exists('g:relab_debug') "get(g:, 'relab_debug', 0)
    autocmd BufWritePost relab.vim,*/relab/*.vim source <afile>
          \ | call relab#tests#run() | let relab = relab#parser#new()
    autocmd BufWritePost */autoload/relab/id_key.txt
          \ | execute printf('source %s/parser.vim', expand('<afile>:p:h'))
          \ | call relab#tests#run() | let relab = relab#parser#new()
  endif
augroup END
