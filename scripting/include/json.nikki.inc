// Originally by Exolent[jNr] (https://forums.alliedmods.net/showthread.php?t=189772)
// Ported from AMXX pawn to SourceMod sourcepawn by Nicholas Hastings
// Decoding fixed by Nikkii (https://forums.alliedmods.net/showpost.php?p=1914836&postcount=10)

#if defined _json_included
	#endinput
#endif

#define _json_included

#define JSON_KEY_SIZE   512
#define JSON_STR_SIZE   512

//#define JSON_DEBUG

#if defined JSON_DEBUG
	#define JSON_VAR new
	#define JSON_FUNC
#else
	#define JSON_VAR stock
	#define JSON_FUNC stock
#endif

JSON_VAR String:__json_key[ JSON_KEY_SIZE ];
JSON_VAR String:__json_key2[ JSON_KEY_SIZE ];
JSON_VAR String:__json_string[ JSON_STR_SIZE ];

enum JSON
{
	JSON_INVALID = 0,
	
	JSON_Cell,
	JSON_Float,
	JSON_Unsigned,
	JSON_String,
	JSON_Object
};

JSON_FUNC JSON:json_create(bool:is_array=false)
{
	new Handle:hObject = CreateTrie( );
	new Handle:data = CreateTrie( );
	new Handle:keys = CreateArray( JSON_KEY_SIZE );
	
	SetTrieValue( hObject, "data", data );
	SetTrieValue( hObject, "keys", keys );
	
	if( is_array )
	{
		SetTrieValue( hObject, "is_array", true );
	}
	
	return JSON:hObject;
}

JSON_FUNC JSON:json_from_array(const any:hArray[], size, JSON:types[]={JSON_INVALID}, JSON:force_type=JSON_INVALID)
{
	new JSON:json = json_create( .is_array = true );
	
	if( json == JSON_INVALID )
	{
		return JSON_INVALID;
	}
	
	new String:key[ 12 ];
	
	for( new i = 0; i < size; i++ )
	{
		IntToString( i, key, sizeof( key ) );
		
		json_set_cell( json, key, hArray[ i ], ( force_type ? force_type : types[ i ] ) );
	}
	
	return json;
}

JSON_FUNC JSON:json_from_array2(Handle:hArray, size=-1, any:types, bool:force_type=false)
{
	if( hArray == INVALID_HANDLE )
	{
		return JSON_INVALID;
	}
	
	if( size < 0 )
	{
		size = GetArraySize( hArray );
	}
	
	if( !size )
	{
		return JSON_INVALID;
	}
	
	new JSON:json = json_create( .is_array = true );
	
	if( json == JSON_INVALID )
	{
		return JSON_INVALID;
	}
	
	new String:key[ 12 ];
	
	for( new i = 0; i < size; i++ )
	{
		IntToString( i, key, sizeof(key) );
		
		json_set_cell( json, key, GetArrayCell( hArray, i ), JSON:( force_type ? types : GetArrayCell( types, i ) ) );
	}
	
	return json;
}

JSON_FUNC bool:json_set_cell(JSON:hObject, const String:key[], any:value, JSON:type=JSON_Cell)
{
	if( hObject == JSON_INVALID )
	{
		return false;
	}
	
	new Handle:data, Handle:keys;
	
	GetTrieValue( Handle:hObject, "data", data );
	GetTrieValue( Handle:hObject, "keys", keys );
	
	if( !__json_delete( data, key ) )
	{
		PushArrayString( keys, key );
	}
	
	new Handle:info = CreateTrie( );
	
	SetTrieValue( info, "type", type );
	SetTrieValue( info, "value", value );
	
	SetTrieValue( data, key, info );
	
	return true;
}

