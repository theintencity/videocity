# Copyright (c) 2009, Kundan Singh. All rights reserved. See LICENSING for details.

'''
The video city project aims at web based video telephony, conferencing and sharing for variety of consumer and enterprise services.
This server side software includes a web server on port 5080, a Flash server on port 1935 and a control API server on port 8080.
The software implements multi-party call, recording, authentication, privacy and sharing of files, photos, videos in real-time.
'''

import os, sys, string, cgi, time, thread, BaseHTTPServer, cStringIO, traceback, random
try: import multitask, rtmp, webscript
except: print 'Please set PYTHONPATH to include p2p-sip/src and rtmplite/'; exit(-1)

_debug = True

#----------------------------
# WEB SERVER IMPLEMENTATION
#----------------------------

# directory structure and file configuration: top-level www, recordings in flvs and embed in embed.
_index, _www, _flvs, _embed, _cgi = 'index.html', 'www/', 'flvs/', 'embed', 'cgi/'
_mapped = ('flvs', 'embed', 'users', 'cgi', 'download')
# mime-type configuration
_supported = {'.html': 'text/html', '.txt': 'text/plain', '.js': 'application/x-javascript', '.css': 'text/css',
              '.xml': 'text/xml',  
              '.ico': 'image/vnd.microsoft.icon', '.png': 'image/png', '.jpg': 'image/jpeg', '.gif': 'image/gif',
              '.swf': 'application/x-shockwave-flash', '.flv': 'video/x-flv',
              '.zip': 'application/x-octet-stream', '.tgz': 'application/x-octet-stream' }

