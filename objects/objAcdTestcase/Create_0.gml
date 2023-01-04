/// @description ..

acName = "Unnamed AC";
acCtxid = undefined;
acFilters = undefined;
acEntities = undefined;
acStorage = undefined;
acFiles = undefined;
acId = undefined;
acContexts = undefined;
acContextsHintLine = "";

amount_ = 0;


findButton = method(id, objTestcase.findButton);
attachToButton = method(id, objTestcase.attachToButton);
askForString = objTestcase.askForString;
bll = objTestcase.bll;

bll.contextsGetAll().andThen(function(e) {
	acContexts = e.resultAsJson.contexts;
	acContextsHintLine = "";
	for (var i_ = 0, l_ = array_length(acContexts); i_ < l_; ++i_) {
		var ctx_ = acContexts[@ i_];
		
		// allowed context ids for the string ui dialog:
		acContextsHintLine += string(ctx_.id);
		if (i_ < l_ - 1) {
			acContextsHintLine += ",";
		}
	}
}).andCatch(function(e) {
	acContexts = undefined;
	show_message_async("Failed to fetch context ids, you cannot publish an AC.\n" + e.result);
});

publishAc = function() {
	if (is_undefined(acContexts)) {
		exit;
	}
	
	if (!is_undefined(acCtxid)) {
		var found_ = false;
		for (var i_ = 0, l_ = array_length(acContexts); i_ < l_; ++i_) {
			var ctx_ = acContexts[@ i_];
		
			if (acCtxid == ctx_.id) {
				found_ = true;
				break;
			}
		}
		if (!found_) {
			show_message_async("Context id is invalid, valid ones are:\n" + acContextsHintLine);
			exit;
		}
	}
	
	bll
	.assetCandidateCreate(
		acName,
		acCtxid,
		acStorage,
		acFilters,
		acEntities)
	.andThen(function(e) {
		acId = e.resultAsJson.asset_candidate.id;
		if (!is_undefined(acFiles)) {
			var l_ = array_length(acFiles);
			amount_ = l_; //< mark as completed when this reaches zero
			for (var i_ = 0; i_ < l_; ++i_) {
				bll
				.assetCandidateAddFile(
					acId,
					acFiles[@ i_].purpose,
					acFiles[@ i_].name,
					acFiles[@ i_].bufferId
					// size and offset are not specified
				)
				.andThen(function(e) {
					--amount_;
					if (amount_ <= 0) {
						bll
						.assetCandidateUpdate(
							acId,
							true)
						.andThen(function(e) {
							show_message_async("AC created with files. :))");
						})
						.andCatch(function(e) {
							show_message_async("Unable to mark as completed:\n" + e.result);
						})
						.andFinally(function(e) {
							show_debug_message(e);
						});
					}
				})
				.andCatch(function(e) {
					show_message_async("Failed to upload a file:\n" + e.result);
				})
				.andFinally(function(e) {
					show_debug_message(e);
				});
			}
		}
		else {
			bll
			.assetCandidateUpdate(
				acId,
				true)
			.andThen(function(e) {
				show_message_async("AC created without files. :)");
			})
			.andCatch(function(e) {
				show_message_async("Unable to mark as completed:\n" + e.result);
			});
		}
	})
	.andCatch(function(e) {
		show_message_async("An error occurred when creating an AC:\n" + e.result);
	})
	.andFinally(function(e) {
		show_debug_message(e);
	});
};

