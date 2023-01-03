/// @description handle dialog ids..

var myid_ = async_load[? "id"];
var reqslen_ = array_length(dialogIds);
var targindex_ = -1, pair_ = undefined;
for (var i_ = 0; i_ < reqslen_; ++i_) {
	pair_ = dialogIds[@ i_];
	if (myid_ != pair_.requestId) {
		continue;
	}
	
	targindex_ = i_;
	break;
}

if (targindex_ == -1) {
	// wtf? dialog we are not aware of?
	exit;
}

// get rid of it
array_delete(dialogIds, targindex_, 1);

// work with pair_
pair_.callbackFunction(async_load[? "result"]);
