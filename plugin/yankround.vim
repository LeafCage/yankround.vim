let s:save_cpo = &cpo| set cpo&vim
"=============================================================================
let g:yankround_dir = get(g:, 'yankround_dir', '~/.cache/yankround')
let g:yankround_max_history = get(g:, 'yankround_max_history', 30)
let g:yankround_max_element_length = get(g:, 'yankround_max_element_length', 1048576)
let g:yankround_use_region_hl = get(g:, 'yankround_use_region_hl', 0)
let g:yankround_region_hl_groupname = get(g:, 'yankround_region_hl_groupname', 'YankRoundRegion')
"======================================
nnoremap <silent><Plug>(yankround-p)    :<C-u>exe yankround#init('p')<Bar>call yankround#activate()<CR>
nnoremap <silent><Plug>(yankround-P)    :<C-u>exe yankround#init('P')<Bar>call yankround#activate()<CR>
nnoremap <silent><Plug>(yankround-gp)    :<C-u>exe yankround#init('gp')<Bar>call yankround#activate()<CR>
nnoremap <silent><Plug>(yankround-gP)    :<C-u>exe yankround#init('gP')<Bar>call yankround#activate()<CR>
nnoremap <silent><Plug>(yankround-prev)    :<C-u>call yankround#prev()<CR>
nnoremap <silent><Plug>(yankround-next)    :<C-u>call yankround#next()<CR>
"=============================================================================

let s:path = expand(g:yankround_dir). '/cache'
let g:_yankround_cache = has_key(g:, '_yankround_cache') ? g:_yankround_cache : !filereadable(s:path) ? [] : readfile(s:path)
unlet s:path
let g:_yankround_stop_caching = 0

aug yankround
  autocmd!
  autocmd CursorMoved *   call s:append_yankcache()
  autocmd ColorScheme *   call s:define_region_hl()
  autocmd VimLeavePre *   call yankround#persistent()
aug END
function! s:append_yankcache() "{{{
  if g:_yankround_stop_caching || @" ==# substitute(get(g:_yankround_cache, 0, ''), '^.\d*\t', '', '') || @"=~'^.\?$'
    \ || g:yankround_max_element_length!=0 && strlen(@")>g:yankround_max_element_length
    return
  end
  call insert(g:_yankround_cache, getregtype('"'). "\t". @")
  call s:new_dupliexcluder().filter(g:_yankround_cache)
  if len(g:_yankround_cache) > g:yankround_max_history
    call remove(g:_yankround_cache, g:yankround_max_history, -1)
  end
endfunction
"}}}

function! s:define_region_hl() "{{{
  if &bg=='dark'
    highlight default YankRoundRegion   guibg=Brown ctermbg=Brown term=reverse
  else
    highlight default YankRoundRegion   guibg=LightRed ctermbg=LightRed term=reverse
  end
endfunction
"}}}
call s:define_region_hl()

"=============================================================================
let s:_dupliexcluder = {}
function! s:new_dupliexcluder() "{{{
  let _ = {'seens': {}}
  call extend(_, s:_dupliexcluder, 'keep')
  return _
endfunction
"}}}
function! s:_dupliexcluder.filter(list) "{{{
  return filter(a:list, 'self._seen(v:val)')
endfunction
"}}}
function! s:_dupliexcluder._seen(str) "{{{
  if has_key(self.seens, a:str)
    return
  end
  if a:str!=''
    let self.seens[a:str] = 1
  end
  return 1
endfunction
"}}}

"=============================================================================
"END "{{{1
let &cpo = s:save_cpo| unlet s:save_cpo
