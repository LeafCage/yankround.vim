if !(exists('*neobundle#get') && neobundle#get('ctrlp.vim')!={} || get(g:, 'loaded_ctrlp'))
  finish
endif
command! -nargs=0   CtrlPYankRound    call ctrlp#init(ctrlp#yankround#id())
