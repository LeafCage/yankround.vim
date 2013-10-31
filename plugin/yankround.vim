let s:save_cpo = &cpo| set cpo&vim
"=============================================================================
let g:yankround_dir = get(g:, 'yankround_dir', '~/.cache/yankround')
let g:yankround_max_history = get(g:, 'yankround_max_history', 30)
"======================================
nnoremap <silent><Plug>(yankround-p)    p:<C-u>call yankround#init_rounder('p')<CR>
nnoremap <silent><Plug>(yankround-P)    P:<C-u>call yankround#init_rounder('P')<CR>
nnoremap <silent><Plug>(yankround-prev)    :<C-u>call yankround#prev()<CR>
nnoremap <silent><Plug>(yankround-next)    :<C-u>call yankround#next()<CR>
command! -nargs=0   CtrlPYankRound    call ctrlp#init(ctrlp#yankround#id())
"=============================================================================

let s:path = expand(g:yankround_dir). '/cache'
let g:yankround#cache = has_key(g:, 'yankround#cache') ? g:yankround#cache : !filereadable(s:path) ? [] : map(readfile(s:path), 'eval(v:val)')
unlet s:path
let g:yankround#stop_autocmd = 0

aug yankround
  autocmd!
  autocmd CursorMoved *   call s:append_yankround()
  autocmd VimLeavePre *   call yankround#persistent()
aug END
function! s:append_yankround() "{{{
  if g:yankround#stop_autocmd || @" ==# get(g:yankround#cache, 0, ['', ''])[1] || @"=~'^.\?$'
    return
  end
  call insert(g:yankround#cache, [getregtype('"'), @"])
  call s:new_dupliexcluder().filter(g:yankround#cache)
  if len(g:yankround#cache) > g:yankround_max_history
    call remove(g:yankround#cache, g:yankround_max_history-1, -1)
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