JSON_FUNC bool:json_set_array(JSON:hObject, const String:key[], const any:hArray[], size, JSON:types[]={JSON_INVALID}, JSON:force_type=JSON_INVALID)
{
	if( hObject == JSON_INVALID )
	{
		return false;
	}
	
	new JSON:child = json_from_array( hArray, size, types, force_type );
	
	return ( child == JSON_INVALID ) ? false : json_set_cell( hObject, key, child, JSON_Object );
}

JSON_FUNC bool:json_set_array2(JSON:hObject, const String:key[], Handle:hArray, size=-1, any:types, bool:force_type=false)
{
	if( hObject == JSON_INVALID )
	{
		return false;
	}
	
	new JSON:child = json_from_array2( hArray, size, types, force_type );
	
	return ( child == JSON_INVALID ) ? false : json_set_cell( hObject, key, child, JSON_Object );
}

JSON_FUNC bool:json_set_string(JSON:hObject, const String:key[], const String:string[])
{
	if( hObject == JSON_INVALID )
	{
		return false;
	}
	
	new Handle:data, Handle:keys;
	
	GetTrieValue( Handle:hObject, "data", data );
	GetTrieValue( Handle:hObject, "keys", keys );
	
	if( !__json_delete( data, key ) )
	{
		PushArrayString( keys, key );
	}
	
	new Handle:info = CreateTrie( );
	
	SetTrieValue( info, "type", JSON_String );
	SetTrieString( info, "value", string );
	
	SetTrieValue( data, key, info );
	
	return true;
}

JSON_FUNC bool:json_get_cell(JSON:hObject, const String:key[], &any:value, &JSON:type=JSON_Cell)
{
	if( hObject == JSON_INVALID )
	{
		return false;
	}
	
	new Handle:data;
	GetTrieValue( Handle:hObject, "data", data );
	
	new Handle:info;
	
	if( !GetTrieValue( data, key, info ) )
	{
		return false;
	}
	
	GetTrieValue( info, "type", type );
	
	if( type != JSON_Cell && type != JSON_Unsigned && type != JSON_Float && type != JSON_Object )
	{
		return false;
	}
	
	GetTrieValue( info, "value", value );
	
	return true;
}

JSON_FUNC bool:json_get_float(JSON:hObject, const String:key[], &Float:value)
{
	if( hObject == JSON_INVALID )
	{
		return false;
	}
	
	new Handle:data;
	GetTrieValue( Handle:hObject, "data", data );
	
	new Handle:info;
	
	if( !GetTrieValue( data, key, info ) )
	{
		return false;
	}
	
	GetTrieValue( info, "type", type );
	
	if( type != JSON_Cell && type != JSON_Unsigned && type != JSON_Float )
	{
		return false;
	}
	
	GetTrieValue( info, "value", value );
	
	return true;
}

JSON_FUNC bool:json_get_array(JSON:hObject, const String:key[], any:output[], outputsize, &readsize, JSON:types[])
{
	if( hObject == JSON_INVALID )
	{
		return false;
	}
	
	new Handle:data;
	GetTrieValue( Handle:hObject, "data", data );
	
	new Handle:info;
	
	if( !GetTrieValue( data, key, info ) )
	{
		return false;
	}
	
	new JSON:type;
	GetTrieValue( info, "type", type );
	
	if( type != JSON_Object )
	{
		return false;
	}
	
	new JSON:hArray;
	GetTrieValue( data, "value", hArray );
	
	new String:num[12];
	new index;
	
	while( index < outputsize )
	{
		IntToString( index, num, sizeof(num) );
		
		if( !json_get_cell( hArray, num, output[ index ], types[ index ] ) )
		{
			break;
		}
		
		index++;
	}

	readsize = index + 1;
	
	return ( index > 0 );
}

