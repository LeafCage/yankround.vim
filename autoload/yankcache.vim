if exists('s:save_cpo')| finish| endif
let s:save_cpo = &cpo| set cpo&vim
"=============================================================================
let s:_cacherounder = {}
function! s:new_cacherounder(keybind) "{{{
  let _ = {'pos': getpos('.'), 'idx': 0, 'keybind': a:keybind}
  call extend(_, s:_cacherounder)
  return _
endfunction
"}}}
function! s:_cacherounder.detect_cursmoved() "{{{
  if getpos('.')==self.pos
    return
  end
  unlet s:cacherounder
  aug yankcache_rounder
    autocmd!
  aug END
  let g:yankcache#stop_autocmd = 0
endfunction
"}}}
function! s:_cacherounder.round_cache(incdec) "{{{
  if g:yankcache#cache==[]
    return
  end
  let g:yankcache#stop_autocmd = 1
  try
    let cachelen = len(g:yankcache#cache)
    let self.idx += a:incdec
    let self.idx = self.idx>=cachelen ? 0 : self.idx<0 ? cachelen-1 : self.idx
    let entry = g:yankcache#cache[self.idx]
    call setreg('"', entry[1], entry[0])
    silent undo
    silent exe 'norm! ""'. self.keybind
    ec 'yankcache: ('. (self.idx+1). '/'. cachelen. ')'
  finally
    let self.pos = getpos('.')
  endtry
endfunction
"}}}

"======================================
"Main
function! yankcache#init_rounder(keybind) "{{{
  let s:cacherounder = s:new_cacherounder(a:keybind)
  aug yankcache_rounder
    autocmd!
    autocmd CursorMoved *   call s:cacherounder.detect_cursmoved()
  aug END
endfunction
"}}}
function! yankcache#next() "{{{
  if !has_key(s:, 'cacherounder')
    return
  end
  call s:cacherounder.round_cache(-1)
endfunction
"}}}
function! yankcache#prev() "{{{
  if !has_key(s:, 'cacherounder')
    return
  end
  call s:cacherounder.round_cache(1)
endfunction
"}}}

function! yankcache#is_active() "{{{
  return has_key(s:, 'cacherounder')
endfunction
"}}}

"======================================
function! yankcache#persistent() "{{{
  if get(g:, 'yankcache_dir', '')=='' || g:yankcache#cache==[]
    return
  end
  let dir = expand(g:yankcache_dir)
  if !isdirectory(dir)
    call mkdir(dir, 'p')
  end
  call writefile(map(g:yankcache#cache, 'string(v:val)'), dir. '/cache')
endfunction
"}}}

"=============================================================================
"END "{{{1
let &cpo = s:save_cpo| unlet s:save_cpo
