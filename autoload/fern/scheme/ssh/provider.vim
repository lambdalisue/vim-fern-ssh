let s:Promise = vital#fern#import('Async.Promise')
let s:AsyncLambda = vital#fern#import('Async.Lambda')

function! fern#scheme#ssh#provider#new() abort
  return {
        \ 'get_root': funcref('s:provider_get_root'),
        \ 'get_parent' : funcref('s:provider_get_parent'),
        \ 'get_children' : funcref('s:provider_get_children'),
        \}
endfunction

function! s:provider_get_root(uri) abort
  call fern#logger#debug(a:uri)
  let fri = fern#fri#parse(a:uri)
  call fern#logger#debug(fri)
  let root = s:node(fri.authority, fri.path, 1)
  call fern#logger#debug(root)
  return root
endfunction

function! s:provider_get_parent(node, ...) abort
  if fern#internal#filepath#is_root(a:node._path)
    return s:Promise.reject('no parent node exists for the root')
  endif
  try
    let path = fern#internal#filepath#to_slash(a:node._path)
    let parent = fern#internal#path#dirname(path)
    let parent = fern#internal#filepath#from_slash(parent)
    return s:Promise.resolve(s:node(a:node._host, parent, 1))
  catch
    return s:Promise.reject(v:exception)
  endtry
endfunction

function! s:provider_get_children(node, ...) abort
  let token = a:0 ? a:1 : s:CancellationToken.none
  let host = a:node._host
  let conn = fern_ssh#connection#new(host)
  return s:list_entries(conn, a:node._path, token)
        \.then(s:AsyncLambda.map_f({ v -> s:safe(funcref('s:node', [host] + v)) }))
        \.then(s:AsyncLambda.filter_f({ v -> !empty(v) }))
endfunction

function! s:node(host, path, isdir) abort
  let status = a:isdir
  let name = fern#internal#path#basename(fern#internal#filepath#to_slash(a:path))
  let sshpath = fern#fri#format(fern#fri#new({
        \ 'scheme': 'ssh',
        \ 'authority': a:host,
        \ 'path': a:path,
        \}))
  let bufname = status
        \ ? fern#fri#format(fern#fri#new({
        \     'scheme': 'fern',
        \     'path': sshpath,
        \   }))
        \ : sshpath
  return {
        \ 'name': name,
        \ 'status': status,
        \ 'hidden': name[:0] ==# '.',
        \ 'bufname': bufname,
        \ '_path': a:path,
        \ '_host': a:host,
        \}
endfunction

function! s:safe(fn) abort
  try
    return a:fn()
  catch
    return v:null
  endtry
endfunction

function! s:list_entries(conn, path, token) abort
  let prefix = a:path ==# '' ? '' : (a:path . '/')
  return a:conn.start(['ls', '-1AUF', a:path], {
        \   'token': a:token,
        \   'reject_on_failure': 1,
        \})
        \.catch({ v -> s:Promise.reject(join(v.stderr, "\n")) })
        \.then({ v -> v.stdout })
        \.then(s:AsyncLambda.filter_f({ v -> !empty(v) }))
        \.then(s:AsyncLambda.map_f({ v -> prefix . v }))
        \.then(s:AsyncLambda.map_f({ v -> s:list_entries_item(v) }))
endfunction

function! s:list_entries_item(path) abort
  if a:path[-1:] == '/'
    return [a:path[:-2], 1]
  else
    return [a:path, 0]
  endif
endfunction
