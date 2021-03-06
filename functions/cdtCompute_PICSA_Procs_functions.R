

compute_PICSA_Procs <- function(GeneralParameters){
	if(!dir.exists(GeneralParameters$output)){
		InsertMessagesTxt(main.txt.out, paste(GeneralParameters$output, "did not find"), format = TRUE)
		return(NULL)
	}

	if(is.na(GeneralParameters$min.frac)){
		InsertMessagesTxt(main.txt.out, "Min Frac is missing", format = TRUE)
		return(NULL)
	}

	if(is.na(GeneralParameters$dryday)){
		InsertMessagesTxt(main.txt.out, "Dry day definition is missing", format = TRUE)
		return(NULL)
	}else{
		if(GeneralParameters$dryday == 0) GeneralParameters$dryday <- 0.001
	}

	##########################################

	onset <- try(readRDS(GeneralParameters$onset), silent = TRUE)
	if(inherits(onset, "try-error")){
		InsertMessagesTxt(main.txt.out, paste("Unable to read", GeneralParameters$onset), format = TRUE)
		return(NULL)
	}

	cessation <- try(readRDS(GeneralParameters$cessation), silent = TRUE)
	if(inherits(cessation, "try-error")){
		InsertMessagesTxt(main.txt.out, paste("Unable to read", GeneralParameters$cessation), format = TRUE)
		return(NULL)
	}

	if(onset$params$data.type != cessation$params$data.type){
		InsertMessagesTxt(main.txt.out, "Onset and Cessation data are of different types", format = TRUE)
		return(NULL)
	}

	##########################################

	start.mon <- as.numeric(format(onset$start.date[1], "%m"))
	start.day <- as.numeric(format(onset$start.date[1], "%d"))
	index <- get.Index.DailyYears(onset$ts.date, start.mon, start.day)

	idx.ons <- seq(nrow(index$range.date))
	idx.cess <- sapply(idx.ons, function(j){
		pos <- which(as.Date(index$range.date[j, 1], "%Y%m%d") <= cessation$start.date &
					as.Date(index$range.date[j, 2], "%Y%m%d") >= cessation$start.date)
		if(length(pos) == 0) pos <- NA
		pos
	})

	if(all(is.na(idx.cess))){
		InsertMessagesTxt(main.txt.out, "Onset and Cessation do not overlap", format = TRUE)
		return(NULL)
	}

	idx.ons <- idx.ons[!is.na(idx.cess)]
	idx.cess <- idx.cess[!is.na(idx.cess)]
	range.date <- index$range.date[idx.ons, , drop = FALSE]

	##########################################

	if(onset$params$data.type == "cdtstation"){
		if(!any(onset$data$id%in%cessation$data$id)){
			InsertMessagesTxt(main.txt.out, "Onset & Cessation stations do not match", format = TRUE)
			return(NULL)
		}

		onset.file <- file.path(dirname(GeneralParameters$onset), 'CDTDATASET', "ONSET.rds")
		cessa.file <- file.path(dirname(GeneralParameters$cessation), 'CDTDATASET', "CESSATION.rds")

		precip.file <- file.path(dirname(GeneralParameters$onset), 'CDTDATASET',"PRECIP.rds")
		# etp.file <- file.path(dirname(GeneralParameters$onset), 'CDTDATASET',"PET.rds")
		# wb.file <- file.path(dirname(GeneralParameters$cessation), 'CDTDATASET',"WB.rds")

		onset$onset <- readRDS(onset.file)
		cessation$cessation <- readRDS(cessa.file)

		onset$data$prec <- readRDS(precip.file)
		# onset$data$etp <- readRDS(etp.file)
		# cessation$data$wb <- readRDS(wb.file)

		##################
		jnx <- match(onset$data$id, cessation$data$id)
		jnx <- jnx[!is.na(jnx)]
		cessation$data$id <- cessation$data$id[jnx]

		stn.id <- cessation$data$id
		stn.lon <- cessation$data$lon[jnx]
		stn.lat <- cessation$data$lat[jnx]
		cessation$cessation <- cessation$cessation[, jnx, drop = FALSE]

		inx <- onset$data$id%in%cessation$data$id
		onset$onset <- onset$onset[, inx, drop = FALSE]

		prec <- onset$data$prec[, inx, drop = FALSE]
		daty <- onset$data$date
		# onset$data$etp <- onset$data$etp[, inx, drop = FALSE]
		# cessation$data$wb <- cessation$data$wb[, jnx, drop = FALSE]

		##################

		onset$start.date <- onset$start.date[idx.ons]
		onset$onset <- onset$onset[idx.ons, , drop = FALSE]
		cessation$cessation <- cessation$cessation[idx.cess, , drop = FALSE]
	}

	##################

	if(onset$params$data.type == "cdtdataset"){
		onset.file <- file.path(dirname(GeneralParameters$onset), "CDTDATASET", "CDTDATASET.rds")
		cessa.file <- file.path(dirname(GeneralParameters$cessation), "CDTDATASET", "CDTDATASET.rds")

		onset.index <- try(readRDS(onset.file), silent = TRUE)
		if(inherits(onset.index, "try-error")){
			InsertMessagesTxt(main.txt.out, paste("Unable to read", onset.file), format = TRUE)
			return(NULL)
		}

		cessa.index <- try(readRDS(cessa.file), silent = TRUE)
		if(inherits(cessa.index, "try-error")){
			InsertMessagesTxt(main.txt.out, paste("Unable to read", cessa.file), format = TRUE)
			return(NULL)
		}

		##################
		SP1 <- defSpatialPixels(list(lon = onset.index$coords$mat$x, lat = onset.index$coords$mat$y))
		SP2 <- defSpatialPixels(list(lon = cessa.index$coords$mat$x, lat = cessa.index$coords$mat$y))
		if(is.diffSpatialPixelsObj(SP1, SP2, tol = 1e-04)){
			InsertMessagesTxt(main.txt.out, "Onset & Cessation have different resolution or bbox", format = TRUE)
			return(NULL)
		}

		if(onset.index$chunksize != cessa.index$chunksize){
			InsertMessagesTxt(main.txt.out, "Onset & Cessation have different chunk size", format = TRUE)
			return(NULL)
		}

		##################

		prec <- try(readRDS(onset$params$cdtdataset$prec), silent = TRUE)
		if(inherits(prec, "try-error")){
			InsertMessagesTxt(main.txt.out, paste("Unable to read daily rainfall:", onset$params$cdtdataset$prec), format = TRUE)
			return(NULL)
		}

		SP3 <- defSpatialPixels(list(lon = prec$coords$mat$x, lat = prec$coords$mat$y))
		if(is.diffSpatialPixelsObj(SP1, SP3, tol = 1e-04)){
			InsertMessagesTxt(main.txt.out, "Daily rainfall, Onset & Cessation have different resolution or bbox", format = TRUE)
			return(NULL)
		}
		rm(SP2, SP3)
	}

	##########################################

	if(GeneralParameters$seastot$useTotal){
		if(GeneralParameters$seastot$data.type != onset$params$data.type){
			InsertMessagesTxt(main.txt.out, "Rainfall, Onset and Cessation data are of different types", format = TRUE)
			return(NULL)
		}

		if(GeneralParameters$seastot$data.type == "cdtstation"){
			prec1 <- getStnOpenData(GeneralParameters$seastot$cdtstation$prec)
			if(is.null(prec1)) return(NULL)
			prec1 <- getCDTdataAndDisplayMsg(prec1, GeneralParameters$seastot$Tstep)
			if(is.null(prec1)) return(NULL)

			if(!any(stn.id%in%prec1$id)){
				InsertMessagesTxt(main.txt.out, "Rainfall to be used to calculate seasonal amount and Onset stations do not match", format = TRUE)
				return(NULL)
			}

			##################
			daty1 <- prec1$dates
			## test if date intersect daty and daty1

			##################
			jnx <- match(stn.id, prec1$id)
			jnx <- jnx[!is.na(jnx)]
			prec1$id <- prec1$id[jnx]

			inx <- stn.id%in%prec1$id
			prec <- prec[, inx, drop = FALSE]
			onset$onset <- onset$onset[, inx, drop = FALSE]
			cessation$cessation <- cessation$cessation[, inx, drop = FALSE]

			stn.id <- prec1$id
			stn.lon <- prec1$lon[jnx]
			stn.lat <- prec1$lat[jnx]
			prec1 <- prec1$data[, jnx, drop = FALSE]
		}

		##################

		if(GeneralParameters$seastot$data.type == "cdtdataset"){
			prec1 <- try(readRDS(GeneralParameters$seastot$cdtdataset$prec), silent = TRUE)
			if(inherits(prec1, "try-error")){
				InsertMessagesTxt(main.txt.out, paste("Unable to read", GeneralParameters$seastot$cdtdataset$prec), format = TRUE)
				return(NULL)
			}

			SP2 <- defSpatialPixels(list(lon = prec1$coords$mat$x, lat = prec1$coords$mat$y))
			if(is.diffSpatialPixelsObj(SP1, SP2, tol = 1e-04)){
				InsertMessagesTxt(main.txt.out, "Rainfall to be used to calculate seasonal amount and Onset have different resolution or bbox", format = TRUE)
				return(NULL)
			}
			rm(SP1, SP2)

			##################
			if(onset.index$chunksize != prec1$chunksize){
				InsertMessagesTxt(main.txt.out, "Rainfall to be used to calculate seasonal amount and Onset have different chunk size", format = TRUE)
				return(NULL)
			}

			##################
			## test if date intersect prec$dateInfo$date and prec1$dateInfo$date
		}
	}

	##########################################

	if(onset$params$data.type == "cdtstation"){
		outDIR <- file.path(GeneralParameters$output, "PICSA_data")
		dir.create(outDIR, showWarnings = FALSE, recursive = TRUE)

		datadir <- file.path(outDIR, 'CDTSTATIONS')
		dir.create(datadir, showWarnings = FALSE, recursive = TRUE)

		dataOUT <- file.path(outDIR, 'CDTDATASET')
		dir.create(dataOUT, showWarnings = FALSE, recursive = TRUE)

		#########################################

		output <- list(params = GeneralParameters, data.type = onset$params$data.type,
						data = list(id = stn.id, lon = stn.lon, lat = stn.lat, date = daty),
						start.date = onset$start.date)

		EnvPICSAplot$output <- output
		EnvPICSAplot$PathPicsa <- outDIR

		saveRDS(output, gzfile(file.path(outDIR, "PICSA.rds"), compression = 7))
		saveRDS(prec, gzfile(file.path(dataOUT, 'Daily_precip.rds'), compression = 7))

		###################
		coldaty <- format(onset$start.date, "%Y%m%d")
		xhead <- rbind(stn.id, stn.lon, stn.lat)
		chead <- c('ID.STN', 'LON', 'START.DATE/LAT')
		infohead <- cbind(chead, xhead)

		#########################################

		## index season
		dimONSET <- dim(onset$onset)
		ONSET <- format(onset$onset, "%Y%m%d")
		dim(ONSET) <- dimONSET
		CESSAT <- format(cessation$cessation, "%Y%m%d")
		dim(CESSAT) <- dimONSET

		indexDaily <- lapply(seq_along(onset$start.date), function(j){
						getIndexSeasonVarsRow(ONSET[j, ], CESSAT[j, ], daty, "daily")
					})
		indexDaily <- do.call(rbind, indexDaily)

		if(GeneralParameters$seastot$useTotal){
			indexSeason <- lapply(seq_along(onset$start.date), function(j){
							getIndexSeasonVarsRow(ONSET[j, ], CESSAT[j, ], daty1, GeneralParameters$seastot$Tstep)
						})
			indexSeason <- do.call(rbind, indexSeason)
		}

		#########################################

		ONSET[is.na(ONSET)] <- -99
		ONSET <- rbind(infohead, cbind(coldaty, ONSET))
		writeFiles(ONSET, file.path(datadir, "Onset_date.csv"))
		rm(ONSET)

		CESSAT[is.na(CESSAT)] <- -99
		CESSAT <- rbind(infohead, cbind(coldaty, CESSAT))
		writeFiles(CESSAT, file.path(datadir, "Cessation_date.csv"))
		rm(CESSAT); gc()

		#########################################

		## season length
		SEASON.LENGTH <- cessation$cessation - onset$onset

		######
		saveRDS(SEASON.LENGTH, gzfile(file.path(dataOUT, 'Season_length.rds'), compression = 7))

		SEASON.LENGTH[is.na(SEASON.LENGTH)] <- -99
		SEASON.LENGTH <- rbind(infohead, cbind(coldaty, SEASON.LENGTH))
		writeFiles(SEASON.LENGTH, file.path(datadir, "Season_length.csv"))
		rm(SEASON.LENGTH)

		###################
		## season onset
		ONSET <- onset$onset - onset$start.date

		######
		saveRDS(ONSET, gzfile(file.path(dataOUT, 'Onset_days.rds'), compression = 7))

		ONSET[is.na(ONSET)] <- -99
		ONSET <- rbind(infohead, cbind(coldaty, ONSET))
		writeFiles(ONSET, file.path(datadir, "Onset_days.csv"))
		rm(ONSET)

		###################
		## season cessation
		CESSAT <- cessation$cessation - onset$start.date

		######
		saveRDS(CESSAT, gzfile(file.path(dataOUT, 'Cessation_days.rds'), compression = 7))

		CESSAT[is.na(CESSAT)] <- -99
		CESSAT <- rbind(infohead, cbind(coldaty, CESSAT))
		writeFiles(CESSAT, file.path(datadir, "Cessation_days.csv"))
		rm(CESSAT); gc()

		#########################################

		datDaily <- lapply(seq(ncol(indexDaily)), function(j){
			idx <- indexDaily[, j]
			len <- sapply(idx, length)
			out <- rep(NA, length(idx))
			rout <- as.list(out)
			ina <- sapply(seq_along(idx), function(j) len[j] == 1 | all(is.na(idx[[j]])))
			if(all(ina)) return(list(nona = out, rr = rout))
			idx <- idx[!ina]
			rr <- prec[unlist(idx), j]
			out[!ina] <- sapply(relist(is.na(rr), idx), sum)
			rout[!ina] <- relist(rr, idx)
			list(nona = 1-(out/len), rr = rout)
		})
		FracDaily <- do.call(cbind, lapply(datDaily, '[[', 'nona'))
		FracDaily[FracDaily < GeneralParameters$min.frac] <- NA
		PREC <- do.call(cbind, lapply(datDaily, '[[', 'rr'))
		PREC[is.na(FracDaily)] <- NA
		rm(datDaily, prec)

		if(GeneralParameters$seastot$useTotal){
			datSeas <- lapply(seq(ncol(indexSeason)), function(j){
				idx <- indexSeason[, j]
				len <- sapply(idx, length)
				out <- rep(NA, length(idx))
				rout <- as.list(out)
				ina <- sapply(seq_along(idx), function(j) len[j] == 1 | all(is.na(idx[[j]])))
				if(all(ina)) return(list(nona = out, rr = rout))
				idx <- idx[!ina]
				rr <- prec1[unlist(idx), j]
				out[!ina] <- sapply(relist(is.na(rr), idx), sum)
				rout[!ina] <- relist(rr, idx)
				list(nona = 1-(out/len), rr = rout)
			})
			FracSeas <- do.call(cbind, lapply(datSeas, '[[', 'nona'))
			FracSeas[FracSeas < GeneralParameters$min.frac] <- NA
			PREC1 <- do.call(cbind, lapply(datSeas, '[[', 'rr'))
			PREC1[is.na(FracSeas)] <- NA
			rm(datSeas, FracSeas, prec1)
		}

		###################

		## seasonal total
		RAINTOTAL <- sapply(if(GeneralParameters$seastot$useTotal) PREC1 else PREC, sum, na.rm = TRUE)
		dim(RAINTOTAL) <- dim(PREC)
		RAINTOTAL[is.na(FracDaily)] <- NA

		######
		saveRDS(RAINTOTAL, gzfile(file.path(dataOUT, 'Seasonal_rain_amount.rds'), compression = 7))

		RAINTOTAL[is.na(RAINTOTAL)] <- -99
		RAINTOTAL <- rbind(infohead, cbind(coldaty, RAINTOTAL))
		writeFiles(RAINTOTAL, file.path(datadir, "Seasonal_rain_amount.csv"))
		rm(RAINTOTAL); gc()

		if(GeneralParameters$seastot$useTotal) rm(PREC1)

		###################
		## number of rainy day
		NBRAINDAYS <- sapply(PREC, function(x) sum(!is.na(x) & x >= GeneralParameters$dryday))
		dim(NBRAINDAYS) <- dim(PREC)
		NBRAINDAYS[is.na(FracDaily)] <- NA

		######
		saveRDS(NBRAINDAYS, gzfile(file.path(dataOUT, 'Number_rainy_day.rds'), compression = 7))

		NBRAINDAYS[is.na(NBRAINDAYS)] <- -99
		NBRAINDAYS <- rbind(infohead, cbind(coldaty, NBRAINDAYS))
		writeFiles(NBRAINDAYS, file.path(datadir, "Number_rainy_day.csv"))
		rm(NBRAINDAYS)

		###################
		## maximum 24 hour
		RAINMAX24H <- sapply(PREC, max, na.rm = TRUE)
		dim(RAINMAX24H) <- dim(PREC)
		RAINMAX24H[is.na(FracDaily)] <- NA

		######
		saveRDS(RAINMAX24H, gzfile(file.path(dataOUT, 'Maximum_rain_daily.rds'), compression = 7))

		RAINMAX24H[is.na(RAINMAX24H)] <- -99
		RAINMAX24H <- rbind(infohead, cbind(coldaty, RAINMAX24H))
		writeFiles(RAINMAX24H, file.path(datadir, "Maximum_rain_daily.csv"))
		rm(RAINMAX24H); gc()

		###################
		## Quantile 95th, number, total
		xtmp <- lapply(seq(ncol(PREC)), function(j){
			rr <- PREC[, j]
			rrs <- unlist(rr)
			q95th <- quantile8(rrs[rrs >= GeneralParameters$dryday], probs = 0.95)
			rrs <- relist(!is.na(rrs) & rrs >= q95th, rr)
			nbQ95th <- sapply(rrs, sum)
			TotQ95th <- mapply(function(x, y) sum(x[y]), x = rr, y = rrs)
			list(q95 = q95th, nbq95 = nbQ95th, totq95 = TotQ95th)
		})

		Q95th <- round(do.call(cbind, lapply(xtmp, '[[', 'q95')), 1)
		NbQ95th <- do.call(cbind, lapply(xtmp, '[[', 'nbq95'))
		NbQ95th[is.na(FracDaily)] <- NA
		TotalQ95th <- do.call(cbind, lapply(xtmp, '[[', 'totq95'))
		TotalQ95th[is.na(FracDaily)] <- NA
		rm(xtmp)

		######
		saveRDS(Q95th, gzfile(file.path(dataOUT, 'Percentile_95th.rds'), compression = 7))

		Q95th[is.na(Q95th)] <- -99
		Q95th <- rbind(infohead, cbind("Perc95th", Q95th))
		writeFiles(Q95th, file.path(datadir, "Percentile_95th.csv"))
		rm(Q95th)

		######
		saveRDS(NbQ95th, gzfile(file.path(dataOUT, 'Number_day_above_Perc95th.rds'), compression = 7))

		NbQ95th[is.na(NbQ95th)] <- -99
		NbQ95th <- rbind(infohead, cbind(coldaty, NbQ95th))
		writeFiles(NbQ95th, file.path(datadir, "Number_day_above_Perc95th.csv"))
		rm(NbQ95th)

		######
		saveRDS(TotalQ95th, gzfile(file.path(dataOUT, 'Total_rain_above_Perc95th.rds'), compression = 7))

		TotalQ95th[is.na(TotalQ95th)] <- -99
		TotalQ95th <- rbind(infohead, cbind(coldaty, TotalQ95th))
		writeFiles(TotalQ95th, file.path(datadir, "Total_rain_above_Perc95th.csv"))
		rm(TotalQ95th); gc()

		###################
		## Dry Spell
		DRYSPELLS <- lapply(seq(ncol(PREC)), function(j){
			rr <- PREC[, j]
			rrs <- unlist(rr)
			rrs <- relist(!is.na(rrs) & rrs < GeneralParameters$dryday, rr)
			rr <- lapply(rrs, rle)
			rr <- lapply(rr, function(x) x$lengths[x$values])
			rr[sapply(rr, length) == 0] <- 0
			rr
		})
		DRYSPELLS <- do.call(cbind, DRYSPELLS)
		DRYSPELLS[is.na(FracDaily)] <- NA

		###################
		saveRDS(DRYSPELLS, gzfile(file.path(dataOUT, 'Dry_Spells.rds'), compression = 7))

		#########
		DRYSPELLmax <- sapply(DRYSPELLS, max, na.rm = TRUE)
		dim(DRYSPELLmax) <- dim(PREC)
		DRYSPELLmax[is.na(FracDaily)] <- NA

		saveRDS(DRYSPELLmax, gzfile(file.path(dataOUT, 'Longest_dry_spell.rds'), compression = 7))

		DRYSPELLmax[is.na(DRYSPELLmax)] <- -99
		DRYSPELLmax <- rbind(infohead, cbind(coldaty, DRYSPELLmax))
		writeFiles(DRYSPELLmax, file.path(datadir, "Longest_dry_spell.csv"))
		rm(DRYSPELLmax)

		#########
		DRYSPELL5 <- sapply(DRYSPELLS, function(x) sum(!is.na(x) & x >= 5))
		dim(DRYSPELL5) <- dim(PREC)
		DRYSPELL5[is.na(FracDaily)] <- NA

		DRYSPELL5[is.na(DRYSPELL5)] <- -99
		DRYSPELL5 <- rbind(infohead, cbind(coldaty, DRYSPELL5))
		writeFiles(DRYSPELL5, file.path(datadir, "Dry_Spell_5days.csv"))
		rm(DRYSPELL5)

		#########
		DRYSPELL7 <- sapply(DRYSPELLS, function(x) sum(!is.na(x) & x >= 7))
		dim(DRYSPELL7) <- dim(PREC)
		DRYSPELL7[is.na(FracDaily)] <- NA

		# saveRDS(DRYSPELL7, gzfile(file.path(dataOUT, 'Dry_Spell_7days.rds'), compression = 7))

		DRYSPELL7[is.na(DRYSPELL7)] <- -99
		DRYSPELL7 <- rbind(infohead, cbind(coldaty, DRYSPELL7))
		writeFiles(DRYSPELL7, file.path(datadir, "Dry_Spell_7days.csv"))
		rm(DRYSPELL7)

		#########
		DRYSPELL10 <- sapply(DRYSPELLS, function(x) sum(!is.na(x) & x >= 10))
		dim(DRYSPELL10) <- dim(PREC)
		DRYSPELL10[is.na(FracDaily)] <- NA

		DRYSPELL10[is.na(DRYSPELL10)] <- -99
		DRYSPELL10 <- rbind(infohead, cbind(coldaty, DRYSPELL10))
		writeFiles(DRYSPELL10, file.path(datadir, "Dry_Spell_10days.csv"))
		rm(DRYSPELL10)

		#########
		DRYSPELL15 <- sapply(DRYSPELLS, function(x) sum(!is.na(x) & x >= 15))
		dim(DRYSPELL15) <- dim(PREC)
		DRYSPELL15[is.na(FracDaily)] <- NA

		DRYSPELL15[is.na(DRYSPELL15)] <- -99
		DRYSPELL15 <- rbind(infohead, cbind(coldaty, DRYSPELL15))
		writeFiles(DRYSPELL15, file.path(datadir, "Dry_Spell_15days.csv"))
		rm(DRYSPELL15)

		rm(PREC, DRYSPELLS, FracDaily); gc()
	}

	##########################################

	if(onset$params$data.type == "cdtdataset"){
		outDIR <- file.path(GeneralParameters$output, "PICSA_data")
		dir.create(outDIR, showWarnings = FALSE, recursive = TRUE)

		ncdfOUT <- file.path(outDIR, 'DATA_NetCDF')
		dir.create(ncdfOUT, showWarnings = FALSE, recursive = TRUE)

		dataOUT <- file.path(outDIR, 'CDTDATASET')
		dir.create(dataOUT, showWarnings = FALSE, recursive = TRUE)

		datafileIdx <- file.path(dataOUT, 'CDTDATASET.rds')

		Season_length.Dir <- file.path(dataOUT, 'Season_length')
		dir.create(Season_length.Dir, showWarnings = FALSE, recursive = TRUE)
		Onset_days.Dir <- file.path(dataOUT, 'Onset_days')
		dir.create(Onset_days.Dir, showWarnings = FALSE, recursive = TRUE)
		Cessation_days.Dir <- file.path(dataOUT, 'Cessation_days')
		dir.create(Cessation_days.Dir, showWarnings = FALSE, recursive = TRUE)
		Seasonal_rain_amount.Dir <- file.path(dataOUT, 'Seasonal_rain_amount')
		dir.create(Seasonal_rain_amount.Dir, showWarnings = FALSE, recursive = TRUE)
		Number_rainy_day.Dir <- file.path(dataOUT, 'Number_rainy_day')
		dir.create(Number_rainy_day.Dir, showWarnings = FALSE, recursive = TRUE)
		Maximum_rain_daily.Dir <- file.path(dataOUT, 'Maximum_rain_daily')
		dir.create(Maximum_rain_daily.Dir, showWarnings = FALSE, recursive = TRUE)
		Percentile_95th.Dir <- file.path(dataOUT, 'Percentile_95th')
		dir.create(Percentile_95th.Dir, showWarnings = FALSE, recursive = TRUE)
		Number_day_above_Perc95th.Dir <- file.path(dataOUT, 'Number_day_above_Perc95th')
		dir.create(Number_day_above_Perc95th.Dir, showWarnings = FALSE, recursive = TRUE)
		Total_rain_above_Perc95th.Dir <- file.path(dataOUT, 'Total_rain_above_Perc95th')
		dir.create(Total_rain_above_Perc95th.Dir, showWarnings = FALSE, recursive = TRUE)
		Dry_Spells.Dir <- file.path(dataOUT, 'Dry_Spells')
		dir.create(Dry_Spells.Dir, showWarnings = FALSE, recursive = TRUE)

		#########################################

		onset$start.date <- onset$start.date[idx.ons]

		index.out <- onset.index
		index.out$varInfo$name <- "picsa"
		index.out$varInfo$units <- ""
		index.out$varInfo$longname <- "All seasonal PICSA data"

		index.out$dateInfo$date <- format(onset$start.date, "%Y%m%d")
		index.out$dateInfo$index <- seq_along(onset$start.date)

		con <- gzfile(datafileIdx, compression = 6)
		open(con, "wb")
		saveRDS(index.out, con)
		close(con)

		#################
		output <- list(params = GeneralParameters, data.type = onset$params$data.type,
						daily.precip = onset$params$cdtdataset$prec, 
						start.date = onset$start.date, range.date = range.date)

		EnvPICSAplot$output <- output
		EnvPICSAplot$PathPicsa <- outDIR

		saveRDS(output, gzfile(file.path(outDIR, "PICSA.rds"), compression = 7))

		#########################################

		chunkfile <- sort(unique(onset.index$colInfo$index))
		chunkcalc <- split(chunkfile, ceiling(chunkfile/onset.index$chunkfac))

		do.parChunk <- if(onset.index$chunkfac > length(chunkcalc)) TRUE else FALSE
		do.parCALC <- if(do.parChunk) FALSE else TRUE

		toExports <- c("readCdtDatasetChunk.sequence", "writeCdtDatasetChunk.sequence",
						"quantile8", "getIndexSeasonVarsRow", "doparallel")
		packages <- c("doParallel")

		is.parallel <- doparallel(do.parCALC & (length(chunkcalc) > 5))
		`%parLoop%` <- is.parallel$dofun
		ret <- foreach(jj = seq_along(chunkcalc), .export = toExports, .packages = packages) %parLoop% {
			ons.data <- readCdtDatasetChunk.sequence(chunkcalc[[jj]], onset.file, do.par = do.parChunk)
			ons.data <- ons.data[idx.ons, , drop = FALSE]

			cess.data <- readCdtDatasetChunk.sequence(chunkcalc[[jj]], cessa.file, do.par = do.parChunk)
			cess.data <- cess.data[idx.cess, , drop = FALSE]

			#########################################

			## index season
			dimONSET <- dim(ons.data)
			ONSET <- format(as.Date(ons.data, origin = "1970-1-1"), "%Y%m%d")
			dim(ONSET) <- dimONSET
			CESSAT <- format(as.Date(cess.data, origin = "1970-1-1"), "%Y%m%d")
			dim(CESSAT) <- dimONSET

			indexDaily <- lapply(seq_along(onset$start.date), function(j){
							getIndexSeasonVarsRow(ONSET[j, ], CESSAT[j, ], prec$dateInfo$date, "daily")
						})
			indexDaily <- do.call(rbind, indexDaily)

			if(GeneralParameters$seastot$useTotal){
				indexSeason <- lapply(seq_along(onset$start.date), function(j){
								getIndexSeasonVarsRow(ONSET[j, ], CESSAT[j, ], prec1$dateInfo$date, GeneralParameters$seastot$Tstep)
							})
				indexSeason <- do.call(rbind, indexSeason)
			}

			rm(ONSET, CESSAT); gc()

			#########################################

			## season length
			SEASON.LENGTH <- cess.data - ons.data

			######
			writeCdtDatasetChunk.sequence(SEASON.LENGTH, chunkcalc[[jj]], index.out, Season_length.Dir, do.par = do.parChunk)
			rm(SEASON.LENGTH); gc()

			###################
			## season onset
			ONSET <- ons.data - as.integer(onset$start.date)

			######
			writeCdtDatasetChunk.sequence(ONSET, chunkcalc[[jj]], index.out, Onset_days.Dir, do.par = do.parChunk)
			rm(ONSET); gc()

			###################
			## season cessation
			CESSAT <- cess.data - as.integer(onset$start.date)

			######
			writeCdtDatasetChunk.sequence(CESSAT, chunkcalc[[jj]], index.out, Cessation_days.Dir, do.par = do.parChunk)
			rm(CESSAT)

			rm(cess.data, ons.data); gc()

			#########################################

			prec.data <- readCdtDatasetChunk.sequence(chunkcalc[[jj]], onset$params$cdtdataset$prec, do.par = do.parChunk)
			prec.data <- prec.data[prec$dateInfo$index, , drop = FALSE]

			datDaily <- lapply(seq(ncol(indexDaily)), function(j){
				idx <- indexDaily[, j]
				len <- sapply(idx, length)
				out <- rep(NA, length(idx))
				rout <- as.list(out)
				ina <- sapply(seq_along(idx), function(j) len[j] == 1 | all(is.na(idx[[j]])))
				if(all(ina)) return(list(nona = out, rr = rout))
				idx <- idx[!ina]
				rr <- prec.data[unlist(idx), j]
				out[!ina] <- sapply(relist(is.na(rr), idx), sum)
				rout[!ina] <- relist(rr, idx)
				list(nona = 1-(out/len), rr = rout)
			})
			FracDaily <- do.call(cbind, lapply(datDaily, '[[', 'nona'))
			FracDaily[FracDaily < GeneralParameters$min.frac] <- NA
			PREC <- do.call(cbind, lapply(datDaily, '[[', 'rr'))
			PREC[is.na(FracDaily)] <- NA
			rm(datDaily, prec.data); gc()

			if(GeneralParameters$seastot$useTotal){
				prec1.data <- readCdtDatasetChunk.sequence(chunkcalc[[jj]], GeneralParameters$seastot$cdtdataset$prec, do.par = do.parChunk)
				prec1.data <- prec1.data[prec1$dateInfo$index, , drop = FALSE]

				datSeas <- lapply(seq(ncol(indexSeason)), function(j){
					idx <- indexSeason[, j]
					len <- sapply(idx, length)
					out <- rep(NA, length(idx))
					rout <- as.list(out)
					ina <- sapply(seq_along(idx), function(j) len[j] == 1 | all(is.na(idx[[j]])))
					if(all(ina)) return(list(nona = out, rr = rout))
					idx <- idx[!ina]
					rr <- prec1.data[unlist(idx), j]
					out[!ina] <- sapply(relist(is.na(rr), idx), sum)
					rout[!ina] <- relist(rr, idx)
					list(nona = 1-(out/len), rr = rout)
				})
				FracSeas <- do.call(cbind, lapply(datSeas, '[[', 'nona'))
				FracSeas[FracSeas < GeneralParameters$min.frac] <- NA
				PREC1 <- do.call(cbind, lapply(datSeas, '[[', 'rr'))
				PREC1[is.na(FracSeas)] <- NA
				rm(datSeas, FracSeas, prec1.data); gc()
			}

			###################

			## seasonal total
			RAINTOTAL <- sapply(if(GeneralParameters$seastot$useTotal) PREC1 else PREC, sum, na.rm = TRUE)
			dim(RAINTOTAL) <- dim(PREC)
			RAINTOTAL[is.na(FracDaily)] <- NA

			######
			writeCdtDatasetChunk.sequence(RAINTOTAL, chunkcalc[[jj]], index.out, Seasonal_rain_amount.Dir, do.par = do.parChunk)
			rm(RAINTOTAL); gc()
			if(GeneralParameters$seastot$useTotal) rm(PREC1)

			###################
			## number of rainy day
			NBRAINDAYS <- sapply(PREC, function(x) sum(!is.na(x) & x >= GeneralParameters$dryday))
			dim(NBRAINDAYS) <- dim(PREC)
			NBRAINDAYS[is.na(FracDaily)] <- NA

			######
			writeCdtDatasetChunk.sequence(NBRAINDAYS, chunkcalc[[jj]], index.out, Number_rainy_day.Dir, do.par = do.parChunk)
			rm(NBRAINDAYS); gc()

			###################
			## maximum 24 hour
			RAINMAX24H <- sapply(PREC, max, na.rm = TRUE)
			dim(RAINMAX24H) <- dim(PREC)
			RAINMAX24H[is.na(FracDaily)] <- NA

			######
			writeCdtDatasetChunk.sequence(RAINMAX24H, chunkcalc[[jj]], index.out, Maximum_rain_daily.Dir, do.par = do.parChunk)
			rm(RAINMAX24H); gc()

			###################
			## Quantile 95th, number, total
			xtmp <- lapply(seq(ncol(PREC)), function(j){
				rr <- PREC[, j]
				rrs <- unlist(rr)
				q95th <- quantile8(rrs[rrs >= GeneralParameters$dryday], probs = 0.95)
				rrs <- relist(!is.na(rrs) & rrs >= q95th, rr)
				nbQ95th <- sapply(rrs, sum)
				TotQ95th <- mapply(function(x, y) sum(x[y]), x = rr, y = rrs)
				list(q95 = q95th, nbq95 = nbQ95th, totq95 = TotQ95th)
			})

			Q95th <- round(do.call(cbind, lapply(xtmp, '[[', 'q95')), 1)
			NbQ95th <- do.call(cbind, lapply(xtmp, '[[', 'nbq95'))
			NbQ95th[is.na(FracDaily)] <- NA
			TotalQ95th <- do.call(cbind, lapply(xtmp, '[[', 'totq95'))
			TotalQ95th[is.na(FracDaily)] <- NA
			rm(xtmp); gc()

			######
			writeCdtDatasetChunk.sequence(Q95th, chunkcalc[[jj]], index.out, Percentile_95th.Dir, do.par = do.parChunk)
			rm(Q95th)

			######
			writeCdtDatasetChunk.sequence(NbQ95th, chunkcalc[[jj]], index.out, Number_day_above_Perc95th.Dir, do.par = do.parChunk)
			rm(NbQ95th); gc()

			######
			writeCdtDatasetChunk.sequence(TotalQ95th, chunkcalc[[jj]], index.out, Total_rain_above_Perc95th.Dir, do.par = do.parChunk)
			rm(TotalQ95th); gc()

			###################
			## Dry Spell
			DRYSPELLS <- lapply(seq(ncol(PREC)), function(j){
				rr <- PREC[, j]
				rrs <- unlist(rr)
				rrs <- relist(!is.na(rrs) & rrs < GeneralParameters$dryday, rr)
				rr <- lapply(rrs, rle)
				rr <- lapply(rr, function(x) x$lengths[x$values])
				rr[sapply(rr, length) == 0] <- 0
				rr
			})
			DRYSPELLS <- do.call(cbind, DRYSPELLS)
			DRYSPELLS[is.na(FracDaily)] <- NA

			#######
			writeCdtDatasetChunk.sequence(DRYSPELLS, chunkcalc[[jj]], index.out, Dry_Spells.Dir, do.par = do.parChunk)

			rm(PREC, DRYSPELLS, FracDaily); gc()

			return(0)
		}
		if(is.parallel$stop) stopCluster(is.parallel$cluster)

		rm(prec, prec1)

		##########################################

		Season_length.Nc <- file.path(ncdfOUT, 'Season_length')
		dir.create(Season_length.Nc, showWarnings = FALSE, recursive = TRUE)
		Onset_days.Nc <- file.path(ncdfOUT, 'Onset_days')
		dir.create(Onset_days.Nc, showWarnings = FALSE, recursive = TRUE)
		Cessation_days.Nc <- file.path(ncdfOUT, 'Cessation_days')
		dir.create(Cessation_days.Nc, showWarnings = FALSE, recursive = TRUE)
		Seasonal_rain_amount.Nc <- file.path(ncdfOUT, 'Seasonal_rain_amount')
		dir.create(Seasonal_rain_amount.Nc, showWarnings = FALSE, recursive = TRUE)
		Number_rainy_day.Nc <- file.path(ncdfOUT, 'Number_rainy_day')
		dir.create(Number_rainy_day.Nc, showWarnings = FALSE, recursive = TRUE)
		Maximum_rain_daily.Nc <- file.path(ncdfOUT, 'Maximum_rain_daily')
		dir.create(Maximum_rain_daily.Nc, showWarnings = FALSE, recursive = TRUE)
		Number_day_above_Perc95th.Nc <- file.path(ncdfOUT, 'Number_day_above_Perc95th')
		dir.create(Number_day_above_Perc95th.Nc, showWarnings = FALSE, recursive = TRUE)
		Total_rain_above_Perc95th.Nc <- file.path(ncdfOUT, 'Total_rain_above_Perc95th')
		dir.create(Total_rain_above_Perc95th.Nc, showWarnings = FALSE, recursive = TRUE)

		Dry_Spell_7days.Nc <- file.path(ncdfOUT, 'Dry_Spell_7days')
		dir.create(Dry_Spell_7days.Nc, showWarnings = FALSE, recursive = TRUE)
		Longest_dry_spell.Nc <- file.path(ncdfOUT, 'Longest_dry_spell')
		dir.create(Longest_dry_spell.Nc, showWarnings = FALSE, recursive = TRUE)

		Percentile_95th.Nc <- file.path(ncdfOUT, 'Percentile_95th')
		dir.create(Percentile_95th.Nc, showWarnings = FALSE, recursive = TRUE)

		##########################################

		start.date <- format(onset$start.date, "%Y%m%d")
		chunkdate <- split(start.date, ceiling(seq_along(start.date)/10))

		x <- index.out$coords$mat$x
		y <- index.out$coords$mat$y
		nx <- length(x)
		ny <- length(y)
		dx <- ncdim_def("Lon", "degreeE", x)
		dy <- ncdim_def("Lat", "degreeN", y)
		xy.dim <- list(dx, dy)

		######################
		q95 <- lapply(chunkfile, function(j){
			file.rds <- file.path(Percentile_95th.Dir, paste0(j, ".rds"))
			readRDS(file.rds)
		})
		q95 <- do.call(cbind, q95)
		q95 <- q95[, index.out$colInfo$order]
		q95[is.na(q95)] <- -99
		nc.grd <- ncvar_def("q95", "mm", xy.dim, -99, "95th percentile", "short", shuffle = TRUE, compression = 9)
		filenc <- file.path(Percentile_95th.Nc, "data_95th_perc.nc")
		nc <- nc_create(filenc, nc.grd)
		ncvar_put(nc, nc.grd, matrix(q95, nx, ny))
		nc_close(nc)

		######################
		ret <- lapply(chunkdate, function(dates){

			seasL <- readCdtDatasetChunk.sepdir.dates.order(datafileIdx, Season_length.Dir, dates)
			seasL[is.na(seasL)] <- -99
			nc.grd <- ncvar_def("seas.len", "days", xy.dim, -99, "Length of the rainy season", "short", shuffle = TRUE, compression = 9)
			for(j in seq_along(dates)){
				filenc <- file.path(Season_length.Nc, paste0("data_", dates[j], ".nc"))
				nc <- nc_create(filenc, nc.grd)
				ncvar_put(nc, nc.grd, matrix(seasL[j, ], nx, ny))
				nc_close(nc)
			}
			rm(seasL)

			onsetD <- readCdtDatasetChunk.sepdir.dates.order(datafileIdx, Onset_days.Dir, dates)
			onsetD[is.na(onsetD)] <- -99
			for(j in seq_along(dates)){
				units <- paste("days since", dates[j])
				nc.grd <- ncvar_def("onset", units, xy.dim, -99, "Starting dates of the rainy season", "short", shuffle = TRUE, compression = 9)
				filenc <- file.path(Onset_days.Nc, paste0("data_", dates[j], ".nc"))
				nc <- nc_create(filenc, nc.grd)
				ncvar_put(nc, nc.grd, matrix(onsetD[j, ], nx, ny))
				nc_close(nc)
			}
			rm(onsetD)

			cessaD <- readCdtDatasetChunk.sepdir.dates.order(datafileIdx, Cessation_days.Dir, dates)
			cessaD[is.na(cessaD)] <- -99
			for(j in seq_along(dates)){
				units <- paste("days since", dates[j])
				nc.grd <- ncvar_def("cessation", units, xy.dim, -99, "Ending dates of the rainy season", "short", shuffle = TRUE, compression = 9)
				filenc <- file.path(Cessation_days.Nc, paste0("data_", dates[j], ".nc"))
				nc <- nc_create(filenc, nc.grd)
				ncvar_put(nc, nc.grd, matrix(cessaD[j, ], nx, ny))
				nc_close(nc)
			}
			rm(cessaD)

			seasTot <- readCdtDatasetChunk.sepdir.dates.order(datafileIdx, Seasonal_rain_amount.Dir, dates)
			seasTot[is.na(seasTot)] <- -99
			nc.grd <- ncvar_def("seas.precip", "mm", xy.dim, -99, "Seasonal rainfall amounts", "short", shuffle = TRUE, compression = 9)
			for(j in seq_along(dates)){
				filenc <- file.path(Seasonal_rain_amount.Nc, paste0("data_", dates[j], ".nc"))
				nc <- nc_create(filenc, nc.grd)
				ncvar_put(nc, nc.grd, matrix(seasTot[j, ], nx, ny))
				nc_close(nc)
			}
			rm(seasTot)

			nbDay <- readCdtDatasetChunk.sepdir.dates.order(datafileIdx, Number_rainy_day.Dir, dates)
			nbDay[is.na(nbDay)] <- -99
			nc.grd <- ncvar_def("nb.rain", "days", xy.dim, -99, "Seasonal number of rainy days", "short", shuffle = TRUE, compression = 9)
			for(j in seq_along(dates)){
				filenc <- file.path(Number_rainy_day.Nc, paste0("data_", dates[j], ".nc"))
				nc <- nc_create(filenc, nc.grd)
				ncvar_put(nc, nc.grd, matrix(nbDay[j, ], nx, ny))
				nc_close(nc)
			}
			rm(nbDay)

			max24h <- readCdtDatasetChunk.sepdir.dates.order(datafileIdx, Maximum_rain_daily.Dir, dates)
			max24h[is.na(max24h)] <- -99
			nc.grd <- ncvar_def("max24h", "mm", xy.dim, -99, 'Seasonal maximum of daily rainfall', "short", shuffle = TRUE, compression = 9)
			for(j in seq_along(dates)){
				filenc <- file.path(Maximum_rain_daily.Nc, paste0("data_", dates[j], ".nc"))
				nc <- nc_create(filenc, nc.grd)
				ncvar_put(nc, nc.grd, matrix(max24h[j, ], nx, ny))
				nc_close(nc)
			}
			rm(max24h)

			nb95 <- readCdtDatasetChunk.sepdir.dates.order(datafileIdx, Number_day_above_Perc95th.Dir, dates)
			nb95[is.na(nb95)] <- -99
			nc.grd <- ncvar_def("nbq95th", "days", xy.dim, -99, 'Seasonal count of days when RR > 95th percentile', "short", shuffle = TRUE, compression = 9)
			for(j in seq_along(dates)){
				filenc <- file.path(Number_day_above_Perc95th.Nc, paste0("data_", dates[j], ".nc"))
				nc <- nc_create(filenc, nc.grd)
				ncvar_put(nc, nc.grd, matrix(nb95[j, ], nx, ny))
				nc_close(nc)
			}
			rm(nb95)

			tot95 <- readCdtDatasetChunk.sepdir.dates.order(datafileIdx, Total_rain_above_Perc95th.Dir, dates)
			tot95[is.na(tot95)] <- -99
			nc.grd <- ncvar_def("totq95th", "mm", xy.dim, -99, 'Seasonal total of precipitation when RR > 95th percentile', "short", shuffle = TRUE, compression = 9)
			for(j in seq_along(dates)){
				filenc <- file.path(Total_rain_above_Perc95th.Nc, paste0("data_", dates[j], ".nc"))
				nc <- nc_create(filenc, nc.grd)
				ncvar_put(nc, nc.grd, matrix(tot95[j, ], nx, ny))
				nc_close(nc)
			}
			rm(tot95)

			drySpell <- readCdtDatasetChunk.sepdir.dates.order(datafileIdx, Dry_Spells.Dir, dates)

			drySpell7 <- sapply(drySpell, function(x) sum(!is.na(x) & x >= 7))
			dim(drySpell7) <- dim(drySpell)
			drySpell7[is.na(drySpell7)] <- -99
			nc.drySpell7 <- ncvar_def("dryspell7", "count", xy.dim, -99, 'Number of Dry Spells greater than 7 consecutive days', "short", shuffle = TRUE, compression = 9)

			drySpellmax <- sapply(drySpell, max, na.rm = TRUE)
			dim(drySpellmax) <- dim(drySpell)
			drySpellmax[is.na(drySpellmax) | is.infinite(drySpellmax)] <- -99
			nc.drySpellmax <- ncvar_def("dryspellmax", "days", xy.dim, -99, "Longest dry spell", "short", shuffle = TRUE, compression = 9)

			for(j in seq_along(dates)){
				filenc <- file.path(Dry_Spell_7days.Nc, paste0("data_", dates[j], ".nc"))
				nc <- nc_create(filenc, nc.drySpell7)
				ncvar_put(nc, nc.drySpell7, matrix(drySpell7[j, ], nx, ny))
				nc_close(nc)

				filenc <- file.path(Longest_dry_spell.Nc, paste0("data_", dates[j], ".nc"))
				nc <- nc_create(filenc, nc.drySpellmax)
				ncvar_put(nc, nc.drySpellmax, matrix(drySpellmax[j, ], nx, ny))
				nc_close(nc)
			}

			return(0)
		})
	}


	if(GeneralParameters$plot2file & onset$params$data.type == "cdtstation"){

	}

	rm(onset, cessation)

	return(0)
}

