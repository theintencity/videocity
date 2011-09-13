#!/usr/bin/env python
# A script to proxy a URL with pre-processing, such as extracting the FLV url from a youtube URL
# or extracting a list of image files from a web page.

import urllib, urllib2, urlparse, re

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
u.headers = dict([tuple(nv.split('=', 1)) for nv in u.headers.split('&')]) if u.headers else {}

videoid = slideid = videoplaylist = None
if u.scheme == 'http' and u.path is not None:
    if re.match('(([a-z][a-z]\.)|(www\.))?youtube\.', u.host or ''):
        videoplaylist = u.headers['p'] if u.path == '/view_play_list' and 'p' in u.headers else ''
        videoid = u.path[3:] if u.path.startswith('/v/') else u.headers.get('v', '' if u.path.startswith('/watch') else '')
    elif u.host == 'www.slideshare.net' and not u.path.startswith('/secret'):
        slideid = u.path[1:]

# print videoid, slideid

if videoid:
    # see https://raw.github.com/rg3/youtube-dl/2011.08.04/youtube-dl for source
    print 'getting for videoid', videoid
    if u.user and u.password: # if user/password is present, then set language, login and verify age.
        try:
            urllib2.urlopen(urllib2.Request(r'http://www.youtube.com/?hl=en&persist_hl=1&gl=US&persist_gl=1&opt_out_ackd=1')).read()
            result = urllib2.urlopen(urllib2.Request('https://www.youtube.com/signup?next=/&gl=US&hl=en', urllib.urlencode(dict(current_form='loginForm', next='/', action_login='Log In', username=kwargs.get('user'), password=kwargs.get('password'))))).read()
            if re.search(r'(?i)<form[^>]* name="loginForm"', result) is not None:
                raise ValueError('bad username or password')
            result = urllib2.urlopen(urllib2.Request('http://www.youtube.com/verify_age?next_url=/&gl=US&hl=en', urllib.urlencode(dict(next_url='/', action_confirm='Confirm')))).read()
        except: print 'unable to login: %s' % (str(sys.exc_info()[1]))
    try:
        video_webpage = urllib2.urlopen(urllib2.Request('http://www.youtube.com/watch?v=%s&gl=US&hl=en&amp;has_verified=1' % videoid)).read()
        match = re.search(r'swfConfig.*?"(http:\\/\\/.*?watch.*?-.*?\.swf)"', video_webpage)
        player_url = match and re.sub(r'\\(.)', r'\1', match.group(1))
        for el_type in ['&el=embedded', '&el=detailpage', '&el=vevo', '']:
            video_info_webpage = urllib2.urlopen(urllib2.Request('http://www.youtube.com/get_video_info?&video_id=%s%s&ps=default&eurl=&gl=US&hl=en' % (videoid, el_type))).read()
            video_info = urlparse.parse_qs(video_info_webpage)
            if 'token' in video_info: break
        if 'token' not in video_info:
            if 'reason' in video_info: raise ValueError('YouTube said: %s' % video_info['reason'][0].decode('utf-8'))
            else: raise ValueError('"token" parameter not in video info')
        video_token = urllib.unquote_plus(video_info['token'][0])
        fmt = u.headers['fmt'] if 'fmt' in u.headers else ''
        format_map = [('38', 'video'), ('37', 'mp4'), ('22', 'mp4'), ('45', 'webm'), ('35', 'flv'), ('34', 'flv'), ('43', 'webm'), ('18', 'mp4'), ('6', 'flv'), ('5', 'flv'), ('17', 'mp4'), ('13', '3gp')]
        format_list = [x for x, y in format_map]
        if 'url_encoded_fmt_stream_map' in video_info and len(video_info['url_encoded_fmt_stream_map']) >= 1:
            url_map = dict((ud['itag'], urllib.unquote(ud['url'])) for ud in [dict(pairStr.split('=') for pairStr in uds.split('&')) for uds in video_info['url_encoded_fmt_stream_map'][0].split(',')])
            existing_formats = [x for x in format_list[(format_list.find(u.headers['fmt']) if 'fmt' in u.headers and u.headers['fmt'] in format_list else 0):] if x in url_map]
            if not existing_formats: raise ValueError('no known formats available for video')
            video_url_list = [url_map[f] for f in existing_formats]
        elif 'conn' in video_info and video_info['conn'][0].startswith('rtmp'):
            video_url_list = [video_info['conn'][0]]
        else: raise ValueError('no fmt_url_map or conn found in video info')
        
        if 'mode' in locals() and mode == 'proxy' and not video_url_list[0].startswith('rtmp'): # force proxy mode
            data = urllib.urlopen(video_url_list[0]).read()
            print >>result, '200 OK'
            print >>result, 'Content-Length: %d\n'%(len(data))
            result.write(data)
        else: # else redirect to the url
            print >>result, '302 Redirect'
            print >>result, 'Location:', video_url_list[0]
    except:
        print 'unable to download from youtube: %s' %(str(sys.exc_info()[1]),)
        print >>result, '500 Internal Server Error'
elif videoplaylist:
    print 'getting for videoplaylist', videoplaylist
    data = urllib.urlopen(url).read()
    def uniq(seq):
        last = None
        for x in seq:
            if x != last:
                last = x
                yield x
    matches = [x for x in uniq(re.findall('href="/watch\?v=([^"&]+)', data))]
    if 'fmt' in u.headers: matches = ['%s&fmt=%s'%(x, u.headers['fmt']) for x in matches]
    data = "<show>%s</show>"%(''.join(['<video src="http://www.youtube.com/watch?v=%s"/>'%(id,) for id in matches]),)
    print >>result, '200 OK\n'
    print >>result, data
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
