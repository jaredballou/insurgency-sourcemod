/**
 * vim: set ts=4 :
 * =============================================================================
 * cURL Self Test
 * 
 * =============================================================================
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, version 3.0, as published by the
 * Free Software Foundation.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * As a special exception, AlliedModders LLC gives you permission to link the
 * code of this program (as well as its derivative works) to "Half-Life 2," the
 * "Source Engine," the "SourcePawn JIT," and any Game MODs that run on software
 * by the Valve Corporation.  You must obey the GNU General Public License in
 * all respects for all other code used.  Additionally, AlliedModders LLC grants
 * this exception to all derivative works.  AlliedModders LLC defines further
 * exceptions, found in LICENSE.txt (as of this writing, version JULY-31-2007),
 * or <http://www.sourcemod.net/license.php>.
 *
 * Version: $Id$
 */


/*
Usage:
curl_self_test
curl_hash_test

All output test files in addons/sourcemod/data/curl_test
Test #1 Get cURL version & supported protocols
Test #2 Get a web page
Test #3 Get ca-bundle.crt for #4
Test #4 Verify a https website using ca-bundle.crt
Test #5 Get a web page body & header content to file
Test #6 Download a image for #7
Test #7 Upload image using curl_httppost() & get the uploaded image url
Test #8 Download a file using ftps://

*/

#pragma semicolon 1
#include <sourcemod>
#include <regex>
#include <cURL>

public Plugin:myinfo = 
{
	name = "cURL self test",
	author = "Raydan",
	description = "cURL self test",
	version = "1.1.0.0",
	url = "http://www.ZombieX2.net/"
};


#define USE_THREAD				1
#define TEST_FOLDER				"data/curl_test"

#define TOTAL_TEST_CASE			8

#define TEST_3_CERT_URL			"http://curl.haxx.se/ca/cacert.pem"
#define TEST_3_CERT_FILE		"ca-bundle.crt"

#define TEST_4_VERIFY_SITE		"https://encrypted.google.com/search?q=sourcemod"

#define TEST_6_UPLOAD_FILE		"test_6_for_upload.png"
#define TEST_6_IMAGE_URL		"http://www.google.com/images/logos/ps_logo2.png"

#define TEST_6_UPLOAD_URL		"http://www.image-upload.net/upload.php"
#define TEST_7_OUT_FILE			"test_7_output.html"
#define TEST_7_REGEX			" ?<a href=\"http://www.image-upload.net/viewer.php\\?file=([a-zA-Z0-9.]+)\">"
#define TEST_7_TARGET_URL		"http://www.image-upload.net/images"

/* http://www.secureftp-test.com/ */
#define TEST_8_FTPS_USERPW		"test:test"
#define TEST_8_FTPS_URL			"ftps://ftp.secureftp-test.com:990/bookstore.xml"
#define TEST_8_FILE				"test_8_bookstore.xml"



new CURL_Default_opt[][2] = {
#if USE_THREAD
	{_:CURLOPT_NOSIGNAL,1},
#endif
	{_:CURLOPT_NOPROGRESS,1},
	{_:CURLOPT_TIMEOUT,30},
	{_:CURLOPT_CONNECTTIMEOUT,60},
	{_:CURLOPT_VERBOSE,0}
};

#define CURL_DEFAULT_OPT(%1) curl_easy_setopt_int_array(%1, CURL_Default_opt, sizeof(CURL_Default_opt))

#define TESTCASE_CLOSEHANDLE(%1) if(%1 != INVALID_HANDLE) { CloseHandle(%1); %1 = INVALID_HANDLE; }

new bool:g_test_running = false;
new g_testcase_runned;


new String:curl_test_path[512];



/* static data */
static String:test_md5[][] = {
	"",
	"a",
	"abc",
	"message digest",
	"abcdefghijklmnopqrstuvwxyz",
	"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789",
	"12345678901234567890123456789012345678901234567890123456789012345678901234567890"
};

static String:ret_md5[][] = {
	"d41d8cd98f00b204e9800998ecf8427e",
	"0cc175b9c0f1b6a831c399e269772661",
	"900150983cd24fb0d6963f7d28e17f72",
	"f96b697d7cb7938d525a2f31aaf161d0",
	"c3fcd3d76192e4007dfb496cca67e13b",
	"d174ab98d277d9f5a5611c2c9f419d9f",
	"57edf4a22be3c955ac49da2e2107b67a"
};
	
