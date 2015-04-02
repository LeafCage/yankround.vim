if exists(':CtrlP')
  command! -nargs=0   CtrlPYankRound    call ctrlp#init(ctrlp#yankround#id())
end
