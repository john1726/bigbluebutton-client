/**
* BigBlueButton open source conferencing system - http://www.bigbluebutton.org/
* 
* Copyright (c) 2012 BigBlueButton Inc. and by respective authors (see below).
*
* This program is free software; you can redistribute it and/or modify it under the
* terms of the GNU Lesser General Public License as published by the Free Software
* Foundation; either version 3.0 of the License, or (at your option) any later
* version.
* 
* BigBlueButton is distributed in the hope that it will be useful, but WITHOUT ANY
* WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
* PARTICULAR PURPOSE. See the GNU Lesser General Public License for more details.
*
* You should have received a copy of the GNU Lesser General Public License along
* with BigBlueButton; if not, see <http://www.gnu.org/licenses/>.
*
*/
package org.bigbluebutton.modules.videoconf.business
{
	import com.asfusion.mate.events.Dispatcher;
	
	import flash.events.AsyncErrorEvent;
	import flash.events.IOErrorEvent;
	import flash.events.NetStatusEvent;
	import flash.events.SecurityErrorEvent;
	import flash.media.H264Level;
	import flash.media.H264Profile;
	import flash.media.H264VideoStreamSettings;
	import flash.net.NetConnection;
	import flash.net.NetStream;
	
	import org.as3commons.logging.api.ILogger;
	import org.as3commons.logging.api.getClassLogger;
	import org.bigbluebutton.core.BBB;
	import org.bigbluebutton.core.UsersUtil;
	import org.bigbluebutton.core.managers.ReconnectionManager;
	import org.bigbluebutton.main.api.JSLog;
	import org.bigbluebutton.main.events.BBBEvent;
	import org.bigbluebutton.modules.videoconf.events.ConnectedEvent;
	import org.bigbluebutton.modules.videoconf.events.StartBroadcastEvent;
	import org.bigbluebutton.modules.videoconf.events.StopBroadcastEvent;
	import org.bigbluebutton.modules.videoconf.model.VideoConfOptions;

	
	public class VideoProxy
	{	
		private static const LOGGER:ILogger = getClassLogger(VideoProxy);
		
		public var videoOptions:VideoConfOptions;
		
		private var nc:NetConnection;
		private var _url:String;
		private var camerasPublishing:Object = new Object();
		private var reconnect:Boolean = false;
		private var reconnecting:Boolean = false;
		private var dispatcher:Dispatcher = new Dispatcher();

		private var numNetworkChangeCount:int = 0;
		
		private function parseOptions():void {
			videoOptions = new VideoConfOptions();
			videoOptions.parseOptions();	
		}
		
		public function VideoProxy(url:String)
		{
      		_url = url;
			parseOptions();			
			nc = new NetConnection();
			nc.proxyType = "best";
			nc.client = this;
			nc.addEventListener(AsyncErrorEvent.ASYNC_ERROR, onAsyncError);
			nc.addEventListener(IOErrorEvent.IO_ERROR, onIOError);
			nc.addEventListener(NetStatusEvent.NET_STATUS, onNetStatus);
			nc.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onSecurityError);			
		}
		
		public function reconnectWhenDisconnected(connect:Boolean):void {
			reconnect = connect;
		}
		
	    public function connect():void {
	      nc.connect(_url, UsersUtil.getInternalMeetingID(), UsersUtil.getMyUserID());
	    }
	    
		private function onAsyncError(event:AsyncErrorEvent):void{
			var logData:Object = new Object();
			logData.user = UsersUtil.getUserData();
			logData.message = "VIDEO WEBCAM onAsyncError"; 
			LOGGER.error(JSON.stringify(logData));
		}
		
		private function onIOError(event:NetStatusEvent):void{
			var logData:Object = new Object();
			logData.user = UsersUtil.getUserData();
			logData.message = "VIDEO WEBCAM onIOError"; 
			LOGGER.error(JSON.stringify(logData));
		}
		
		private function onConnectedToVideoApp():void{
			dispatcher.dispatchEvent(new ConnectedEvent(reconnecting));
			if (reconnecting) {
				reconnecting = false;
				
				var attemptSucceeded:BBBEvent = new BBBEvent(BBBEvent.RECONNECT_CONNECTION_ATTEMPT_SUCCEEDED_EVENT);
				attemptSucceeded.payload.type = ReconnectionManager.VIDEO_CONNECTION;
				dispatcher.dispatchEvent(attemptSucceeded);
			}
		}
    
		private function onNetStatus(event:NetStatusEvent):void{

			LOGGER.debug("[{0}] for [{1}]", [event.info.code, _url]);
			var logData:Object = new Object();
			logData.user = UsersUtil.getUserData();
			logData.user.eventCode = event.info.code + "[reconnecting=" + reconnecting + ",reconnect=" + reconnect + "]";
						
			switch(event.info.code){
				case "NetConnection.Connect.Success":
					numNetworkChangeCount = 0;
          			onConnectedToVideoApp();
					break;
				case "NetStream.Play.Failed":
					if (reconnect) {
						JSLog.warn("NetStream.Play.Failed from bbb-video", logData);
						logData.message = "NetStream.Play.Failed from bbb-video";
						LOGGER.info(JSON.stringify(logData));
					}
					
					break;
				case "NetStream.Play.Stop":
					if (reconnect) {
						JSLog.warn("NetStream.Play.Stop from bbb-video", logData);
						logData.message = "NetStream.Play.Stop from bbb-video";
						LOGGER.info(JSON.stringify(logData));
					}
					
					break;		
				case "NetConnection.Connect.Closed":
					logData.message = "NetConnection.Connect.Closed from bbb-video";
					LOGGER.info(JSON.stringify(logData));
					
					dispatcher.dispatchEvent(new StopBroadcastEvent());
					
					if (reconnect) {
						reconnecting = true;

						var disconnectedEvent:BBBEvent = new BBBEvent(BBBEvent.RECONNECT_DISCONNECTED_EVENT);
						disconnectedEvent.payload.type = ReconnectionManager.VIDEO_CONNECTION;
						disconnectedEvent.payload.callback = connect;
						disconnectedEvent.payload.callbackParameters = [];
						dispatcher.dispatchEvent(disconnectedEvent);
					}
					break;
					
				case "NetConnection.Connect.Failed":
					if (reconnecting) {
						var attemptFailedEvent:BBBEvent = new BBBEvent(BBBEvent.RECONNECT_CONNECTION_ATTEMPT_FAILED_EVENT);
						attemptFailedEvent.payload.type = ReconnectionManager.VIDEO_CONNECTION;
						dispatcher.dispatchEvent(attemptFailedEvent);
					}
					
					if (reconnect) {
						JSLog.warn("NetConnection.Connect.Failed from bbb-video", logData);
						logData.message = "NetConnection.Connect.Failed from bbb-video";
						LOGGER.info(JSON.stringify(logData));
					}
					
					disconnect();
					break;		
				case "NetConnection.Connect.NetworkChange":
					numNetworkChangeCount++;
					if (numNetworkChangeCount % 20 == 0) {
						logData.message = "Detected network change on bbb-video";
						logData.numNetworkChangeCount = numNetworkChangeCount;
						LOGGER.info(JSON.stringify(logData));
					}
					break;
        		default:
					LOGGER.debug("[{0}] for [{1}]", [event.info.code, _url]);
					break;
			}
		}
		
		private function onSecurityError(event:NetStatusEvent):void{
		}
		
		public function get connection():NetConnection{
			return this.nc;
		}
		
		public function startPublishing(e:StartBroadcastEvent):void{
			var ns:NetStream = new NetStream(nc);
			ns.addEventListener( NetStatusEvent.NET_STATUS, onNetStatus );
			ns.addEventListener( IOErrorEvent.IO_ERROR, onIOError );
			ns.addEventListener( AsyncErrorEvent.ASYNC_ERROR, onAsyncError );
			ns.client = this;
			ns.attachCamera(e.camera);

			if ((BBB.getFlashPlayerVersion() >= 11) && e.videoProfile.enableH264) {
				var h264:H264VideoStreamSettings = new H264VideoStreamSettings();
				var h264profile:String = H264Profile.MAIN;
				if (e.videoProfile.h264Profile != "main") {
					h264profile = H264Profile.BASELINE;
				}
				var h264Level:String = H264Level.LEVEL_4_1;
				switch (e.videoProfile.h264Level) {
					case "1": h264Level = H264Level.LEVEL_1; break;
					case "1.1": h264Level = H264Level.LEVEL_1_1; break;
					case "1.2": h264Level = H264Level.LEVEL_1_2; break;
					case "1.3": h264Level = H264Level.LEVEL_1_3; break;
					case "1b": h264Level = H264Level.LEVEL_1B; break;
					case "2": h264Level = H264Level.LEVEL_2; break;
					case "2.1": h264Level = H264Level.LEVEL_2_1; break;
					case "2.2": h264Level = H264Level.LEVEL_2_2; break;
					case "3": h264Level = H264Level.LEVEL_3; break;
					case "3.1": h264Level = H264Level.LEVEL_3_1; break;
					case "3.2": h264Level = H264Level.LEVEL_3_2; break;
					case "4": h264Level = H264Level.LEVEL_4; break;
					case "4.1": h264Level = H264Level.LEVEL_4_1; break;
					case "4.2": h264Level = H264Level.LEVEL_4_2; break;
					case "5": h264Level = H264Level.LEVEL_5; break;
					case "5.1": h264Level = H264Level.LEVEL_5_1; break;
				}
				
				
				h264.setProfileLevel(h264profile, h264Level);
				ns.videoStreamSettings = h264;
			}
			
			ns.publish(e.stream, "live");
			camerasPublishing[e.stream] = ns;
		}
		
		public function stopBroadcasting(stream:String):void{
			LOGGER.debug("Closing netstream for webcam publishing");
      			if (camerasPublishing[stream] != null) {
	      			var ns:NetStream = camerasPublishing[stream];
				ns.attachCamera(null);
				ns.close();
				ns = null;
				delete camerasPublishing[stream];
			}	
		}

		public function stopAllBroadcasting():void {
			for each (var ns:NetStream in camerasPublishing)
			{
				ns.attachCamera(null);
				ns.close();
				ns = null;
			}
			camerasPublishing = new Object();
		}

		public function disconnect():void {
      		LOGGER.debug("VideoProxy:: disconnecting from Video application");
      		stopAllBroadcasting();
			if (nc != null) nc.close();
		}
		
		public function onBWCheck(... rest):Number { 
			return 0; 
		} 
		
		public function onBWDone(... rest):void { 
			var p_bw:Number; 
			if (rest.length > 0) p_bw = rest[0]; 
			// your application should do something here 
			// when the bandwidth check is complete 
			LOGGER.debug("bandwidth = {0} Kbps.", [p_bw]); 
		}
		

	}
}
