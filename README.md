#yankround.vim
レジスタの履歴を取得・再利用する。

###概要
*yankround* はレジスタの履歴を取得し、再利用するためのVimプラグインです。 `YankRing.vim`と似た役割・操作性を持ちますが、キーマッピング置き換えによる副作用を少なくしています。  

また、`unite.vim`や、`ctrlp.vim`による履歴の閲覧もサポートしています。 `unite.vim`の機能を使う場合は`unite.vim`(https://github.com/Shougo/unite.vim) `ctrlp.vim`の機能を使う場合は`ctrlp.vim`(https://github.com/kien/ctrlp.vim) をインストールして下さい。  

最新版:  
https://github.com/LeafCage/yankround.vim  


##使い方
####YankRing.vim的な利用法
まず以下の設定をしてください。  

```vim
nmap p <Plug>(yankround-p)
xmap p <Plug>(yankround-p)
nmap P <Plug>(yankround-P)
nmap gp <Plug>(yankround-gp)
xmap gp <Plug>(yankround-gp)
nmap gP <Plug>(yankround-gP)
nmap <C-p> <Plug>(yankround-prev)
nmap <C-n> <Plug>(yankround-next)
```

p でテキストの貼り付けを行った後、&lt;C-p&gt;&lt;C-n&gt;で貼り付けたテキストを前の履歴・次の履歴に置き換えます。カーソルを動かすと置き換えは確定されます。   

####unite.vimによる履歴の閲覧
`unite-source-yankround`を実行して下さい。  

```vim
:Unite yankround
```

レジスタ履歴が一覧表示されます。デフォルトのアクションでカーソル位置に挿入します。&lt;Tab&gt;(`<Plug>(unite_choose_action)`)で詳細アクションを選択します。   

####ctrlp.vimによる履歴の閲覧
`:CtrlPYankRound`コマンドを実行してください。  
レジスタ履歴が一覧表示されます。履歴を選択後、  

- `<CR>`で、その履歴をカーソル位置の前に挿入します。`P`
- `<C-v>`で、その履歴をカーソル位置の後ろに挿入します。`p`
- `<C-s>`(`<C-x>`, `<C-CR>`)で、無名レジスタ `"` にその履歴をセットします。
- `<C-z>`でマークして、`<F7>`でその履歴を履歴から削除します。

