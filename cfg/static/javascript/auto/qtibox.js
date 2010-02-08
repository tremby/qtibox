/*
 * QTIBox
 * Edshare plugin to allow QTI items to be previewed
 */

/*------------------------------------------------------------------------------
(c) 2010 JISC-funded EASiHE project, University of Southampton
Licensed under the Creative Commons 'Attribution non-commercial share alike' 
licence -- see the LICENCE file for more details
------------------------------------------------------------------------------*/

qtibox_playitem = function(docid) {
	var div = $("qtibox_document_" + docid);
	div.innerHTML = '<iframe src="/cgi/qtibox_playitem?docid=' + docid + '" style="width: 100%; height: 30em;" />';
};
