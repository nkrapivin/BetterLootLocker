function BetterLootLockerPromise(ownerOfThisPromiseStruct) constructor {
	fulfillHandlers_ = [];
	rejectHandlers_ = [];
	finallyHandlers_ = [];
	promiseOwner_ = ownerOfThisPromiseStruct;
	
	resolvePromise_ = function(isRejectionBool, argumentStruct) {
		var thens_ = fulfillHandlers_;
		var thenslen_ = array_length(thens_);
		
		var finallies_ = finallyHandlers_;
		var finallylen_ = array_length(finallies_);
		
		var catches_ = rejectHandlers_;
		var catchlen_ = array_length(catches_);
		
		// comment this out if you don't want...
		if (isRejectionBool && catchlen_ <= 0 && finallylen_ <= 0) {
			throw {
				data: argumentStruct,
				message: "A promise has been rejected with no onRejected or onFinally handlers!",
				longMessage: "A promise has been rejected with no onRejected or onFinally handlers!" + "\n\n" + json_stringify(argumentStruct),
				toString: function() { return longMessage; },
				// for compatibility with GameMaker exception structs
				line: -1,
				stacktrace: debug_get_callstack(),
				script: "<a lootlocker promise>"
			};
		}
		
		// perform andThen
		
		try {
			if (!isRejectionBool) {
				for (var i_ = 0; i_ < thenslen_; ++i_) {
					var func_ = thens_[@ i_];
					func_(argumentStruct);
				}
			}
		} catch (exc_) {
			var orig_ = argumentStruct;
			argumentStruct = exc_;
			argumentStruct.isException = true;
			argumentStruct.data = orig_;
			isRejectionBool = true;
		}
		
		array_resize(thens_, 0);
		
		// perform andCatch
		
		try {
			if (isRejectionBool) {
				for (var i_ = 0; i_ < catchlen_; ++i_) {
					var func_ = catches_[@ i_];
					func_(argumentStruct);
				}
			}
		} catch (exc_) {
			// idk what to do when andCatch throws honestly O_O
			// maybe let's call andFinally...
		}
		
		array_resize(catches_, 0);
		
		// perform andFinally
		
		for (var i_ = 0; i_ < finallylen_; ++i_) {
			var func_ = finallies_[@ i_];
			func_(argumentStruct);
		}
		
		array_resize(finallies_, 0);
		
		return self;
	};
	
	andThen = function(onFulfilled = undefined, onRejected = undefined, onFinally = undefined) {
		if (!is_undefined(onFulfilled)) {
			array_push(fulfillHandlers_, onFulfilled);
		}
		
		if (!is_undefined(onRejected)) {
			array_push(rejectHandlers_, onRejected);
		}
		
		if (!is_undefined(onFinally)) {
			array_push(finallyHandlers_, onFinally);
		}
		
		return self;
	};
	
	andCatch = function(onRejected) {
		return andThen(undefined, onRejected, undefined);
	};
	
	andFinally = function(onFinally) {
		return andThen(undefined, undefined, onFinally);
	};
	
	andBack = function() {
		return promiseOwner_;
	};
}

