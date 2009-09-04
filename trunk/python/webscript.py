# Copyright (c) 2009, Kundan Singh. All rights reserved. See LICENSING for details.

'''
Commonly used scripts for the web server, such as for login, create, verify and upload.
'''

import os, sys, re, struct, traceback, email, smtplib, urlparse, random
from base64 import b64encode, b64decode
from app import crypto
from external.simplexml import XML
import vcard

_debug = True

_admin = 'kundan10@gmail.com'  # source address for the email
_masterKey = 'data/kundansingh_99@yahoo.com.key' # master key to sign all visiting cards

#===============================================================================
# Send email, optionally with attachments
#===============================================================================

def sendmail(to, subject, text, frm="", files=[], cc=[], bcc=[], server="localhost"):
    '''A high-level email sender.
    >>> sendmail(['kundansingh_99@yahoo.com'], 'something', 'some other thing', 'kundan10@gmail.com', [('file.txt', 'context of file')])
    '''
    assert type(to)==list and type(files)==list and type(cc)==list and type(bcc)==list  
    m = email.MIMEMultipart.MIMEMultipart()  
    m['From'], m['To'], m['Date'], m['Subject'] = frm, email.Utils.COMMASPACE.join(to), email.Utils.formatdate(localtime=True), subject  
    if cc: m['Cc'] = email.Utils.COMMASPACE.join(cc)  
    m.attach(email.MIMEText.MIMEText(text))  
    for f in files:  
        part = email.MIMEBase.MIMEBase('application', 'octet-stream')  
        basename, content = f if type(f)==tuple else (os.path.basename(f), open(f, 'rb').read())
        part.set_payload(content)  
        email.Encoders.encode_base64(part)  
        part.add_header('Content-Disposition', 'attachment; filename="%s"' % basename)  
        m.attach(part)
    #print m.as_string()
    smtp = smtplib.SMTP(server)  
    smtp.sendmail(frm, to+cc+bcc, m.as_string())  
    smtp.close()  

    
#===============================================================================
# Top-level scripts callable by webserver
#===============================================================================

def _error(value): return ('text/xml', '<result><error>%s</error></result>'%(str(value)))
def _result(**kwargs): return ('text/xml', '<result>' + ''.join('<%s>%s</%s>'%(x,y,x) for x,y in kwargs.items()) + '</result>'); 

_loginEmailSubject = 'Your login card for 39 peers project'
_loginEmailText = '''Hello,
Please download and keep your attached login card confidential.
The card is a private key that you can upload to the 39 peers
software to login. If you are using a public computer please 
delete the card from your PC after you have used it to login.
--
Kundan Singh  http://39peers.net'''

_visitingEmailSubject = lambda x: 'Your visiting card for ' + x.url
_visitingEmailText = lambda x: '''
Hello,
Please download your attached visiting card, and send to your
friends, post on your blog or web page, or use it to connect
to your room.
Room URL: %s 

--
Kundan Singh  http://39peers.net'''%(x.url)

def create(query):
    try:
        if 'logincard' not in query or 'visitingcard' not in query: raise Exception('missing logincard or visitingcard to create')
        logincard, visitingcard = vcard.Card(b64decode(query.get('logincard')[0])), vcard.Card(b64decode(query.get('visitingcard')[0]))
        if _debug: print 'input is', len(logincard.data), len(visitingcard.data)
        loginSent = visitingSent = False # whether emails could be sent successfully or not?
        if not logincard.Ks:  # create private key if needed
            vcard.Card.createKeys(logincard, visitingcard)
            try: 
                sendmail([logincard.email], _loginEmailSubject, _loginEmailText, _admin, [('loginCard.png', logincard.data)])
                loginSent = True
            except: 
                traceback and traceback.print_exc()
                # raise Exception('could not send login card in email to ' + logincard.email)
        global _masterKey
        Ks = crypto.load(_masterKey)
        visitingcard.sign(Ks)
        try: 
            sendmail([visitingcard.email], _visitingEmailSubject(visitingcard), _visitingEmailText(visitingcard), _admin, [('visitingCard.png', visitingcard.data)])
            visitingSent = True
        except: 
            traceback and traceback.print_exc()
            # raise Exception('could not send visiting card in email to ' + visitingcard.email)
        param=dict(code='success') # add more parameters if we didn't send email correctly
        if not loginSent: param['logincard'] = b64encode(logincard.data)
        if not visitingSent: param['visitingcard'] = b64encode(visitingcard.data) 
        return _result(**param)
    except Exception, e: traceback and traceback.print_exc(); return _error(e)
    
def login(query):
    if 'logincard' not in query: raise Exception((400, 'Missing logincard to login'))
    logincard = query.get('logincard')
    return _result(code='success')

def verify(query):
    if 'visitingcard' not in query: raise Exception((400, 'Missing visitingcard to verify'))
    visitingcard = query.get('visitingcard')
    return _result(code='success')

def _makePath(url, filename, randomize=False, subdir=''):
    filename = re.sub(' ', '-', re.sub('[^a-zA-Z0-9_.()-]+', '', filename)) # make a valid file name
    u = urlparse.urlparse(url)
    path = 'www/users' + u.path + '/' + (subdir + '/' if subdir else '') + (str(random.randint(10000,99999)) + '-' if randomize else '') + filename
    url0 = urlparse.urlunparse((u.scheme, u.netloc, path, '', '', ''))
    return (url0, path)
    
