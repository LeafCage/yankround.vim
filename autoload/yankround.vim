if exists('s:save_cpo')| finish| endif
let s:save_cpo = &cpo| set cpo&vim
"=============================================================================
let s:_rounder = {}
let s:_rounder._match_ids = []

function! s:new_rounder(keybind) "{{{
  let _ = {'pos': getpos('.'), 'idx': -1, 'keybind': a:keybind, 'count': v:prevcount==0 ? 1 : v:prevcount, 'changedtick': b:changedtick}
  call extend(_, s:_rounder)
  return _
endfunction
"}}}
function! s:_rounder.detect_cursmoved() "{{{
  if getpos('.')==self.pos
    return
  end
  call s:_rounder.clear_highlight()
  call s:_release_rounder()
endfunction
"}}}
function! s:_rounder.is_valid() "{{{
  if get(self, 'cachelen', 1) != 0 && self.changedtick==b:changedtick
    return 1
  end
  call s:_release_rounder()
endfunction
"}}}

function! s:_rounder.round_cache(incdec) "{{{
  let self.cachelen = len(g:yankround#cache)
  if !self.is_valid()
    return
  end
  let g:yankround#stop_caching = 1
  let self.idx = self._round_idx(a:incdec)
  let [str, regtype] = yankround#_get_cache_and_regtype(self.idx)
  call setreg('"', str, regtype)
  silent undo
  silent exe 'norm!' self.count. '""'. self.keybind
  ec 'yankround: ('. (self.idx+1). '/'. self.cachelen. ')'
  let self.pos = getpos('.')
  let self.changedtick = b:changedtick
endfunction
"}}}

function! s:_rounder.highlight_region() "{{{
  let pat = '.\%>''\[.*\%<''\]..'
  call add(self._match_ids, matchadd('Visual', pat))
endfunction
"}}}

function! s:_rounder.clear_highlight() "{{{
  if !exists('self._match_ids')
    return
  end
  for id in self._match_ids
    try
      call matchdelete(id)
    catch
    endtry
  endfor
endfunction
"}}}
function! s:_rounder._round_idx(incdec) "{{{
  if self.idx==-1
    if @"!=yankround#_get_cache_and_regtype(0)[0]
      return 0
    else
      let self.idx = 0
    end
  end
  let self.idx += a:incdec
  return self.idx>=self.cachelen ? 0 : self.idx<0 ? self.cachelen-1 : self.idx
endfunction
"}}}
function! s:_release_rounder() "{{{
  unlet s:rounder
  aug yankround_rounder
    autocmd!
  aug END
  let g:yankround#stop_caching = 0
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
  call s:rounder.highlight_region()
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
  return has_key(s:, 'rounder') && s:rounder.is_valid()
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
