# Copyright (c) 2009-2010, Kundan Singh. All rights reserved. See LICENSING for details.

'''
The video city project aims at web based video telephony, conferencing and sharing for variety of consumer and enterprise services.
This server side software includes a web server on port 5080 and a Flash server on port 1935. The software implements multi-party 
conference, recording, authentication and sharing of files, photos, videos in real-time as well as asynchronously.
'''

from __future__ import with_statement
import os, sys, string, cgi, time, thread, cStringIO, traceback, random, mimetypes, re
try: from OpenSSL import SSL
except: print 'WARNING: cannot import OpenSSL. Disabling crypto and HTTPS.'
try: import multitask, rtmp, webscript, restlite, restapi
except: print 'Please set PYTHONPATH to include p2p-sip/src, rtmplite/ and restlite/'; exit(-1)

import socket
from SocketServer import BaseServer
from BaseHTTPServer import HTTPServer
from SimpleHTTPServer import SimpleHTTPRequestHandler

_debug = True

#----------------------------
# WEB SERVER IMPLEMENTATION
#----------------------------

@restlite.resource
def indexfile():
    def GET(request):
        vars = request['QUERY_STRING'].split('&') if request['QUERY_STRING'] else []
        vars_dict = dict([x.split('=', 1) for x in vars if x.index('=') > 0])
        index = vars_dict.get('index', 'index')
        if not re.match(r'\w+$', index): raise restlite.Status, '403 Forbidden Index'
        if 'TARGET' in request: vars.append('target=' + request['TARGET'])
        request.start_response('200 OK', [('Content-Type', 'text/html')])
        with open(os.path.join('www', '%s.html'%(index,)), 'rb') as f:
            return str(f.read()).replace("${vars}", '&'.join(vars))
    return locals()

@restlite.resource
def webfile():
    def GET(request):
        path = os.path.join('www', request['PATH_INFO'][1:])
        type, compress = mimetypes.guess_type(path)
        if not type:
            if os.path.splitext(path)[1] == '.flv': type = "video/x-flv" 
            else: raise restlite.Status, '403 Forbidden'
        if not os.path.exists(path): raise restlite.Status, '404 Not Found'
        with open(path, 'rb') as f:
            request.start_response('200 OK', [('Content-Type', type)])
            return f.read()
    return locals()

@restlite.resource
def cgiscript():
    def GET(request):
        try:
            # TODO: this part needs to be separated out in a thread or process.
            path, params = os.path.join('www', 'cgi', request['PATH_INFO'][1:]), request['QUERY_STRING']
            # result = subprocess.Popen('python ' + path, stdout=PIPE, close_fds=True).stdout.read()
            result = cStringIO.StringIO()
            execfile(path, dict(result=result), dict([x.split('=', 2) for x in params.split('&')]))
            responseline, ignore, rest = result.getvalue().partition('\n')
            if responseline.partition(' ')[0].isdigit():
                contentLen, headers = -1, []
                while True:
                    header, ignore, rest = rest.partition('\n'); header = header.strip()
                    if header:
                        name, ignore, value = map(str.strip, header.partition(':'))
                        if name.lower() == 'content-length': contentLen = int(value)
                        headers.append((name, value))
                    else: break
                request.start_response(responseline, headers)
                if rest: return rest[:contentLen]
            else: raise restlite.Status, '500 CGI returned invalid response code ' + responseline.partition(' ')[0]
        except: traceback and traceback.print_exc(); raise restlite.Status, '500 Internal Server Error in CGI'
    return locals()

def postscript(env, start_response):
    try:
        path = env['PATH_INFO']; response = ''
        print 'path=', path
        if path not in webscript.scripts: raise Exception((403, 'Forbidden resource'))
        ctype, pdict = cgi.parse_header(env.get('CONTENT_TYPE',''))
        length = int(cgi.parse_header(env.get('CONTENT_LENGTH', '0'))[0])
        if ctype == 'multipart/form-data':
            string = env['wsgi.input'].read(length)
            fp = cStringIO.StringIO(string)
            query = cgi.parse_multipart(fp, pdict)
        else:
            string = env['wsgi.input'].read(length)
            fp = cStringIO.StringIO(string)
            query = cgi.parse_qs(string, 1)
        type, response = webscript.scripts[path](query)
        if _debug: print type, len(response), response[:100]
        headers = [('Content-Length', str(len(response)) if response else '0')]
        if response and type: headers.append(('Content-Type', type))
        start_response('200 OK', headers)
        if response: return [str(response)]
        else: return []
    except Exception, e:
        print 'Exception:', e
        if e.message and len(e.message) == 2: start_response(str(e.message[0]) + ' ' + e.message[1], [])
        else: start_response('500 ' + str(e.message))
        return []