JSON_FUNC bool:json_get_array2(JSON:hObject, const String:key[], &Handle:output, size, &Handle:types)
{
	if( hObject == JSON_INVALID )
	{
		return false;
	}
	
	new Handle:data;
	GetTrieValue( Handle:hObject, "data", data );
	
	new Handle:info;
	
	if( !GetTrieValue( data, key, info ) )
	{
		return false;
	}
	
	new JSON:type;
	GetTrieValue( info, "type", type );
	
	if( type != JSON_Object )
	{
		return false;
	}
	
	new JSON:hArray;
	GetTrieValue( data, "value", hArray );
	
	new num[ 12 ];
	IntToString( 0, num, sizeof(num) );
	
	new index, value;
	
	while( index < size )
	{
		IntToString( index, num, sizeof(num) );
		
		if( !json_get_cell( hArray, num, value, type ) )
		{
			break;
		}
		
		ArrayPushCell( output, value );
		ArrayPushCell( types, type );
		
		index++;
	}
	
	return ( index > 0 );
}

JSON_FUNC bool:json_get_string(JSON:hObject, const String:key[], String:output[], len)
{
	if( hObject == JSON_INVALID )
	{
		return false;
	}
	
	new Handle:data;
	GetTrieValue( Handle:hObject, "data", data );
	
	new Handle:info;
	
	if( !GetTrieValue( data, key, info ) )
	{
		return false;
	}
	
	new JSON:type;
	GetTrieValue( info, "type", type );
	
	if( type != JSON_String )
	{
		return false;
	}
	
	GetTrieString( info, "value", output, len );
	
	return true;
}

JSON_FUNC JSON:json_get_type(JSON:hObject, const String:key[])
{
	if( hObject == JSON_INVALID )
	{
		return JSON_INVALID;
	}
	
	new Handle:data;
	GetTrieValue( Handle:hObject, "data", data );
	
	new Handle:info;
	
	if( !GetTrieValue( data, key, info ) )
	{
		return JSON_INVALID;
	}
	
	new JSON:type;
	GetTrieValue( info, "type", type );
	
	return type;
}

JSON_FUNC bool:json_delete(JSON:hObject, const String:key[])
{
	if( hObject == JSON_INVALID )
	{
		return false;
	}
	
	new Handle:data, Handle:keys;
	
	GetTrieValue( Handle:hObject, "data", data );
	GetTrieValue( Handle:hObject, "keys", keys );
	
	new size = GetArraySize( keys );
	
	return __json_delete( data, key, keys, size );
}

JSON_FUNC bool:__json_delete(Handle:data, const String:key[], Handle:keys=INVALID_HANDLE, &size=0)
{
	new Handle:info;
	
	if( GetTrieValue( data, key, info ) )
	{
		RemoveFromTrie( data, key );
		
		if( keys != INVALID_HANDLE && size > 0 )
		{
			for( new i = 0; i < size; i++ )
			{
				GetArrayString( keys, i, __json_key2, sizeof(__json_key2) );
				
				if( !strcmp( __json_key2, key ) )
				{
					RemoveFromArray( keys, i-- );
					size--;
				}
			}
		}
		
		new JSON:type;
		GetTrieValue( info, "type", type );
		
		if( type == JSON_Object )
		{
			new JSON:hObject;
			GetTrieValue( info, "value", hObject );
			
			json_destroy( hObject );
		}
		
		CloseHandle( info );
		
		return true;
	}
	
	return false;
}

