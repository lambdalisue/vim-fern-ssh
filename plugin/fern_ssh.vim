if exists('g:fern_ssh_loaded')
  finish
endif
let g:fern_ssh_loaded = 1


function! s:BufReadCmd() abort
  call fern_ssh#buffer#read()
endfunction

function! s:BufWriteCmd() abort
  call fern_ssh#buffer#write()
endfunction

augroup fern_ssh_internal
  autocmd! *
  autocmd BufReadCmd ssh://* ++nested call s:BufReadCmd()
  autocmd BufWriteCmd ssh://* ++nested call s:BufWriteCmd()
  autocmd SessionLoadPost ssh://* ++nested call s:BufReadCmd()
augroup END
