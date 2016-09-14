package org.bigbluebutton.modules.present.commands
{
  import flash.events.Event;
  
  public class ChangePageCommand extends Event
  {
    public static const CHANGE_PAGE_COMMAND:String = "presentation change page command";
    
    public var pageId:String;
    public var preloadCount:uint
	
    public function ChangePageCommand(pageId: String, preloadCount:uint)
    {
      super(CHANGE_PAGE_COMMAND, true, false);
      this.pageId = pageId;
	  this.preloadCount = preloadCount;
    }
  }
}