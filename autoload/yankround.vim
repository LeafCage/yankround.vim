if exists('s:save_cpo')| finish| endif
let s:save_cpo = &cpo| set cpo&vim
"=============================================================================
let s:_rounder = {}
function! s:new_rounder(keybind) "{{{
  let _ = {'pos': getpos('.'), 'idx': 0, 'keybind': a:keybind, 'count': v:prevcount==0 ? 1 : v:prevcount}
  call extend(_, s:_rounder)
  return _
endfunction
"}}}
function! s:_rounder.detect_cursmoved() "{{{
  if getpos('.')==self.pos
    return
  end
  unlet s:rounder
  aug yankround_rounder
    autocmd!
  aug END
  let g:yankround#stop_caching = 0
endfunction
"}}}
function! s:_rounder.round_cache(incdec) "{{{
  let cachelen = len(g:yankround#cache)
  if cachelen < 2
    return
  end
  let g:yankround#stop_caching = 1
  let self.idx += a:incdec
  let self.idx = self.idx>=cachelen ? 0 : self.idx<0 ? cachelen-1 : self.idx
  let [str, regtype] = yankround#_get_cache_and_regtype(self.idx)
  call setreg('"', str, regtype)
  silent undo
  silent exe 'norm!' self.count. '""'. self.keybind
  ec 'yankround: ('. (self.idx+1). '/'. cachelen. ')'
  let self.pos = getpos('.')
endfunction
"}}}

"=============================================================================
"Main
function! yankround#init_rounder(keybind) "{{{
  let s:rounder = s:new_rounder(a:keybind)
  aug yankround_rounder
    autocmd!
    autocmd CursorMoved *   call s:rounder.detect_cursmoved()
  aug END
endfunction
"}}}
function! yankround#prev() "{{{
  if !has_key(s:, 'rounder')
    return
  end
  call s:rounder.round_cache(1)
endfunction
"}}}
function! yankround#next() "{{{
  if !has_key(s:, 'rounder')
    return
  end
  call s:rounder.round_cache(-1)
endfunction
"}}}

function! yankround#is_active() "{{{
  return has_key(s:, 'rounder')
endfunction
"}}}

function! yankround#persistent() "{{{
  if get(g:, 'yankround_dir', '')=='' || g:yankround#cache==[]
    return
  end
  let dir = expand(g:yankround_dir)
  if !isdirectory(dir)
    call mkdir(dir, 'p')
  end
  call writefile(g:yankround#cache, dir. '/cache')
endfunction
"}}}

"======================================
function! yankround#_get_cache_and_regtype(idx) "{{{
  let ret = matchlist(g:yankround#cache[a:idx], '^\(.\d*\)\t\(.*\)')
  return [ret[2], ret[1]]
endfunction
"}}}

"=============================================================================
"END "{{{1
let &cpo = s:save_cpo| unlet s:save_cpo