static String:test_md4[][] = {
	"",
	"a",
	"abc",
	"message digest",
	"abcdefghijklmnopqrstuvwxyz",
	"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789",
	"12345678901234567890123456789012345678901234567890123456789012345678901234567890"
};

static String:ret_md4[][] = {
	"31d6cfe0d16ae931b73c59d7e0c089c0",
	"bde52cb31de33e46245e05fbdbd6fb24",
	"a448017aaf21d8525fc10ae87aa6729d",
	"d9130a8164549fe818874806e1c7014b",
	"d79e1c308aa5bbcdeea8ed63df412da9",
	"043f8582f241db351ce627e153e7f0e4",
	"e33b4ddc9c38f2199c3e7b164fcc0536"
};

static String:test_md2[][] = {
	"",
	"a",
	"abc",
	"message digest",
	"abcdefghijklmnopqrstuvwxyz",
	"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789",
	"12345678901234567890123456789012345678901234567890123456789012345678901234567890"
};

static String:ret_md2[][] = {
	"8350e5a3e24c153df2275c9f80692773",
	"32ec01ec4a6dac72c0ab96fb34c0b5d1",
	"da853b0d3f88d99b30283a69e6ded6bb",
	"ab4f496bfb2a530b219ff33031fe06b0",
	"4e8ddff3650292ab5a4108c3aa47940b",
	"da33def2a42df13975352846c30338cd",
	"d5976f79d83d3a0dc9806c3c66f3efd8"
};

static String:test_sha[][] = {
	"abc",
	"abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq"
};

static String:ret_sha[][] = {
	"0164b8a914cd2a5e74c4f7ff082c4d97f1edf880",
	"d2516ee1acfa5baf33dfc1c471e438449ef134c8"
};

static String:test_sha1[][] = {
	"abc",
	"abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq"
};

static String:ret_sha1[][] = {
	"a9993e364706816aba3e25717850c26c9cd0d89d",
	"84983e441c3bd26ebaae4aa1f95129e5e54670f1"
};


static String:test_sha224_to_512[][] = {
	"",
	"a",
	"abc",
	"message digest",
	"abcdefghijklmnopqrstuvwxyz",
	"abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq",
	"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789",
	"12345678901234567890123456789012345678901234567890123456789012345678901234567890"
};

static String:ret_sha224[][] = {
	"d14a028c2a3a2bc9476102bb288234c415a2b01f828ea62ac5b3e42f",
	"abd37534c7d9a2efb9465de931cd7055ffdb8879563ae98078d6d6d5",
	"23097d223405d8228642a477bda255b32aadbce4bda0b3f7e36c9da7",
	"2cb21c83ae2f004de7e81c3c7019cbcb65b71ab656b22d6d0c39b8eb",
	"45a5f72c39c5cff2522eb3429799e49e5f44b356ef926bcf390dccc2",
	"75388b16512776cc5dba5da1fd890150b0c6455cb4f58b1952522525",
	"bff72b4fcb7d75e5632900ac5f90d219e05e97a7bde72e740db393d9",
	"b50aecbe4e9bb0b57bc5f3ae760a8e01db24f203fb3cdcd13148046e"
};

static String:ret_sha256[][] = {
	"e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
	"ca978112ca1bbdcafac231b39a23dc4da786eff8147c4e72b9807785afee48bb",
	"ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad",
	"f7846f55cf23e14eebeab5b4e1550cad5b509e3348fbc4efa3a1413d393cb650",
	"71c480df93d6ae2f1efad1447c66c9525e316218cf51fc8d9ed832f2daf18b73",
	"248d6a61d20638b8e5c026930c3e6039a33ce45964ff2167f6ecedd419db06c1",
	"db4bfcbd4da0cd85a60c3c37d3fbd8805c77f15fc6b1fdfe614ee0a7c8fdb4c0",
	"f371bc4a311f2b009eef952dd83ca80e2b60026c8e935592d0f9c308453c813e"
};

