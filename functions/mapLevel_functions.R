
customLevels <- function(parent.win, atLev){
	if(Sys.info()["sysname"] == "Windows"){
		txtCol_width <- 30
	}else{
		txtCol_width <- 40
	}

	#########
	tt <- tktoplevel()
	tkgrab.set(tt)
	tkfocus(tt)

	frDialog <- tkframe(tt, relief = 'raised', borderwidth = 2)
	frButt <- tkframe(tt)

	####
	fr1 <- tkframe(frDialog)
	tkgrid(fr1)

	#########
	yscrLevel <- tkscrollbar(fr1, repeatinterval = 4,
							command = function(...) tkyview(textLevel, ...))
	textLevel <- tktext(fr1, bg = "white", wrap = "word", height = 5, width = txtCol_width,
						yscrollcommand = function(...) tkset(yscrLevel, ...))
	tkgrid(textLevel, yscrLevel)
	tkgrid.configure(yscrLevel, sticky = "ns")
	tkgrid.configure(textLevel, sticky = 'nswe') 
	if(length(atLev) > 0) for(j in seq_along(atLev)) tkinsert(textLevel, "end", paste0(atLev[j], ', '))

	#########
	bt.opt.OK <- tkbutton(frButt, text = "OK") 
	bt.opt.CA <- tkbutton(frButt, text = "Cancel")

	tkconfigure(bt.opt.OK, command = function(){
		vlevel <- tclvalue(tkget(textLevel, "0.0", "end"))
		vlevel <- gsub("[\r\n]", "", vlevel)
		vlevel <- gsub('\\s+', '', vlevel)
		vlevel <- strsplit(vlevel, ",")[[1]]
		vlevel <- vlevel[!is.na(vlevel) | vlevel != '']
		atLev <<- vlevel

		tkgrab.release(tt)
		tkdestroy(tt)
		tkfocus(parent.win)
	})

	tkconfigure(bt.opt.CA, command = function(){
		tkgrab.release(tt)
		tkdestroy(tt)
		tkfocus(parent.win)
	})

	tkgrid(bt.opt.OK, row = 0, column = 0, padx = 5, pady = 1, ipadx = 10, sticky = 'w')
	tkgrid(bt.opt.CA, row = 0, column = 1, padx = 5, pady = 1, ipadx = 1, sticky = 'e')

	###############################################################	

	tkgrid(frDialog, row = 0, column = 0, sticky = 'nswe', rowspan = 1, columnspan = 2, padx = 1, pady = 1, ipadx = 1, ipady = 1)
	tkgrid(frButt, row = 1, column = 1, sticky = 'se', rowspan = 1, columnspan = 1, padx = 1, pady = 1, ipadx = 1, ipady = 1)

	tkwm.withdraw(tt)
	tcl('update')
	tt.w <- as.integer(tkwinfo("reqwidth", tt))
	tt.h <- as.integer(tkwinfo("reqheight", tt))
	tt.x <- as.integer(width.scr*0.5-tt.w*0.5)
	tt.y <- as.integer(height.scr*0.5-tt.h*0.5)
	tkwm.geometry(tt, paste('+', tt.x, '+', tt.y, sep = ''))
	tkwm.transient(tt)
	tkwm.title(tt, 'Levels for map')
	tkwm.deiconify(tt)

	##################################################################	
	tkfocus(tt)
	tkbind(tt, "<Destroy>", function() {tkgrab.release(tt); tkfocus(parent.win)})
	tkwait.window(tt)
	return(atLev)
}

