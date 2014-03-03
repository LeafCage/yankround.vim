if exists('s:save_cpo')| finish| endif
let s:save_cpo = &cpo| set cpo&vim
"=============================================================================
function! unite#sources#yankround#define() "{{{
  return s:source
endfunction
"}}}

"=============================================================================
let s:source = {'name': 'yankround', 'description': 'candidates from yankround', 'default_kind': 'word'}
function! s:source.gather_candidates(args, context) "{{{
  return map(copy(g:_yankround_cache), 's:_candidatify(v:val)')
endfunction
"}}}
function! s:_candidatify(cache) "{{{
  let matchlist = matchlist(a:cache, "^\\(.\\d*\\)\t\\(.*\\)")
  return {'word': matchlist[2], 'action__regtype': matchlist[1], 'is_multiline': 1, 'source__raw': a:cache}
endfunction
"}}}
"==================
let s:source.action_table = {'delete': {'description': 'delete from yankround',
  \ 'is_invalidate_cache': 1, 'is_quit': 0, 'is_selectable': 1}}
function! s:source.action_table.delete.func(candidates) "{{{
  for candidate in a:candidates
    call filter(g:_yankround_cache, 'v:val!=#candidate.source__raw')
    let @" = @"==#candidate.word ? '' : @"
  endfor
endfunction
"}}}


"=============================================================================
"END "{{{1
let &cpo = s:save_cpo| unlet s:save_cpo