JSON_FUNC JSON:json_decode(const String:string[], &pos=0, len=0)
{
	if( !len && !( len = strlen( string ) ) )
	{
		return JSON_INVALID;
	}
	
	while( pos < len && isspace( string[ pos ] ) )
	{
		pos++;
	}
	
	while( len > 0 && isspace( string[ len - 1 ] ) )
	{
		len--;
	}
	
	if( !len || pos >= len )
	{
		return JSON_INVALID;
	}
	
	new JSON:json = JSON_INVALID;
	
	switch( string[ pos ] )
	{
		case '{':
		{
			json = json_create( );
			
			new key_start, key_len;
			new bool:escaped;
			new JSON:child;
			new Handle:hArray;
			new Handle:types;
			new string_start;
			new string_len;
			
			while( ++pos < len && isspace( string[ pos ] ) ) { }
			
			while( json )
			{	
				if( pos >= len || string[ pos ] != '"' )
				{
					json_destroy( json );
					return JSON_INVALID;
				}
				
				key_start = pos + 1;
				escaped = false;
				
				while( ++pos <= len )
				{
					if( pos == len )
					{
						json_destroy( json );
						return JSON_INVALID;
					}
					
					if( escaped )
					{
						escaped = false;
					}
					else if( string[ pos ] == '\\' )
					{
						escaped = true;
					}
					else if( string[ pos ] == '"' )
					{
						break;
					}
				}
				
				key_len = pos - key_start + 1;
				
				if( !key_len )
				{
					json_destroy( json );
					return JSON_INVALID;
				}
				
				while( ++pos < len && isspace( string[ pos ] ) ) { }
				
				if( string[ pos ] != ':' )
				{
					json_destroy( json );
					return JSON_INVALID;
				}
				
				while( ++pos < len && isspace( string[ pos ] ) ) { }
				
				switch( string[ pos ] )
				{
					case '{':
					{
						// Read JSON
						child = json_decode( string, pos, len );
						
						if( child == JSON_INVALID )
						{
							json_destroy( json );
							return JSON_INVALID;
						}
						
						strcopy( __json_key, min( sizeof( __json_key ), key_len ), string[ key_start ] );
						
						json_set_cell( json, __json_key, child, JSON_Object );
					}
					case '[':
					{
						// Read array
						hArray = __json_read_array( string, len, pos, string_len, types );
						
						if( hArray == INVALID_HANDLE )
						{
							json_destroy( json );
							return JSON_INVALID;
						}
						
						strcopy( __json_key, min( sizeof( __json_key ), key_len ), string[ key_start ] );
						
						json_set_array2( json, __json_key, hArray, string_len, types, .force_type = false );
						
						CloseHandle( hArray );
						CloseHandle( types );
					}
					case '"':
					{
						// Read string
						escaped = false;
						
						string_len = 0;
						__json_string[ 0 ] = EOS;
						
						while( ++pos <= len )
						{
							if( pos == len )
							{
								json_destroy( json );
								return JSON_INVALID;
							}
							
							if( escaped )
							{
								escaped = false;
								
								if( string_len < sizeof( __json_string ) )
								{
									__json_string[ string_len++ ] = string[ pos ];
								}
							}
							else if( string[ pos ] == '\\' )
							{
								escaped = true;
							}
							else if( string[ pos ] == '"' )
							{
								pos++;
								break;
							}
							else
							{
								
								if( string_len < sizeof( __json_string ) )
								{
									__json_string[ string_len++ ] = string[ pos ];
								}
							}
						}
						
						if( !string_len )
						{
							json_destroy( json );
							return JSON_INVALID;
						}
						
						__json_string[ string_len ] = EOS;
						
						strcopy( __json_key, min( sizeof( __json_key ), key_len ), string[ key_start ] );
						
						json_set_string( json, __json_key, __json_string );
					}
					default:
					{
						// Read true/false, integer, or float
						string_start = pos;
						
						while(pos < len && !isspace( string[ pos ] ) && !iscontrol( string[ pos ] ) ) {
							pos++;
						}
						
						string_len = pos - string_start;
						__json_string[string_len + 1] = '\0';
						
						strcopy( __json_string, min( sizeof( __json_string ), string_len == -1 ? string_len : string_len + 1 ), string[ string_start ] );
						
						if( !strcmp( __json_string, "true", false ) || !strcmp( __json_string, "false", false ) )
						{
							strcopy( __json_key, min( sizeof( __json_key ), key_len ), string[ key_start ] );
							
							json_set_cell( json, __json_key, ( __json_string[ 0 ] == 't' || __json_string[ 0 ] == 'T' ) );
						}
						else if( is_str_num( __json_string ) )
						{
							strcopy( __json_key, min( sizeof( __json_key ), key_len ), string[ key_start ] );
							
							json_set_cell( json, __json_key, StringToInt( __json_string ) );
						}
						else
						{
							string_len = StrContains( __json_string, "." );
							
							if( string_len <= 0 || !is_str_num( __json_string[ string_len + 1 ] ) )
							{
								json_destroy( json );
								return JSON_INVALID;
							}
							
							__json_string[ string_len ] = EOS;
							
							string_start = _:!!( __json_string[ 0 ] == '-' );
							
							if( !is_str_num( __json_string[ string_start ] ) )
							{
								json_destroy( json );
								return JSON_INVALID;
							}
							
							__json_string[ string_len ] = '.';
							
							strcopy( __json_key, min( sizeof( __json_key ), key_len ), string[ key_start ] );
							
							json_set_cell( json, __json_key, StringToFloat( __json_string ), JSON_Float );
						}
					}
				}
				
				while( pos < len && isspace( string[ pos ] ) )
				{
					pos++;
				}
				
				if( string[ pos ] == '}' )
				{
					pos++;
					break;
				}
				else if( string[ pos ] != ',' )
				{
					json_destroy( json );
					return JSON_INVALID;
				}
				
				while( ++pos < len && isspace( string[ pos ] ) ) { }
			}
		}
		case '[':
		{
			// Read array
			new size;
			new Handle:types;
			
			new Handle:hArray = __json_read_array( string, len, pos, size, types );
			
			if( hArray == INVALID_HANDLE )
			{
				return JSON_INVALID;
			}
			
			json = json_from_array2( hArray, size, types );
			
			CloseHandle( hArray );
			CloseHandle( types );
		}
	}
	
	return json;
}

