/************************************************************************
*************************************************************************
Simple Plugins
Description:
	Included file for Simple Chat Processor in the Simple Plugins project
*************************************************************************
*************************************************************************
This file is part of Simple Plugins project.

This plugin is free software: you can redistribute 
it and/or modify it under the terms of the GNU General Public License as
published by the Free Software Foundation, either version 3 of the License, or
later version. 

This plugin is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this plugin.  If not, see <http://www.gnu.org/licenses/>.
*************************************************************************
*************************************************************************
File Information
$Id$
$Author$
$Revision$
$Date$
$LastChangedBy$
$LastChangedDate$
$URL$
$Copyright: (c) Simple Plugins 2008-2009$
*************************************************************************
*************************************************************************/

#if defined _scp_included
  #endinput
#endif
#define _scp_included

#define MAXLENGTH_INPUT			128 	// Inclues \0 and is the size of the chat input box.
#define MAXLENGTH_NAME				64		// This is backwords math to get compability.  Sourcemod has it set at 32, but there is room for more.
#define MAXLENGTH_MESSAGE		256		// This is based upon the SDK and the length of the entire message, including tags, name, : etc.

#define CHATFLAGS_INVALID		0
#define CHATFLAGS_ALL				(1<<0)
#define CHATFLAGS_TEAM				(1<<1)
#define CHATFLAGS_SPEC				(1<<2)
#define CHATFLAGS_DEAD				(1<<3)

enum ChatMessageHookType 
{
	ChatMessageHookType_PreChat,
	ChatMessageHookType_PostChat,
	ChatMessageHookType_PreClientChat,
	ChatMessageHookType_PostClientChat,
};

/**
 *
 * When a player types a chat message
 *
 * @note 		Use MAXLENGTH_  constants above for formating the strings
 * @note 		Do not rely on the recipients handle to exist beyond the forward
 * @note 		Do not start another usermessage (PrintToChat) within this forward
 *
 * @param 		author						The client index of the player who sent the chat message (By-ref)
 * @param 		recipients					The handle to the client index adt array of the players who should recieve the chat message
 * @param 		name						The client's name of the player who sent the chat message (By-ref)
 * @param 		message						The contents of the chat message (By-ref)
 *
 * @note   		This version is only kept for backwards compatibility. Developers, use the native HookChatMessage.
 *
 * @return		Plugin_Changed or Plugin_Handled to proceed to change a modified value, Plugin_Stop to block the message and Plugin_Continue to go through with the message with no changes.
 *
 */
forward Action:OnChatMessage(&author, Handle:recipients, String:name[], String:message[]);



funcenum ChatMessageHook
{
	/**
	 *
	 * Called exactly before a chat message is printed.
	 *
	 * @note 		Use MAXLENGTH_  constants above for formating the strings
	 * @note 		Do not rely on the recipients handle to exist beyond the forward
	 * @note 		Do not start another usermessage (PrintToChat) within this forward
	 *
	 * @param 		author						The client index of the player who sent the chat message (By-ref)			
	 * @param 		recipient 					The client index of the recipient
	 * @param 		name						The client's name of the player who sent the chat message (By-ref)
	 * @param 		message						The contents of the chat message (By-ref)
	 *
	 * @return		Plugin_Changed to proceed to change a modified value, Plugin_Stop or Plugin_Handled to block the message and Plugin_Continue to go through with the message with no changes.
	 *
	 */
	Action:public(&author, recipient, String:name[], String:message[]),

	/**
	 *
	 * Called exactly before a chat message is printed.
	 *
	 * @param 		author						The client index of the player who sent the chat message			
	 * @param 		recipient 					The client index of the recipient
	 * @param 		name						The client's name of the player who sent the chat message
	 * @param 		message						The contents of the chat message
	 *
	 * @noreturn
	 *
	 */
	public(author, recipient, const String:name[], const String:message[]),

	/**
	 *
	 * Called exactly before a chat message is printed.
	 *
	 * @note 		Use MAXLENGTH_  constants above for formating the strings
	 * @note 		Do not rely on the recipients handle to exist beyond the forward
	 * @note 		Do not start another usermessage (PrintToChat) within this forward
	 *
	 * @param 		author						The client index of the player who sent the chat message (By-ref)
	 * @param 		recipients					An array of bools determining whether each specific client should see the message or not (By-ref)
	 * @param 		name						The client's name of the player who sent the chat message (By-ref)
	 * @param 		message						The contents of the chat message (By-ref)
	 *
	 * @note   		This is considered  to be the 'newer' version of OnChatMessage. The old version will be kept for backwards compatibility.
	 *
	 * @return		Plugin_Changed to proceed to change a modified value, Plugin_Stop or Plugin_Handled to block the message and Plugin_Continue to go through with the message with no changes.
	 *
	 */
	Action:public(&author, bool:recipients[MAXPLAYERS + 1], String:name[], String:message[]),

	/**
	 *
	 * Called exactly before a chat message is printed.
	 *
	 * @param 		author						The client index of the player who sent the chat message
	 * @param 		recipients					An array of bools determining whether each specific client should see the message or not
	 * @param 		name						The client's name of the player who sent the chat message
	 * @param 		message						The contents of the chat message
	 *
	 * @noreturn
	 *
	 */
	public(author, bool:recipients[MAXPLAYERS + 1], const String:name[], const String:message[]),
};

/**
 *
 * Hooks when a client types a chat message.
 * 
 * @param			func 						The ChatMessageHook function that should be called.
 * @param			type						The type of the ChatMessageHookType to hook.
 *
 * @return 			True on success. False otherwise.
 *
 */

native bool:HookChatMessage(ChatMessageHookType:type, ChatMessageHook:func);

/**
 *
 * Removes a ChatMessageHook hook.
 * 
 * @param			func 						The ChatMessageHook function that should be removed.
 * @param			type						The type of the ChatMessageHookType to hook.
 *
 *
 * @return 			True on success. False otherwise.
 *
 */

native bool:UnhookChatMessage(ChatMessageHookType:type, ChatMessageHook:func);


/**
 *
 * Gets the current flags for the chat message
 * Should only be called within OnChatMessage() or a ChatMessageHook (Though it will be somewhat inaccurate during the post chat hook)
 *
 * @note 		The usage of this native is not recommended as it is very messily coded.
 *
 * @return		The current type of chat message (see constants) 
 *
 */
native GetMessageFlags();

 
 
/**
 *  Shared plugin information
 */
public SharedPlugin:_pl_scp = 
{
	name = "scp",
	file = "simple-chatprocessor.smx",
#if defined REQUIRE_PLUGIN
	required = 1
#else
	required = 0
#endif
};

#if !defined REQUIRE_PLUGIN
public _pl_scp_SetNTVOptional()
{
	MarkNativeAsOptional("GetMessageFlags");
	MarkNativeAsOptional("HookChatMessage");
	MarkNativeAsOptional("UnhookChatMessage");
}
#endif