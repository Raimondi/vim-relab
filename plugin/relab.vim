let g:relab_file_path = get(g:, 'relab_filepath',
      \ printf('%s/relab_data.txt', expand('<sfile>:p:h:h')))

command! -nargs=* RELab call relab#set(<q-args>)
command! -nargs=* -range=% -complete=file RELabGetSample
      \ call relab#get_sample(<line1>, <line2>, <q-args>)
command! -count RELabUseLine call relab#line2regexp(<count>)
command! -nargs=* RELabDescribe call relab#describe(<q-args>)
command! RELabSample call relab#sample()
command! -nargs=* RELabMatches call relab#matches(0, <q-args>)
command! -nargs=* RELabValidate call relab#matches(1, <q-args>)
command! -bang TestRELab call relab#tests#run(<bang>0)

if exists('g:relab_debug')
  function! s:debug(force, verbose, msg) "{{{
    let debug = get(g:, 'relab_debug', 0)
    let tags = debug > 9 && a:verbose > 9
          \ ? split(debug[0:-2], '\zs') : range(10)
    let debug = debug[-1:]
    let verbose = a:verbose % 10
    let tag = a:verbose > 9 ? a:verbose[0] : 0
    if a:force || verbose <= debug && index(tags, tag) >= 0
      echom printf('%sRELab: %s', a:verbose, a:msg)
    endif
  endfunction "}}}

  command! -count=1 -nargs=+ -bang DebugRELab
        \ call s:debug(<bang>0, <count>, <args>)
else
  command! -count=1 -nargs=+ -bang DebugRELab :
endif

augroup RELab
  autocmd!
  autocmd TextChanged  RELab call relab#ontextchange('textchanged')
  autocmd TextChangedI RELab call relab#ontextchange('textchangedi')

  if exists('g:relab_debug')
    autocmd BufWritePost relab.vim,*/relab/*.vim source <afile>
          \ | call relab#tests#run()
    autocmd BufWritePost */autoload/relab/id_key.txt
          \ | execute printf('source %s/parser.vim', expand('<afile>:p:h'))
          \ | call relab#tests#run()
  endif
augroup END

