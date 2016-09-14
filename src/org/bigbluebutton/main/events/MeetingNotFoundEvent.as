package org.bigbluebutton.main.events
{
  import flash.events.Event;
  
  public class MeetingNotFoundEvent extends Event
  {
    public static const MEETING_NOT_FOUND:String = "meeting not found event";
    
    public var logoutUrl:String;
    
    public function MeetingNotFoundEvent(logoutTo:String)
    {
      super(MEETING_NOT_FOUND, true, false);
      logoutUrl = logoutTo;
    }
  }
}