makeSummaryText = function() {
	var s_ = "";
	
	s_ += "Asset Candidate Summary:\n";
	s_ += "Name: " + acName + "\n";
	
	if (!is_undefined(acCtxid)) {
		s_ += "Context ID: " + string(acCtxid) + "\n";
	}
	
	if (!is_undefined(acFilters)) {
		s_ += "Filters:\n";
		for (var i_ = 0, l_ = array_length(acFilters); i_ < l_; ++i_) {
			s_ += acFilters[@ i_].key + " = " + acFilters[@ i_].value + "\n";
		}
	}
	
	if (!is_undefined(acStorage)) {
		s_ += "KV Storage:\n";
		for (var i_ = 0, l_ = array_length(acStorage); i_ < l_; ++i_) {
			s_ += acStorage[@ i_].key + " = " + acStorage[@ i_].value + "\n";
		}
	}
	
	if (!is_undefined(acEntities)) {
		s_ += "Data entities:\n";
		for (var i_ = 0, l_ = array_length(acEntities); i_ < l_; ++i_) {
			s_ += acEntities[@ i_].name + " = " + acEntities[@ i_].data + "\n";
		}
	}
	
	if (!is_undefined(acFiles)) {
		s_ += "Files:\n";
		for (var i_ = 0, l_ = array_length(acFiles); i_ < l_; ++i_) {
			s_ += acFiles[@ i_].name + " = " + acFiles[@ i_].purpose + "\n";
		}
	}
	
	s_ += "\n";
	return s_;
};

attachToButton("acd_set_name", function(btn) {
	askForString("name:", acName, function(s_) {
		if (s_ == "") {
			exit;
		}
		
		acName = s_;
	});
}, id);

attachToButton("acd_set_context_id", function(btn) {
	askForString("context id\nempty string or cancel for none\nvalid: " + acContextsHintLine, string(acCtxid ?? ""), function(s_) {
		if (s_ == "") {
			acCtxid = undefined;
			exit;
		}
		
		acCtxid = floor(real(s_));
	});
}, id);

attachToButton("acd_add_filter", function(btn) {
	askForString("enter key:", "key", function(s_) {
		if (s_ == "") {
			exit;
		}
		
		temp = s_;
		askForString("enter value:", "value", function(s_) {
			if (s_ == "") {
				exit;
			}
			
			if (is_undefined(acFilters)) acFilters = [];
			array_push(acFilters, { key: temp, value: s_ });
		});
	});
}, id);

attachToButton("acd_add_kvstorage", function(btn) {
	askForString("enter key:", "key", function(s_) {
		if (s_ == "") {
			exit;
		}
		
		temp = s_;
		askForString("enter value:", "value", function(s_) {
			if (s_ == "") {
				exit;
			}
			
			if (is_undefined(acStorage)) acStorage = [];
			array_push(acStorage, { key: temp, value: s_ });
		});
	});
}, id);

attachToButton("acd_add_data_entity", function(btn) {
	askForString("enter name:", "name_for_entity", function(s_) {
		if (s_ == "") {
			exit;
		}
		
		temp = s_;
		askForString("enter data:", "aGVsbG8gd29ybGQ=", function(s_) {
			if (s_ == "") {
				exit;
			}
			
			if (is_undefined(acEntities)) acEntities = [];
			array_push(acEntities, { name: temp, data: s_ });
		});
	});
}, id);

attachToButton("acd_add_file", function(btn) {
	askForString("file purpose: (FILE / THUMBNAIL / PRIMARY_THUMBNAIL)", "FILE", function(s_) {
		if (s_ == "") {
			exit;
		}
		
		temp = string_upper(s_);
		if (temp != "FILE" && temp != "THUMBNAIL" && temp != "PRIMARY_THUMBNAIL") {
			exit;
		}
		
		var path_ = get_open_filename("All files (*.*)|*.*", "");
		if (path_ == "") {
			exit;
		}
		
		var buff_ = buffer_load(path_);
		if (is_undefined(acFiles)) acFiles = [];
		array_push(acFiles, { name: filename_name(path_), purpose: temp, bufferId: buff_ });
	});
}, id);

attachToButton("goto_back", function(btn) {
	room_goto(rmBLLTestcaseUGC);
}, id);

attachToButton("acd_publish_ac", function(btn) {
	publishAc();
}, id);

