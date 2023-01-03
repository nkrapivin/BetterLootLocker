/// @description free buffers

if (!is_undefined(acFiles)) {
	for (var i_ = 0, l_ = array_length(acFiles); i_ < l_; ++i_) {
		buffer_delete(acFiles[@ i_].bufferId);
	}
}