_routes = [
    # api requests
    (r'GET,PUT,POST,DELETE /rest/(?P<type>((xml)|(plain)))/(?P<path>.*)$', 'GET,PUT,POST,DELETE /rest/%(path)s', 'ACCEPT=text/%(type)s', 'CONTENT_TYPE=text/%(type)s'),
    (r'GET,PUT,POST,DELETE /rest/(?P<type>(json))/(?P<path>.*)$', 'GET,PUT,POST,DELETE /rest/%(path)s', 'ACCEPT=application/%(type)s', 'CONTENT_TYPE=application/%(type)s'),
    (r'GET,PUT,POST,DELETE /rest/video/(?P<path>.*)$', 'GET,PUT,POST,DELETE /rest/%(path)s', 'ACCEPT=video/x-flv', 'CONTENT_TYPE=video/x-flv'),
    (r'GET,PUT,POST,DELETE /rest/swf/(?P<path>.*)$', 'GET,PUT,POST,DELETE /rest/%(path)s', 'ACCEPT=application/x-shockwave-flash', 'CONTENT_TYPE=application/x-shockwave-flash'),
    
    # for browser convenience use POST /.../put for PUT and GET /.../delete DELETE
    (r'GET,POST /rest/(?P<path>.*)/delete$', 'DELETE,DELETE /rest/%(path)s'),
    (r'POST /rest/(?P<path>.*)/put$', 'PUT /rest/%(path)s'),
    (r'GET,PUT,POST,DELETE /rest', restapi.wsgiapp),
    
    # web files
    (r'GET /(?P<lang>(hi_IN)|(en_US))/(?P<path>.*)$', 'GET /%(path)s?lang=%(lang)s'), 
    (r'GET /(?P<path>((favicon.ico)|(crossdomain.xml)|(embed)|(flvs)|(users)|(download)|(cgi))(/.*)?)', 'GET /www/%(path)s'),
    (r'GET /www/embed$', 'GET /www/embed/index.swf'),
    (r'GET /www/cgi', cgiscript),
    (r'GET /www', webfile),
    (r'POST /', postscript),
    (r'GET /index.html$', 'GET /'),
    (r'GET /(?P<query>\?.*)?$', indexfile),
    (r'GET /(?P<path>[^\?]+)(?P<query>\?.*)?$', 'GET /%(query)s', 'TARGET=%(path)s', indexfile)
]
webserver = restlite.router(_routes)
        
#----------------------------
# FLASH SERVER IMPLEMENTATION
#----------------------------

class Record(rtmp.App):
    def __init__(self):
        rtmp.App.__init__(self)
    
class Call(rtmp.App):
    def __init__(self):
        rtmp.App.__init__(self)
        self.clientId = 0 # unique client identifier for each client in this call application
    def onConnect(self, client, *args):
        result = rtmp.App.onConnect(self, client, *args)
        self.clientId += 1; client.clientId = self.clientId
        def invokeAdded(self, client): # invoke the added and published callbacks on this client, and added on other clients.
            for other in filter(lambda x: x != client, self.clients):
                yield client.call('added', str(other.clientId))
                yield other.call('added', str(client.clientId))
            for stream in filter(lambda x: x.client != client, self.publishers.values()):
                yield client.call('published', str(stream.client.clientId), stream.name)
            yield
        multitask.add(invokeAdded(self, client)) # need to invoke later so that connection is established before callback
