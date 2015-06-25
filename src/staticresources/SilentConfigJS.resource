Sfdc.onReady(function() {

    // document.getElementById('hideTheSilentConfig').parentNode.parentNode.classList.add('hidden'); // Hides the header of the panel.
    var toHide = document.getElementsByClassName('brandPrimaryFgr');
    for(var f = 0; f < toHide.length; f++ ) {
        if(toHide[f].innerHTML.toLowerCase() == 'system sidebar panel') {
            toHide[f].parentNode.parentNode.classList.add('hidden');
        }
    }
    var prefixArray = ['006','a0c'];
    prefixArray.forEach(function(prefix) {
        if (prefix !== undefined) {
            var toRemove = document.getElementsByName('new');   
            if(document.location.href.indexOf('/' + prefix + '/o') != -1 && toRemove && toRemove.length) {    
                toRemove[0].style.display = 'none';
            }  
            if (document.location.href.toString().indexOf("/"+prefix+"/o") != -1)   {
                $('input[name=new]').hide();
            }
        }
    });

});
