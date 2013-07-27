FreeFrameGL
===========

Syphon is a system for sending video between applications. You can use it to send high resolution and high frame rate video, 3D textures and synthesized content between your FreeFrame host and other applications.

Syphon for FreeFrame includes two plugins:

* Syphon Client - Brings video from other applications into your FreeFrame  host.

* Syphon Server - Publishes video from your host app, so that external applications which support Syphon can use them.

Licensing
===========

Syphon for FreeFrame is published under a Simplified BSD license. See the included License.txt file.

Requirements
===========

Mac OS X 10.6.4 or greater
Any application which supports FreeFrame 1.5 (FFGL) or later (not FreeFrame 1.0).
 
Installation
===========

Install "Syphon Client.bundle" and "Syphon Server.bundle" in a folder where your host application will see them. 

Instructions
===========

Using the Syphon Server plugin - Syphon Server is an effect plugin. Video it receives as input will be made available to other applications. It has the following parameters:

	- Name: name your server so it is identifiable in other applications
	- Monitor: if this is true, video will be drawn in the host app. If it is false, you will stop seeing the output in the host app.

Using the Syphon Client plugin - Syphon Client is a source plugin. It receives video from an existing Syphon Server. It has the following parameters:

	- Name: the name of the Syphon Server to connect to.
	- App Name: the name of the application hosting the server you want to connect to.

Both of these parameters are optional. If neither are provided, any available server will be connected to, otherwise available servers will be matched according to the parameters you provide.

Changes since Public Beta 1
- If neither parameter is provided to the Syphon Client plugin, it will match any available server.
- Fixes and improvements to the underlying Syphon framework.

Credits
===========

Syphon for FreeFrame - Tom Butterworth (bangnoise) and Anton Marini (vade)

http://syphon.v002.info