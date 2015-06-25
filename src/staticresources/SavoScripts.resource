if (!Savo) {
	var Savo = {};
}

Savo.Salesforce = {};
Savo.Salesforce.Opportunity = {};
Savo.Salesforce.User = {};

Savo.Salesforce.sessionId = '';
Savo.Salesforce.partnerUrl = '';
Savo.Salesforce.customVirtualDirectory = null;

Savo.Salesforce.search = function(criteria) {
	return this.redirectToTarget("search", criteria);
};

Savo.Salesforce.redirectToUrl = function(relativeUrl) {
	return this.buildLink("returnurl=" + this.encode(relativeUrl));
};

Savo.Salesforce.redirectToTarget = function(target,parameter) {
	return this.buildLink("redirecttarget=" + target + "&redirectparameter=" + parameter);
};

Savo.Salesforce.buildLink = function(queryString) {
	if (this.customVirtualDirectory !== null) {
		var redirectUrl = "https://www.gosavo.com/" + this.customVirtualDirectory + "/SingleSignOn/Salesforce.ashx?sessionid=" + Savo.Salesforce.sessionId + "&url=" + Savo.Salesforce.partnerUrl;
	}
	else {
		var redirectUrl = "https://www.gosavo.com/prod/SingleSignOn/Salesforce.ashx?sessionid=" + Savo.Salesforce.sessionId + "&url=" + Savo.Salesforce.partnerUrl;
	}
	
	// if additional query string information is passed, add it to the redirect url
	if (queryString !== null) {
		redirectUrl = redirectUrl + "&" + queryString;
	}
	
	return redirectUrl;
};

var stageMapping = {
	"0":"/CustomPage/View.aspx?id=1635885",
	"1":"/CustomPage/View.aspx?id=1635889",
	"2":"/CustomPage/View.aspx?id=1635874",
	"3 - Qualify opportunity":"/CustomPage/View.aspx?id=1635875",
	"4 - Tailor and present solutions":"/CustomPage/View.aspx?id=1657259",
	"5 - Negotiate Sale":"/CustomPage/View.aspx?id=1657335",
	"6 - Negotiate contract":"/CustomPage/View.aspx?id=1657576",
	"7 - Implement solution":"/CustomPage/View.aspx?id=1657624",
	"Qualify":"/CustomPage/View.aspx?id=1635875",
	"Propose":"/CustomPage/View.aspx?id=1657259",
	"Commit":"/CustomPage/View.aspx?id=1657335",
	"Contract":"/CustomPage/View.aspx?id=1657576",
	"Execute":"/CustomPage/View.aspx?id=1657624",
	
};

Savo.Salesforce.redirectToStage = function(salesStage) {
	return Savo.Salesforce.redirectToUrl(stageMapping[salesStage]);
};

var regionMapping = {
	"APAC":"/CustomPage/View.aspx?id=30597637",
	"EMEA":"/CustomPage/View.aspx?id=30571130",
	"India":"/CustomPage/View.aspx?id=1635874",
	"UK&I":"/CustomPage/View.aspx?id=30571227",
	"Latin America":"/CustomPage/View.aspx?id=30820799",
	"North America":"/CustomPage/View.aspx?id=30693663",	
};

Savo.Salesforce.redirectByRegion = function(Region) {
	return Savo.Salesforce.redirectToUrl(regionMapping[Region]);
};

Savo.Salesforce.encode = function(criteria) {
	var result = criteria;	
	result = result.replace(",","%2c");
	result = result.replace("&","%26");	
	return result;
};

Savo.Salesforce.onSearchEnter = function(e, searchTerm) {
	var keynum;
	
	if(window.event) // for IE
		keynum = e.keyCode;
	else if(e.which) // for firefox
		keynum = e.which;
	 
	if (keynum == 13) {
		var redirectUrl = this.search(searchTerm);
		window.open(redirectUrl);
	}
};

Savo.Salesforce.Opportunity.CreateProductDropDown = function(opportunityId, controlId) {
	var result = sforce.connection.query("SELECT Id, Name, (SELECT UnitPrice, PricebookEntry.Name FROM OpportunityLineItems) FROM Opportunity WHERE Id ='" + opportunityId + "'");
	var records = result.getArray("records");

	// because we are only dealing with one opportunity, we just want to get the first record
	var opportunity = records[0];

	// disable the drop down if there are no opportunity line items
	if (opportunity.OpportunityLineItems === null) { 
		Savo.Salesforce.CreateDropdown(controlId);
	}
	else {
		var products = new Array();
		
		// check to see if there is only one line item. if so, then get the single item and add it to the products list
		// otherwise, loop through all the products and add it to the list
		if (opportunity.OpportunityLineItems.size <= 1) { 
			products[0] = opportunity.OpportunityLineItems.records.PricebookEntry.Name; 
		}
		else {
			for (var i=0; i < opportunity.OpportunityLineItems.size; i++) { 
				products[i] = opportunity.OpportunityLineItems.records[i].PricebookEntry.Name; 
			}
		}
		
		// create the dropdown list containing all opportunity line items
		Savo.Salesforce.CreateDropdown(controlId, products);	 
	}
};

// create and populate a dropdown list
Savo.Salesforce.CreateDropdown = function(id, itemArray) {
	if (itemArray === undefined || itemArray.length === 0) {
		document.write("<select id=\"" + id + "\" class=\"savoDropDown\" disabled=\"disabled\">");
	}
	else {
		document.write("<select id=\"" + id + "\" class=\"savoDropDown\">");
		
		for (var j=0; j < itemArray.length; j++) { 
			document.write("<option>" + itemArray[j] + "</option>"); 
		}
	}
	document.write("</select>");
};