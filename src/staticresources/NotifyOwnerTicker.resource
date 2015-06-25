Sfdc.onReady(function() {

    // Including this in all silent configs
    var toHide = document.getElementsByClassName('brandPrimaryFgr');
    for(var f = 0; f < toHide.length; f++ ) {
        if(toHide[f].innerHTML.toLowerCase() == 'system sidebar panel') {
            toHide[f].parentNode.parentNode.classList.add('hidden');
        }
    }
    if ((window.location.href.indexOf('/500') != -1 || window.location.href.indexOf('/00Q') != -1) && document.getElementById('sendMail')) {
		document.getElementById("sendMail").checked = true;
		var ele = document.getElementById("newOwn_mlktp");
		ele.addEventListener("change", GlobalExp_CheckSendEmail, false);
	}

});
function GlobalExp_CheckSendEmail() {
	document.getElementById("sendMail").checked = true;
}