if get(g:, 'relab_set_mappings', 0)
  " let's add some super useful mappings
  nnoremap <unique><buffer><silent> <leader>rd :<C-U>RELabDescribe<CR>
  nnoremap <unique><buffer><silent> <leader>rm :<C-U>RELabMatches<CR>
  nnoremap <unique><buffer><silent> <leader>rv :<C-U>RELabValidate<CR>
  nnoremap <unique><buffer><silent> <leader>rs :<C-U>RELabSample<CR>
  if bufname('%') !=? 'RELab'
    " except in this case where it doesn't make much sense
    nnoremap <unique><buffer><silent> <leader>rl :<C-U>RELabUseLine<CR>
  endif
endif
