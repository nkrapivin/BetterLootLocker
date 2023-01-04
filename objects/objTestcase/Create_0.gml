/// @description make an http thingy

if (instance_number(object_index) > 1) {
	instance_destroy();
	exit;
}

makeRandomSessionId = function() {
	var alphabet = "0123456789abcdef";
	var sessid = "";
	randomize();
	repeat (32) {
		// GameMaker strings are 1-indexed
		// yes I know this isn't quite up to spec, no I don't care.
		sessid += string_char_at(alphabet, irandom_range(1, string_length(alphabet)));
	}
	sessid = string_insert("-", sessid, 9);
	sessid = string_insert("-", sessid, 14);
	sessid = string_insert("-", sessid, 19);
	sessid = string_insert("-", sessid, 24);
	return sessid;
};
sessionId = makeRandomSessionId();

http = instance_create_layer(x, y, layer, objDefaultHttpHandler);
bll = new BetterLootLocker(http.httpHandlerFunction);
// -- change these parameters -- //
bll.setGameKey("dev_c5f06511aac54769ab35cb2fcedbb149");
bll.setIsDevelopment(true);
bll.setDomainKey("xebmpt49");
bll.setSessionId(sessionId);
bll.setGameVersion(GM_version); // good enough for test purposes
// ^^ change these parameters ^^ //

dialogIds = [];
askForString = function(titleString, defaultString, onFunction, selfOpt = undefined) {
	var dialogId_;
	if (is_undefined(titleString) || titleString == "") {
		dialogId_ = show_message_async(defaultString);
	}
	else {
		dialogId_ = get_string_async(titleString, defaultString);
	}
	
	if (dialogId_ < 0) {
		onFunction("");
		exit;
	}
	
	array_push(dialogIds, { requestId: dialogId_, callbackFunction: onFunction, selfCtx: selfOpt });
};

findButton = function(tagString) {
	with (objGuiButton) {
		if (tag != tagString) {
			continue;
		}
		
		return id;
	}
	
	return undefined;
};

attachToButton = function(tagString, onButtonClickFunction) {
	findButton(tagString).onButtonClick = onButtonClickFunction;
};

playerName = "<none>";
playerEmail = "";
sessToken = "";
signedIn = false;

writeToken = function() {
	var tk_ = sessToken;
	var jsoncache_ = json_stringify({token: tk_});
	var buff_ = buffer_create(string_byte_length(jsoncache_), buffer_fixed, 1);
	buffer_write(buff_, buffer_text, jsoncache_);
	buffer_save(buff_, "llcache.dat");
	buffer_delete(buff_);	
};

updateBtns = function() {
	if (room == rmBLLTestcase) {
		findButton("signin").text = signedIn ? ("Signed in: " + playerName) : "Sign in";
	}
	else if (room == rmBLLTestcaseUGC) {
		
	}
};

askForNameIfNone = function(overrideBoolOpt = false) {
	if (playerName == "" || overrideBoolOpt) {
		askForString("Please set a player name:", "MyCoolName", function(name_) {
			if (name_ == "") {
				exit;
			}
			
			bll
			.playerSetName(name_)
			.andThen(function(e) {
				playerName = e.resultAsJson.name;
				updateBtns();
			})
			.andCatch(function(e) {
				show_debug_message("Unable to change your name:\n" + e.result);
			})
			.andFinally(function(e) {
				show_debug_message(e);
			});
		});
	}	
};

onLoginOkay = function() {
	updateBtns();
	writeToken();
	askForNameIfNone();
};

attemptSilentSignin = function() {
	if (file_exists("llcache.dat")) {
		var buff_ = buffer_load("llcache.dat");
		if (buff_ < 0) {
			exit;
		}
	
		var jstruct_ = json_parse(buffer_read(buff_, buffer_string));
		buffer_delete(buff_);
		
		sessToken = jstruct_.token;
		bll
		.setSessionToken(sessToken)
		.playerGetName()
		.andThen(function(e) {
			// signed in!
			playerName = e.resultAsJson.name;
			signedIn = true;
			onLoginOkay();
		})
		.andCatch(function(e) {
			// uh oh
			//file_delete("cache.dat");
			signedIn = false;
			show_message_async("Silent sign in failed, please sign in again");
		})
		.andFinally(function(e) {
			show_debug_message(json_stringify(e));
		});
	}	
};



// attempt to sign in silently
attemptSilentSignin();



