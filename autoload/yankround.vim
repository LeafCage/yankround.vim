if exists('s:save_cpo')| finish| endif
let s:save_cpo = &cpo| set cpo&vim
"=============================================================================
let s:_cacherounder = {}
function! s:new_cacherounder(keybind) "{{{
  let _ = {'pos': getpos('.'), 'idx': 0, 'keybind': a:keybind, 'count': v:prevcount==0 ? 1 : v:prevcount}
  call extend(_, s:_cacherounder)
  return _
endfunction
"}}}
function! s:_cacherounder.detect_cursmoved() "{{{
  if getpos('.')==self.pos
    return
  end
  unlet s:cacherounder
  aug yankround_rounder
    autocmd!
  aug END
  let g:yankround#stop_autocmd = 0
endfunction
"}}}
function! s:_cacherounder.round_cache(incdec) "{{{
  if g:yankround#cache==[]
    return
  end
  let g:yankround#stop_autocmd = 1
  try
    let cachelen = len(g:yankround#cache)
    let self.idx += a:incdec
    let self.idx = self.idx>=cachelen ? 0 : self.idx<0 ? cachelen-1 : self.idx
    let [str, regtype] = yankround#_get_cache_and_regtype(self.idx)
    call setreg('"', str, regtype)
    silent undo
    silent exe 'norm!' self.count. '""'. self.keybind
    ec 'yankround: ('. (self.idx+1). '/'. cachelen. ')'
  finally
    let self.pos = getpos('.')
  endtry
endfunction
"}}}

"======================================
"Main
function! yankround#init_rounder(keybind) "{{{
  let s:cacherounder = s:new_cacherounder(a:keybind)
  aug yankround_rounder
    autocmd!
    autocmd CursorMoved *   call s:cacherounder.detect_cursmoved()
  aug END
endfunction
"}}}
function! yankround#next() "{{{
  if !has_key(s:, 'cacherounder')
    return
  end
  call s:cacherounder.round_cache(-1)
endfunction
"}}}
function! yankround#prev() "{{{
  if !has_key(s:, 'cacherounder')
    return
  end
  call s:cacherounder.round_cache(1)
endfunction
"}}}

function! yankround#is_active() "{{{
  return has_key(s:, 'cacherounder')
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
  let ret = matchlist(g:yankround#cache[a:idx], "^\\(.\\d*\\)\t\\(.*\\)")
  return [ret[2], ret[1]]
endfunction
"}}}

"=============================================================================
"END "{{{1
let &cpo = s:save_cpo| unlet s:save_cpo
