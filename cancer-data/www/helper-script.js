// Javascript helper functions for tasks that cannot be done using pure Shiny

/* By default, the height of the plotting area is not tall enough so
 * the plot is rendered with a scroll bar, which is horrible.  This function
 * calculates what the available width for the plot is, and adjusts the
 * plot area's height in order to make sure there is enough room to fit the plot
 *
 * @params target - the element to adjust
 * @params by - the element to use as a reference
 */
function equalizePlotHeight(target, by) {
	var eBy = document.getElementById(by);
	var width = eBy.scrollWidth;
	var eTarget = document.getElementById(target);
	eTarget.style.height = width + "px";
	
	// Pass ths width value back into Shiny as a shiny input
	Shiny.onInputChange("plotDim", width);
}