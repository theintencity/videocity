
import sys, json
import restlite, restdata

_debug = True

data = {'_access': 'drwxr-xr-x', '_owner': 'root'}
users = {}

routes = [
    # rest api requests
    (r'GET,PUT,POST,DELETE /(?P<type>((xml)|(plain)))/(?P<path>.*)$', 'GET,PUT,POST,DELETE /%(path)s', 'ACCEPT=text/%(type)s', 'CONTENT_TYPE=text/%(type)s'),
    (r'GET,PUT,POST,DELETE /(?P<type>(json))/(?P<path>.*)$', 'GET,PUT,POST,DELETE /%(path)s', 'ACCEPT=application/%(type)s', 'CONTENT_TYPE=application/%(type)s'),
    # for browser convenience use POST /.../put for PUT and GET /.../delete DELETE
    (r'GET,POST /(?P<path>.*)/delete$', 'DELETE,DELETE /%(path)s'),
    (r'POST /(?P<path>.*)/put$', 'PUT /%(path)s'),
    
    # user data access at /rest/user
    (r'GET,PUT,POST,DELETE /user', restdata.bind(data, users)),
]

# the top level application to represent URL prefix /rest
wsgiapp = restlite.router(routes)

def _main():
    from wsgiref.simple_server import make_server
    httpd = make_server('', 5080, restlite.router([(r'GET,PUT,POST,DELETE /rest', wsgiapp),]))
    try: httpd.serve_forever()
    except KeyboardInterrupt: pass
    
def _unittest():
    import thread
    import urllib2, cookielib
    
    def adduser(user, password):
        global data, users
        data[user] = {'_access': 'drwx--x--x', '_owner': user}
        users[user] = restdata.hash(user, 'localhost', password)
    
    password_mgr = urllib2.HTTPPasswordMgrWithDefaultRealm()
    top_level_url = 'localhost:5080'
    prefix = 'http://' + top_level_url;
    password_mgr.add_password(None, top_level_url, 'kundan10@gmail.com', 'mypass')
    cj = cookielib.CookieJar()
    urllib2.install_opener(urllib2.build_opener(urllib2.HTTPBasicAuthHandler(password_mgr), urllib2.HTTPCookieProcessor(cj)))

    def urlopen(url, entity=None):
        print '-------',url
        try: return urllib2.urlopen(prefix + url, entity).read()
        except urllib2.HTTPError: return sys.exc_info()[1]
        
    def test():
        adduser('kundan10@gmail.com', 'mypass')
        adduser('henry@example.net', 'otherpass')

        # get the top level directory
        print json.loads(urlopen('/rest/json/user'))
        
        r1 = {'_access': 'drwx------'}
        urlopen('/rest/json/user/kundan10@gmail.com/private/put', json.dumps(r1))
        r2 = {'_access': 'drwxrwxrwx'}
        urlopen('/rest/json/user/kundan10@gmail.com/public/put', json.dumps(r2))
        r3 = {'_access': 'drwx-w--w-'}
        urlopen('/rest/json/user/kundan10@gmail.com/inbox/put', json.dumps(r3))
        r4 = {'_access': 'drwx------'}
        urlopen('/rest/json/user/kundan10@gmail.com/sent/put', json.dumps(r4))
        print urlopen('/rest/json/user/kundan10@gmail.com')
        
        c1 = [{'user': 'henry@example.net'}, {'user': 'sanjay@example.net'}]
        urlopen('/rest/json/user/kundan10@gmail.com/private/contacts/put', json.dumps(c1))
        urlopen('/rest/json/user/kundan10@gmail.com/private/contacts/0/name/put', json.dumps('Henry Sinnreich'))
        print urlopen('/rest/json/user/kundan10@gmail.com/private/contacts')
        
        urlopen('/rest/json/user/kundan10@gmail.com/private/contacts/0/delete')
        print urlopen('/rest/json/user/kundan10@gmail.com/private/contacts')
        
        urlopen('/rest/json/user/kundan10@gmail.com/sent/delete')
        print json.loads(urlopen('/rest/json/user/kundan10@gmail.com'))
        
        data['henry@example.net']['public'] = {'_access': 'drwxrwxrwx', 'key1': 'value1', 'key2': 'value2'}
        print urlopen('/rest/json/user/henry@example.net')
        urlopen('/rest/json/user/henry@example.net/public/key3/put', json.dumps('value3'))
        print json.loads(urlopen('/rest/json/user/henry@example.net/public'))
        
    thread.start_new_thread(test, ())
    
    
# For testing launch the server
if __name__ == '__main__':
    if len(sys.argv) > 1 and sys.argv[1] == '--unittest': 
        _unittest() # if unit test is desired, perform unit testing
    _main()