JSON_FUNC Handle:__json_read_array(const String:string[], len, &pos, &size, &Handle:types)
{
	new Handle:output = CreateArray( JSON_STR_SIZE );
	size = 0;
	types = CreateArray( );
	
	new bool:failed;
	
	new JSON:child;
	new Handle:hArray;
	new hArray_size;
	new Handle:hArray_types;
	new bool:escaped;
	new string_start;
	new string_len;
	
	while( ++pos <= len )
	{
		while( pos < len && isspace( string[ pos ] ) )
		{
			pos++;
		}
		
		if( pos == len )
		{
			//PrintToServer("Position reached length in __json_read_array");
			failed = true;
			break;
		}
		
		switch( string[ pos ] )
		{
			case ']':
			{
				pos++;
				break;
			}
			case '{':
			{
				child = json_decode( string, pos, len );
				
				if( child == JSON_INVALID )
				{
					//PrintToServer("Unable to decode child in __json_read_array");
					failed = true;
					break;
				}
				
				PushArrayCell( output, child );
				PushArrayCell( types, JSON_Object );
				size++;
			}
			case '[':
			{
				hArray = __json_read_array( string, len, pos, hArray_size, hArray_types );
				
				if( hArray == INVALID_HANDLE )
				{
					//PrintToServer("Unable to read child array in __json_read_array");
					failed = true;
					break;
				}
				
				PushArrayCell( output, json_from_array2( hArray, hArray_size, hArray_types ) );
				PushArrayCell( types, JSON_Object );
				size++;
				
				CloseHandle( hArray );
				CloseHandle( hArray_types );
			}
			case '"':
			{
				// Read string
				escaped = false;
				
				string_len = 0;
				__json_string[ 0 ] = EOS;
				
				while( ++pos <= len )
				{
					if( pos == len )
					{
						//PrintToServer("Unable to read string (pos==len) in __json_read_array");
						failed = true;
						break;
					}
					
					if( escaped )
					{
						escaped = false;
						
						if( string_len < sizeof( __json_string ) )
						{
							__json_string[ string_len++ ] = string[ pos ];
						}
					}
					else if( string[ pos ] == '\\' )
					{
						escaped = true;
					}
					else if( string[ pos ] == '"' )
					{
						pos++;
						break;
					}
					else
					{
						
						if( string_len < sizeof( __json_string ) )
						{
							__json_string[ string_len++ ] = string[ pos ];
						}
					}
				}
				
				if( failed )
					break;
				
				if( !string_len )
				{
					//PrintToServer("Unable to read string (!string_len) in __json_read_array");
					failed = true;
					break;
				}
				
				PushArrayString( output, __json_string );
				PushArrayCell( types, JSON_String );
				size++;
			}
			default:
			{
				// Read true/false, integer, or float
				string_start = pos;
				
				while( pos < len && !isspace( string[ pos ] ) && !iscontrol( string[ pos ]) ) {
					pos++;
				}
				
				string_len = pos - string_start + 1;
				
				strcopy( __json_string, min( sizeof( __json_string ), string_len ), string[ string_start ] );
				
				if( !strcmp( __json_string, "true", false ) || !strcmp( __json_string, "false", false ) )
				{
					PushArrayCell( output, ( __json_string[ 0 ] == 't' || __json_string[ 0 ] == 'T' ) );
					PushArrayCell( types, JSON_Cell );
					size++;
				}
				else if( is_str_num( __json_string ) )
				{
					PushArrayCell( output, StringToInt( __json_string ) );
					PushArrayCell( types, JSON_Cell );
					size++;
				}
				else
				{
					string_len = StrContains( __json_string, "." );
					
					if( string_len <= 0 || !is_str_num( __json_string[ string_len + 1 ] ) )
					{
						//PrintToServer("Unable to read float (string_len <= 0 || !is_str_num) in __json_read_array - %i - '%s' - %i", string_len, __json_string, is_str_num( __json_string ));
						failed = true;
						break;
					}
					
					__json_string[ string_len ] = EOS;
					
					string_start = _:!!( __json_string[ 0 ] == '-' );
					
					if( !is_str_num( __json_string[ string_start ] ) )
					{
						//PrintToServer("Unable to read float (!is_str_num) in __json_read_array");
						failed = true;
						break;
					}
					
					__json_string[ string_len ] = '.';
					
					PushArrayCell( output, StringToFloat( __json_string ) );
					PushArrayCell( types, JSON_Float );
					size++;
				}
			}
		}
		
		while( pos < len && isspace( string[ pos ] ) )
		{
			pos++;
		}
		
		if( string[ pos ] == ']' )
		{
			pos++;
			break;
		}
		else if( string[ pos ] != ',' )
		{
			//PrintToServer("Invalid character in __json_read_array, got '%c' expected ','", string[ pos ]);
			failed = true;
			break;
		}
	}
	
	if( failed )
	{
		while( --size >= 0 )
		{
			if( GetArrayCell( types, size ) == JSON_Object )
			{
				child = GetArrayCell( output, size );
				
				json_destroy( child );
			}
		}
		
		CloseHandle( output );
		CloseHandle( types );
		
		output = INVALID_HANDLE;
	}
	
	return output;
}

