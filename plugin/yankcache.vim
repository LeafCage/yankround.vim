let s:save_cpo = &cpo| set cpo&vim
"=============================================================================
let g:yankcache_dir = get(g:, 'yankcache_dir', '~/.cache/yankcache')
let g:yankcache_max_history = get(g:, 'yankcache_max_history', 30)
"======================================
nnoremap <silent><Plug>(yankcache-p)    p:<C-u>call yankcache#init_rounder('p')<CR>
nnoremap <silent><Plug>(yankcache-P)    P:<C-u>call yankcache#init_rounder('P')<CR>
nnoremap <silent><Plug>(yankcache-prev)    :<C-u>call yankcache#prev()<CR>
nnoremap <silent><Plug>(yankcache-next)    :<C-u>call yankcache#next()<CR>
command! -nargs=0   CtrlPYankCache    call ctrlp#init(ctrlp#yankcache#id())
"=============================================================================

let s:path = expand(g:yankcache_dir). '/cache'
let g:yankcache#cache = has_key(g:, 'yankcache#cache') ? g:yankcache#cache : !filereadable(s:path) ? [] : map(readfile(s:path), 'eval(v:val)')
unlet s:path
let g:yankcache#stop_autocmd = 0

aug YankCache
  autocmd!
  autocmd CursorMoved *   call s:append_yankcache()
  autocmd VimLeavePre *   call yankcache#persistent()
aug END
function! s:append_yankcache() "{{{
  if g:yankcache#stop_autocmd || @" ==# get(g:yankcache#cache, 0, ['', ''])[1] || @"=~'^.\?$'
    return
  end
  call insert(g:yankcache#cache, [getregtype('"'), @"])
  call s:new_dupliexcluder().filter(g:yankcache#cache)
  if len(g:yankcache#cache) > g:yankcache_max_history
    call remove(g:yankcache#cache, g:yankcache_max_history-1, -1)
  end
endfunction
"}}}


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
function! s:_dupliexcluder._seen(val) "{{{
  if has_key(self.seens, string(a:val))
    return
  end
  if !empty(a:val)
    let self.seens[string(a:val)] = 1
  end
  return 1
endfunction
"}}}

"=============================================================================
"END "{{{1
let &cpo = s:save_cpo| unlet s:save_cpo
