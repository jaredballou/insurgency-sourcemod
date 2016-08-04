#include <sourcemod>

public Plugin:myinfo = 
{
    name = "[INS] User Message Debug",
    author = "jballou",
    description = "dumps messages",
    version = "0.1",
    url = ""
}

public OnPluginStart()
{
	HookUserMessage(GetUserMessageId("Geiger"),HookUserMessages,true);
	HookUserMessage(GetUserMessageId("Train"),HookUserMessages,true);
	HookUserMessage(GetUserMessageId("AchievementEvent"),HookUserMessages,true);
	HookUserMessage(GetUserMessageId("CloseCaption"),HookUserMessages,true);
	HookUserMessage(GetUserMessageId("CloseCaptionDirect"),HookUserMessages,true);
	HookUserMessage(GetUserMessageId("HintText"),HookUserMessages,true);
	HookUserMessage(GetUserMessageId("KeyHintText"),HookUserMessages,true);
	HookUserMessage(GetUserMessageId("HudText"),HookUserMessages,true);
	HookUserMessage(GetUserMessageId("SayText"),HookUserMessages,true);
	HookUserMessage(GetUserMessageId("SayText2"),HookUserMessages,true);
	HookUserMessage(GetUserMessageId("TextMsg"),HookUserMessages,true);
	HookUserMessage(GetUserMessageId("HudMsg"),HookUserMessages,true);
	HookUserMessage(GetUserMessageId("ResetHUD"),HookUserMessages,true);
	HookUserMessage(GetUserMessageId("CreditsMsg"),HookUserMessages,true);
	HookUserMessage(GetUserMessageId("ShowMenu"),HookUserMessages,true);
	HookUserMessage(GetUserMessageId("VGUIMenu"),HookUserMessages,true);
	HookUserMessage(GetUserMessageId("VGUIHide"),HookUserMessages,true);
	HookUserMessage(GetUserMessageId("ItemPickup"),HookUserMessages,true);
	HookUserMessage(GetUserMessageId("Damage"),HookUserMessages,true);
	HookUserMessage(GetUserMessageId("CurrentTimescale"),HookUserMessages,true);
	HookUserMessage(GetUserMessageId("DesiredTimescale"),HookUserMessages,true);
	HookUserMessage(GetUserMessageId("VoiceMask"),HookUserMessages,true);
	HookUserMessage(GetUserMessageId("RequestState"),HookUserMessages,true);
	HookUserMessage(GetUserMessageId("Shake"),HookUserMessages,true);
	HookUserMessage(GetUserMessageId("Tilt"),HookUserMessages,true);
	HookUserMessage(GetUserMessageId("Fade"),HookUserMessages,true);
	HookUserMessage(GetUserMessageId("Rumble"),HookUserMessages,true);
	HookUserMessage(GetUserMessageId("PlayerStatsUpdate"),HookUserMessages,true);
	HookUserMessage(GetUserMessageId("RoundStats"),HookUserMessages,true);
	HookUserMessage(GetUserMessageId("GameStats"),HookUserMessages,true);
	HookUserMessage(GetUserMessageId("CallVoteFailed"),HookUserMessages,true);
	HookUserMessage(GetUserMessageId("VoteStart"),HookUserMessages,true);
	HookUserMessage(GetUserMessageId("VotePass"),HookUserMessages,true);
	HookUserMessage(GetUserMessageId("VoteFailed"),HookUserMessages,true);
	HookUserMessage(GetUserMessageId("VoteSetup"),HookUserMessages,true);
	HookUserMessage(GetUserMessageId("VoiceSubtitle"),HookUserMessages,true);
	HookUserMessage(GetUserMessageId("MapVoteStart"),HookUserMessages,true);
	HookUserMessage(GetUserMessageId("MapVoteEnd"),HookUserMessages,true);
	HookUserMessage(GetUserMessageId("MapVoteUpdate"),HookUserMessages,true);
	HookUserMessage(GetUserMessageId("MapVoteReceived"),HookUserMessages,true);
	HookUserMessage(GetUserMessageId("SendAudio"),HookUserMessages,true);
	HookUserMessage(GetUserMessageId("HQAudio"),HookUserMessages,true);
	HookUserMessage(GetUserMessageId("FireMode"),HookUserMessages,true);
	HookUserMessage(GetUserMessageId("FFMsg"),HookUserMessages,true);
	HookUserMessage(GetUserMessageId("DeathInfo"),HookUserMessages,true);
	HookUserMessage(GetUserMessageId("AngleHack"),HookUserMessages,true);
	HookUserMessage(GetUserMessageId("CameraMode"),HookUserMessages,true);
	HookUserMessage(GetUserMessageId("Pain"),HookUserMessages,true);
	HookUserMessage(GetUserMessageId("VoiceCmd"),HookUserMessages,true);
	HookUserMessage(GetUserMessageId("VInventory"),HookUserMessages,true);
	HookUserMessage(GetUserMessageId("UnitOrder"),HookUserMessages,true);
	HookUserMessage(GetUserMessageId("ObjOrder"),HookUserMessages,true);
	HookUserMessage(GetUserMessageId("GameMessage"),HookUserMessages,true);
	HookUserMessage(GetUserMessageId("ObjMsg"),HookUserMessages,true);
	HookUserMessage(GetUserMessageId("PlayerInfo"),HookUserMessages,true);
	HookUserMessage(GetUserMessageId("PlayerLogin"),HookUserMessages,true);
	HookUserMessage(GetUserMessageId("ShowHint"),HookUserMessages,true);
	HookUserMessage(GetUserMessageId("ReinforceMsg"),HookUserMessages,true);
	HookUserMessage(GetUserMessageId("PlayerStatus"),HookUserMessages,true);
	HookUserMessage(GetUserMessageId("MoraleNotice"),HookUserMessages,true);
	HookUserMessage(GetUserMessageId("PositionUpdate"),HookUserMessages,true);
	HookUserMessage(GetUserMessageId("PurchaseError"),HookUserMessages,true);
}
public Action:HookUserMessages(UserMsg:msg_id, Handle:bf, const players[], playersNum, bool:reliable, bool:init) 
{
	new String:MsgName[256];
    GetUserMessageName(msg_id,MsgName,sizeof(MsgName));
	PrintToServer("[UMDEBUG] MsgName %s",MsgName);
}