static String:ret_sha384[][] = {
	"38b060a751ac96384cd9327eb1b1e36a21fdb71114be07434c0cc7bf63f6e1da274edebfe76f65fbd51ad2f14898b95b",
	"54a59b9f22b0b80880d8427e548b7c23abd873486e1f035dce9cd697e85175033caa88e6d57bc35efae0b5afd3145f31",
	"cb00753f45a35e8bb5a03d699ac65007272c32ab0eded1631a8b605a43ff5bed8086072ba1e7cc2358baeca134c825a7",
	"473ed35167ec1f5d8e550368a3db39be54639f828868e9454c239fc8b52e3c61dbd0d8b4de1390c256dcbb5d5fd99cd5",
	"feb67349df3db6f5924815d6c3dc133f091809213731fe5c7b5f4999e463479ff2877f5f2936fa63bb43784b12f3ebb4",
	"3391fdddfc8dc7393707a65b1b4709397cf8b1d162af05abfe8f450de5f36bc6b0455a8520bc4e6f5fe95b1fe3c8452b",
	"1761336e3f7cbfe51deb137f026f89e01a448e3b1fafa64039c1464ee8732f11a5341a6f41e0c202294736ed64db1a84",
	"b12932b0627d1c060942f5447764155655bd4da0c9afa6dd9b9ef53129af1b8fb0195996d2de9ca0df9d821ffee67026"
};

static String:ret_sha512[][] = {
	"cf83e1357eefb8bdf1542850d66d8007d620e4050b5715dc83f4a921d36ce9ce47d0d13c5d85f2b0ff8318d2877eec2f63b931bd47417a81a538327af927da3e",
	"1f40fc92da241694750979ee6cf582f2d5d7d28e18335de05abc54d0560e0f5302860c652bf08d560252aa5e74210546f369fbbbce8c12cfc7957b2652fe9a75",
	"ddaf35a193617abacc417349ae20413112e6fa4e89a97ea20a9eeee64b55d39a2192992a274fc1a836ba3c23a3feebbd454d4423643ce80e2a9ac94fa54ca49f",
	"107dbf389d9e9f71a3a95f6c055b9251bc5268c2be16d6c13492ea45b0199f3309e16455ab1e96118e8a905d5597b72038ddb372a89826046de66687bb420e7c",
	"4dbff86cc2ca1bae1e16468a05cb9881c97f1753bce3619034898faa1aabe429955a1bf8ec483d7421fe3c1646613a59ed5441fb0f321389f77f48a879c7b1f1",
	"204a8fc6dda82f0a0ced7beb8e08a41657c16ef468b228a8279be331a703c33596fd15c13b1b07f9aa1d3bea57789ca031ad85c7a71dd70354ec631238ca3445",
	"1e07be23c26a86ea37ea810c8ec7809352515a970e9253c26f536cfc7a9996c45c8370583e0a78fa4a90041d71a4ceab7423f19c71b9d5a3e01249f0bebd5894",
	"72ec1ef1124a45b047e8b7c75a932195135bb61de24ec0d1914042246e0aec3a2354e093d76f3048b456764346900cb130d2a4fd5dd16abb5e30bcb850dee843"
};

static String:test_ripemd160[][] = {
	"",
	"a",
	"abc",
	"message digest",
	"abcdefghijklmnopqrstuvwxyz",
	"abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq",
	"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789",
	"12345678901234567890123456789012345678901234567890123456789012345678901234567890"
};

static String:ret_ripemd160[][] = {
	"9c1185a5c5e9fc54612808977ee8f548b2258d31",
	"0bdc9d2d256b3ee9daae347be6f4dc835a467ffe",
	"8eb208f7e05d987a9b044a8e98c6b087f15a0bfc",
	"5d0689ef49d2fae572b881b123a85ffa21595f36",
	"f71c27109c692c1b56bbdceb5b9d2865b3708dbc",
	"12a053384a9c0c88e405a06c27dcf49ada62eb2b",
	"b0e20b6e3116640286ed3a87a5713079b21f5189",
	"9b752e45573d4b39f4dbd3323cab82bf63326bfb"
};



new Handle:test_3_file = INVALID_HANDLE;

new Handle:test_5_file_body = INVALID_HANDLE;
new Handle:test_5_file_header = INVALID_HANDLE;

new Handle:test_6_file = INVALID_HANDLE;

new Handle:test_7_form = INVALID_HANDLE;
new Handle:test_7_file = INVALID_HANDLE;

new Handle:test_8_file = INVALID_HANDLE;


/* Plugin Start */

