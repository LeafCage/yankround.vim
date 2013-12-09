if exists('s:save_cpo')| finish| endif
let s:save_cpo = &cpo| set cpo&vim
"=============================================================================
let s:_rounder = {}
function! s:new_rounder(keybind) "{{{
  let _ = {'pos': getpos('.'), 'idx': -1, 'keybind': a:keybind, 'count': v:prevcount==0 ? 1 : v:prevcount,
    \ 'changedtick': b:changedtick, 'match_id': 0}
  call extend(_, s:_rounder)
  if g:yankround_use_region_hl
    call _.region_hl(getregtype('"'))
  end
  return _
endfunction
"}}}
function! s:_rounder.region_hl(regtype) "{{{
  if a:regtype[0]=="\<C-v>"
    let [sl, sc] = [line("'["), col("'[")]
    let [el, ec] = [line("']"), col("']")]
    let pat = printf('\v\c%%>%dl%%>%dc.*%%<%dl%%<%dc', sl-1, sc-1, el+1, ec+1)
  else
    let pat = '.\%>''\[.*\%<''\]..'
  end
  let self.match_id = matchadd(g:yankround_region_hl_groupname, pat)
endfunction
"}}}
function! s:_rounder.detect_cursmoved() "{{{
  if getpos('.')==self.pos
    return
  end
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
  if g:yankround_use_region_hl
    call matchdelete(self.match_id)
    call self.region_hl(regtype)
  end
  let self.pos = getpos('.')
  let self.changedtick = b:changedtick
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
  call s:rounder._clear_region_hl()
  unlet s:rounder
  aug yankround_rounder
    autocmd!
  aug END
  let g:yankround#stop_caching = 0
endfunction
"}}}
function! s:_rounder._clear_region_hl() "{{{
  if self.match_id
    call matchdelete(self.match_id)
  end
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