JSON_FUNC json_encode(JSON:hObject, String:output[], len)
{
	if( hObject == JSON_INVALID )
	{
		return 0;
	}
	
	new Handle:data, Handle:keys;
	
	GetTrieValue( Handle:hObject, "data", data );
	GetTrieValue( Handle:hObject, "keys", keys );
	
	new dummy;
	new bool:is_array = GetTrieValue( Handle:hObject, "is_array", dummy );
	
	new pos = strcopy( output, len, is_array ? "[" : "{" );
	
	new size = GetArraySize( keys );
	
	new Handle:info;
	new bool:first = true;
	new JSON:type;
	new value;
	
	for( new i = 0; i < size; i++ )
	{
		GetArrayString( keys, i, __json_key, sizeof( __json_key ) );
		
		if( GetTrieValue( data, __json_key, info ) )
		{
			if( first )
			{
				first = false;
			}
			else
			{
				pos += strcopy( output[ pos ], len - pos, "," );
			}
			
			if( !is_array )
			{
				pos += strcopy( output[ pos ], len - pos, "\"" );
				
				pos += json_escape( __json_key, output[ pos ], len - pos );
				
				pos += strcopy( output[ pos ], len - pos, "\":" );
			}
			
			GetTrieValue( info, "type", type );
			
			switch( type )
			{
				case JSON_Cell:
				{
					GetTrieValue( info, "value", value );
					
					pos += FormatEx( output[ pos ], len - pos, "%d", value );
				}
				case JSON_Unsigned:
				{
					GetTrieValue( info, "value", value );
					
					pos += FormatEx( output[ pos ], len - pos, "%u", value );
				}
				case JSON_Float:
				{
					GetTrieValue( info, "value", value );
					
					pos += FormatEx( output[ pos ], len - pos, "%f", value );
					
					// Remove insignificant digits
					while( output[ --pos ] == '0' ) { }
					
					if( output[ pos ] == '.' )
					{
						output[ pos ] = EOS;
					}
					else
					{
						
						output[ ++pos ] = EOS;
					}
				}
				case JSON_String:
				{
					GetTrieString( info, "value", __json_string, sizeof( __json_string ) );
					
					pos += strcopy( output[ pos ], len - pos, "\"" );
					
					pos += json_escape( __json_string, output[ pos ], len - pos );
					
					pos += strcopy( output[ pos ], len - pos, "\"" );
				}
				case JSON_Object:
				{
					GetTrieValue( info, "value", value );
					
					pos += json_encode( JSON:value, output[ pos ], len - pos );
				}
			}
		}
	}
	
	pos += strcopy( output[ pos ], len - pos, is_array ? "]" : "}" );
	
	return pos;
}

