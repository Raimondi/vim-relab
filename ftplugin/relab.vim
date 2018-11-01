if get(g:, 'relab_set_mappings', 0)
  nnoremap <unique><buffer><silent> <leader>rl :<C-U>RELabUseLine<CR>
  if bufname('%') ==? 'RELab'
    nnoremap <unique><buffer><silent> <leader>ra :<C-U>RELabAnalyze<CR>
    nnoremap <unique><buffer><silent> <leader>rm :<C-U>RELabMatches<CR>
    nnoremap <unique><buffer><silent> <leader>rv :<C-U>RELabValidate<CR>
    nnoremap <unique><buffer><silent> <leader>rs :<C-U>RELabEditSample<CR>
  endif
endif