function BetterLootLocker(httpHandlerFunction) constructor {
	httpHandlerFunction_ = httpHandlerFunction;
	gameKey_ = undefined;
	gameVersion_ = undefined;
	sessionId_ = undefined;
	sessionToken_ = undefined;
	domainKey_ = undefined;
	isDevelopment_ = undefined;
	llVersion_ = "2021-03-01"; // LL-Version: http header
	
	makeDsmap_ = function() {
		var argc_ = argument_count, map_ = ds_map_create();
		for (var i_ = 0; i_ < argc_; i_ += 2) {
			var name_ = argument[i_], value_ = argument[i_ + 1];
			if (!is_undefined(value_) && !is_ptr(value_)) {
				ds_map_add(map_, name_, value_);
			}
		}
		
		return map_;
	};
	
	makeJsonBody_ = function() {
		var argc_ = argument_count, struct_ = { };
		for (var i_ = 0; i_ < argc_; i_ += 2) {
			var name_ = argument[i_], value_ = argument[i_ + 1];
			if (!is_undefined(value_) && !is_ptr(value_)) {
				variable_struct_set(struct_, name_, value_);
			}
		}
		
		return json_stringify(struct_);
	};
	
	makeJsonInner_ = function() {
		var argc_ = argument_count, struct_ = undefined;
		for (var i_ = 0; i_ < argc_; i_ += 2) {
			var name_ = argument[i_], value_ = argument[i_ + 1];
			if (!is_undefined(value_) && !is_ptr(value_)) {
				if (is_undefined(struct_)) {
					struct_ = { };
				}
				
				variable_struct_set(struct_, name_, value_);
			}
		}
		
		return struct_;
	};
	
	httpPostJson_ = function(httpUrlString, httpMethodString, headersMap, bodyStringOrBufferId) {
		ds_map_add(headersMap, "LL-Version", llVersion_); // append to *all* outcoming requests
		var httpId_ = http_request(httpUrlString, httpMethodString, headersMap, bodyStringOrBufferId);
		ds_map_destroy(headersMap);
		if (!is_string(bodyStringOrBufferId)) {
			buffer_delete(bodyStringOrBufferId);
		}
		
		var promise_ = undefined;
		if (httpId_ < 0) {
			// wtf? http allocation failed? signal a very bad condition
			throw "http allocation failed somehow??? invalid url or invalid headers?";
		}
		else {
			// register a promise
			promise_ = new BetterLootLockerPromise(self);
			return httpHandlerFunction_(httpId_, promise_);
		}
	};
	
	setGameKey = function(gameKeyString) {
		gameKey_ = gameKeyString;
		return self;
	};
	
	setGameVersion = function(gameVersionString) {
		gameVersion_ = gameVersionString;
		return self;
	};
	
	setSessionId = function(sessionIdString) {
		sessionId_ = sessionIdString;
		return self;
	};
	
	setSessionToken = function(sessionTokenString) {
		sessionToken_ = sessionTokenString;
		return self;
	};
	
	setDomainKey = function(domainKeyString) {
		domainKey_ = domainKeyString;
		return self;
	};
	
	setIsDevelopment = function(isDevelopmentBool) {
		isDevelopment_ = isDevelopmentBool ? "true": "false";
		return self;
	};
	
	loginAsGuest = function(playerIdentifierString) {
		return httpPostJson_(
			"https://api.lootlocker.io/game/v2/session/guest",
			"POST",
			makeDsmap_("Content-Type", "application/json"),
			makeJsonBody_(
				"game_key", gameKey_,
				"game_version", gameVersion_,
				"session_id", sessionId_,
				"player_identifier", playerIdentifierString,
				"development_mode", isDevelopment_
			)
		);
	};
	
	loginAsSteam = function(steamIdInt64) {
		return httpPostJson_(
			"https://api.lootlocker.io/game/v2/session",
			"POST",
			makeDsmap_("Content-Type", "application/json"),
			makeJsonBody_(
				"game_key", gameKey_,
				"game_version", gameVersion_,
				"session_id", sessionId_,
				"player_identifier", string(steamIdInt64),
				"platform", "steam",
				"development_mode", isDevelopment_
			)
		);
	};
	
	loginAsNintendoSwitch = function(nsaJwtBase64IdTokenString) {
		return httpPostJson_(
			"https://api.lootlocker.io/game/session/nintendo-switch",
			"POST",
			makeDsmap_("Content-Type", "application/json"),
			makeJsonBody_(
				"game_key", gameKey_,
				"game_version", gameVersion_,
				"session_id", sessionId_,
				"nsa_id_token", nsaJwtBase64IdTokenString,
				"development_mode", isDevelopment_
			)
		);
	};
	
	loginAsPlayStationNetwork = function(psnOnlineIdString) {
		return httpPostJson_(
			"https://api.lootlocker.io/game/v2/session",
			"POST",
			makeDsmap_("Content-Type", "application/json"),
			makeJsonBody_(
				"game_key", gameKey_,
				"game_version", gameVersion_,
				"session_id", sessionId_,
				"player_identifier", psnOnlineIdString,
				"platform", "psn",
				"development_mode", isDevelopment_
			)
		);
	};
	
	loginAsAndroid = function(deviceIdString) {
		return httpPostJson_(
			"https://api.lootlocker.io/game/v2/session",
			"POST",
			makeDsmap_("Content-Type", "application/json"),
			makeJsonBody_(
				"game_key", gameKey_,
				"game_version", gameVersion_,
				"session_id", sessionId_,
				"player_identifier", deviceIdString,
				"platform", "android",
				"development_mode", isDevelopment_
			)
		);
	};
	
	loginAsWhitelabel = function(emailString, whitelabelTokenString) {
		return httpPostJson_(
			"https://api.lootlocker.io/game/v2/session/white-label",
			"POST",
			makeDsmap_("Content-Type", "application/json"),
			makeJsonBody_(
				"game_key", gameKey_,
				"game_version", gameVersion_,
				"session_id", sessionId_,
				"email", emailString,
				"token", whitelabelTokenString,
				"development_mode", isDevelopment_
			)
		);	
	};
	
	whitelabelSignIn = function(emailString, passwordString, doRememberBool) {
		return httpPostJson_(
			"https://api.lootlocker.io/white-label-login/login",
			"POST",
			makeDsmap_("Content-Type", "application/json", "domain-key", domainKey_, "is-development", isDevelopment_),
			makeJsonBody_(
				"email", emailString,
				"password", passwordString,
				"remember", bool(doRememberBool)
			)
		);
	};
	
	whitelabelVerifySession = function(emailString, tokenString) {
		return httpPostJson_(
			"https://api.lootlocker.io/white-label-login/verify-session",
			"POST",
			makeDsmap_("Content-Type", "application/json", "domain-key", domainKey_, "is-development", isDevelopment_),
			makeJsonBody_(
				"token", tokenString,
				"email", emailString
			)
		);
	};
	
	whitelabelSignUp = function(emailString, passwordString) {
		return httpPostJson_(
			"https://api.lootlocker.io/white-label-login/sign-up",
			"POST",
			makeDsmap_("Content-Type", "application/json", "domain-key", domainKey_, "is-development", isDevelopment_),
			makeJsonBody_(
				"email", emailString,
				"password", passwordString
			)
		);
	};
	
	whitelabelRequestVerification = function(userIdReal) {
		return httpPostJson_(
			"https://api.lootlocker.io/white-label-login/request-verification",
			"POST",
			makeDsmap_("Content-Type", "application/json", "domain-key", domainKey_, "is-development", isDevelopment_),
			makeJsonBody_(
				"user_id", userIdReal
			)
		);
	};
	
	whitelabelRequestResetPassword = function(userIdReal) {
		return httpPostJson_(
			"https://api.lootlocker.io/white-label-login/request-reset-password",
			"POST",
			makeDsmap_("Content-Type", "application/json", "domain-key", domainKey_, "is-development", isDevelopment_),
			makeJsonBody_(
				// TODO: FIXME: this should be the email? docs are weird...
				"user_id", userIdReal
			)
		);
	};
	
	whitelabelDeleteSession = function(tokenString) {
		return httpPostJson_(
			"https://api.lootlocker.io/white-label-login/session",
			"DELETE",
			makeDsmap_("Content-Type", "application/json", "domain-key", domainKey_, "is-development", isDevelopment_),
			makeJsonBody_(
				"token", tokenString
			)
		);
	};
	
	endSession = function(alsoLogoutBoolOpt = undefined) {
		return httpPostJson_(
			"https://api.lootlocker.io/game/v1/session",
			"DELETE",
			makeDsmap_(
				"x-session-token", sessionToken_,
				"logout", (is_undefined(alsoLogoutBoolOpt)? alsoLogoutBoolOpt: (alsoLogoutBoolOpt? "true": "false"))
			),
			""
		);
	};
	
	leaderboardGetScoreList = function(leaderboardIdString, countReal, afterRealOpt = undefined) {
		return httpPostJson_(
			"https://api.lootlocker.io/game/leaderboards/"
				+ leaderboardIdString
				+ "/list?count=" + string(countReal)
				+ (is_undefined(afterRealOpt) ? "" : ("&after=" + string(afterRealOpt))),
			"GET",
			makeDsmap_("x-session-token", sessionToken_),
			""
		);
	};
	
	leaderboardSubmitScore = function(leaderboardIdString, scoreReal, metadataStringOpt = undefined, memberIdStringOpt = undefined) {
		return httpPostJson_(
			"https://api.lootlocker.io/game/leaderboards/"
				+ leaderboardIdString
				+ "/submit",
			"POST",
			makeDsmap_("x-session-token", sessionToken_, "Content-Type", "application/json"),
			makeJsonBody_(
				"score", scoreReal,
				"metadata", string(metadataStringOpt),
				"member_id", string(memberIdStringOpt)
			)
		);
	};
	
	leaderboardGetMemberRank = function(leaderboardIdString, memberIdString) {
		return httpPostJson_(
			"https://api.lootlocker.io/game/leaderboards/"
				+ leaderboardIdString
				+ "/member/" + string(memberIdString),
			"GET",
			makeDsmap_("x-session-token", sessionToken_),
			""
		);
	};
	
	leaderboardGetAllMemberRanks = function(memberIdString, countReal, afterRealOpt = undefined) {
		return httpPostJson_(
			"https://api.lootlocker.io/game/leaderboards/member/"
				+ string(memberIdString)
				+ "?count=" + string(countReal)
				+ (is_undefined(afterRealOpt)? "": ("&after=" + string(afterRealOpt))),
			"GET",
			makeDsmap_("x-session-token", sessionToken_),
			""
		);
	};
	
	storageGetAll = function() {
		return httpPostJson_(
			"https://api.lootlocker.io/game/v1/player/storage",
			"GET",
			makeDsmap_("x-session-token", sessionToken_),
			""
		);
	};
	
	storageGetKey = function(keyString) {
		return httpPostJson_(
			"https://api.lootlocker.io/game/v1/player/storage?key=" + string(keyString),
			"GET",
			makeDsmap_("x-session-token", sessionToken_),
			""
		);
	};
	
	storageDeleteKey = function(keyString) {
		return httpPostJson_(
			"https://api.lootlocker.io/game/v1/player/storage?key=" + string(keyString),
			"DELETE",
			makeDsmap_("x-session-token", sessionToken_),
			""
		);
	};
	
	storageUpdateKeys = function(inputDataArray) {
		return httpPostJson_(
			"https://api.lootlocker.io/game/v1/player/storage",
			"POST",
			makeDsmap_("x-session-token", sessionToken_, "Content-Type", "application/json"),
			json_stringify(inputDataArray)
		);
	};
	
	playerGetInfo = function() {
		return httpPostJson_(
			"https://api.lootlocker.io/game/player/info",
			"GET",
			makeDsmap_("x-session-token", sessionToken_),
			""
		);
	};
	
	playerGetName = function() {
		return httpPostJson_(
			"https://api.lootlocker.io/game/player/name",
			"GET",
			makeDsmap_("x-session-token", sessionToken_),
			""
		);
	};
	
	playerSetName = function(nameString) {
		return httpPostJson_(
			"https://api.lootlocker.io/game/player/name",
			"PATCH",
			makeDsmap_("x-session-token", sessionToken_, "Content-Type", "application/json"),
			makeJsonBody_(
				"name", nameString
			)
		);
	};
	
	playerSetPrivate = function() {
		return httpPostJson_(
			"https://api.lootlocker.io/game/v1/player/profile/public",
			"DELETE",
			makeDsmap_("x-session-token", sessionToken_),
			""
		);
	};
	
	playerSetPublic = function() {
		return httpPostJson_(
			"https://api.lootlocker.io/game/v1/player/profile/public",
			"POST",
			makeDsmap_("x-session-token", sessionToken_),
			""
		);
	};
	
	assetCandidateCreate = function(nameStringOpt = undefined, contextIdRealOpt = undefined, kvStorageArrayOpt = undefined, filtersArrayOpt = undefined, dataEntitiesArrayOpt = undefined) {
		return httpPostJson_(
			"https://api.lootlocker.io/game/v1/player/assets/candidates",
			"POST",
			makeDsmap_("x-session-token", sessionToken_, "Content-Type", "application/json"),
			makeJsonBody_(
				"data", makeJsonInner_(
					"name", nameStringOpt,
					"context_id", contextIdRealOpt,
					"kv_storage", kvStorageArrayOpt,
					"filters", filtersArrayOpt,
					"data_entities", dataEntitiesArrayOpt
				)
			)
		);
	};
	
	assetCandidateUpdate = function(idReal, isCompletedBool, nameStringOpt = undefined, contextIdRealOpt = undefined, kvStorageArrayOpt = undefined, filtersArrayOpt = undefined, dataEntitiesArrayOpt = undefined) {
		return httpPostJson_(
			"https://api.lootlocker.io/game/v1/player/assets/candidates/" + string(idReal),
			"PUT",
			makeDsmap_("x-session-token", sessionToken_, "Content-Type", "application/json"),
			makeJsonBody_(
				"completed", bool(isCompletedBool),
				"data", makeJsonInner_(
					"name", nameStringOpt,
					"context_id", contextIdRealOpt,
					"kv_storage", kvStorageArrayOpt,
					"filters", filtersArrayOpt,
					"data_entities", dataEntitiesArrayOpt
				)
			)
		);
	};
	
	assetCandidateDelete = function(idReal) {
		return httpPostJson_(
			"https://api.lootlocker.io/game/v1/player/assets/candidates/" + string(idReal),
			"DELETE",
			makeDsmap_("x-session-token", sessionToken_),
			""
		);
	};
	
	assetCandidateListing = function() {
		return httpPostJson_(
			"https://api.lootlocker.io/game/v1/player/assets/candidates",
			"GET",
			makeDsmap_("x-session-token", sessionToken_),
			""
		);
	};
	
	assetCandidateGet = function(idReal) {
		return httpPostJson_(
			"https://api.lootlocker.io/game/v1/player/assets/candidates/" + string(idReal),
			"GET",
			makeDsmap_("x-session-token", sessionToken_),
			""
		);
	};
	
	assetCandidateDeleteFile = function(idReal, fileIdReal) {
		return httpPostJson_(
			"https://api.lootlocker.io/game/v1/player/assets/candidates/" + string(idReal) + "/file/" + string(fileIdReal),
			"DELETE",
			makeDsmap_("x-session-token", sessionToken_),
			""
		);
	};
	
	assetCandidateAddFile = function(idReal, purposeString, fileNameString, fileBufferId, fileSizeRealOpt = 0, fileOffsetRealOpt = 0) {
		if (fileSizeRealOpt <= 0) {
			fileSizeRealOpt = buffer_get_size(fileBufferId) - fileOffsetRealOpt;
		}
		var buff_ = buffer_create(1, buffer_grow, 1);
		// -- submit the actual file
		buffer_write(buff_, buffer_text, "--------------------------ee354ed66ff52e4f\r\n");
		buffer_write(buff_, buffer_text, "Content-Disposition: form-data; name=\"file\"; filename=\"" + fileNameString + "\"\r\n");
		buffer_write(buff_, buffer_text, "Content-Type: application/octet-stream\r\n");
		buffer_write(buff_, buffer_text, "\r\n");
		buffer_resize(buff_, buffer_tell(buff_) + fileSizeRealOpt);
		buffer_copy(fileBufferId, fileOffsetRealOpt, fileSizeRealOpt, buff_, buffer_tell(buff_));
		buffer_seek(buff_, buffer_seek_relative, fileSizeRealOpt);
		buffer_write(buff_, buffer_text, "\r\n");
		// -- submit the purpose field
		buffer_write(buff_, buffer_text, "--------------------------ee354ed66ff52e4f\r\n");
		buffer_write(buff_, buffer_text, "Content-Disposition: form-data; name=\"purpose\"\r\n");
		buffer_write(buff_, buffer_text, "\r\n");
		buffer_write(buff_, buffer_text, purposeString + "\r\n");
		buffer_write(buff_, buffer_text, "--------------------------ee354ed66ff52e4f--\r\n");
		// -- finish him
		// make sure the buffer is *exactly* the right size, no grow leftover
		buffer_resize(buff_, buffer_tell(buff_));
		return httpPostJson_(
			"https://api.lootlocker.io/game/v1/player/assets/candidates/" + string(idReal) + "/file",
			//"https://enmtkpe6b2t9q.x.pipedream.net/game/v1/player/assets/candidates/" + string(idReal) + "/file",
			"POST",
			// yes I know that I should make a random form-data boundary, no, I don't care at all.
			makeDsmap_("x-session-token", sessionToken_, "Expect", "100-continue", "Content-Type", "multipart/form-data; boundary=------------------------ee354ed66ff52e4f"),
			buff_
		);
	};
	
	playerUploadFile = function(isFilePublicBoolOpt, purposeStringOpt = undefined, fileNameString, fileBufferId, fileSizeRealOpt = 0, fileOffsetRealOpt = 0) {
		if (fileSizeRealOpt <= 0) {
			fileSizeRealOpt = buffer_get_size(fileBufferId) - fileOffsetRealOpt;
		}
		var buff_ = buffer_create(1, buffer_grow, 1);
		// -- submit the actual file
		buffer_write(buff_, buffer_text, "--------------------------a620a16d76d561f3\r\n");
		buffer_write(buff_, buffer_text, "Content-Disposition: form-data; name=\"file\"; filename=\"" + fileNameString + "\"\r\n");
		buffer_write(buff_, buffer_text, "Content-Type: application/octet-stream\r\n");
		buffer_write(buff_, buffer_text, "\r\n");
		// ---- append the contents of fileBufferId to buff_
		buffer_resize(buff_, buffer_tell(buff_) + fileSizeRealOpt);
		buffer_copy(fileBufferId, fileOffsetRealOpt, fileSizeRealOpt, buff_, buffer_tell(buff_));
		buffer_seek(buff_, buffer_seek_relative, fileSizeRealOpt);
		buffer_write(buff_, buffer_text, "\r\n");
		// -- submit the purpose field
		if (!is_undefined(purposeStringOpt) && string_length(purposeStringOpt) > 0) {
			buffer_write(buff_, buffer_text, "--------------------------a620a16d76d561f3\r\n");
			buffer_write(buff_, buffer_text, "Content-Disposition: form-data; name=\"purpose\"\r\n");
			buffer_write(buff_, buffer_text, "\r\n");
			buffer_write(buff_, buffer_text, purposeStringOpt + "\r\n");
			buffer_write(buff_, buffer_text, "--------------------------a620a16d76d561f3\r\n");
		}
		// -- submit the is_public field
		buffer_write(buff_, buffer_text, "--------------------------a620a16d76d561f3\r\n");
		buffer_write(buff_, buffer_text, "Content-Disposition: form-data; name=\"is_public\"\r\n");
		buffer_write(buff_, buffer_text, "\r\n");
		buffer_write(buff_, buffer_text, (isFilePublicBoolOpt? "true": "false") + "\r\n");
		buffer_write(buff_, buffer_text, "--------------------------a620a16d76d561f3--\r\n");
		// -- finish him
		// make sure the buffer is *exactly* the right size, no grow leftover
		buffer_resize(buff_, buffer_tell(buff_));
		return httpPostJson_(
			"https://api.lootlocker.io/game/player/files",
			"POST",
			// yes I know that I should make a random form-data boundary, no, I don't care at all.
			makeDsmap_("x-session-token", sessionToken_, "Expect", "100-continue", "Content-Type", "multipart/form-data; boundary=------------------------a620a16d76d561f3"),
			buff_ // this should send the raw bytes in the POST body, not a UTF-8 string
		);	
	};
	
	playerListFiles = function() {
		return httpPostJson_(
			"https://api.lootlocker.io/game/player/files",
			"GET",
			makeDsmap_("x-session-token", sessionToken_),
			""
		);
	};
	
	playerListPublicFiles = function(playerId) {
		return httpPostJson_(
			"https://api.lootlocker.io/game/player/" + string(playerId) + "/files",
			"GET",
			makeDsmap_("x-session-token", sessionToken_),
			""
		);
	};
	
	playerGetSingleFile = function(fileId) {
		return httpPostJson_(
			"https://api.lootlocker.io/game/player/files/" + string(fileId),
			"GET",
			makeDsmap_("x-session-token", sessionToken_),
			""
		);
	};
	
	playerDeleteFile = function(fileId) {
		return httpPostJson_(
			"https://api.lootlocker.io/game/player/files/" + string(fileId),
			"DELETE",
			makeDsmap_("x-session-token", sessionToken_),
			""
		);
	};
	
	missionsGetAll = function() {
		return httpPostJson_(
			"https://api.lootlocker.io/game/v1/missions",
			"GET",
			makeDsmap_("x-session-token", sessionToken_),
			""
		);
	};
	
	missionsGetSingle = function(missionId) {
		return httpPostJson_(
			"https://api.lootlocker.io/game/v1/mission/" + string(missionId),
			"GET",
			makeDsmap_("x-session-token", sessionToken_),
			""
		);
	};
	
	missionsStartMission = function(missionId) {
		return httpPostJson_(
			"https://api.lootlocker.io/game/v1/mission/" + string(missionId) + "/start",
			"POST",
			makeDsmap_("x-session-token", sessionToken_),
			""
		);
	};
	
	missionsFinishMission = function(missionId, missionSignatureString, playerId, finishTimeString, finishScoreStringOpt = undefined, checkpointTimesArrayOpt = undefined) {
		var jsonpayload_ = makeJsonInner_(
			"finish_time", finishTimeString,
			"finish_score", finishScoreStringOpt,
			"checkpoint_times", checkpointTimesArrayOpt
		);
		// there is sha1_string_unicode and sha1_string_utf8??????????
		var jsonsig_ = sha1_string_utf8(json_stringify(jsonpayload_) + missionSignatureString + string(playerId));
		var jbody_ = makeJsonBody_(
			"signature", jsonsig_,
			"payload", jsonpayload_
		);
		return httpPostJson_(
			"https://api.lootlocker.io/game/v1/mission/" + string(missionId) + "/end",
			"POST",
			makeDsmap_("x-session-token", sessionToken_, "Content-Type", "application/json"),
			jbody_
		);
	};
	
	mapsGetAll = function() {
		return httpPostJson_(
			"https://api.lootlocker.io/game/v1/maps",
			"GET",
			makeDsmap_("x-session-token", sessionToken_),
			""
		);
	};
	
	collectablesGetAll = function() {
		return httpPostJson_(
			"https://api.lootlocker.io/game/v1/collectable",
			"GET",
			makeDsmap_("x-session-token", sessionToken_),
			""
		);
	};
	
	collectablesCollectItem = function(itemSlugString) {
		return httpPostJson_(
			"https://api.lootlocker.io/game/v1/collectable",
			"POST",
			makeDsmap_("x-session-token", sessionToken_, "Content-Type", "application/json"),
			makeJsonBody_(
				"slug", itemSlugString
			)
		);
	};
	
	messagesGetAll = function() {
		return httpPostJson_(
			"https://api.lootlocker.io/game/v1/messages",
			"GET",
			makeDsmap_("x-session-token", sessionToken_),
			""
		);
	};
	
	pingServerTime = function() {
		return httpPostJson_(
			"https://api.lootlocker.io/game/ping",
			"GET",
			makeDsmap_("x-session-token", sessionToken_),
			""
		);
	};
	
	arrayToAssetString_ = function(filtersArray) {
		var s_ = "";
		for (var i_ = 0, l_ = array_length(filtersArray); i_ < l_; ++i_) {
			s_ += filtersArray[@ i_].key;
			s_ += "=";
			s_ += filtersArray[@ i_].value;
			if (i_ < l_ - 1) {
				s_ += ";";
			}
		}
		return s_;
	};
	
	contextsGetAll = function() {
		return httpPostJson_(
			"https://api.lootlocker.io/game/v1/contexts",
			"GET",
			makeDsmap_("x-session-token", sessionToken_),
			""
		);
	};
	
	assetsGetAll = function(sinceDateStringOpt = undefined) {
		return httpPostJson_(
			"https://api.lootlocker.io/game/v1/assets"
			+ (is_undefined(sinceDateStringOpt)? "": ("?since=" + sinceDateStringOpt)),
			"GET",
			makeDsmap_("x-session-token", sessionToken_),
			""
		);
	};
	
	assetsGetList = function(countReal, afterRealOpt = undefined, contextIdRealOpt = undefined, filterStringOpt = undefined, includeUgcBoolOpt = undefined, assetFiltersArrayOpt = undefined, ugcCreatorPlayerIdOpt = undefined) {
		return httpPostJson_(
			"https://api.lootlocker.io/game/v1/assets/list"
			+ "?count=" + string(countReal)
			+ (is_undefined(afterRealOpt)? "": ("&after=" + string(afterRealOpt)))
			+ (is_undefined(contextIdRealOpt)? "": ("&context_id=" + string(contextIdRealOpt)))
			+ (is_undefined(filterStringOpt)? "": ("&filter=" + filterStringOpt))
			+ (is_undefined(assetFiltersArrayOpt)? "": ("&asset_filters=" + arrayToAssetString_(assetFiltersArrayOpt)))
			+ (is_undefined(includeUgcBoolOpt)? "": ("&include_ugc=" + (includeUgcBoolOpt? "true": "false")))
			+ (is_undefined(ugcCreatorPlayerIdOpt)? "": ("&ugc_creator_player_id=" + string(ugcCreatorPlayerIdOpt))),
			"GET",
			makeDsmap_("x-session-token", sessionToken_),
			""
		);
	};
	
	assetsGetFavourites = function() {
		return httpPostJson_(
			"https://api.lootlocker.io/game/v1/asset/favourites",
			"GET",
			makeDsmap_("x-session-token", sessionToken_),
			""
		);
	};
	
	assetsAddFavourite = function(assetId) {
		return httpPostJson_(
			"https://api.lootlocker.io/game/v1/asset/" + string(assetId) + "/favourite",
			"POST",
			makeDsmap_("x-session-token", sessionToken_),
			""
		);
	};
	
	assetsRemoveFavourite = function(assetId) {
		return httpPostJson_(
			"https://api.lootlocker.io/game/v1/asset/" + string(assetId) + "/favourite",
			"DELETE",
			makeDsmap_("x-session-token", sessionToken_),
			""
		);
	};
	
	getFile = function(cdnUrlString, whereLocationString) {
		var httpId_ = http_get_file(cdnUrlString, whereLocationString);
		var promise_ = undefined;
		if (httpId_ < 0) {
			// wtf? http allocation failed? signal a very bad condition
			throw "http_get_file() failed";
		}
		else {
			// register a promise
			promise_ = new BetterLootLockerPromise(self);
			return httpHandlerFunction_(httpId_, promise_);
		}
	};
}




