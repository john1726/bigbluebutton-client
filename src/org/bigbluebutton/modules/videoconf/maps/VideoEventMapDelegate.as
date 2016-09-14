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
package org.bigbluebutton.modules.videoconf.maps
{
  import com.asfusion.mate.events.Dispatcher;
  
  import flash.events.IEventDispatcher;
  import flash.media.Camera;
  
  import mx.collections.ArrayCollection;
  import mx.collections.ArrayList;
  
  import org.as3commons.logging.api.ILogger;
  import org.as3commons.logging.api.getClassLogger;
  import org.bigbluebutton.common.Media;
  import org.bigbluebutton.common.events.CloseWindowEvent;
  import org.bigbluebutton.common.events.OpenWindowEvent;
  import org.bigbluebutton.common.events.ToolbarButtonEvent;
  import org.bigbluebutton.core.BBB;
  import org.bigbluebutton.core.UsersUtil;
  import org.bigbluebutton.core.managers.UserManager;
  import org.bigbluebutton.core.model.VideoProfile;
  import org.bigbluebutton.core.vo.CameraSettingsVO;
  import org.bigbluebutton.main.events.BBBEvent;
  import org.bigbluebutton.main.events.MadePresenterEvent;
  import org.bigbluebutton.main.events.StoppedViewingWebcamEvent;
  import org.bigbluebutton.main.events.UserJoinedEvent;
  import org.bigbluebutton.main.events.UserLeftEvent;
  import org.bigbluebutton.main.model.users.BBBUser;
  import org.bigbluebutton.main.model.users.events.BroadcastStartedEvent;
  import org.bigbluebutton.main.model.users.events.BroadcastStoppedEvent;
  import org.bigbluebutton.main.model.users.events.StreamStoppedEvent;
  import org.bigbluebutton.modules.videoconf.business.VideoProxy;
  import org.bigbluebutton.modules.videoconf.events.ClosePublishWindowEvent;
  import org.bigbluebutton.modules.videoconf.events.ConnectedEvent;
  import org.bigbluebutton.modules.videoconf.events.ShareCameraRequestEvent;
  import org.bigbluebutton.modules.videoconf.events.StartBroadcastEvent;
  import org.bigbluebutton.modules.videoconf.events.StopBroadcastEvent;
  import org.bigbluebutton.modules.videoconf.events.StopShareCameraRequestEvent;
  import org.bigbluebutton.modules.videoconf.model.VideoConfOptions;
  import org.bigbluebutton.modules.videoconf.views.GraphicsWrapper;
  import org.bigbluebutton.modules.videoconf.views.ToolbarPopupButton;
  import org.bigbluebutton.modules.videoconf.views.VideoDock;

  public class VideoEventMapDelegate
  {
	private static const LOGGER:ILogger = getClassLogger(VideoEventMapDelegate);
	private static var PERMISSION_DENIED_ERROR:String = "PermissionDeniedError";

    private var options:VideoConfOptions = new VideoConfOptions();
    private var uri:String;

    private var button:ToolbarPopupButton = new ToolbarPopupButton();
    private var proxy:VideoProxy;

    private var _dispatcher:IEventDispatcher;
    private var _ready:Boolean = false;
    private var _isPublishing:Boolean = false;
    private var _isPreviewWebcamOpen:Boolean = false;
    private var _isWaitingActivation:Boolean = false;
    private var _chromeWebcamPermissionDenied:Boolean = false;

    private var _videoDock:VideoDock;
    private var _graphics:GraphicsWrapper = new GraphicsWrapper();
    private var streamList:ArrayList = new ArrayList();
    private var numberOfWindows:Object = new Object();

	private var _restream:Boolean = false;
	private var _cameraIndex:int;
	private var _videoProfile:VideoProfile;
	
	private var globalDispatcher:Dispatcher;
	
    public function VideoEventMapDelegate(dispatcher:IEventDispatcher)
    {
      _dispatcher = dispatcher;
	  globalDispatcher = new Dispatcher();
    }

    private function get me():String {
      return UsersUtil.getMyUsername();
    }

    public function start(uri:String):void {
      LOGGER.debug("VideoEventMapDelegate:: [{0}] Video Module Started.", [me]);
      this.uri = uri;

      _videoDock = new VideoDock();
      var windowEvent:OpenWindowEvent = new OpenWindowEvent(OpenWindowEvent.OPEN_WINDOW_EVENT);
      windowEvent.window = _videoDock;
      _dispatcher.dispatchEvent(windowEvent);

      _videoDock.addChild(_graphics);
    }

    public function viewCamera(userID:String, stream:String, name:String, mock:Boolean = false):void {
      LOGGER.debug("VideoEventMapDelegate:: [{0}] viewCamera. ready = [{1}]", [me, _ready]);

      if (!_ready) return;
      LOGGER.debug("VideoEventMapDelegate:: [{0}] Viewing [{1} stream [{2}]", [me, userID, stream]);
      if (! UserManager.getInstance().getConference().amIThisUser(userID)) {
        openViewWindowFor(userID);
      }
    }

	public function handleStreamStoppedEvent(event:StreamStoppedEvent):void {
		if (UserManager.getInstance().getConference().amIThisUser(event.userId)) {
			closePublishWindowByStream(event.streamId);
		} else {
			closeViewWindowWithStream(event.userId, event.streamId);
		}
	}
	
    public function handleUserLeftEvent(event:UserLeftEvent):void {
      LOGGER.debug("VideoEventMapDelegate:: [{0}] handleUserLeftEvent. ready = [{1}]", [me, _ready]);

      if (!_ready) return;

      closeWindow(event.userID);
    }

    public function handleUserJoinedEvent(event:UserJoinedEvent):void {
		LOGGER.debug("VideoEventMapDelegate:: [{0}] handleUserJoinedEvent. ready = [{1}]", [me, _ready]);

      if (!_ready) return;

      if (options.displayAvatar) {
        openAvatarWindowFor(event.userID);
      }
    }

    private function displayToolbarButton():void {
      button.isPresenter = true;

      if (options.presenterShareOnly) {
        if (UsersUtil.amIPresenter()) {
          button.isPresenter = true;
        } else {
          button.isPresenter = false;
        }
      }

    }

    private function addToolbarButton():void{

      if (proxy.videoOptions.showButton) {
        displayToolbarButton();

        var event:ToolbarButtonEvent = new ToolbarButtonEvent(ToolbarButtonEvent.ADD);
        event.button = button;
		event.module="Webcam";
        _dispatcher.dispatchEvent(event);
      }
    }

    private function autoStart():void {
      if (options.skipCamSettingsCheck) {
        skipCameraSettingsCheck();
      } else {
        var dp:Object = [];
        for(var i:int = 0; i < Media.availableCameras; i++) {
          dp.push({label: Media.getCameraName(i), status: button.OFF_STATE});
        }
        button.enabled = false;
        var shareCameraRequestEvent:ShareCameraRequestEvent = new ShareCameraRequestEvent();
        shareCameraRequestEvent.camerasArray = dp;
        _dispatcher.dispatchEvent(shareCameraRequestEvent);
      }
    }

    private function changeDefaultCamForMac():Camera {
      for (var i:int = 0; i < Media.availableCameras; i++){
        if (Camera.names[i] == "USB Video Class Video") {
          /** Set as default for Macs */
          return Camera.getCamera("USB Video Class Video");
        }
      }

      return null;
    }

    private function skipCameraSettingsCheck(camIndex:int = -1):void {
      if (camIndex == -1) {
        var cam:Camera = changeDefaultCamForMac();
        if (cam == null) {
          cam = Camera.getCamera();
        }
        camIndex = cam.index;
      }

      var videoProfile:VideoProfile = BBB.defaultVideoProfile;
      initCameraWithSettings(camIndex, videoProfile);
    }

    private function openWebcamWindows():void {
		LOGGER.debug("VideoEventMapDelegate:: [{0}] openWebcamWindows. ready = [{1}]", [me, _ready]);

      var uids:ArrayCollection = UsersUtil.getUserIDs();

      for (var i:int = 0; i < uids.length; i++) {
        var u:String = uids.getItemAt(i) as String;
        LOGGER.debug("VideoEventMapDelegate:: [{0}] openWebcamWindows:: open window for = [{1}]", [me, u]);
        openWebcamWindowFor(u);
      }
    }

    private function openWebcamWindowFor(userID:String):void {
      LOGGER.debug("VideoEventMapDelegate:: [{0}] openWebcamWindowFor:: open window for = [{1}]", [me, userID]);
      if (! UsersUtil.isMe(userID) && UsersUtil.hasWebcamStream(userID)) {
        LOGGER.debug("VideoEventMapDelegate:: [{0}] openWebcamWindowFor:: Not ME and user = [{1}] is publishing.", [me, userID]);

        if (hasWindow(userID)) {
          LOGGER.debug("VideoEventMapDelegate:: [{0}] openWebcamWindowFor:: user = [{1}] has a window open. Close it.", [me, userID]);
          closeWindow(userID);
        }
        LOGGER.debug("VideoEventMapDelegate:: [{0}] openWebcamWindowFor:: View user's = [{1}] webcam.", [me, userID]);
        openViewWindowFor(userID);
      } else {
        if (UsersUtil.isMe(userID) && options.autoStart) {
          LOGGER.debug("VideoEventMapDelegate:: [{0}] openWebcamWindowFor:: It's ME and AutoStart. Start publishing.", [me]);
          autoStart();
        } else {
          if (options.displayAvatar) {
            LOGGER.debug("VideoEventMapDelegate:: [{0}] openWebcamWindowFor:: It's NOT ME and NOT AutoStart. Open Avatar for user = [{1}]", [me, userID]);
            openAvatarWindowFor(userID);
          } else {
            LOGGER.debug("VideoEventMapDelegate:: [{0}] openWebcamWindowFor:: Is THERE another option for user = [{1}]", [me, userID]);
          }
        }
      }
    }

    private function openAvatarWindowFor(userID:String):void {
      if (! UsersUtil.hasUser(userID)) return;

      closeAllAvatarWindows(userID);

      _graphics.addAvatarFor(userID);
    }

    private function closeAllAvatarWindows(userID:String):void {
      _graphics.removeAvatarFor(userID);
    }

    private function openPublishWindowFor(userID:String, camIndex:int, videoProfile:VideoProfile):void {
      closeAllAvatarWindows(userID);

      _graphics.addCameraFor(userID, camIndex, videoProfile);
    }

    private function hasWindow(userID:String):Boolean {
      return _graphics.hasGraphicsFor(userID);
    }

    private function closeWindow(userID:String):void {
      _graphics.removeGraphicsFor(userID);
    }

    private function closePublishWindowByStream(stream:String):int {
      return _graphics.removeVideoByStreamName(UsersUtil.getMyUserID(), stream);
    }
    
    private function closePublishWindow():void {
      closeWindow(UsersUtil.getMyUserID());
    }

    private function openViewWindowFor(userID:String):void {
      if (!proxy.connection.connected) {
        return;
      }
      
      LOGGER.debug("VideoEventMapDelegate:: [{0}] openViewWindowFor:: Opening VIEW window for [{1}] [{2}]", [me, userID, UsersUtil.getUserName(userID)]);

      var bbbUser:BBBUser = UsersUtil.getUser(userID);
      if (bbbUser.hasStream) {
        closeAllAvatarWindows(userID);
      }
      _graphics.addVideoFor(userID, proxy.connection);
    }

    public function connectToVideoApp():void {
      proxy = new VideoProxy(uri);
	  proxy.reconnectWhenDisconnected(true);
      proxy.connect();
    }

    public function startPublishing(e:StartBroadcastEvent):void{
	  LOGGER.debug("VideoEventMapDelegate:: [{0}] startPublishing:: Publishing stream to: {1}/{2}", [me, proxy.connection.uri, e.stream]);
      proxy.startPublishing(e);

	  _isWaitingActivation = false;
      _isPublishing = true;
      UsersUtil.setIAmPublishing(true);

      var broadcastEvent:BroadcastStartedEvent = new BroadcastStartedEvent();
      streamList.addItem(e.stream);
      broadcastEvent.stream = e.stream;
      broadcastEvent.userid = UsersUtil.getMyUserID();
      broadcastEvent.isPresenter = UsersUtil.amIPresenter();
      broadcastEvent.camSettings = UsersUtil.amIPublishing();

      _dispatcher.dispatchEvent(broadcastEvent);
	  if (proxy.videoOptions.showButton) {
		  button.publishingStatus(button.START_PUBLISHING);
	  }
    }

    public function stopPublishing(e:StopBroadcastEvent):void{
      LOGGER.debug("VideoEventMapDelegate:: [{0}] Stop publishing. ready = [{1}]", [me, _ready]);
      checkLastBroadcasting();
      streamList.removeItem(e.stream);
      stopBroadcasting(e.stream);
      button.setCamAsInactive(e.camId);
    }

    private function checkLastBroadcasting():void {
      LOGGER.debug("[VideoEventMapDelegate:checkLastBroadcasting]");
      _isPublishing = streamList.length > 0;
      UsersUtil.setIAmPublishing(streamList.length > 0);
    }

    private function stopBroadcasting(stream:String = ""):void {
      if (stream == null) stream = "";
      LOGGER.debug("Stopping broadcast{0}", [(stream.length > 0? " of stream [" + stream + "]": "")]);

      proxy.stopBroadcasting(stream);

      var broadcastEvent:BroadcastStoppedEvent = new BroadcastStoppedEvent();
      broadcastEvent.stream = stream;
      broadcastEvent.userid = UsersUtil.getMyUserID();
      broadcastEvent.avatarURL = UsersUtil.getAvatarURL();
      _dispatcher.dispatchEvent(broadcastEvent);

      if (stream.length > 0) {
        var camId:int = closePublishWindowByStream(stream);

        if (proxy.videoOptions.showButton) {
          //Make toolbar button enabled again
          button.publishingStatus(button.STOP_PUBLISHING, camId);
        }
      } else {
        closePublishWindow();
        
        if (proxy.videoOptions.showButton) {
          // make toolbar button enabled again
          button.setAllCamAsInactive();
        }
      }

      if (streamList.length == 0 && options.displayAvatar) {
        LOGGER.debug("VideoEventMapDelegate:: [{0}] Opening avatar", [me]);
        openAvatarWindowFor(UsersUtil.getMyUserID());
      }
    }

    public function handleClosePublishWindowEvent(event:ClosePublishWindowEvent):void {
      LOGGER.debug("Closing publish window");
      if (_isPublishing || _chromeWebcamPermissionDenied) {
        stopBroadcasting();
      }
    }

    public function handleShareCameraRequestEvent(event:ShareCameraRequestEvent):void {
		LOGGER.debug("[VideoEventMapDelegate:handleShareCameraRequestEvent]");
		if (options.skipCamSettingsCheck) {
			skipCameraSettingsCheck(int(event.defaultCamera));
		} else {
			openWebcamPreview(event.publishInClient, event.defaultCamera, event.camerasArray);
		}
    }

    public function handleStopAllShareCameraRequestEvent(event:StopShareCameraRequestEvent):void {
      LOGGER.debug("[VideoEventMapDelegate:handleStopAllShareCameraRequestEvent]");
      stopBroadcasting();
    }

    public function handleStopShareCameraRequestEvent(event:StopShareCameraRequestEvent):void {
      LOGGER.debug("[VideoEventMapDelegate:handleStopShareCameraRequestEvent]");
      var userID:String = UsersUtil.getMyUserID();
      var camIndex:int = event.camId;

      _graphics.removeVideoByCamIndex(userID, camIndex);
    }

	public function handleCamSettingsClosedEvent(event:BBBEvent):void{
		_isPreviewWebcamOpen = false;
	}

    private function openWebcamPreview(publishInClient:Boolean, defaultCamera:String, camerasArray:Object):void {
      var openEvent:BBBEvent = new BBBEvent(BBBEvent.OPEN_WEBCAM_PREVIEW);
      openEvent.payload.publishInClient = publishInClient;
      openEvent.payload.defaultCamera = defaultCamera;
      openEvent.payload.camerasArray = camerasArray;
      openEvent.payload.chromePermissionDenied = _chromeWebcamPermissionDenied;

	  _isPreviewWebcamOpen = true;

      _dispatcher.dispatchEvent(openEvent);
    }

    public function stopModule():void {
      LOGGER.debug("VideoEventMapDelegate:: stopping video module");
      closeAllWindows();
	  proxy.reconnectWhenDisconnected(false);
      proxy.disconnect();
    }

    public function closeAllWindows():void{
      LOGGER.debug("VideoEventMapDelegate:: closing all windows");
      if (_isPublishing) {
        stopBroadcasting();
      }

      _graphics.shutdown();
	  
	  var event:CloseWindowEvent = new CloseWindowEvent(CloseWindowEvent.CLOSE_WINDOW_EVENT);
	  event.window = _videoDock;
	  globalDispatcher.dispatchEvent(event);
    }

    public function switchToPresenter(event:MadePresenterEvent):void{
      LOGGER.debug("VideoEventMapDelegate:: [{0}] Got Switch to presenter event. ready = [{1}]", [me, _ready]);

      if (options.showButton) {
        displayToolbarButton();
      }
    }

    public function switchToViewer(event:MadePresenterEvent):void{
      LOGGER.debug("VideoEventMapDelegate:: [{0}] Got Switch to viewer event. ready = [{1}]", [me, _ready]);

      if (options.showButton){
        LOGGER.debug("****************** Switching to viewer. Show video button?=[{0}]", [UsersUtil.amIPresenter()]);
        displayToolbarButton();
        if (_isPublishing && options.presenterShareOnly) {
          stopBroadcasting();
        }
      }
    }

    public function connectedToVideoApp(event: ConnectedEvent):void{
      LOGGER.debug("VideoEventMapDelegate:: [{0}] Connected to video application.", [me]);
      _ready = true;
      if (event.reconnection) {
        closeAllWindows();
        handleRestream();
      } else {
        addToolbarButton();
      }
      
      openWebcamWindows();
    }

    public function handleCameraSetting(event:BBBEvent):void {
	  _cameraIndex = event.payload.cameraIndex;
      _videoProfile = event.payload.videoProfile;
	  _restream = event.payload.restream;
      LOGGER.debug("VideoEventMapDelegate::handleCameraSettings [{0},{1}]", [_cameraIndex, _videoProfile.id]);
      initCameraWithSettings(_cameraIndex, _videoProfile);
    }

	public function handleEraseCameraSetting(event:BBBEvent):void {
		_cameraIndex = -1;
		_videoProfile = null;
		_restream = event.payload.restream;
	}
	
	private function handleRestream():void {
		if(_restream){
			LOGGER.debug("VideoEventMapDelegate::handleRestream [{0},{1}]", [_cameraIndex, _videoProfile.id]);
			initCameraWithSettings(_cameraIndex, _videoProfile);
		}
	}
	
    private function initCameraWithSettings(camIndex:int, videoProfile:VideoProfile):void {
      var camSettings:CameraSettingsVO = new CameraSettingsVO();
      camSettings.camIndex = camIndex;
      camSettings.videoProfile = videoProfile;

      UsersUtil.setCameraSettings(camSettings);

      _isWaitingActivation = true;
      button.setCamAsActive(camIndex);
      openPublishWindowFor(UsersUtil.getMyUserID(), camIndex, videoProfile);
    }

    private function closeViewWindowWithStream(userID:String, stream:String):void {
      _graphics.removeVideoByStreamName(userID, stream);
    }

    public function handleStoppedViewingWebcamEvent(event:StoppedViewingWebcamEvent):void {
      LOGGER.debug("VideoEventMapDelegate::handleStoppedViewingWebcamEvent [{0}] received StoppedViewingWebcamEvent for user [{1}]", [me, event.webcamUserID]);

      closeViewWindowWithStream(event.webcamUserID, event.streamName);

      if (options.displayAvatar && UsersUtil.hasUser(event.webcamUserID) && ! UsersUtil.isUserLeaving(event.webcamUserID)) {
        LOGGER.debug("VideoEventMapDelegate::handleStoppedViewingWebcamEvent [{0}] Opening avatar for user [{1}]", [me, event.webcamUserID]);
        openAvatarWindowFor(event.webcamUserID);
      }
    }
  }
}
