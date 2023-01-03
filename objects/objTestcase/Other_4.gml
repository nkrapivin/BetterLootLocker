/// @description Вставьте описание здесь
// Вы можете записать свой код в этом редакторе

if (room == rmBLLTestcase) {
	// prepare GUI controls
	attachToButton("signin", function(btn) {
		if (signedIn) {
			exit;
		}
	
		askForString("email?", "test@example.com", function(email_) {
			if (email_ == "") {
				exit;
			}
		
			askForString("password?", "12345", function(password_) {
				if (password_ == "") {
					exit;
				}
			
				bll
				.whitelabelSignIn(playerEmail, password_, true) // < sign in whitelabel
				.andThen(function(e) {
					playerEmail = e.resultAsJson.email;
					bll
					.loginAsWhitelabel(playerEmail, e.resultAsJson.session_token) // < exchange to game session
					.andThen(function(e) {
						sessToken = e.resultAsJson.session_token;
						bll
						.setSessionToken(sessToken)
						.playerGetName()
						.andThen(function(e) {
							playerName = e.resultAsJson.name;
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
						show_message_async("Sign in stage 2 failed:\n" + e.result); // < fails here
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
			});
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
		
			playerEmail = email_;
			askForString("password?", "12345", function(password_) {
				if (password_ == "") {
					exit;
				}
			
				bll
				.whitelabelSignUp(playerEmail, password_)
				.andThen(function(e) {
					show_message_async("Please verify your email first, only then sign in.\nemail: " + e.resultAsJson.email);
				})
				.andCatch(function(e) {
					show_message_async("There was an error when signing up:\n" + e.result);
				})
				.andFinally(function(e) {
					show_debug_message(e);
				});
			});
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

	attachToButton("goto_ac", function(btn) {
		if (!signedIn) {
			exit;
		}
	
		room_goto(rmBLLTestcaseUGC);
	});
	
	updateBtns();
}
else if (room == rmBLLTestcaseUGC) {
	attachToButton("goto_back", function(btn) {
		room_goto(rmBLLTestcase);
	});
	
	attachToButton("goto_ac_designer", function(btn) {
		room_goto(rmBLLTestcaseACDesigner);
	});
	
	attachToButton("goto_ac_list", function(btn) {
		global.pageBLL = bll;
		global.pageInitScript = function(pageMenuHandler) { with (pageMenuHandler) {
			bll = global.pageBLL;
			backRoom = rmBLLTestcaseUGC;
			statusText = "";
			
			onPageScroll = function() {
				if (pageIndex < 0) {
					pageIndex = 0;
					exit;
				}
				
				stopScrolling = true;
				statusText = "Fetching...";
				
				
				
				bll
				.assetCandidateListing()
				.andThen(function(e) {
					var items = e.resultAsJson.asset_candidates;
					
					with (objGuiButton) {
						if (tag == "CustomMadeBtn") {
							instance_destroy();
						}
					}
					
					var startIndex = pageIndex * pageElements;
					var myX = 192 + 64;
					var myY = 64;
					for (
					var i_ = startIndex,
					l_ = min(startIndex + pageElements, array_length(items));
					i_ < l_;
					++i_) {
						var it = items[@ i_];
						
						with (instance_create_layer(myX, myY, "Gui", objGuiButton)) {
							bll = other.bll;
							tag2 = it;
							owner = other;
							tag = "CustomMadeBtn";
							text = "(del.)";
							
							onButtonClick = function(btn) {
								bll
								.assetCandidateDelete(tag2.id)
								.andThen(function(e) {
									owner.onPageScroll();
								});
							};
							
							onUpdate = function(btn) {
								var s_ = "";
								
								draw_set_halign(fa_left);
								draw_set_valign(fa_top);
								draw_set_color(c_white);
								
								s_ += tag2.data.name + " (STATUS = " + tag2.status + ")\n";
								
								draw_text(x + sprite_width + sprite_width/4, y, s_);
							};
							
							onButtonRightClick = function(btn) {
								
							};
						}
						
						myY += 64 + 32;
					}
					
					statusText = "Fetched!";
				})
				.andCatch(function(e) {
					statusText = "There was an error";	
				})
				.andFinally(function(e) {
					stopScrolling = false;
				});
			};
			
			onDrawSummary = function() {
				var s_ = "Asset Candidates:\n";
				s_ += "Page " + string(1 + pageIndex) + "\n";
				s_ += statusText + "\n";
				
				draw_text(x, y, s_);
			};
			
			onPageScroll();
		}};
		room_goto(rmBLLTestcasePageMenu);
	});
}