#        if _debug:
#            def printBW(client, interval=5):
#                while True:
#                    yield multitask.sleep(interval)
#                    print 'client bandwidth up=', int(client.stream.bytesRead*8/interval*0.001),'down=', int(client.stream.bytesWritten*8/interval*0.001)
#                    client.stream.bytesRead = client.stream.bytesWritten = 0
#            self._bwthread = printBW(client)
#            multitask.add(self._bwthread)
        return result
    def onDisconnect(self, client):
        rtmp.App.onDisconnect(self, client)
        if hasattr(self, '_bwthread'): self._bwthread.close()
        def invokeRemoved(self, client): # invoke the removed callbacks on other clients
            for other in filter(lambda x: x != client, self.clients):
                yield other.call('removed', str(client.clientId))
            yield
        if filter(lambda x: x != client, self.clients): multitask.add(invokeRemoved(self, client))
        else: webscript.delete(path=client.path.partition('/')[2])
    def onPublish(self, client, stream):
        rtmp.App.onPublish(self, client, stream)
        def publishInternal(self, client, stream):
            for other in filter(lambda x: x != client, self.clients):
                yield other.call('published', str(client.clientId), stream.name)
        multitask.add(publishInternal(self, client, stream))
    def onClose(self, client, stream):
        rtmp.App.onClose(self, client, stream)
        def closeInternal(self, client, stream):
            for other in filter(lambda x: x != client, self.clients):
                yield other.call('unpublished', str(client.clientId), stream.name)
        multitask.add(closeInternal(self, client, stream))
    def onCommand(self, client, cmd, *args):
        def commandInternal(self, client, cmd, *args):
            if cmd == 'broadcast': # broadcast the command to everyone else in the call
                for other in filter(lambda x: x != client, self.clients):
                    yield other.call(cmd, str(client.clientId), *args)
            elif cmd == 'unicast': # send the command to the given identifier (identified by client.clientId).
                for other in filter(lambda x: x.clientId == int(args[0]), self.clients):
                    yield other.call(cmd, str(client.clientId), *args[1:])
            elif cmd == 'multicast': # send the command to multiple identifiers
                ids = map(lambda x: int(x.strip()), args[0].split(',; \t'))
                for other in filter(lambda x: x.clientId in ids, self.clients):
                    yield other.call(cmd, str(client.clientId), *args[1:])
            elif cmd == 'anycast': # send the command to any identifier other than us.
                others = filter(lambda x: x != client, self.clients)
                if others:
                    yield random.choice(others).call(cmd, str(client.clientId), *args)
        multitask.add(commandInternal(self, client, cmd, *args))

# The main routine to start, run and stop the service
def runHTTP(addr=('0.0.0.0', 5080)): # create and run a web server instance
    from wsgiref.simple_server import make_server
    httpd = make_server(addr[0], addr[1], webserver)
    if _debug: print time.asctime(), 'Web server starts', addr
    try: httpd.serve_forever()
    except KeyboardInterrupt: pass
    httpd.server_close()
    if _debug: print time.asctime(), 'Server stops'

class SecureHTTPServer(HTTPServer):
    def __init__(self, server_address, HandlerClass):
        BaseServer.__init__(self, server_address, HandlerClass)
        ctx = SSL.Context(SSL.SSLv23_METHOD)
        #server.pem's location (containing the server private key and
        #the server certificate).
        fpem = 'server.pem'
        ctx.use_privatekey_file (fpem)
        ctx.use_certificate_file(fpem)
        self.socket = SSL.Connection(ctx, socket.socket(self.address_family,
                                                        self.socket_type))
        self.server_bind()
        self.server_activate()


class SecureHTTPRequestHandler(SimpleHTTPRequestHandler):
    def setup(self):
        self.connection = self.request
        self.rfile = socket._fileobject(self.request, "rb", self.rbufsize)
        self.wfile = socket._fileobject(self.request, "wb", self.wbufsize)
    # TODO: the secure web server needs to invoke restlite.

def runHTTPS(addr=('0.0.0.0', 5443)): # create and run a secure web server instance
    httpd = SecureHTTPServer(addr, SecureHTTPRequestHandler)
    sa = httpd.socket.getsockname()
    print 'Serving HTTPS on', sa
    httpd.serve_forever()    
    
def runRTMP(addr=('0.0.0.0', 1935)): # create and run a flash server instance
    server = rtmp.FlashServer()
    server.apps = dict({'record': Record, 'call': Call}) # only support call and record applications  
    server.root = 'www/flvs/'
    server.start(*addr)
    if _debug: print time.asctime(), 'Flash server starts', addr
    try: multitask.run()
    except KeyboardInterrupt: thread.interrupt_main()
    
#def runTelnet(addr=('127.0.0.1', 5023)): # create the telnet command server
#    server = terminal.Server()
#    try: server.serve_forever()
#    except KeyboardInterrupt: pass
    
if __name__ == '__main__':
    thread.start_new_thread(runRTMP, ()) # Flash server started in separate thread
    if 'SSL' in globals(): # SSL was imported
        thread.start_new_thread(runHTTPS, ()) # Secure web server runs in separate thread
    # thread.start_new_thread(runTelnet, ())
    runHTTP() # Web server runs in the main thread
    
