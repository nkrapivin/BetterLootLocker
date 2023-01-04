/// @description ...

if (room == rmBLLTestcaseLeaderboard) {
	var myX = 192 + 64 + 64;
	var myY = 64;
	
	if (is_undefined(lbItems)) {
		exit;
	}
	
	for (var i_ = 0, l_ = array_length(lbItems); i_ < l_; ++i_) {
		var item_ = lbItems[@ i_];
		
		var s_ = "";
		s_ += "rank#" + string(item_.rank) + " - score#" + string(item_.score) + " - member#" + item_.member_id + "\n";
		if (variable_struct_exists(item_, "player")) {
			s_ += item_.player.name + " public uid=" + item_.player.public_uid + " id=" + string(item_.player.id) + " ";
		}
		else {
			s_ += "(no player information) ";
		}
		
		if (variable_struct_exists(item_, "metadata")) {
			s_ += "metadata=" + string(item_.metadata);
		}
		
		draw_set_halign(fa_left);
		draw_set_valign(fa_top);
		draw_set_color(c_white);
		draw_text(myX, myY, s_);
		myY += 32;
	}
	
	draw_set_halign(fa_left);
	draw_set_valign(fa_top);
	draw_set_color(c_white);
	draw_text(130, 190, string(1 + lbIndex) + "\n\n\n\n" + (lbBusy? "WAIT": "idle"));
}


