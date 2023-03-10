/// @description Initialize methods.

if (instance_number(object_index) > 1) {
	instance_destroy();
	exit;
}

requests = [];
httpHandlerFunction = function(httpRequestId, promiseStruct) {
	array_push(requests, { requestId: httpRequestId, resolver: promiseStruct });
	return promiseStruct;
};

parseJsonSafe = function(thingString) {
	try {
		return json_parse(thingString);
	}
	catch (__please_just_ignore_the_exception_struct__) {
		return undefined;
	}
};

// pass the `httpHandlerFunction` variable as the first argument...