def upload(query):
    if filter(lambda x: x not in query, ('target', 'filedata')): raise Exception((400, 'Must supply target and filedata to upload'))
    target, filedata = map(lambda x: query.get(x)[0], ('target', 'filedata'))
    logincard, visitingcard = map(lambda x: vcard.Card(b64decode(query.get(x)[0])) if x in query else None, ('logincard', 'visitingcard'))
    if _debug: print 'target=', target, 'filedata=', len(filedata), filedata[:100]
    if 'encoding' in query and query.get('encoding')[0].lower() == 'base64': filedata = b64decode(filedata)
    files = dict(map(lambda y: (query.get(y[1])[0], b64decode(query.get('filedata'+str(y[0]))[0])), filter(lambda x: x[1] in query, map(lambda i: (i, 'filename'+str(i)), xrange(32)))))
    if _debug: print 'extracted files', dict(files).keys()
    xml = XML(filedata)
    card = logincard if target == 'index.xml' else visitingcard
    if card is None: raise Exception((400, 'Must supply a valid card'))
    subdir = 'private' if target == 'inbox.xml' else 'public' if target == 'index.xml' else 'active'
    for file in filter(lambda x: isinstance(x, XML) and x['src'] is not None and x['src'][:7] == 'file://' and x['src'] in files, xml.children): # for embedded file contents
        name, content = file['src'][7:], files[file['src']]
        url, path = _makePath(url=card.url, filename=name, randomize=True, subdir=subdir)
        file['src'] = url
        ext = os.path.splitext(name)[1].lower(); file.tag = 'video' if ext == '.flv' else 'image' if ext[1:] in ('jpg','png','jpeg','gif','swf') else file.tag
        if _debug: print 'file=', name, 'content=', len(content)
        if not os.path.exists(os.path.dirname(path)): os.makedirs(os.path.dirname(path), 0755)
        fp = open(path, 'w'); fp.write(content); fp.close()
    url, path = _makePath(url=card.url, filename=target)
    try: fp = open(path); old = XML(fp.read()); fp.close()
    except: old = XML('<page/>')
    if target != 'inbox.xml' and xml['id'] is not None: del old.children[lambda x: x['id'] == xml['id']]
    old.children += xml
    fp = open(path, 'w'); fp.write(str(old)); fp.close()
    result = _result(code='success', target=target, filedata=xml)
    if _debug: print result
    return result

def trash(query):
    if 'filedata' not in query: raise Exception((400, 'Must supply filedata to trash'))
    filedata = query.get('filedata')[0]
    logincard, visitingcard = map(lambda x: vcard.Card(b64decode(query.get(x)[0])) if x in query else None, ('logincard', 'visitingcard'))
    if _debug: 'filedata=', len(filedata), filedata[:100]
    if 'encoding' in query and query.get('encoding')[0].lower() == 'base64': filedata = b64decode(filedata)
    xml = XML(filedata)
    if _debug: print 'xml=', str(xml)
    if logincard is not None: targets = ('index.xml', 'inbox.xml', 'active.xml')
    elif visitingcard is not None: targets = ('active.xml',)
    else: raise Exception((400, 'Must supply a valid card'))
    card = logincard if logincard is not None else visitingcard
    # TODO: need to delete the referred files also, if they are not used elsewhere.
    for target in targets:
        url, path = _makePath(url=card.url, filename=target)
        try: fp = open(path); old = XML(fp.read()); fp.close()
        except: old = XML('<page/>')
        if _debug: print 'before', str(old)
        if xml['id'] is not None: del old.children[lambda x: x['id'] == xml['id']]
        if _debug: print 'after', str(old)
        fp = open(path, 'w'); fp.write(str(old)); fp.close()
    result = _result(code='success')
    if _debug: print result
    return result

def access(query):
    try:
        if filter(lambda x: x not in query, ('room', 'type')): raise Exception((400, 'Must supply room and type to change access'))
        room, type = map(lambda x: query.get(x)[0], ('room', 'type'))
        logincard, visitingcard = map(lambda x: vcard.Card(b64decode(query.get(x)[0])) if x in query else None, ('logincard', 'visitingcard'))
        if logincard is None or type == 'public' and visitingcard is None: raise Exception('missing logincard or visitingcard to change access')
        url, path = _makePath(url=room, filename='visitingCard.png')
        if _debug: print 'changing', room, 'to', type, 'file', path
        try:
            if not os.path.exists(os.path.dirname(path)): os.makedirs(os.path.dirname(path), 0755)
            if type == 'public': file = open(path, "w"); file.write(visitingcard.data); file.close();
            else: os.remove(path)
        except: 
            if _debug: print 'exception in access', traceback and traceback.print_exc()
        return _result(code='success')
    except Exception, e: traceback and traceback.print_exc(); return _error(e)

def delete(path): # this is actually invoked in a different thread by videocity module.
    try: 
        file, dir = 'www/users/%s/active.xml'%(path), 'www/users/%s/active'%(path)
        if os.path.isfile(file): os.remove(file)
        for file in os.listdir(dir): os.remove(dir + '/' + file)
    except: print sys.exc_info()
    
    
scripts = dict(create=create, login=login, verify=verify, upload=upload, trash=trash, access=access)

