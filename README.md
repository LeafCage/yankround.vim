#yankround.vim
レジスタの履歴を取得・再利用する。

##概要
*yankround* はレジスタの履歴を取得し、再利用するためのVimプラグインです。`YankRing.vim`と似た役割・操作性を持ちますが、キーマッピング置き換えによる副作用を少なくしています。  
`ctrlp.vim`の機能を使う場合は`ctrlp.vim`をインストールして下さい。  

最新版:  
https://github.com/LeafCage/yankround.vim  


##使い方
####YankRing.vim的な利用法
まず以下の設定をしてください。  

```vim
nmap p <Plug>(yankround-p)
nmap P <Plug>(yankround-P)
nmap gp <Plug>(yankround-gp)
nmap gP <Plug>(yankround-gP)
nmap <C-p> <Plug>(yankround-prev)
nmap <C-n> <Plug>(yankround-next)
```

p でテキストの貼り付けを行った後、&lt;C-p&gt;&lt;C-n&gt;で貼り付けたテキストを前の履歴・次の履歴に置き換えます。カーソルを動かすと置き換えは確定されます。  

####ctrlp.vimによる履歴の閲覧
`:CtrlPYankRound`コマンドを実行してください。  
レジスタ履歴が一覧表示されます。履歴を選択後、  
 - &lt;CR&gt;で、その履歴をカーソル位置に挿入します。
 - &lt;C-x&gt;(&lt;C-s&gt;)で、無名レジスタ " にその履歴をセットします。
 - &lt;C-t&gt;で、その履歴を履歴から削除します。
