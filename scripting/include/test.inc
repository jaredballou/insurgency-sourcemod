stock bool:Test_SetFilename(Handle:hTest, const String:value[]) {
	return SetTrieString(hTest, "filename", value);
}

stock bool:Test_GetFilename(Handle:hTest, String:value[], max_size) {
	return GetTrieString(hTest, "filename", value, max_size);
}

stock bool:Test_SetFails(Handle:hTest, value) {
	return SetTrieValue(hTest, "fails", value);
}

stock bool:Test_GetFails(Handle:hTest, &value) {
	return GetTrieValue(hTest, "fails", value);
}

stock bool:Test_SetTests(Handle:hTest, value) {
	return SetTrieValue(hTest, "tests", value);
}

stock bool:Test_GetTests(Handle:hTest, &value) {
	return GetTrieValue(hTest, "tests", value);
}

stock bool:Test_SetFile(Handle:hTest, Handle:value) {
	return SetTrieValue(hTest, "file", value);
}

stock bool:Test_GetFile(Handle:hTest, &Handle:value) {
	return GetTrieValue(hTest, "file", value);
}

stock bool:Test_SetProcessed(Handle:hTest, value) {
	return SetTrieValue(hTest, "processed", value);
}

stock bool:Test_GetProcessed(Handle:hTest, &value) {
	return GetTrieValue(hTest, "processed", value);
}

stock Test_Inherit(Handle:hObj, count) {
	new tests;
	Test_GetTests(hObj, tests);
	new Handle:file;
	Test_GetFile(hObj, file);

	tests = count;
	file = INVALID_HANDLE;

	Test_SetTests(hObj, tests);
	Test_SetFile(hObj, file);

}

stock Handle:Test_New(count) {
	new Handle:hObj = CreateTrie();
	Test_Inherit(hObj, count);
	return hObj;
}

stock Test_Deherit(Handle:hObj) {

}

stock Test_Destroy(Handle:hObj) {
	Test_Deherit(hObj);

	CloseHandle(hObj);
}

stock Test_Pass(Handle:hTest, const String:sTest[]) {
	new processed;
	Test_GetProcessed(hTest, processed);

	Test_LogThis(hTest, "ok %i - %s", processed, sTest);
	processed++;


	Test_SetProcessed(hTest, processed);

}

stock Test_Fail(Handle:hTest, const String:sTest[]) {
	new fails;
	Test_GetFails(hTest, fails);
	new processed;
	Test_GetProcessed(hTest, processed);

	Test_LogThis(hTest, "not ok %i - %s", processed, sTest);
	Test_LogThis(hTest, "#   Failed test '%s'", sTest);
	fails++;
	processed++;

	Test_SetFails(hTest, fails);
	Test_SetProcessed(hTest, processed);

}

stock Test_Is_String(Handle:hTest, const String:got[], const String:expected[], const String:sTest[]) {
	new fails;
	Test_GetFails(hTest, fails);
	new processed;
	Test_GetProcessed(hTest, processed);

	if(StrEqual(got, expected)) {
		Test_LogThis(hTest, "ok %i - %s", processed, sTest);
	} else {
		Test_LogThis(hTest, "not ok %i - %s", processed, sTest);
		Test_LogThis(hTest, "#   Failed test '%s'", sTest);
		Test_LogThis(hTest, "#          got: '%s'", got);
		Test_LogThis(hTest, "#     expected: '%s'", expected);
		fails++;
	}

	processed++;

	Test_SetFails(hTest, fails);
	Test_SetProcessed(hTest, processed);

}

stock Test_Is(Handle:hTest, any:got, any:expected, const String:sTest[]) {
	new fails;
	Test_GetFails(hTest, fails);
	new processed;
	Test_GetProcessed(hTest, processed);

	if(got == expected) {
		Test_LogThis(hTest, "ok %i - %s", processed, sTest);
	} else {
		Test_LogThis(hTest, "not ok %i - %s", processed, sTest);
		Test_LogThis(hTest, "#   Failed test '%s'", sTest);
		Test_LogThis(hTest, "#          got: '%i'", got);
		Test_LogThis(hTest, "#     expected: '%i'", expected);
		fails++;
	}

	processed++;

	Test_SetFails(hTest, fails);
	Test_SetProcessed(hTest, processed);
}

stock Test_IsNot(Handle:hTest, any:got, any:expected, const String:sTest[]) {
	new fails;
	Test_GetFails(hTest, fails);
	new processed;
	Test_GetProcessed(hTest, processed);

	if(got != expected) {
		Test_LogThis(hTest, "ok %i - %s", processed, sTest);
	} else {
		Test_LogThis(hTest, "not ok %i - %s", processed, sTest);
		Test_LogThis(hTest, "#   Failed test '%s'", sTest);
		Test_LogThis(hTest, "#          got: '%i'", got);
		Test_LogThis(hTest, "#     expected: '%i'", expected);
		fails++;
	}

	processed++;

	Test_SetFails(hTest, fails);
	Test_SetProcessed(hTest, processed);
}

