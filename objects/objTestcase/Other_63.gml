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

var myresult_ = async_load[? "result"] ?? "";

// work with pair_
if (!is_undefined(pair_.selfCtx)) {
	with (pair_.selfCtx) pair_.callbackFunction(myresult_);
}
else {
	pair_.callbackFunction(myresult_);
}