JSON_FUNC json_escape(const String:string[], String:output[], len)
{
	new pos, c, o;
	
	while( ( c = string[ pos++ ] ) > 0 )
	{
		if( o == len )
		{
			// Out of room for the rest of the string
			// Fail the escaping since we cannot give back full string
			o = 0;
			break;
		}
		
		if( c == '"' || c == '\\' )
		{
			if( ( o + 2 ) > len )
			{
				// Cannot finish escaping the string, so fail the function
				o = 0;
				break;
			}
			
			output[ o++ ] = '\\';
			output[ o++ ] = c;
		}
		else
		{
			output[ o++ ] = c;
		}
	}
	
	output[ o ] = EOS;
	
	return o;
}

JSON_FUNC bool:json_destroy(&JSON:hObject)
{
	if( hObject == JSON_INVALID )
	{
		return false;
	}
	
	new Handle:data, Handle:keys;
	
	GetTrieValue( Handle:hObject, "data", data );
	GetTrieValue( Handle:hObject, "keys", keys );
	
	new size = GetArraySize( keys );
	
	for( new i = 0; i < size; i++ )
	{
		GetArrayString( keys, i, __json_key, sizeof( __json_key ) );
		
		__json_delete( data, __json_key );
	}
	
	CloseHandle( data );
	CloseHandle( keys );
	
	CloseHandle( Handle:hObject );
	
	hObject = JSON_INVALID;
	
	return true;
}

static JSON_FUNC isspace( c )
{
	return c == ' '
		|| c == '\t'
		|| c == '\n'
		|| c == '\r'
		|| c == '\v'
		|| c == '\f'
	;
}

static JSON_FUNC iscontrol( c )
{
	return c == ','
		|| c == '{'
		|| c == '}'
		|| c == '['
		|| c == ']'
	;
}

static JSON_FUNC min( x, y )
{
	return ( x < y ) ? x : y;
}

static JSON_FUNC bool:is_str_num( const String:sString[] )
{
	new i = 0;

	if (sString[i] && (sString[i] == '-' || sString[i] == '+'))
		i = 1;
	
	while (sString[i] && IsCharNumeric(sString[i]))
		++i;
	
	return sString[i] == 0 && i != 0;
}