public OnPluginStart()
{
	PluginInit();
	
	RegConsoleCmd("curl_self_test", curl_self_test);
	RegConsoleCmd("curl_hash_test", curl_hash_test);
	g_test_running = false;
}

public PluginInit()
{
	g_testcase_runned = 0;
	BuildPath(Path_SM, curl_test_path, sizeof(curl_test_path), TEST_FOLDER);
	new Handle:test_folder_handle = OpenDirectory(curl_test_path);
	if(test_folder_handle == INVALID_HANDLE)
	{
		if(!CreateDirectory(curl_test_path, 557))
		{
			SetFailState("Unable Create folder %s",TEST_FOLDER);
			return;
		}
	} else {
		new String:buffer[128];
		new String:path[512];
		new FileType:type;
		while(ReadDirEntry(test_folder_handle, buffer, sizeof(buffer), type))
		{
			if(type != FileType_File)
				continue;
			
			BuildPath(Path_SM, path, sizeof(path), "%s/%s", TEST_FOLDER, buffer);
			DeleteFile(path);
		}
		CloseHandle(test_folder_handle);
	}
}


/* Test Case */
public Test_1()
{
	new current_test = 1;
	new String:version[256];
	new String:protocols[256];
	curl_version(version,sizeof(version));
	curl_protocols(protocols, sizeof(protocols));
	PrintTestCaseDebug(current_test,"Get cUrl Version");
	PrintTestCaseDebug(current_test, "Version: %s",version);
	PrintTestCaseDebug(current_test, "Protocols: %s",protocols);
	
	onComplete(INVALID_HANDLE, CURLE_OK, current_test);
}

public Test_2()
{
	new current_test = 2;
	PrintTestCaseDebug(current_test,"simple get a remote web page");
	new Handle:curl = curl_easy_init();
	if(curl != INVALID_HANDLE)
	{
		CURL_DEFAULT_OPT(curl);
		curl_easy_setopt_string(curl, CURLOPT_URL, "http://www.google.com");
		ExecCURL(curl,current_test);
	} else {
		PrintCreatecUrlError(current_test);
	}
}

public Test_3()
{
	new current_test = 3;
	PrintTestCaseDebug(current_test,"download %s for test #4",TEST_3_CERT_URL);
	new Handle:curl = curl_easy_init();
	if(curl != INVALID_HANDLE)
	{
		test_3_file = CreateTestFile(TEST_3_CERT_FILE, "w");
		CURL_DEFAULT_OPT(curl);
		curl_easy_setopt_handle(curl, CURLOPT_WRITEDATA, test_3_file);
		curl_easy_setopt_string(curl, CURLOPT_URL, TEST_3_CERT_URL);
		ExecCURL(curl,current_test);
	} else {
		PrintCreatecUrlError(current_test);
	}
}
public Test_4()
{
	new current_test = 4;
	PrintTestCaseDebug(current_test,"using #3 cert file to verify %s", TEST_4_VERIFY_SITE);
	new Handle:curl = curl_easy_init();
	if(curl != INVALID_HANDLE)
	{
		new String:path[512];
		BuildPath(Path_SM, path, sizeof(path), "%s/%s", TEST_FOLDER, TEST_3_CERT_FILE);
		CURL_DEFAULT_OPT(curl);
		curl_easy_setopt_string(curl,CURLOPT_CAINFO, path);
		curl_easy_setopt_int(curl, CURLOPT_SSL_VERIFYPEER, 1);
		curl_easy_setopt_int(curl, CURLOPT_SSL_VERIFYHOST, 2);
		curl_easy_setopt_string(curl, CURLOPT_URL, TEST_4_VERIFY_SITE);
		ExecCURL(curl, current_test);
	} else {
		PrintCreatecUrlError(current_test);
	}
}

public Test_5()
{
	new current_test = 5;
	PrintTestCaseDebug(current_test,"download a web page & header");
	new Handle:curl = curl_easy_init();
	if(curl != INVALID_HANDLE)
	{
		CURL_DEFAULT_OPT(curl);
		test_5_file_body = CreateTestFile("test5_body.txt", "w");
		test_5_file_header = CreateTestFile("test5_header.txt", "w");
		curl_easy_setopt_handle(curl, CURLOPT_WRITEDATA, test_5_file_body);
		curl_easy_setopt_handle(curl, CURLOPT_HEADERDATA, test_5_file_header);
		curl_easy_setopt_string(curl, CURLOPT_URL, "http://www.google.co.uk/index.html");
		ExecCURL(curl,current_test);
	} else {
		PrintCreatecUrlError(current_test);
	}
}

