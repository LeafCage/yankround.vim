if exists('s:save_cpo')| finish| endif
let s:save_cpo = &cpo| set cpo&vim
"=============================================================================
let s:_rounder = {}
function! s:new_rounder(keybind) "{{{
  let _ = {'keybind': a:keybind, 'count': v:count1, 'register': v:register, 'idx': -1, 'match_id': 0,
    \ 'in_cmdwin': bufname('%')==#'[Command Line]', 'anchortime': localtime()}
  if !_.in_cmdwin && undotree().seq_last!=0
    let _.undofilepath = expand(g:yankround_dir).'/save_undo'
    exe 'wundo!' _.undofilepath
  end
  call extend(_, s:_rounder)
  return _
endfunction
"}}}
function! s:_rounder.activate() "{{{
  let self.pos = getpos('.')
  call self.update_changedtick()
  let self.using_region_hl = g:yankround_use_region_hl
  if self.using_region_hl
    call self._region_hl(getregtype(self.register))
  end
endfunction
"}}}
function! s:_rounder._region_hl(regtype) "{{{
  let [sl, sc] = [line("'["), col("'[")]
  let [el, ec] = [line("']"), col("']")]
  let dots = sl==el ? '.*' : '\_.*'
  let pat =
    \ a:regtype[0]==#"\<C-v>" ? printf('\v%%>%dl%%>%dc.*%%<%dl%%<%dc', sl-1, sc-1, el+1, ec+1) :
    \ a:regtype==#'v' ? printf('\v%%%dl%%>%dc%s%%%dl%%<%dc', sl, sc-1, dots, el, ec+1) :
    \ printf('\v%%%dl%s%%%dl', sl, dots, el)
  let self.match_id = matchadd(g:yankround_region_hl_groupname, pat)
  if !self.in_cmdwin
    let t:yankround_anchor = self.anchortime
    let w:yankround_anchor = self.anchortime
  end
endfunction
"}}}

function! s:_rounder.update_changedtick() "{{{
  let self.changedtick = b:changedtick
endfunction
"}}}

function! s:_rounder.is_cursormoved() "{{{
  return getpos('.')!=s:rounder.pos
endfunction
"}}}
function! s:_rounder.is_valid() "{{{
  if get(self, 'cachelen', 1) != 0 && has_key(self, 'changedtick') && self.changedtick==b:changedtick
    return 1
  end
  call s:destroy_rounder()
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
  call self._rest_undotree()
  silent exe 'norm!' self.count. '""'. self.keybind
  if self.using_region_hl
    call self.clear_region_hl()
    call self._region_hl(regtype)
  end
  let self.pos = getpos('.')
  call self.update_changedtick()
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
function! s:_rounder._rest_undotree() "{{{
  if self.in_cmdwin
    return
  elseif has_key(self, 'undofilepath')
    silent exe 'rundo' self.undofilepath
    return
  end
  let save_ul = &undolevels
  set ul=-1
  call setline('.', getline('.'))
  set nomod
  let &ul = save_ul
endfunction
"}}}

function! s:_rounder.clear_region_hl() "{{{
  if !(has_key(self, 'using_region_hl') && self.using_region_hl && self.match_id)
    return
  end
  if self.in_cmdwin
    if bufname('%')==#'[Command Line]'
      call matchdelete(self.match_id)
      let self.match_id = 0
    end
    return
  end
  let save_here = [tabpagenr(), winnr(), winsaveview()]
  if !has_key(t:, 'yankround_anchor') && !s:_caught_tabpage_anchor(self.anchortime)
    return
  end
  if !has_key(w:, 'yankround_anchor') && !s:_caught_win_anchor(self.anchortime)
    silent exe 'tabn' save_here[0]
    call winrestview(save_here[2])
    return
  end
  call matchdelete(self.match_id)
  let self.match_id = 0
  unlet t:yankround_anchor w:yankround_anchor
  try
    silent exe 'tabn' save_here[0]
    silent exe save_here[1].'wincmd w'
  catch /E523:/ "in :map-<expr>
  endtry
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
    call s:destroy_rounder()
  end
  if getregtype()!=''
    let s:rounder = s:new_rounder(a:keybind)
  end
  return 'norm! "'. v:register. v:count1. a:keybind
endfunction
"}}}
function! yankround#activate() "{{{
  if !has_key(s:, 'rounder')
    return
  end
  call s:rounder.activate()
  call s:_rounder_autocmd()
endfunction
"}}}

function! s:destroy_rounder() "{{{
  call s:rounder.clear_region_hl()
  unlet s:rounder
  aug yankround_rounder
    autocmd!
  aug END
  let g:_yankround_stop_caching = 0
endfunction
"}}}

function! yankround#prev() "{{{
  if !has_key(s:, 'rounder')
    return
  end
  call s:rounder.round_cache(1)
  echo 'yankround:' yankround#get_roundstatus()
endfunction
"}}}
function! yankround#next() "{{{
  if !has_key(s:, 'rounder')
    return
  end
  call s:rounder.round_cache(-1)
  echo 'yankround:' yankround#get_roundstatus()
endfunction
"}}}

function! yankround#is_active() "{{{
  return has_key(s:, 'rounder') && s:rounder.is_valid()
endfunction
"}}}
function! yankround#get_roundstatus() "{{{
  return has_key(s:, 'rounder') ? '('. (s:rounder.idx+1). '/'. s:rounder.cachelen. ')' : ''
endfunction
"}}}

"======================================
function! s:_rounder_autocmd() "{{{
  aug yankround_rounder
    autocmd!
    autocmd CursorMoved *   if s:rounder.is_cursormoved()| call s:destroy_rounder()| end
    autocmd BufWritePost *  call s:rounder.update_changedtick()
    autocmd InsertEnter *   call s:rounder.clear_region_hl()
  aug END
endfunction
"}}}

function! yankround#on_cmdwinenter() "{{{
  if !has_key(s:, 'rounder')
    return
  end
  let s:save_rounder = deepcopy(s:rounder)
  unlet s:rounder
  aug yankround_rounder
    autocmd!
  aug END
  let g:_yankround_stop_caching = 0
endfunction
"}}}
function! yankround#on_cmdwinleave() "{{{
  if !has_key(s:, 'save_rounder')
    return
  end
  let g:_yankround_stop_caching = 1
  let s:rounder = s:save_rounder
  call s:_rounder_autocmd()
endfunction
"}}}

function! yankround#_get_cache_and_regtype(idx) "{{{
  let ret = matchlist(g:_yankround_cache[a:idx], '^\(.\d*\)\t\(.*\)')
  return [ret[2], ret[1]]
endfunction
"}}}

"=============================================================================
"END "{{{1
let &cpo = s:save_cpo| unlet s:save_cpo
