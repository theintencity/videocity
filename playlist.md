# Introduction #

When you visit a room such as `http://server:5080/kundansingh_99@yahoo.com`, the client first fetches the "visitingCard.png" relative to this URL. If found, the room is assumed to be public, and that visiting card is used. If not found, you are given an option to upload a visiting card. Once you enter the room, the "index.xml" file relative to the room URL is fetched. This file, if present, describes the initial room content such as play lists. Similarly when you login using your private login card, and your private login card is for your main room URL, then your "inbox.xml" file relative to your main room URL is fetched. This file, if present, describes all the messages (i.e., play lists) privately sent to you. Similarly, all the media shared in an active session in a room, are stored in a temporary file named "active.xml" relative to the room URL. This file is temporary because it gets deleted when the session terminates. In summary, the room description (index.xml), the active session description (active.xml) and the mail box (inbox.xml) are just XML files containing play lists. This document describes the format of the XML file and play list.

Each play list itself is an XML element `<show/>`. In the room view, when you drag-drag items from one play list to another, or when you drag one play list to another to move, or when you send, share or upload a play list, the system manipulates these XML elements. For example, when you upload files from local computer, a new XML play list is created. When you upload the play list to your room, the XML is appended in your room's "index.xml". When you send the play list to the owner of the room, the XML is appended to the owner's "inbox.xml". When you share the play list in the room with others, the XML is appended to the "active.xml" file for that room.


# Description #

An example to understand the format is best to start with. An example "index.xml" file describing a room is shown below.
```
<page>
  <show id="a73be56d" description="a song">
    <text description="brief description">Text describing this play list</text>
    <video src="http://www.youtube.com/watch?v=TczKK_zJVBg" description="chehra" />
  </show>
  <show id="ba4627af" description="random media">
    <text interval="15000" description="Introduction"><b>What I like?</b>
      <br/>I love Python
    </text>
    <image src="http://some-server/some-image.jpg" description="some photo" />
    <file src="file://snapshot.jpg" description="Snapshot photo" />
    <stream src="rtmp://server:5080/flvs/null/72635123.flv" desc="Recorded video" />
    <video src="rtmp://server:5080/users/kundansingh_99@yahoo.com/public/video2.flv" />
    <show src="http://another-server/another-show" />
  </show>
</page>
```

### show ###
As you can see, the room's top level element is `<page/>`. A page can contain zero or more play lists identified by `<show/>` elements. In the example, there are two play lists. Each `<show/>` tag has an "id" attribute that identifies the play list. The id should be unique within a page, and usually generated randomly by the owner of the play list. The "description" attribute of the play list is currently not used, but is intended to be displayed in the user interface of the play list. We can add additional attributes in future such as `layout="maximized"` to play it in maximized size, `backgroundColor="#ffffff"` to set the background color of this play list, `subtitle="http://..."` to set the subtitles, `mode="parallel"` to play all children at the same time in the play list, and so on.

Each play list is a sequence of play items. A play item can be either a text, image, video, stream, file or another embedded show (play list) element. In the case on an embedded show element, the player recursively fetches the `src` of the embedded play list, and merges it into the main play list. For example, if the URL resolves in to another XML file containing the top level `show` tag, and five children elements of type `image` then all those five `image}} elements will be merged into the main play list, replacing the original embedded {{{show` element. To facilitate slide shows from slideshare.net service, our server replaces the `slide}} tag with {{{image` tag and also does some other post-processing after fetching the embedded show description from slideshare.net web site. An embedded show is fetched using our server as a proxy, so that we can do such processing.

Each of the play item can have an optional `description` attribute that is used to describe the play item in the user interface of the play list. In our implementation, the description of the currently selected play item appears in the bottom bar of the play list view.

Each of the play item can also have an optional `src` attribute that points to the actual resource represented by the play item. In the implementation, a `src` attribute is an URL with `http`, `file` or `rtmp` scheme, for web, local file or media server resource, respectively.

Below we describe individual items.

### text ###

The `text` element can have an optional `interval` attribute which indicates the number of milliseconds to keep that text item displayed in a slide show or play mode. The default value is 2000 indicating a 2 second interval. The `src` attribute is currently not used for a `text` element.

The `text` element itself describes the text to be displayed. If the element starts with regular text, it is treated as regular text to be displayed in a text-area, otherwise if the element starts with an open pointed bracket `<` then it is treated as an HTML text and displayed as such in the text-area including any HTML formatting as supported by Flash Player.

### image ###

An `image` tag displays the image or photo. The display interval is five seconds in slide show or play mode. The resource can be any image file such as jpeg, gif, png, or another SWF file.

### video ###

A `video` tag plays a video fetched using `http`. The video must be of {{{FLV}} format. Our server translates youtube URLs to FLV video URL, and allows playing a youtube video. Note that a video URL is always proxied through our server, so that we can do any such processing. Our server also translates locally uploaded mpeg or avi files to FLV format using ffmpeg, if available, so that locally uploaded files can be added to a play list.

The `video` tag is different from `stream` tag, as the former is used for progressive downloaded video playback and the latter for real-time video play back.

### stream ###

A `stream` tag plays a real-time video using RTMP. The `src` attribute must be an `rtmp:` URL pointing to, preferably, our server. An `id` attribute is required for a `stream` element. The `id` attribute represents the stream name to be played in RTMP. For example, if the src points to "rtmp://server:5080/flvs/kundansingh\_99@yahoo.com" then the client will make NetConnection connection to this URL. If the id is "video1" then the client will play the stream named "video1" or file named "video1.flv" once connected. Our implementation currently doesn't support time positioning of RTMP streams, but will be added in future.

Usually, a video recorded by user's camera uses an `stream` element. Since the recording from Flash Player is done using RTMP on our server, the src attribute points to our server, and the id attribute points to the recorded FLV file on our server. The file is recorded by the server under a directory that is specific to the logged in user or "null" for guest user.

### file ###

A `file` tag represents one of the two types of resources: either a locally uploaded file, or if the file type doesn't fall into text, image, video or stream, such as for file sharing scenario to share a ZIP file.

The implementation stores the content of the file along with the play item for locally uploaded files such as local photo or video. However, once the play list is sent to another user, shared in the room, or uploaded to a room, the client sends the content to the server, the server creates a web accessible resource for the file, and the client replaces the URL from `file://` to `http:///` and the element from `<file/>` to `<image/>` or `<video/>` if applicable based on the file name extension. Thus, once the file is shared, the resource becomes web accessible and available to others using an `http` URL.

# Conclusion #

We have described the format of a room, mail box and play list. These are still "work-in-progress" and new ideas are welcome. For example, we would like to keep the real-time participant video information as well in the "active.xml" file. Perhaps an application or game sharing can be built by allowing third-party play items in the play list. For example, `<app src="..." plugin="..."/>` can represent a shared application or shared flash game, where the plugin attribute gives the location of the application or SWF file that can be used as a child in the play list to actually display the application or game interface, and the src attribute gives the location of the context or state of the game. For example, all users playing from location `http://gameserver/room5` get connected to the same game context or state, and can play the multi-player game or use the multi-party application.