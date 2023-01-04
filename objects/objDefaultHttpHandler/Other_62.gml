/// @description Listen for incoming HTTP events.

show_debug_message(json_encode(async_load));

var hid_ = async_load[? "id"];
var hstatus_ = async_load[? "status"];
var hhstatus_ = async_load[? "http_status"];
var hfilename_ = async_load[? "filename"];
var hurl_ = async_load[? "url"];
var hresult_ = async_load[? "result"];
var hresponseheaders_ = async_load[? "response_headers"];

// hackfix for GameMaker not understanding HTTP 204 No Content replies
if (hhstatus_ == 204) {
	hstatus_ = 0;
}

if (hstatus_ == 1) {
	// ignore requests that are in progress, we only want finished ones.
	show_debug_message("An HTTP request is in progress");
	exit;
}

var reqslen_ = array_length(requests);
var targindex_ = -1, pair_ = undefined;
for (var i_ = 0; i_ < reqslen_; ++i_) {
	pair_ = requests[@ i_];
	if (hid_ != pair_.requestId) {
		continue;
	}
	
	targindex_ = i_;
	break;
}

if (targindex_ == -1) {
	// a request that we are not aware of :(
	exit;
}

// delete it off
array_delete(requests, targindex_, 1);

var hresultjson_ = parseJsonSafe(hresult_);
var hheadersstruct_ = undefined;
if (!is_undefined(hresponseheaders_) && hresponseheaders_ >= 0) {
	hheadersstruct_ = parseJsonSafe(json_encode(hresponseheaders_));
}

var hstruct_ = {
	status: hstatus_,
	httpStatus: hhstatus_,
	url: hurl_,
	filename: hfilename_,
	result: hresult_,
	headers: hheadersstruct_,
	resultAsJson: hresultjson_,
	isException: false
};

// now we can work with pair_
pair_.resolver.resolvePromise_((hstatus_ < 0 || hhstatus_ < 200 || hhstatus_ > 299), hstruct_);


