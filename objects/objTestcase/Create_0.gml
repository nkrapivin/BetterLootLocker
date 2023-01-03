/// @description make an http thingy


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
// ^^ change these parameters ^^ //
bll.setSessionId(sessionId);
bll.setGameVersion(GM_version); // good enough for test purposes

dialogIds = [];
askForString = function(titleString, defaultString, onFunction) {
	var dialogId_ = get_string_async(titleString, defaultString);
	if (dialogId_ < 0) {
		onFunction("");
		exit;
	}
	
	array_push(dialogIds, { requestId: dialogId_, callbackFunction: onFunction });
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
	findButton("signin").text = signedIn ? ("Signed in: " + playerName) : "Sign in";	
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
			file_delete("cache.dat");
			signedIn = false;
			show_message_async("Sign in failed, please sign in again");
		})
		.andFinally(function(e) {
			show_debug_message(json_stringify(e));
		});
	}	
};

// prepare GUI controls
attachToButton("signin", function(btn) {
	if (signedIn) {
		exit;
	}
	
	askForString("email?", "test@example.com", function(email_) {
		if (email_ == "") {
			exit;
		}
		
		playerEmail = email_;
		askForString("password?", "12345", method({that: other}, function(password_) {
			if (password_ == "") {
				exit;
			}
			
			that.bll
			.whitelabelSignIn(that.playerEmail, password_, true)
			.andThen(function(e) {
				that.playerEmail = e.resultAsJson.email;
				that.bll
				.loginAsWhitelabel(that.playerEmail, e.resultAsJson.session_token)
				.andThen(function(e) {
					that.sessToken = e.resultAsJson.session_token;
					that.bll
					.playerGetName()
					.andThen(function(e) {
						that.playerName = e.resultAsJson.name;
						signedIn = true;
						onLoginOkay();
					})
					.andCatch(function(e) {
						show_message_async("Sign in stage 3 failed:\n" + e.result);
					})
					.andFinally(function(e) {
						show_debug_message(e);
					});
				})
				.andCatch(function(e) {
					show_message_async("Sign in stage 2 failed:\n" + e.result);
				})
				.andFinally(function(e) {
					show_debug_message(e);
				});
			})
			.andCatch(function(e) {
				show_message_async("Sign in failed:\n" + e.result);
			})
			.andFinally(function(e) {
				show_debug_message(e);
			});
		}));
	});
});

attachToButton("signin_guest", function(btn) {
	if (signedIn) {
		exit;
	}
	
	askForString("player id?", "someplayerid1337", function(pid_) {
		if (pid_ == "") {
			exit;	
		}
		
		bll
		.loginAsGuest(pid_)
		.andThen(function(e) {
			sessToken = e.resultAsJson.session_token;
			bll
			.setSessionToken(sessToken)
			.playerGetName()
			.andThen(function(e) {
				playerName = e.resultAsJson.name;
				signedIn = true;
				show_message_async("Guest Sign in okay, but please use whitelabel instead.");
				onLoginOkay();
			})
			.andCatch(function(e) {
				show_message_async("Guest Sign in stage 2 failed:\n" + e.result);
			})
			.andFinally(function(e) {
				show_debug_message(e);
			});
		})
		.andCatch(function(e) {
			show_message_async("Guest Sign in failed:\n" + e.result);
		})
		.andFinally(function(e) {
			show_debug_message(e);
		});
	});
});

attachToButton("register", function(btn) {
	askForString("email?", "test@example.com", function(email_) {
		if (email_ == "") {
			exit;
		}
		
		askForString("password?", "12345", method({email: email_, that: other}, function(password_) {
			if (password_ == "") {
				exit;
			}
			
			that.bll
			.whitelabelSignUp(email, password_)
			.andThen(function(e) {
				show_message_async("Please verify your email first, only then sign in.\nemail: " + e.resultAsJson.email);
			})
			.andCatch(function(e) {
				show_message_async("There was an error when signing up:\n" + e.result);
			})
			.andFinally(function(e) {
				show_debug_message(e);
			});
		}));
	});
});

attachToButton("playernameset", function(btn) {
	if (!signedIn) {
		exit;
	}
	
	askForNameIfNone(true);
});

attachToButton("signout", function(btn) {
	if (!signedIn) {
		exit;
	}
	
	playerName = "";
	playerEmail = "";
	sessToken = "";
	signedIn = false;
	
	bll
	.endSession(true)
	.andThen(function(e) {
		show_message_async("Signed out and erased cache, please sign in again");	
	})
	.andCatch(function(e) {
		show_message_async("Failed to end your session:\n" + e.result);	
	})
	.andFinally(function(e) {
		show_debug_message(e);
	})
	.andBack()
	.setSessionToken(undefined);
	
	sessionId = makeRandomSessionId();
	
	file_delete("llcache.dat");
	updateBtns();
});

// attempt to sign in silently
attemptSilentSignin();



