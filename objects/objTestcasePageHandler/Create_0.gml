/// @description init

pageIndex = 0; // override
pageElements = 4; // override
stopScrolling = false;

createPageItem = function() {
	// override!	
};

onPageScroll = function() {
	// override!
};

onCleanup = function() {
	// override!
};

onDrawSummary = function() {
	
};

backRoom = rmBLLTestcase;

findButton = method(id, objTestcase.findButton);
attachToButton = method(id, objTestcase.attachToButton);

attachToButton("page_forward", function(btn) {
	if (stopScrolling) {
		exit;
	}
	
	++pageIndex;
	onPageScroll();
});

attachToButton("page_backward", function(btn) {
	if (stopScrolling) {
		exit;
	}
	
	--pageIndex;
	onPageScroll();
});

attachToButton("goto_back", function(btn) {
	room_goto(backRoom);
});

global.pageInitScript(id);
global.pageInitScript = undefined;

