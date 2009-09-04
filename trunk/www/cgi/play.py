#!/usr/bin/env python
# A script to proxy a URL with pre-processing, such as extracting the FLV url from a youtube URL
# or extracting a list of image files from a web page.

import urllib, re

# result variable is set when invoked as CGI
if not globals().has_key('result') and __name__ == '__main__':
    import sys
    result = sys.stdout
    if len(sys.argv) > 1: url = sys.argv[1]
    else: exit('Usage: ' + sys.argv[0] + ' http-url')

url = urllib.unquote(url)

_syntax = re.compile('(?P<scheme>[a-zA-Z][a-zA-Z0-9\+\-\.]*):(?:\/\/)?'  # scheme: 'http', 'rtmp', 'https'
            + '(?:(?:(?P<user>[a-zA-Z0-9\-\_\.\!\~\*\'\(\)&=\+\$,;\?\/\%]+)' # user
            + '(?::(?P<password>[^:@;\?]+))?)@)?' # password
            + '(?:(?:(?P<host>[^;\?:/]*)(?::(?P<port>[\d]+))?))'  # host, port
            + '(?:(?P<path>[^;\?]+)?)' # path
            + '(?:;(?P<params>[^\?]*))?' # parameters
            + '(?:\?(?P<headers>.*))?$') # headers

class myobject: pass
u = myobject()

u.__dict__ = dict(zip(('scheme', 'user', 'password', 'host', 'port', 'path', 'parameters', 'headers'), _syntax.match(url or '').groups()))

videoid = slideid = None
if u.scheme == 'http' and u.path is not None:
    if re.match('(([a-z][a-z]\.)|(www\.))?youtube\.', u.host or ''):
        videoid = u.path[3:] if u.path.startswith('/v/') else (filter(lambda x: x.startswith('v='), u.headers.split('&') if u.headers else [])[0][2:] if u.path.startswith('/watch') else '')
    elif u.host == 'www.slideshare.net' and not u.path.startswith('/secret'):
        slideid = u.path[1:]

# print videoid, slideid

if videoid:
    print 'getting for videoid', videoid
    data = dict(map(lambda y: (y[0], y[2]), map(lambda x: x.partition('=') , urllib.urlopen('http://youtube.com/get_video_info?video_id=' + videoid).read().split('&'))))
    url = 'http://www.youtube.com/get_video.php?video_id=' + videoid + '&t=' + data['token'];
    # headers = get_headers(url,1);
    #if !is_array(headers['Location']): url = $headers['Location'];
    #else:
    #    for h in headers['Location']:
    #        if strpos(h,'googlevideo.com') != false: url = h; break
    if 'mode' in locals() and mode == 'proxy': # force a proxy mode
        data = urllib.urlopen(url).read()
        print >>result, '200 OK'
        print >>result, 'Content-Length: %d\n'%(len(data))
        result.write(data)
    else: # else redirect to the url
        print >>result, '302 Redirect'
        print >>result, 'Location:', url
elif slideid:
    data = urllib.urlopen('http://www.slideshare.net/' + slideid).read()
    matches = re.search('"doc":\s*"([^"]+)"', data)
    if matches:
        url = 'http://cdn.slideshare.net/' + matches.groups()[0] + '.xml'
        data = urllib.urlopen(url).read().lower().replace("<slide", "<image") # Converts <Show>,<Slide Src.../> to lower. TODO: what if Src URL has upper?
        print >>result, '200 OK\n'
        print >>result, data
    elif re.search('marked\sprivate', data):
        print >>result, '403 Private'
    else:
        print >>result, '404 Not Found'
elif url:
    if 'mode' in locals() and mode == 'proxy': # force a proxy mode
        data = urllib.urlopen(url).read()
        print >>result, '200 OK'
        print >>result, 'Content-Length: %d\n'%(len(data))
        result.write(data)
    else: # else redirect to the url
        print >>result, '302 Redirect'
        print >>result, 'Location:', url
else:
    print >>result, '400 Please specify a url parameter'

