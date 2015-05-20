# Welcome to the Internet Video City #

> This project was migrated from <https://code.google.com/p/videocity> on May 17, 2015  
> Keywords: *VideoConferencing*, *VideoRoom*, *SoftCard*, *Python*, *Flash*  
> Members: *kundan10* (owner), *theintencity* (owner), *shailend.yede*, *kss.iitk*  
> Links: [Support](http://groups.google.com/group/myprojectguide), [Video](http://www.youtube.com/watch?v=hInkz60ecC4), [Blog](http://p2p-sip.blogspot.com/2009/09/internet-video-city.html)  
> Downloads: [installer for Windows](/downloads/videocity-1.1-wind32.zip) Sep 2009, 5.2MB, 1656 download count, [installer for Mac OS X](/downloads/videocity-1.1-macosx.zip) Sep 2009, 9.7MB, 189 download count  
> License: [GNU GPL v3](http://www.gnu.org/licenses/gpl.html)  
> Others: starred by 22 users  

![Logo](/doc/logo.png)

This is a web-based video telephony and conference application. (Please see [this blog article](http://p2p-sip.blogspot.com/2009/09/internet-video-city.html) for what's new in the project and please see [this video demo on youtube](http://www.youtube.com/watch?v=hInkz60ecC4)). The video communication is abstracted out as a city. Once you signup, you own a home, where you can have several rooms. You can decorate your rooms with your favorite photos and videos, invite your friends and family to visit a room by handing out visiting card, or visit other people's rooms to video chat with them or to leave a video message if they are not in their home. You can keep a room open for public or make it private. You can wander in the city and knock on the doors of other people's home to make new friends.

Once you signup, you get two soft-card (TM): a Private login card and an Internet visiting card. The private login card is your access card that you will upload to gain access to your room or to login, and the Internet visiting card is an invitation card that you can give out to your friends and family so that they can visit you in your room.
An example Internet visiting card is shown below.

<img src='/doc/visitingCard.png' />

Once you have created a room, and have logged in to your room, you can make your room public in which case your Internet visiting card will be uploaded to the server and available to everyone by just visiting your videocity URL.

## Goals of this project ##

The Internet Video City project aims at providing open source and free software to support enterprise and consumer video conferencing using ubiquitous web based Flash Player platform. The motive of this project is to provide tools and technologies to other developers and system engineers so that they can easily incorporate the video communication feature in their service, software or enterprise infrastructure. Hence, we use open and customizable architecture, open standards, and promote third party contributions.

Following are the high level features of the software:

  1. Multi-party multimedia conferencing with audio, video, text and sharing.
  1. Recording, playback and editing of conferences and video messages.
  1. Sharing of videos, photos and files from local PC as well as Internet.
  1. Shared browsing and media viewing experience. (pending)
  1. Customizable video rooms and video home pages.
  1. Secure and authenticated access control.
  1. Self organizing scalable and robust client-server architecture. (pending)
  1. Web-based client using Flash Player plugin as well as Firefox extension. (partly pending)
  1. Open source and embedable client side software.
  1. Portable software written in Python and ActionScript.


## Architecture ##

The software consists of client and server. The server is written in the Python 2.7 programming language. The client is written in ActionScript 3.0 and runs in either Flash Player browser plugin of standalone Adobe Integrated Runtime (AIR) platform. Similar to Python's motto, this software comes with batteries included, and doesn't require external dependencies. In particular, it has built-in web and media servers.

The client viewer application controls the main display, shows local and remote videos, and provides user friendly menu options. The client also captures and plays audio and video using the underlying Flash Player plugin. The backend server controls the authentication, conference state and sharing of media. In this client server architecture, multiple clients connect to the server hosting a conference. The conference state may get distributed among multiple servers depending on the current load and geography of the network.


## Getting Started ##

Windows or Mac OS X users may try to use the installer under the [download](/downloads) page. Please pick the appropriate file for your platform. Follow the instructions in the [INSTALL](/INSTALL) file available in the downloaded archive. Since this is "work in progress", the installer will be slightly outdated compared to the SVN source code.

If you are a developer and wants to get started with this software, I recommend that you checkout the sources from SVN, run the server and point your browser to the local server.

[See this page for detailed instructions.](/gettingstarted.md) (The instructions there are slightly dated for older version that uses videocity.py instead of server.py and without dependency on restlite).

This project depends on three other projects: [39 peers p2p-sip](https://github.com/theintencity/p2p-sip), [rtmplite RTMP server](https://github.com/theintencity/rtmplite) and [restlite RESTful server tools](https://github.com/theintencity/restlite). To run the videocity server you will need to first download and install these projects. Then change your PYTHONPATH to include these project directories. An example is shown below assuming you checked out p2p-sip, rtmplite, restlite and videocity projects in the same directory.

```
bash$ cd videocity
bash$ export PYTHONPATH=.:../rtmplite:../restlite:../p2p-sip/src
```

Then you can run the server as follows using python 2.7 interpreter:
```
bash$ python python/server.py
```

Once the server is running you can open a browser with Flash Player 10.0.22 or higher installed, and point your browser to [http://localhost:5080](http://localhost:5080)

To see an example pre-created video room, point your browser to
[http://localhost:5080/kundansingh\_99@yahoo.com](http://localhost:5080/kundansingh_99@yahoo.com) and enter the room.

An example screen shot after your visit the room URL is shown below. You can see more screen shots in the [wiki page](/screenshots.md).

<img src='/doc/screenshot1.png' />


## Authors' Note ##

This project is "work in progress". Some of the objectives are still pending, especially the security and access control part, and robustness and scalability. The source code is well documented but there is no external user documentation yet.

## Support ##

If you want to contribute to this project or report a bug or patch, please send me a note to the [support group](http://groups.google.com/group/myprojectguide). You don't need to subscribe to that group to post a message. **I look forward to hearing from you!**


