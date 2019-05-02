#pragma semicolon 1

#include <sourcemod>
#include <keyvalues>

#define PLUGIN_VERSION "1.1.1"

public Plugin:myinfo = 
{
	name = "EventInfo",
	author = "theY4Kman",
	description = "Gives players information on certain events or chat triggers",
	version = PLUGIN_VERSION,
	url = "http://y4kstudios.com/sourcemod/"
};

new Handle:info;

public OnPluginStart(){
  CreateTimer(3.0,TimerHookEvents);
  RegConsoleCmd("say",HookedCmdEvent);
  RegConsoleCmd("say_team",HookedCmdEvent);
  
  // The version cvar
  CreateConVar("eventinfo_version",PLUGIN_VERSION,"The version of the SourceMod plugin EventInfo, by theY4Kman",FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED);
}

public Action:TimerHookEvents(Handle:timer){
  HookEvents();
}

public HookEvents(){
  new String:path[PLATFORM_MAX_PATH];
  BuildPath(Path_SM,path,sizeof(path),"configs/eventinfo.cfg");
  
  info = CreateKeyValues("EventInfo");
  FileToKeyValues(info,path);
  
  if(KvGotoFirstSubKey(info)){
    new String:nevent[128];
    do {
      KvGetSectionName(info,nevent,sizeof(nevent));
      HookEventEx(nevent,HookedEvent);
    } while(KvGotoNextKey(info));
  } else {
    LogMessage("Could not find the \"EventInfo\" Key in \"%s\"!",path);
  }
  
  return Plugin_Handled;
}

public HookedEvent(Handle:event, const String:name[], bool:dontBroadcast){
  KvRewind(info);
  if(KvJumpToKey(info,name)) CreateTimer(KvGetFloat(info,"delay"),EventReply,GetClientOfUserId(GetEventInt(event,"userid")));
}

public Action:HookedCmdEvent(client,args){
  new String:chat[130];
  GetCmdArgString(chat,sizeof(chat));
  new sindex = 0;
  if(chat[0] == '"'){
    sindex = 1;
    chat[strlen(chat)-1] = '\0';
  }
  
  KvRewind(info);
  if(KvJumpToKey(info,chat[sindex])) CreateTimer(KvGetFloat(info,"delay"),EventReply,client);
}

public Action:EventReply(Handle:timer,any:client){
    if(client){
    new String:msg[512];
    new String:uname[64];
    new String:hostname[128];
    new Handle:hhost;
    
    GetClientName(client,uname,sizeof(uname));
    hhost = FindConVar("hostname");
    GetConVarString(hhost,hostname,sizeof(hostname));
  
    KvSetEscapeSequences(info,true);
    KvGetString(info,"message",msg,sizeof(msg));
    
    ReplaceString(msg,sizeof(msg),"%u",uname);
    ReplaceString(msg,sizeof(msg),"%h",hostname);
    ReplaceString(msg,sizeof(msg),"\\n","\n");
    if(!KvGetNum(info,"type")){
      SendHintText(client,msg);
    } else if(KvGetNum(info,"type") == 1) {
      PrintToChat(client,msg);
    } else {
      new Handle:panel = CreatePanel();
      DrawPanelText(panel,msg);
      SendPanelToClient(panel,client,PanelHandle,KvGetNum(info,"time"));
    }
  }
  return Plugin_Handled;
}

public PanelHandle(Handle:menu, MenuAction:action, param1, param2){
}

// THANKS SO MUCH TO _pRED FOR THESE STOCKS!
// Get on irc.gamesurge.net #sourcemod and give him hugs!
stock SendHintText(client, String:text[], any:...){
    new String:message[192];

    VFormat(message,191,text, 2);
    new len = strlen(message);
    if(len > 30){
        new LastAdded=0;
        
        for(new i=0;i<len;i++){
            if((message[i]==' ' && LastAdded > 30 && (len-i) > 10) || ((GetNextSpaceCount(text,i+1) + LastAdded)  > 34)){
                message[i] = '\n';
                LastAdded = 0;
            }
            else LastAdded++;
        }
    }
    new Handle:HintMessage = StartMessageOne("HintText",client);
    BfWriteByte(HintMessage,-1);
    BfWriteString(HintMessage,message);
    EndMessage();
}
stock GetNextSpaceCount(String:text[],CurIndex){
    new Count=0;
    new len = strlen(text);
    for(new i=CurIndex;i<len;i++){
        if(text[i] == ' ') return Count;
        else Count++;
    }
    return Count;
}
