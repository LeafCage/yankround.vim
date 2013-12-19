if exists('s:save_cpo')| finish| endif
let s:save_cpo = &cpo| set cpo&vim
"=============================================================================
let s:_rounder = {}
function! s:new_rounder(keybind) "{{{
  let _ = {'keybind': a:keybind, 'count': v:count1, 'register': v:register, 'idx': -1, 'stop': 0, 'match_id': 0}
  call extend(_, s:_rounder)
  return _
endfunction
"}}}
function! s:_rounder.activate() "{{{
  let self.pos = getpos('.')
  let self.changedtick = b:changedtick
  let self.using_region_hl = g:yankround_use_region_hl
  let self.anchortime = localtime()
  if self.using_region_hl
    let t:yankround_anchor = self.anchortime
    let w:yankround_anchor = self.anchortime
    call self._region_hl(getregtype(self.register))
  end
  aug yankround_rounder
    autocmd!
    autocmd CursorMoved *   call s:rounder.detect_cursmoved()
    autocmd BufWritePost *  call s:rounder.destroy()
    autocmd CmdwinEnter *   let s:rounder.stop = 1
    autocmd CmdwinLeave *   let s:rounder.stop = 0
  aug END
endfunction
"}}}
function! s:_rounder._region_hl(regtype) "{{{
  let [sl, sc] = [line("'["), col("'[")]
  let [el, ec] = [line("']"), col("']")]
  let pat =
    \ a:regtype[0]==#"\<C-v>" ? printf('\v%%>%dl%%>%dc.*%%<%dl%%<%dc', sl-1, sc-1, el+1, ec+1) :
    \ a:regtype[0]==#'v' ? printf('\v%%%dl%%>%dc\_.*%%%dl%%<%dc', sl, sc-1, el, ec+1) :
    \ sl==el ? '\%'.sl.'l' : printf('\v%%%dl\_.*%%%dl', sl, el)
  let self.match_id = matchadd(g:yankround_region_hl_groupname, pat)
endfunction
"}}}

function! s:_rounder.detect_cursmoved() "{{{
  if self.stop || getpos('.')==self.pos
    return
  end
  call s:rounder.destroy()
endfunction
"}}}
function! s:_rounder.is_valid() "{{{
  if get(self, 'cachelen', 1) != 0 && self.changedtick==b:changedtick
    return 1
  end
  call s:rounder.destroy()
endfunction
"}}}
function! s:_rounder.round_cache(incdec) "{{{
  let self.cachelen = len(g:_yankround_cache)
  if !self.is_valid()
    return
  end
  let g:_yankround_stop_caching = 1
  let self.idx = self._round_idx(a:incdec)
  let [str, regtype] = yankround#_get_cache_and_regtype(self.idx)
  call setreg('"', str, regtype)
  silent undo
  silent exe 'norm!' self.count. '""'. self.keybind
  ec 'yankround: ('. (self.idx+1). '/'. self.cachelen. ')'
  if self.using_region_hl
    call matchdelete(self.match_id)
    call self._region_hl(regtype)
  end
  let self.pos = getpos('.')
  let self.changedtick = b:changedtick
endfunction
"}}}
function! s:_rounder._round_idx(incdec) "{{{
  if self.idx==-1
    if @"!=yankround#_get_cache_and_regtype(0)[0] || self.register!='"'
      return 0
    else
      let self.idx = 0
    end
  end
  let self.idx += a:incdec
  return self.idx>=self.cachelen ? 0 : self.idx<0 ? self.cachelen-1 : self.idx
endfunction
"}}}

function! s:_rounder.destroy() "{{{
  if self.using_region_hl
    call self._clear_region_hl()
  end
  unlet s:rounder
  aug yankround_rounder
    autocmd!
  aug END
  let g:_yankround_stop_caching = 0
endfunction
"}}}

function! s:_rounder._clear_region_hl() "{{{
  let save_here = [tabpagenr(), winnr(), winsaveview()]
  if !has_key(t:, 'yankround_anchor') && !s:_caught_tabpage_anchor(self.anchortime)
    echoerr 'yankround: match ID '. self.match_id. ' is not found.'
    return
  end
  if !has_key(w:, 'yankround_anchor') && !s:_caught_win_anchor(self.anchortime)
    silent exe 'tabn' save_here[0]
    call winrestview(save_here[2])
    echoerr 'yankround: match ID '. self.match_id. ' is not found.'
    return
  end
  call matchdelete(self.match_id)
  unlet t:yankround_anchor w:yankround_anchor
  silent exe 'tabn' save_here[0]
  silent exe save_here[1].'wincmd w'
  call winrestview(save_here[2])
endfunction
"}}}
function! s:_caught_tabpage_anchor(anchortime) "{{{
  for tn in range(1, tabpagenr('$'))
    if gettabvar(tn, 'yankround_anchor')==a:anchortime
      silent exe 'tabn' tn
      return 1
    end
  endfor
endfunction
"}}}
function! s:_caught_win_anchor(anchortime) "{{{
  for wn in range(1, winnr('$'))
    if getwinvar(wn, 'yankround_anchor')==a:anchortime
      silent exe wn.'wincmd w'
      return 1
    end
  endfor
endfunction
"}}}


"=============================================================================
"Main
function! yankround#init(keybind) "{{{
  if has_key(s:, 'rounder')
    call s:rounder.destroy()
  end
  let s:rounder = s:new_rounder(a:keybind)
  return 'norm! "'. v:register. v:count1. a:keybind
endfunction
"}}}
function! yankround#activate() "{{{
  call s:rounder.activate()
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

"======================================
function! yankround#_get_cache_and_regtype(idx) "{{{
  let ret = matchlist(g:_yankround_cache[a:idx], '^\(.\d*\)\t\(.*\)')
  return [ret[2], ret[1]]
endfunction
"}}}

"=============================================================================
"END "{{{1
let &cpo = s:save_cpo| unlet s:save_cpo
