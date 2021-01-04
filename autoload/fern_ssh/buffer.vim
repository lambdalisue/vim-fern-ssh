let s:Lambda = vital#fern#import('Lambda')
let s:Promise = vital#fern#import('Async.Promise')

function! fern_ssh#buffer#read() abort
  augroup fern_ssh_buffer_read
    autocmd! * <buffer>
    autocmd BufReadCmd <buffer> ++nested call s:BufReadCmd()
    autocmd BufWriteCmd <buffer> ++nested call s:BufWriteCmd()
  augroup END

  setlocal buftype=acwrite
  filetype detect
  return s:BufReadCmd()
endfunction

function! fern_ssh#buffer#write() abort
  return s:BufWriteCmd()
endfunction


function! s:BufReadCmd() abort
  let fri = fern#fri#parse(expand('<afile>'))
  let conn = fern_ssh#connection#new(fri.authority)
  let bufnr = expand('<abuf>') + 0
  return conn.start(['cat', fri.path], {
        \ 'reject_on_failure': v:true,
        \})
        \.then({ r -> r.stdout })
        \.then({ c -> fern#internal#buffer#replace(bufnr, c) })
        \.catch({e -> fern#logger#error(e) })
endfunction

function! s:BufWriteCmd() abort
  let fri = fern#fri#parse(expand('<afile>'))
  let conn = fern_ssh#connection#new(fri.authority)
  let bufnr = expand('<abuf>') + 0
  let content = getbufline(bufnr, 1, '$')
  return conn.start([printf('cat > %s', escape(fri.path, '\'))], {
        \ 'stdin': s:Promise.resolve(content),
        \ 'reject_on_failure': v:true,
        \})
        \.then({ -> setbufvar(bufnr, "&modified", 0) })
        \.catch({e -> fern#logger#error(e) })
endfunction