public Test_6()
{
	new current_test = 6;
	PrintTestCaseDebug(current_test,"download google logo for test #7");
	new Handle:curl = curl_easy_init();
	if(curl != INVALID_HANDLE)
	{
		CURL_DEFAULT_OPT(curl);
		test_6_file = CreateTestFile(TEST_6_UPLOAD_FILE, "wb");
		curl_easy_setopt_handle(curl, CURLOPT_WRITEDATA, test_6_file);
		curl_easy_setopt_string(curl, CURLOPT_URL, TEST_6_IMAGE_URL);
		ExecCURL(curl, current_test);
	} else {
		PrintCreatecUrlError(current_test);
	}
}


public Test_7()
{
	new current_test = 7;
	PrintTestCaseDebug(current_test,"upload test #6 image to image-upload.net");
	new Handle:curl = curl_easy_init();
	if(curl != INVALID_HANDLE)
	{
		CURL_DEFAULT_OPT(curl);
		new String:path[512];
		BuildPath(Path_SM, path, sizeof(path), "%s/%s", TEST_FOLDER, TEST_6_UPLOAD_FILE);
		test_7_form = curl_httppost();
		curl_formadd(test_7_form, CURLFORM_COPYNAME, "userfile[]", CURLFORM_FILE, path, CURLFORM_END);
		curl_formadd(test_7_form, CURLFORM_COPYNAME, "private_upload", CURLFORM_COPYCONTENTS, "0", CURLFORM_END);
		curl_easy_setopt_handle(curl, CURLOPT_HTTPPOST, test_7_form);
		
		test_7_file = CreateTestFile(TEST_7_OUT_FILE, "w");
		curl_easy_setopt_handle(curl, CURLOPT_WRITEDATA, test_7_file);
		curl_easy_setopt_string(curl, CURLOPT_URL, TEST_6_UPLOAD_URL);

		ExecCURL(curl, current_test);
	} else {
		PrintCreatecUrlError(current_test);
	}
}


public Test_8()
{
	new current_test = 8;
	PrintTestCaseDebug(current_test,"sftp test - %s",TEST_8_FTPS_URL);
	new Handle:curl = curl_easy_init();
	if(curl != INVALID_HANDLE)
	{
		CURL_DEFAULT_OPT(curl);
		test_8_file = CreateTestFile(TEST_8_FILE, "w");
		curl_easy_setopt_handle(curl, CURLOPT_WRITEDATA, test_8_file);
		curl_easy_setopt_int(curl, CURLOPT_SSL_VERIFYPEER, 0);
		curl_easy_setopt_int(curl, CURLOPT_SSL_VERIFYHOST, 2);
		curl_easy_setopt_string(curl, CURLOPT_USERPWD, TEST_8_FTPS_USERPW);
		curl_easy_setopt_string(curl, CURLOPT_URL, TEST_8_FTPS_URL);
		ExecCURL(curl, current_test);
	} else {
		PrintCreatecUrlError(current_test);
	}
}

public onComplete(Handle:hndl, CURLcode: code, any:data)
{
	new current_test = data;
	if(hndl != INVALID_HANDLE && code != CURLE_OK)
	{
		new String:error_buffer[256];
		curl_easy_strerror(code, error_buffer, sizeof(error_buffer));
		PrintTestCaseDebug(current_test, "FAIL - %s", error_buffer);
		CloseHandle(hndl);
		g_test_running = false;
		return;
	}
	
	PrintTestCaseDebug(current_test, "*Passed*");
	
	TestCaseEndPreClose(current_test);
	
	TESTCASE_CLOSEHANDLE(hndl)

	TestCaseEndPostClose(current_test);
	
	g_testcase_runned++;
	
	if(g_testcase_runned == TOTAL_TEST_CASE)
	{
		PrintTestMessage("YA! Passed All Test~");
		g_test_running = false;
	}
	
	#if !USE_THREAD
	switch(g_testcase_runned)
	{
		case 1: Test_2();
		case 2: Test_3();
			//case 4: Test_4();
		case 4: Test_5();
		case 5: Test_6();
			//case 7: Test_7();
		case 7: Test_8();
	}
	#endif
}

