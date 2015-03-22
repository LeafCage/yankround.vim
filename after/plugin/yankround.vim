if get(g:, 'ctrlp_available')
  command! -nargs=0   CtrlPYankRound    call ctrlp#init(ctrlp#yankround#id())
end