stock Test_End(Handle:hTest) {
	new tests;
	Test_GetTests(hTest, tests);
	new fails;
	Test_GetFails(hTest, fails);
	new processed;
	Test_GetProcessed(hTest, processed);
	new Handle:file;
	Test_GetFile(hTest, file);

	if(tests > processed) {
		Test_LogThis(hTest, "# Looks like you planned to run %i tests, but only ran %i.", tests, processed);
	}

	if(tests < processed) {
		Test_LogThis(hTest, "# Looks like you ran %i more tests than you originally planned.", processed - tests);
	}

	Test_LogThis(hTest, "# You ran %i of %i tests, %i failed, %i passed", processed, tests, fails, processed - fails);
	if(file != INVALID_HANDLE) {
		CloseHandle(file);
	}


}

stock Test_Ok(Handle:hTest, bool:bOk, const String:sTest[]) {
	new fails;
	Test_GetFails(hTest, fails);
	new processed;
	Test_GetProcessed(hTest, processed);

	if(bOk) {
		Test_LogThis(hTest, "ok %i - %s", processed, sTest);
	} else {
		Test_LogThis(hTest, "not ok %i - %s", processed, sTest);
		Test_LogThis(hTest, "#   Failed test '%s'", sTest);
		fails++;
	}
	processed++;

	Test_SetFails(hTest, fails);
	Test_SetProcessed(hTest, processed);
}

stock Test_OkNot(Handle:hTest, bool:bOkNot, const String:sTest[]) {
	new fails;
	Test_GetFails(hTest, fails);
	new processed;
	Test_GetProcessed(hTest, processed);

	if(!bOkNot) {
		Test_LogThis(hTest, "ok %i - %s", processed, sTest);
	} else {
		Test_LogThis(hTest, "not ok %i - %s", processed, sTest);
		Test_LogThis(hTest, "#   Failed test '%s'", sTest);
		fails++;
	}
	processed++;

	Test_SetFails(hTest, fails);
	Test_SetProcessed(hTest, processed);
}

stock Test_Is_Float(Handle:hTest, Float:got, Float:expected, const String:sTest[]) {
	new fails;
	Test_GetFails(hTest, fails);
	new processed;
	Test_GetProcessed(hTest, processed);

	if(got == expected) {
		Test_LogThis(hTest, "ok %i - %s", processed, sTest);
	} else {
		Test_LogThis(hTest, "not ok %i - %s", processed, sTest);
		Test_LogThis(hTest, "#   Failed test '%s'", sTest);
		Test_LogThis(hTest, "#          got: '%f'", got);
		Test_LogThis(hTest, "#     expected: '%f'", expected);
		fails++;
	}

	processed++;


	Test_SetFails(hTest, fails);
	Test_SetProcessed(hTest, processed);

}

stock Test_Like(Handle:hTest, const String:got[], const String:pattern[], const String:sTest[]) {
	new fails;
	Test_GetFails(hTest, fails);
	new processed;
	Test_GetProcessed(hTest, processed);

	new Handle:hRegEx = CompileRegex(pattern);
	if(MatchRegex(hRegEx, got) > 0) {
		Test_LogThis(hTest, "ok %i - %s", processed, sTest);
	} else {
		Test_LogThis(hTest, "not ok %i - %s", processed, sTest);
		Test_LogThis(hTest, "#   Failed test '%s'", sTest);
		Test_LogThis(hTest, "#          got: '%s'", got);
		Test_LogThis(hTest, "#      pattern: '%s'", pattern);
		fails++;
	}

	CloseHandle(hRegEx);

	processed++;

	Test_SetFails(hTest, fails);
	Test_SetProcessed(hTest, processed);

}

stock Test_LogThis(Handle:hTest, const String:format[], any:...) {
	new String:filename[PLATFORM_MAX_PATH];
	Test_GetFilename(hTest, filename, PLATFORM_MAX_PATH);
	new Handle:file;
	Test_GetFile(hTest, file);

	new String:sMessage[255];
	VFormat(sMessage, sizeof(sMessage), format, 3);

	if(StrEqual(filename, "")) {
		PrintToServer(sMessage);
	} else {
		if(file == INVALID_HANDLE) {
			file = OpenFile(filename, "a");
		}

		WriteFileLine(file, sMessage);
	}

	Test_SetFile(hTest, file);

}