public Action:curl_self_test(client, args)
{
	if(g_test_running)
	{
		PrintTestMessage("cURL Test is running, Please wait...");
		return Plugin_Handled;
	}
	
	g_test_running = true;
	g_testcase_runned = 0;
	
#if USE_THREAD
	Test_1();
	Test_2();
	Test_3();
		//Test_4();
	Test_5();
	Test_6();
		//Test_7();
	Test_8();
#else
	Test_1();
#endif
	
	return Plugin_Handled;
}

stock ExecCURL(Handle:curl, current_test)
{
#if USE_THREAD
	curl_easy_perform_thread(curl, onComplete, current_test);
#else
	new CURLcode:code = curl_load_opt(curl);
	if(code != CURLE_OK) {
		PrintTestCaseDebug(current_test, "curl_load_opt Error");
		PrintcUrlError(code);
		CloseHandle(curl);
		return;
	}
	
	code = curl_easy_perform(curl);
	
	onComplete(curl, code, current_test);

#endif
}

public TestCaseEndPreClose(current_test)
{

}

public TestCaseEndPostClose(current_test)
{
	switch(current_test)
	{
		case 3:
		{
			TESTCASE_CLOSEHANDLE(test_3_file)
			Test_4();
		}
		case 5:
		{
			TESTCASE_CLOSEHANDLE(test_5_file_body)
			TESTCASE_CLOSEHANDLE(test_5_file_header)
		}
		case 6:
		{
			TESTCASE_CLOSEHANDLE(test_6_file)
			Test_7();
		}
		case 7:
		{
			TESTCASE_CLOSEHANDLE(test_7_form)
			TESTCASE_CLOSEHANDLE(test_7_file)
			Test_7_Action();
		}
		case 8:
		{
			TESTCASE_CLOSEHANDLE(test_8_file)
		}
	}
}

public Test_7_Action()
{
	new Handle:regex = CompileRegex(TEST_7_REGEX);
	if(regex == INVALID_HANDLE)
	{
		PrintTestCaseDebug(7, "WARNING - unable create regex");
		return;
	}
	new String:file_path[512];
	Format(file_path, sizeof(file_path),"%s/%s",curl_test_path, TEST_7_OUT_FILE);
	new Handle:file = OpenFile(file_path,"r");
	if(file == INVALID_HANDLE)
	{
		CloseHandle(regex);
		PrintTestCaseDebug(7, "WARNING - %s not found",TEST_7_OUT_FILE);
		return;
	}
	
	new bool:found = false;
	new String:buffer[1024];
	while(ReadFileLine(file, buffer, sizeof(buffer)))
	{
		new RegexError:ret;
		new pos = MatchRegex(regex, buffer, ret);
		if(ret == REGEX_ERROR_NONE && pos == 2)
		{
			new String:the_image[64];
			GetRegexSubString(regex, 1, the_image, sizeof(the_image));
			PrintTestCaseDebug(7, "Uploaded image - %s/%s", TEST_7_TARGET_URL,the_image);
			found = true;
			break;
		}
	}
	
	if(!found)
	{
		PrintTestCaseDebug(7, "WARNING - upload may be fail...");
	}
	
	CloseHandle(regex);
	CloseHandle(file);
}


