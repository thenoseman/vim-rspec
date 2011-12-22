"
" Vim Rspec
" Last change: March 5 2009
" Version> 0.0.5
" Maintainer: Eustáquio 'TaQ' Rangel
" License: GPL
" URL: git://github.com/taq/vim-rspec
"
" Script to run the spec command inside Vim
" To install, unpack the files on your ~/.vim directory and source it 
"
" The following options can be set/overridden in your .vimrc
"   * g:RspecRBFilePath      :: Path to vim-rspec.rb
"   * g:RspecBin             :: Rspec binary command (in rspec 2 this is 'rspec')
"   * g:RspecOpts            :: Opts to send to rspec call
"   * g:RspecSplitHorizontal :: Set to 1 to cause horizontal split (default:0)

let s:hpricot_cmd    = ""
let s:hpricot      = 0
let s:helper_dir = expand("<sfile>:h")

function! s:find_hpricot()
  return system("gem search -i hpricot")
endfunction

function! s:error_msg(msg)
  echohl ErrorMsg
  echo a:msg
  echohl None
endfunction

function! s:notice_msg(msg)
  echohl MoreMsg
  echo a:msg
  echohl None
endfunction

function! s:fetch(varname, default)
  if exists("g:".a:varname)
    return eval("g:".a:varname)
  else
    return a:default
  endif
endfunction

function! s:createOutputWin()
  if !exists("g:RspecSplitHorizontal")
    let g:RspecSplitHorizontal=0
  endif

  let splitLocation = "botright "

  if bufexists('RSpecOutput')
    silent! bw! RSpecOutput
  end

  if g:RspecSplitHorizontal == 1
    silent! exec splitLocation . ' ' . ' new'
  else
    silent! exec splitLocation . ' ' . ' vnew'
  end
  silent! exec "edit RSpecOutput"
endfunction

function! s:RunSpecMain(type)
  let l:bufn = bufname("%")

  if len(s:hpricot_cmd)<1
    let s:hpricot_cmd = s:find_hpricot()
    let s:hpricot = match(s:hpricot_cmd,'true')>=0
  end

  if !s:hpricot
    call s:error_msg("You need the hpricot gem or xsltproc to run this script.")
    return
  end

  " find the installed rspec command
  let l:default_cmd = ""
  if executable("spec")==1
    let l:default_cmd = "spec"
  elseif executable("rspec")==1
    let l:default_cmd = "rspec"
  end

  " filter
  let l:filter = "ruby ". s:fetch("RspecRBPath", s:helper_dir."/vim-rspec.rb")

  " run just the current file
  if a:type=="file"
    if match(l:bufn,'_spec.rb')>=0
      call s:notice_msg("Running spec on the current file...")
      let l:spec_bin = s:fetch("RspecBin",l:default_cmd)
      let l:spec_opts = s:fetch("RspecOpts", "")
      let l:spec = l:spec_bin . " " . l:spec_opts . " -f h " . l:bufn
    else
      call s:error_msg("Seems ".l:bufn." is not a *_spec.rb file")
      return
    end
  else
    let l:dir = expand("%:p:h")
    if isdirectory(l:dir."/spec")>0
      call s:notice_msg("Running spec on the spec directory ...")
    else
      " try to find a spec directory on the current path
      let l:tokens = split(l:dir,"/")
      let l:dir = ""
      for l:item in l:tokens
        call remove(l:tokens,-1)
        let l:path = "/".join(l:tokens,"/")."/spec"
        if isdirectory(l:path)
          let l:dir = l:path
          break
        end
      endfor
      if len(l:dir)>0
        call s:notice_msg("Running spec with on the spec directory found (".l:dir.") ...")
      else
        call s:error_msg("No ".l:dir."/spec directory found")
        return
      end
    end
    if isdirectory(l:dir)<0
      call s:error_msg("Could not find the ".l:dir." directory.")
      return
    end
    let l:spec = s:fetch("RspecBin", "spec") . s:fetch("RspecOpts", "")
    let l:spec = l:spec . " -f h " . l:dir . " -p **/*_spec.rb"
  end

  " run the spec command
  let s:cmd  = l:spec." | ".l:filter
  echo


  "put the result on a new buffer
  call s:createOutputWin()
  setl buftype=nofile
  silent exec "r! ".s:cmd
  setl syntax=vim-rspec
  silent exec "nnoremap <buffer> <cr> :call <SID>TryToOpen()<cr>"
  silent exec 'nnoremap <silent> <buffer> n /\/.*\:<cr>:call <SID>TryToOpen()<cr>'
  silent exec 'nnoremap <silent> <buffer> N ?/\/.*\:<cr>:call <SID>TryToOpen()<cr>'
  silent exec "nnoremap <buffer> q :q<CR>"
  setl nolist
  setl nohls
  setl foldmethod=expr
  setl foldexpr=getline(v:lnum)=~'^\+'
  setl foldtext=\"+--\ \".string(v:foldend-v:foldstart+1).\"\ passed\ \"
  call cursor(1,1)

endfunction

function! s:TryToOpen()
  let l:line = getline(".")
  if match(l:line,'^  [\/\.]')<0
    call s:error_msg("No file found.")
    return
  end
  let l:tokens = split(l:line,":")

  " move back to the other window, if available
  " if there is no other window this will do nothing
  wincmd w

  " open the file in question (either in the split)
  " that was already open, or in the current win
  exec "e ".substitute(l:tokens[0],'/^\s\+',"","")
  call cursor(l:tokens[1],1)
endfunction

function! RunSpec()
  call s:RunSpecMain("file")
endfunction

function! RunSpecs()
  call s:RunSpecMain("dir")
endfunction

command! RunSpec  call RunSpec()
command! RunSpecs  call RunSpecs()
