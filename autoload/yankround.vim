if exists('s:save_cpo')| finish| endif
let s:save_cpo = &cpo| set cpo&vim
"=============================================================================
let s:Rounder = {}
function! s:newRounder(keybind, is_vmode) "{{{
  let obj = {'keybind': a:keybind, 'count': v:count1, 'register': v:register, 'idx': -1, 'match_id': 0,
    \ 'in_cmdwin': bufname('%')==#'[Command Line]', 'anchortime': localtime(), 'is_vmode': a:is_vmode}
  if !obj.in_cmdwin && undotree().seq_last!=0
    let obj.undofilepath = expand(g:yankround_dir).'/save_undo'
    exe 'wundo!' fnameescape(obj.undofilepath)
  end
  call extend(obj, s:Rounder)
  return obj
endfunction
"}}}
function! s:Rounder.activate() "{{{
  let self.pos = getpos('.')
  call self.update_changedtick()
  let self.using_region_hl = g:yankround_use_region_hl
  if self.using_region_hl
    call self._region_hl(getregtype(self.register))
  end
endfunction
"}}}
function! s:Rounder._region_hl(regtype) "{{{
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

function! s:Rounder.update_changedtick() "{{{
  let self.changedtick = b:changedtick
endfunction
"}}}

function! s:Rounder.is_cursormoved() "{{{
  return getpos('.')!=s:rounder.pos
endfunction
"}}}
function! s:Rounder.is_valid() "{{{
  if get(self, '_cachelen', 1) != 0 && has_key(self, 'changedtick') && self.changedtick==b:changedtick
    return 1
  end
  call s:destroy_rounder()
endfunction
"}}}

function! s:Rounder.round_cache(delta) "{{{
  let self._cachelen = len(g:_yankround_cache)
  if !self.is_valid()
    return
  end
  let g:_yankround_stop_caching = 1
  let self.idx = self._round_idx(a:delta)
  let [str, regtype] = yankround#_get_cache_and_regtype(self.idx)
  call setreg('"', str, regtype)
  silent undo
  call self._rest_undotree()
  if self.is_vmode
    silent exe 'norm! gv"0'. self.count. self.keybind
  else
    silent exe 'norm! ""'. self.count. self.keybind
  end
  if self.using_region_hl
    call self.clear_region_hl()
    call self._region_hl(regtype)
  end
  let self.pos = getpos('.')
  call self.update_changedtick()
endfunction
"}}}
function! s:Rounder._round_idx(delta) "{{{
  if self.idx==-1
    if @"!=yankround#_get_cache_and_regtype(0)[0] || self.register!='"'
      return 0
    else
      let self.idx = self.is_vmode ? 1 : 0
    end
  end
  let self.idx += a:delta
  return self.idx>=self._cachelen ? 0 : self.idx<0 ? self._cachelen-1 : self.idx
endfunction
"}}}
function! s:Rounder._rest_undotree() "{{{
  if self.in_cmdwin
    return
  elseif has_key(self, 'undofilepath')
    silent exe 'rundo' fnameescape(self.undofilepath)
    return
  end
  let save_ul = &undolevels
  set ul=-1
  call setline('.', getline('.'))
  set nomod
  let &ul = save_ul
endfunction
"}}}

function! s:Rounder.clear_region_hl() "{{{
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

let s:BaseCmdline = {}
function! s:newBaseCmdline() "{{{
  let obj = copy(s:BaseCmdline)
  let obj.idx = -1
  let obj.pos = getpos('.')
  let obj.line = getcmdline()
  let cursor = getcmdpos()-1
  let obj.head = obj.line[:cursor-1]
  let obj.tail = obj.line[cursor :]
  return obj
endfunction
"}}}
function! s:BaseCmdline.is_identical(context) "{{{
  return self.pos==getpos('.') && stridx(a:context.line, self.head)==0 && a:context.line[a:context.cursor :]==self.tail
endfunction
"}}}
function! s:BaseCmdline.get_popstr(context, delta) "{{{
  let self._cachelen = len(g:_yankround_cache)
  if self._cachelen==0
    return ''
  elseif self.idx==-1
    let self.idx = 0
    let self.origin = a:context.line[len(self.head)-1 : a:context.cursor-1]
    let str = self._get_yankcache()
    if str !=# self.origin
      return str
    end
  end
  let self.idx += a:delta
  let self.idx = self.idx>self._cachelen ? 0 : self.idx<0 ? self._cachelen : self.idx
  return self._get_yankcache()
endfunction
"}}}
function! s:BaseCmdline.replace_cmdline(str) "{{{
  let upper = self.head. a:str
  call setcmdpos(len(upper) +1)
  return upper. self.tail
endfunction
"}}}
function! s:BaseCmdline._get_yankcache() "{{{
  if self.idx==self._cachelen
    return self.origin
  end
  let [str, regtype] = yankround#_get_cache_and_regtype(self.idx)
  return substitute(substitute(str, '\%(^\|\n\)\@<=\s*\n\|\n$', '', 'g'), '\n', '| ', 'g')
endfunction
"}}}


"=============================================================================
"Main:
function! yankround#init(keybind, ...) "{{{
  let is_vmode = a:0
  if has_key(s:, 'rounder')
    call s:destroy_rounder()
  end
  if getregtype()!=''
    let s:rounder = s:newRounder(a:keybind, is_vmode)
  end
  if !is_vmode || v:register!='"'
    return 'norm! '. (is_vmode ? 'gv' : ''). '"'. v:register. v:count1. a:keybind
  end
  let @0 = @"
  return 'norm! gv"0'. v:count1. a:keybind
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
  call Yankround_append()
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
  return has_key(s:, 'rounder') ? '('. (s:rounder.idx+1). '/'. s:rounder._cachelen. ')' : ''
endfunction
"}}}

"--------------------------------------
function! yankround#is_cmdline_popable() "{{{
  let context = {'line': getcmdline(), 'cursor': getcmdpos()-1}
  let ret = exists('s:basecmdline') && s:basecmdline.is_identical(context)
  if !ret
    unlet! s:basecmdline
  end
  return ret
endfunction
"}}}
function! yankround#cmdline_base() "{{{
  let s:basecmdline = s:newBaseCmdline()
  return s:basecmdline.line
endfunction
"}}}
function! yankround#cmdline_pop(delta) "{{{
  let context = {'line': getcmdline(), 'cursor': getcmdpos()-1}
  if !(exists('s:basecmdline') && s:basecmdline.is_identical(context))
    unlet! s:basecmdline
    return context.line
  end
  let str = s:basecmdline.get_popstr(context, a:delta)
  return str=='' ? context.line : s:basecmdline.replace_cmdline(str)
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
