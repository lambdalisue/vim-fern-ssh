let s:Process = vital#fern#import("Async.Promise.Process")


function! fern_ssh#connection#new(host) abort
  let conn = {
        \ "host": a:host,
        \ "start": funcref("s:connection_start"),
        \}
  return conn
endfunction

function! s:connection_start(args, ...) abort dict
  let options = copy(a:0 ? a:1 : {})
  let args = ['ssh', '-T', '-x', self.host, s:cmdline(a:args)]
  call fern#logger#debug(args)
  return s:Process.start(args, options)
endfunction

function! s:cmdline(args) abort
  let args = copy(a:args)
  " let args = map(args, { -> escape(v:val, ' \')})
  return join(args, ' ')
endfunction
