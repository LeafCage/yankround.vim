if exists('s:save_cpo')| finish| endif
let s:save_cpo = &cpo| set cpo&vim
"=============================================================================
let s:CTRLP_BUILTINS = ctrlp#getvar('g:ctrlp_builtins')
"======================================
let s:ctrlp_yankcache_var = {'lname': 'yankcache', 'sname': 'ynkc', 'typs': 'tabe', 'sort': 0}
let s:ctrlp_yankcache_var.init = 'ctrlp#yankcache#init()'
let s:ctrlp_yankcache_var.accept = 'ctrlp#yankcache#accept'
let g:ctrlp_ext_vars = add(get(g:, 'ctrlp_ext_vars', []), s:ctrlp_yankcache_var)
unlet s:ctrlp_yankcache_var
let s:index_id = s:CTRLP_BUILTINS + len(g:ctrlp_ext_vars)
function! ctrlp#yankcache#id() "{{{
  return s:index_id
endfunction
"}}}
function! ctrlp#yankcache#init() "{{{
  return map(copy(g:yankcache#cache), 's:_change_regmodechar(v:val[0]). "\t". strtrans(v:val[1])')
endfunction
"}}}
function! ctrlp#yankcache#accept(action, str) "{{{
  call ctrlp#exit()
  let str = a:str
  let strlist = map(copy(g:yankcache#cache), 's:_change_regmodechar(v:val[0]). "\t". strtrans(v:val[1])')
  let idx = index(strlist, str)
  if a:action=='t'
    call remove(g:yankcache#cache, idx)
    call ctrlp#init(ctrlp#yankcache#id())
    return
  end
  call setreg('"', g:yankcache#cache[idx][1], g:yankcache#cache[idx][0])
  if a:action!='h'
    exe 'norm! ""'. (col('$')-col('.')<=1 ? 'p': 'P')
  end
endfunction
"}}}
unlet s:CTRLP_BUILTINS

"======================================
function! s:_change_regmodechar(char) "{{{
  return a:char==#'v' ? 'c' : a:char==#'V' ? 'l' : a:char
endfunction
"}}}

"=============================================================================
"END "{{{1
let &cpo = s:save_cpo| unlet s:save_cpo
