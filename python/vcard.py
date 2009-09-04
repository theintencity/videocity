# Copyright (c) 2009, Kundan Singh. All rights reserved. See LICENSING for details.

'''
The novel Internet visiting card idea is implemented in this module using Card object. 
The idea is to use an image for the login and visiting card. The login card stores a private key in the image, whereas
the visiting card stores a public key. The user should keep the login card confidential and give out the visiting card
to others to call him. The PNG image format is used with chunk types 'lsAB', 'ksAB', 'jsAB' to store the user information,
private/public BER encoded string, and signature if any. An image is more intuitive for the user instead of having to
keep some binary/text file for keys. Moreover the user can always open the image to view the user information. This
module treats the user information as opaque, but just uses it for signature and authentication. The Image 
generator program should put appropriate image and co-relate it to the user information.
'''

import os, sys, struct, hashlib, traceback

if __name__ == '__main__': # hack to add other libraries in the sys.path
    f = sys.path.pop(0)
    sys.path += [f, os.path.dirname(f), os.path.join(os.path.dirname(f), 'external')]
    
from app import crypto

_debug = False

H = lambda x: hashlib.sha1(x).hexdigest() # the hash function used in this implementation for signature

#===============================================================================
# Login Card and Visiting Card
#===============================================================================

_infoType, _keyType, _signType = 'lsAB', 'ksAB', 'jsAB'
_infoNames = ('title', 'email', 'owner', 'name', 'keywords', 'url')
    
def _readUTF(input, offset):
    if offset >= len(input): return None
    size, = struct.unpack('>H', input[offset:offset+2])
    return (unicode(input[offset+2:offset+2+size]), offset+2+size)

class PNG(object): # implement image related methods
    crcTable = [0 for x in xrange(0, 256)]
    for n in xrange(0, 256):
        c = n
        for k in xrange(0, 8):
            if c & 1: c = (0xedb88320 ^ ((c >> 1) & 0x7fffffff)) & 0xffffffff
            else: c = ((c >> 1) & 0x7fffffff)
            crcTable[n] = c

    @staticmethod
    def getChunk(image, chunk): # return the given chunk in PNG file
        if len(image) < 8: raise Exception('image data is too small')
        offset, size, info = 8, len(image), None
        while offset < size:
            length, = struct.unpack('>I', image[offset:offset+4]); type = image[offset+4:offset+8]
            if type == chunk: info = image[offset+8:offset+8+length]
            offset += 12+length
        return info
    @staticmethod
    def removeChunk(image, chunk): # return the image after removing the given chunk in the PNG file
        if len(image) < 8: raise Exception('image data is too small')
        offset, size, result = 8, len(image), image[:8]
        while offset < size:
            length, = struct.unpack('>I', image[offset:offset+4]); type = image[offset+4:offset+8]
            if type != chunk: result += image[offset:offset+12+length]
            offset += 12+length
        return result
    @staticmethod
    def setChunk(image, chunk, value): # update the chunk in PNG file
        if len(image) < 8: raise Exception('image data is too small')
        offset, size, off, info, infoOffset, infoSize = 8, len(image), 0, None, 0, 0
        while offset < size:
            length, = struct.unpack('>I', image[offset:offset+4]); type = image[offset+4:offset+8]
            if type == chunk: infoOffset, infoSize = offset, 12+length
            offset += 12+length
            if infoOffset == 0: infoOffset = offset
        elem = struct.pack('>I', len(value)) + chunk + value
        crc = 0xffffffff
        for i in xrange(4, len(elem)):
            crc = (PNG.crcTable[(crc ^ ord(elem[i])) & 0xff] ^ ((crc >> 8) & 0x7fffffff)) & 0xffffffff;
        crc = crc ^ 0xffffffff
        elem += struct.pack('>I', crc)
        return image[0:infoOffset] + elem + image[infoOffset+infoSize:]
    
class Card(object):
    '''Represent a Card with image data in _data, and other properties such as title, email, owner, name, keywords, url.
    The Ks or Kp property are set for login card and visiting card respectively.
    >>> lc = Card(open('data/loginCard.png').read())     # user's login card
    >>> vc = Card(open('data/visitingCard.png').read())  # user's visiting card
    >>> Ks = crypto.load('data/kundansingh_99@yahoo.com.key') # CA's key
    >>> Card.createKeys(lc, vc)    # create the Ks, Kp keys. (Not needed if cards are already valid).
    >>> vc.sign(Ks)                # sign the visiting card using key Ks
    >>> print vc.verify(Ks)        # verify the signature
    True
    '''
    def __init__(self, value=None):
        self._data = self.title = self.email = self.owner = self.name = self.keywords = self.url = self.Ks = self.Kp = None
        if value: self.load(value)
        
    def __repr__(self):
        return '<Card title=\"%s\" email=\"%s\" owner=\"%s\" name=\"%s\" url=\"%s\" keywords=\"%s\" />'%(self.title, self.email, self.owner, self.name, self.url, ';'.join(self.keywords) if self.keywords else '')
    
    @property
    def data(self): return self._data
    
    def load(self, value): # load the raw data and info from the given value
        self._data = value
        info, key = PNG.getChunk(value, _infoType), PNG.getChunk(value, _keyType)
        if not info: raise Exception('cannot read card information')
        off = 0
        while off < len(info):
            name, off = _readUTF(info, off); value, off = _readUTF(info, off)
            if name in _infoNames: self.__dict__[name] = value
            else: break
        if self.keywords: self.keywords = map(unicode.strip, self.keywords.split(';'))
        if key: 
            if self.title == 'Private Login Card': self.Ks = crypto.load(key)
            elif self.title == 'Internet Visiting Card': self.Kp = crypto.load(key)
            else: raise ValueError('Neither a Private Login Card nor a Internet Visiting Card. title=%r'%(self.title))
    
    @staticmethod
    def createKeys(login, visiting): # create the private/public key in the card pair 
        login.Ks, visiting.Kp = crypto.generateRSA()
        login._data = PNG.setChunk(login.data, _keyType, str(login.Ks))
        visiting._data = PNG.setChunk(visiting.data, _keyType, str(visiting.Kp))
    
    def sign(self, Ks): # using Ks, sign the Kp of self and add a signType chunk
        img = PNG.removeChunk(self.data, _signType)
        s = crypto.sign(Ks, H(img))
        self._data = PNG.setChunk(self.data, _signType, s)

    def verify(self, Kp): # using Kp, verify signType chunk as sign of self's Kp.
        s = PNG.getChunk(self.data, _signType)
        img = PNG.removeChunk(self.data, _signType)
        return crypto.verify(Kp, H(img), s)
    
if __name__ == '__main__':
    import doctest
    doctest.testmod()