# HTTP request handler class
class MyHandler(BaseHTTPServer.BaseHTTPRequestHandler):
    def do_GET(s):
        try:
            s.path = s.path[1:]; vars = []  # ignore the first '/'
            s.path, ignore, headers = s.path.partition('?')
            if s.path == _index: s.path = ''
            if s.path == _embed: s.path += '/index.swf'
            if '..' in s.path.split('/'):
                s.send_error(403, 'Forbidden path')
                return
            if s.path.split('/')[0] in _mapped or s.path == 'favicon.ico': 
                s.path = _www + s.path
                if _debug: print s.path
            if s.path[0:4] != _www:
                target, ignore, rest = s.path.partition('/')
                #if '/' in rest:
                #    s.send_error(404, 'No Such User')
                #    return
                rest = s.path
                if rest: vars += ['target=' + rest]
                if headers: vars += headers.split('&')
                if _debug: print 'vars=', vars
                s.path = _www + _index
            ext = os.path.splitext(s.path)[1]
            if ext in _supported:
                fname = os.path.join(os.curdir, s.path)
                f = open(fname, 'rb')
                s.send_response(200)
                s.send_header('Content-Type', _supported[ext])
                s.end_headers()
                if s.path == _www + _index:
                    input = f.read()
                    input = str(input).replace("${vars}", '&'.join(vars))
                    s.wfile.write(input)
                else:
                    s.wfile.write(f.read())
                f.close()
            elif str(s.path).startswith(_www + _cgi): # only python CGI is supported
                try:
                    # TODO: this part needs to be separated out in a thread or process.
                    if _debug: print 'path=', s.path, 'headers=', headers
                    path, params = s.path, headers
                    # result = subprocess.Popen('python ' + path, stdout=PIPE, close_fds=True).stdout.read()
                    result = cStringIO.StringIO()
                    if _debug: 'starting script', path
                    execfile(path, dict(result=result), dict([x.split('=', 2) for x in params.split('&')]))
                    if _debug: print 'script returned'
                    responseline, ignore, rest = result.getvalue().partition('\n')
                    code, ignore, status = responseline.partition(' ')
                    if code.isdigit():
                        s.send_response(int(code), status)
                        contentLen = -1
                        while True:
                            header, ignore, rest = rest.partition('\n'); header = header.strip()
                            if header:
                                name, ignore, value = map(str.strip, header.partition(':'))
                                if name.lower() == 'content-length': contentLen = int(value)
                                s.send_header(name, value)
                            else: break
                        s.end_headers()
                        if rest:
                            print 'rest is', len(rest), contentLen
                            s.wfile.write(rest[:contentLen])
                    else: s.send_error(500, 'CGI returned invalid response code ' + code)
                except: traceback and traceback.print_exc(); s.send_error(500, 'Internal Server Error in CGI')
            else:
                s.send_error(403, 'Forbidden')
        except IOError:
            print 'File Not Found:', s.path
            s.send_error(404, 'File Not Found')
    
    def do_POST(s):
        try:
            s.path = s.path[1:]; response = ''
            if s.path not in webscript.scripts: raise Exception((403, 'Forbidden resource'))
            ctype, pdict = cgi.parse_header(s.headers.getheader('content-type'))
            length = int(cgi.parse_header(s.headers.getheader('content-length'))[0])
            if ctype == 'multipart/form-data':
                string = s.rfile.read(length)
                fp = cStringIO.StringIO(string)
                query = cgi.parse_multipart(fp, pdict)
            else:
                string = s.rfile.read(length)
                fp = cStringIO.StringIO(string)
                query = cgi.parse_qs(string, 1)
            type, response = webscript.scripts[s.path](query)
            if _debug: print type, len(response), response[:100]
            s.send_response(200)
            s.send_header('Content-Length', response and len(response) or 0)
            if response and type: s.send_header('Content-Type', type)
            s.end_headers()
            if response: s.wfile.write(response)
        except Exception, e:
            print 'Exception:', e
            if e.message and len(e.message) == 2: s.send_error(e.message[0], e.message[1])
            else: s.send_error(500, str(e.message))
            
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
                client.call('added', str(other.clientId))
                other.call('added', str(client.clientId))
            for stream in filter(lambda x: x.client != client, self.publishers.values()):
                client.call('published', str(stream.client.clientId), stream.name)
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
                other.call('removed', str(client.clientId))
            yield
        if filter(lambda x: x != client, self.clients): multitask.add(invokeRemoved(self, client))
        else: webscript.delete(path=client.path.partition('/')[2])
    def onPublish(self, client, stream):
        rtmp.App.onPublish(self, client, stream)
        for other in filter(lambda x: x != client, self.clients):
            other.call('published', str(client.clientId), stream.name)
    def onClose(self, client, stream):
        rtmp.App.onClose(self, client, stream)
        for other in filter(lambda x: x != client, self.clients):
            other.call('unpublished', str(client.clientId), stream.name)
    def onCommand(self, client, cmd, *args):
        if cmd == 'broadcast': # broadcast the command to everyone else in the call
            for other in filter(lambda x: x != client, self.clients):
                other.call(cmd, str(client.clientId), *args)
        elif cmd == 'unicast': # send the command to the given identifier (identiier by client.clientId).
            for other in filter(lambda x: x.clientId == int(args[0]), self.clients):
                other.call(cmd, str(client.clientId), *args[1:])
        elif cmd == 'multicast': # send the command to multiple identifiers
            ids = map(lambda x: int(x.strip()), args[0].split(',; \t'))
            for other in filter(lambda x: x.clientId in ids, self.clients):
                other.call(cmd, str(client.clientId), *args[1:])
        elif cmd == 'anycast': # send the command to any identifier other than us.
            others = filter(lambda x: x != client, self.clients)
            if others:
                random.choice(others).call(cmd, str(client.clientId), *args)

# The main routine to start, run and stop the service
def runHTTP(addr=('0.0.0.0', 5080)): # create and run a web server instance
    server_class = BaseHTTPServer.HTTPServer
    server = server_class(addr, MyHandler)
    if _debug: print time.asctime(), 'Web server starts', addr
    try: server.serve_forever()
    except KeyboardInterrupt: pass
    server.server_close()
    if _debug: print time.asctime(), 'Server stops'
    
def runRTMP(addr=('0.0.0.0', 1935)): # create and run a flash server instance
    server = rtmp.FlashServer()
    server.apps = dict({'record': Record, 'call': Call}) # only support call and record applications  
    server.root = _www + _flvs
    server.start(*addr)
    if _debug: print time.asctime(), 'Flash server starts', addr
    try: multitask.run()
    except KeyboardInterrupt: thread.interrupt_main()
    
if __name__ == '__main__':
    thread.start_new_thread(runRTMP, ()) # Flash server started in separate thread
    runHTTP() # Web server runs in the main thread
    