public Action:curl_hash_test(client, args)
{
	for(new i=0;i<sizeof(test_md5);i++)
	{
		if(!CheckHash(test_md5[i],Openssl_Hash_MD5,ret_md5[i]))
			return Plugin_Handled;
		PrintHashTestDebug("md5 #%d Pass",i+1);
	}
	
	for(new i=0;i<sizeof(test_md4);i++)
	{
		if(!CheckHash(test_md4[i],Openssl_Hash_MD4,ret_md4[i]))
			return Plugin_Handled;
		PrintHashTestDebug("md4 #%d Pass",i+1);
	}
	
	for(new i=0;i<sizeof(test_md2);i++)
	{
		if(!CheckHash(test_md2[i],Openssl_Hash_MD2,ret_md2[i]))
			return Plugin_Handled;
		PrintHashTestDebug("md2 #%d Pass",i+1);
	}
	
	for(new i=0;i<sizeof(test_sha);i++)
	{
		if(!CheckHash(test_sha[i],Openssl_Hash_SHA,ret_sha[i]))
			return Plugin_Handled;
		PrintHashTestDebug("sha #%d Pass",i+1);
	}
	
	for(new i=0;i<sizeof(test_sha1);i++)
	{
		if(!CheckHash(test_sha1[i],Openssl_Hash_SHA1,ret_sha1[i]))
			return Plugin_Handled;
		PrintHashTestDebug("sha1 #%d Pass",i+1);
	}
	
	for(new i=0;i<sizeof(test_sha224_to_512);i++)
	{
		if(!CheckHash(test_sha224_to_512[i],Openssl_Hash_SHA224,ret_sha224[i]))
			return Plugin_Handled;
		PrintHashTestDebug("sha224 #%d Pass",i+1);
	}
	
	for(new i=0;i<sizeof(test_sha224_to_512);i++)
	{
		if(!CheckHash(test_sha224_to_512[i],Openssl_Hash_SHA256,ret_sha256[i]))
			return Plugin_Handled;
		PrintHashTestDebug("sha256 #%d Pass",i+1);
	}
	
	for(new i=0;i<sizeof(test_sha224_to_512);i++)
	{
		if(!CheckHash(test_sha224_to_512[i],Openssl_Hash_SHA384,ret_sha384[i]))
			return Plugin_Handled;
		PrintHashTestDebug("sha384 #%d Pass",i+1);
	}
	
	for(new i=0;i<sizeof(test_sha224_to_512);i++)
	{
		if(!CheckHash(test_sha224_to_512[i],Openssl_Hash_SHA512,ret_sha512[i]))
			return Plugin_Handled;
		PrintHashTestDebug("sha512 #%d Pass",i+1);
	}
	
	for(new i=0;i<sizeof(test_ripemd160);i++)
	{
		if(!CheckHash(test_ripemd160[i],Openssl_Hash_RIPEMD160,ret_ripemd160[i]))
			return Plugin_Handled;
		PrintHashTestDebug("ripemd160 #%d Pass",i+1);
	}
	
	PrintHashTestDebug("Try hash bin/server.dll");
	curl_hash_file("bin/server.dll",Openssl_Hash_MD5, hash_complete_callback);
	
	return Plugin_Handled;
}

public hash_complete_callback(const bool:success, const String:buffer[])
{
	if(!success)
	{
		PrintHashTestDebug("Hash Fail: ubale hash server.dll");
		return;
	}
	PrintHashTestDebug("server.dll MD5: %s",buffer);
	PrintHashTestDebug("All Hash Test Pass!!");
}

public bool:CheckHash(const String:data[], Openssl_Hash:type, const String:ret[])
{
	static String:hash_type[][16] = {
		"md5",
		"md4",
		"md2",
		"sha",
		"sha1",
		"sha224",
		"sha256",
		"sha384",
		"sha512",
		"ripemd160"
	};
	new String:buffer[256];
	curl_hash_string(data,strlen(data), type, buffer, sizeof(buffer));
	
	if(strcmp(buffer, ret, false) != 0)
	{
		PrintHashTestDebug("Hash FAIL: %s : %s",hash_type[type], data);
		return false;
	}
	return true;
}


public Handle:CreateTestFile(const String:path[], const String:mode[])
{
	new String:file_path[512];
	Format(file_path, sizeof(file_path),"%s/%s",curl_test_path, path);
	return curl_OpenFile(file_path, mode);
}

stock PrintCreatecUrlError(index)
{
	PrintToServer("[CURL Test #%d] curl_easy_init Fail",index);
	g_test_running = false;
}

stock PrintTestCaseDebug(index, const String:format[], any:...)
{
	decl String:buffer[256];
	VFormat(buffer, sizeof(buffer), format, 3);
	PrintToServer("[CURL Test #%d] %s",index, buffer);
}

stock PrintTestMessage(const String:format[], any:...)
{
	decl String:buffer[256];
	VFormat(buffer, sizeof(buffer), format, 2);
	PrintToServer("[CURL Test] %s", buffer);
}

stock PrintcUrlError(CURLcode: code)
{
	new String:buffer[512];
	curl_easy_strerror(code, buffer, sizeof(buffer));
	PrintToServer("[CURL Test ERROR] %s",buffer);
}


stock PrintHashTestDebug(const String:format[], any:...)
{
	decl String:buffer[256];
	VFormat(buffer, sizeof(buffer), format, 2);
	PrintToServer("[CURL Hash Test] %s", buffer);
}
