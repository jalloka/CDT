
FindU.wRef <- function(Bseries, Rseries, output, station, station_ref, MissingValueCode = -99, p.lev = 0.95, Iadj = 10000, Mq = 10, Ny4a = 0, GUI = F) {
    
    
    ####################################################### 
    Station <- paste("BaseSeries_", station, sep = "")
    Station_Ref <- paste("RefSeries_", station_ref, sep = "")
    
    
    # ErrorMSG<-NA assign('ErrorMSG',ErrorMSG,envir=.GlobalEnv)
    Nmin <- 5  # set global parameter of Nmin
    assign("Nmin", Nmin, envir = .GlobalEnv)
    if (Ny4a > 0 & Ny4a <= 5) 
        Ny4a <- 5
    if (!p.lev %in% c(0.75, 0.8, 0.9, 0.95, 0.99, 0.9999)) {
        InsertMessagesTxt(main.txt.out, paste("FindU: input p.lev", p.lev, "error"), format = TRUE)
        # cat(paste('FindU: input p.lev',p.lev,'error'),'\n') ErrorMSG<<-paste('FindU: input p.lev',p.lev,'error\n', get('ErrorMSG',env=.GlobalEnv),'\n') if(!GUI)
        # cat(ErrorMSG)
        return(-1)
    }
    plev <- p.lev
    pkth <- match(p.lev, c(0.75, 0.8, 0.9, 0.95, 0.99, 0.9999))
    
    Read.wRef(Bseries, Rseries, MissingValueCode)  # read in data for both base and ref series
    N <- length(Y0)
    Nadj <- Ny4a * Nt  # Y0 is Base-Ref on common period
    readPTtable(N, pkth)  # read in PTmax table
    Pk0 <- Pk.PMT(N)  # calculate penalty vector for target Y0 series
    oout <- PTK(Y0, Pk0)  # find 1st break point, then get 2 more, pick max(prob)
    # as official first break point
    I0 <- 0
    I2 <- oout$KPx
    I4 <- N
    oout1 <- PTKI0I2(Y0, I0, I2)
    I1 <- oout1$Ic
    oout2 <- PTKI0I2(Y0, I2, I4)
    I3 <- oout2$Ic
    oout3 <- PTKI0I2(Y0, I1, I3)
    I02 <- oout3$Ic
    
    prob <- PTKIc(Y0, Pk0, I02)$prob
    if (I02 > 0 & prob >= plev) {
        Ns <- 1
        Ips <- c(I02, N)
        Niter <- 0  # take cor==0, search for all possible changepoints
        tt <- TRUE
        while (tt) {
            Niter <- Niter + 1
            tt <- FALSE
            Ips0 <- NULL
            for (Iseg in 1:(Ns + 1)) {
                I0 <- if (Iseg == 1) 
                  0 else Ips[Iseg - 1]
                I2 <- Ips[Iseg]
                otmp <- PTKI0I2(Y0, I0, I2)
                if (otmp$prob > 0) 
                  Ips0 <- sort(c(Ips0, otmp$Ic))
            }
            # finished find new possible changepoints, sorted in Ips0
            tt1 <- TRUE
            while (tt1) {
                # check Ips0 and insert new break points
                if (length(Ips0) == 0) 
                  tt1 <- FALSE else {
                  PTx.mx <- (-9999)
                  PTx95.mx <- 0.001
                  prob.mx <- 0
                  for (i in 1:length(Ips0)) {
                    # search Ips0 series, find max prob
                    Ips1 <- sort(c(Ips, Ips0[i]))
                    Ic <- Ips0[i]
                    id <- match(Ic, Ips1)
                    
                    
                    ############################################ 
                    if (id == length(Ips1)) {
                      print(Ips1)
                      print(id)
                      InsertMessagesTxt(main.txt.out, "error in FindSteps", format = TRUE)
                      return(-1)
                      # stop('error in FindSteps')
                    }
                    
                    ######################################################### 
                    
                    I0 <- if (id == 1) 
                      1 else Ips1[id - 1] + 1
                    I2 <- Ips1[id + 1]
                    Ns1 <- Ns + 1
                    Nseg <- I2 - I0
                    PTx95 <- getPTx95(0, (Nseg - 1))
                    Pk1 <- Pk.PMT(Nseg)
                    otmp <- PTKIc(Y0[I0:I2], Pk1, Ic - I0 + 1)
                    if (otmp$prob < plev) 
                      Ips0[i] <- 0 else if (otmp$PTk/PTx95 > PTx.mx/PTx95.mx) {
                      PTx.mx <- otmp$PTk
                      PTx95.mx <- PTx95
                      Imx <- Ic
                      inc <- i
                      prob.mx <- otmp$prob
                    }
                  }
                  if (prob.mx >= plev) {
                    Ips <- sort(c(Ips, Imx))  # insert new point into Ips
                    Ns <- Ns + 1
                    Ips0 <- Ips0[-inc]  # exclude co-responding point in Ips0
                    tt <- TRUE
                  } else tt1 <- FALSE  # finish inserting new points into Ips
                  Ips0 <- Ips0[Ips0 != 0]
                }
            }
        }  # end of searching for all possible changepoints
    } else {
        Ns <- 0
        Ips <- N
    }
    
    Ns.initial <- Ns
    oout <- Rphi(Y0, Ips, Ns)
    cor <- oout$cor
    corL <- oout$corl
    corU <- oout$corh
    
    # find first possible changepoint
    PTx95 <- getPTx95(cor, N - 1)
    PTx95L <- getPTx95(corL, N - 1)
    PTx95U <- getPTx95(corU, N - 1)
    
    I0 <- 1
    Ic <- I02
    otmp <- PTKIc(Y0, Pk0, I02)
    
    
    ########################################################## define output file
    
    ofileIout <- paste(output, "_1Cs.txt", sep = "")
    file.create(ofileIout)
    ofileMout <- paste(output, "_mCs.txt", sep = "")
    # ofileRout<-paste(output,'_Base_Ref.fitU',sep='')
    
    ######################################################### write '_1Cs.txt'
    
    if (otmp$PTk < PTx95L) {
        # search for more changepoints
        cat(paste(Ns, "changepoints in Series", Station, paste("sample:(", sprintf("%1.0f", 1), " ", sprintf("%-4.4s", "YifD"), sprintf("%10.0f", 19000101), ")", 
            sep = ""), "\n"), file = ofileIout)
        InsertMessagesTxt(main.txt.out, paste("PMF finds no Type-1 changepoints in the series", station))
        # cat('PMT finds no Type-1 changepoints in the series!\n')
        Ns <- 0
        Ips <- N
    } else {
        # start searching for possible new breakpoints
        Ns <- 1
        Ips <- c(I02, N)  # first break point settle down, start searching for more
        tt <- TRUE
        Niter <- 0
        while (tt) {
            # condition on is there any more Bps to insert in Ips?
            Niter <- Niter + 1
            tt <- FALSE
            Ips0 <- NULL
            for (i in 1:(Ns + 1)) {
                # search for new break points
                I0 <- if (i == 1) 
                  0 else Ips[i - 1]
                I2 <- Ips[i]
                otmp <- PTKI0I2(Y0, I0, I2)
                if (otmp$prob > 0) 
                  Ips0 <- sort(c(Ips0, otmp$Ic))
            }
            # finished find new possible changepoints, stored in Ips0
            tt1 <- TRUE
            while (tt1) {
                # check Ips0 and insert new break points
                if (length(Ips0) == 0) 
                  tt1 <- FALSE else {
                  PTx.mx <- (-9999)
                  PTx95L.mx <- 0.001
                  for (i in 1:length(Ips0)) {
                    # search Ips0 series, find max prob
                    Ips1 <- sort(c(Ips, Ips0[i]))
                    Ic <- Ips0[i]
                    id <- match(Ic, Ips1)
                    
                    ############################################ 
                    
                    if (id == length(Ips1)) {
                      print(Ips1)
                      print(id)
                      InsertMessagesTxt(main.txt.out, "error in FindSteps", format = TRUE)
                      return(-1)
                      # stop('error in FindSteps')
                    }
                    
                    ############################################ 
                    
                    I0 <- if (id == 1) 
                      0 else Ips1[id - 1]
                    I2 <- Ips1[id + 1]
                    Ns1 <- Ns + 1
                    Nseg <- I2 - I0
                    Pk1 <- Pk.PMT(Nseg)
                    PTx95L <- getPTx95(corL, I2 - I0 - 1)
                    otmp <- PTKIc(Y0[(I0 + 1):I2], Pk1, Ic - I0)
                    # if(otmp$prob<plev) Ips0[i]<-0
                    if (otmp$PTk < PTx95L) 
                      Ips0[i] <- 0 else {
                      if (otmp$PTk/PTx95L > PTx.mx/PTx95L.mx) {
                        PTx.mx <- otmp$PTk
                        Imx <- Ic
                        inc <- i
                        PTx95L.mx <- PTx95L
                      }
                    }
                  }
                  if (PTx.mx >= PTx95L.mx) {
                    Ips <- sort(c(Ips, Imx))  # insert new point into Ips
                    Ns <- Ns + 1
                    Ips0 <- Ips0[-inc]  # exclude co-responding point in Ips0
                    tt <- TRUE  # continue search
                  } else tt1 <- FALSE  # finish inserting new points into Ips
                  Ips0 <- Ips0[Ips0 != 0]
                }
            }
        }  # finish search for new break points
        
        # check least significant changepoint
        tt0 <- TRUE
        tt <- TRUE
        while (tt0) {
            while (tt) {
                PTx.mn <- 9999.9
                PTx95L.mn <- 9999.9
                Imin <- 0
                if (Ns == 0) 
                  tt <- FALSE else {
                  for (i in 1:Ns) {
                    I1 <- if (i == 1) 
                      0 else Ips[i - 1]
                    I3 <- Ips[i + 1]
                    Ic <- Ips[i]
                    Nseg <- I3 - I1
                    Pk0 <- Pk.PMT(Nseg)
                    PTx95 <- getPTx95(corL, Nseg - 1)
                    otmp <- PTKIc(Y0[(I1 + 1):I3], Pk0, Ic - I1)
                    # otmp<-PTKI0I2(W,I1,I3)
                    if (otmp$PTk/PTx95 < PTx.mn/PTx95L.mn) {
                      PTx.mn <- otmp$PTk
                      PTx95L.mn <- PTx95
                      Imin <- i
                    }
                  }
                  if (Imin > 0 & PTx.mn < PTx95L.mn) {
                    Ns <- Ns - 1
                    Ips <- Ips[-Imin]
                  } else tt <- FALSE
                }
            }
            otmp <- Rphi(Y0, Ips, Ns)
            W <- otmp$W
            WL <- otmp$WL
            WU <- otmp$WU
            cor <- otmp$cor
            corl <- otmp$corl
            corh <- otmp$corh
            df <- (N - 2 - Ns)
            p.cor <- pt(abs(cor) * sqrt(df/(1 - cor^2)), df)
            if (Ns.initial > Ns) {
                Ns.initial <- Ns
                tt <- T
                corL <- corl
            } else tt0 <- FALSE
        }
        
    }
    # final output
    if (Ns > 0) {
        Nsegs <- Ips - c(0, Ips[1:Ns])
        Iseg.longest <- sort(Nsegs, index = T, decreasing = T)$ix[1]
    } else Iseg.longest <- 0
    
    if (Iadj > (Ns + 1) | Iseg.longest == 0) 
        Iseg.adj <- Ns + 1 else if (Iadj == 0) 
        Iseg.adj <- Iseg.longest else Iseg.adj <- Iadj
    
    
    #################################################### write '_Ustat.txt'
    
    
    ofileSout <- paste(output, "_Ustat.txt", sep = "")
    file.create(ofileSout)
    cat(paste("Input Base Series:", Station, "\n"), file = ofileSout)
    cat(paste("Input Ref Series:", Station_Ref, "\n"), file = ofileSout, append = T)
    
    
    #################################################### write '_1Cs.txt'
    
    if (Ns == 0) {
        cat(paste(Ns, "changepoints in Series", Station, ",", Station_Ref, paste("sample:(", sprintf("%1.0f", 1), " ", sprintf("%-4.4s", "YifD"), sprintf("%10.0f", 
            19000101), ")", sep = ""), "\n"), file = ofileIout)
        InsertMessagesTxt(main.txt.out, paste("PMT finds no Type-1 changepoints in the series", station))
        # cat('PMT finds no Type-1 changepoints in the series!\n')
    } else {
        cat(paste("The adj-diff. autocor is:", round(cor, 4), "(", round(corl, 4), ",", round(corh, 4), "p=", round(p.cor, 4), ")\n"), file = ofileSout, append = T)
        cat(paste(Ns, "changepoints in Series", Station, ",", Station_Ref, "\n"), file = ofileIout, append = T)
        for (i in 1:Ns) {
            I0 <- if (i == 1) 
                0 else Ips[i - 1]
            Ic <- Ips[i]
            I3 <- Ips[i + 1]
            Nseg <- I3 - I0
            PTx95 <- getPTx95(cor, Nseg)
            PTx95l <- getPTx95(corl, Nseg)
            PTx95h <- getPTx95(corh, Nseg)
            Pk0 <- Pk.PMT(Nseg)
            otmpW <- PTKIc(W[(I0 + 1):I3], Pk0, Ic - I0)
            otmpL <- PTKIc(WL[(I0 + 1):I3], Pk0, Ic - I0)
            otmpU <- PTKIc(WU[(I0 + 1):I3], Pk0, Ic - I0)
            probW <- otmpW$prob
            probL <- min(c(otmpL$prob, otmpU$prob))
            probU <- max(c(otmpL$prob, otmpU$prob))
            otmp <- PTKIc(Y0[(I0 + 1):I3], Pk0, Ic - I0)
            # else if(Id==1) { # type-1 changepoints
            if (otmp$PTk < PTx95l) 
                Idc <- "No  " else if (otmp$PTk >= PTx95l & otmp$PTk < PTx95h) 
                Idc <- "?   " else if (otmp$PTk >= PTx95h) 
                Idc <- "Yes "
            # }
            
            
            #################################################### write '_1Cs.txt'
            
            
            cat(paste(sprintf("%1.0f", 1), " ", sprintf("%-4.4s", Idc), sprintf("%10.0f", IY0[Ic]), " (", sprintf("%6.4f", probL), "-", sprintf("%6.4f", probU), 
                ")", sprintf("%6.3f", plev), sprintf("%10.4f", otmp$PTk), " (", sprintf("%10.4f", PTx95l), "-", sprintf("%10.4f", PTx95h), ")\n", sep = ""), file = ofileIout, 
                append = TRUE)
            
            
            #################################################### write '_Ustat.txt'
            
            cat(paste("PMT : c=", sprintf("%4.0f", Ic), "; (Time ", sprintf("%10.0f", IY0[Ic]), "); Type= 1; p=", sprintf("%10.4f", probW), "(", sprintf("%6.4f", 
                probL), "-", sprintf("%6.4f", probU), ")", "; PTmax=", sprintf("%10.4f", otmp$PTk), "; CV95=", sprintf("%10.4f", PTx95), "(", sprintf("%10.4f", PTx95l), 
                "-", sprintf("%10.4f", PTx95h), "); Nseg=", sprintf("%4.0f", Nseg), "\n", sep = ""), file = ofileSout, append = TRUE)
        }
    }
    
    # estimate delta from Y0 (Base-Ref)
    otmp <- Rphi(Y0, Ips, Ns)
    cor <- otmp$cor
    muDif <- rep(0, Ns + 1)
    Ro <- Y0
    Wo <- Y0
    omuDif <- Y0
    oY0 <- Y0
    for (i in 1:(Ns + 1)) {
        I0 <- if (i == 1) 
            1 else Ips[i - 1] + 1
        I2 <- if (i > Ns) 
            length(Y0) else Ips[i]
        muDif[i] <- mean(Y0[I0:I2])
        omuDif[I0:I2] <- muDif[i]
        Ro[I0:I2] <- Y0[I0:I2] - muDif[i]
    }
    Wo[1] <- Ro[1]
    Wo[2:N] <- Ro[2:N] - cor * Ro[1:(N - 1)] * IY0flg[1:(N - 1)]  # use IY0flg to identify
    # missing date, this is same as -- if missing Ro else Ro-cor*Ro[n-1] write.table(cbind(IY0,round(oY0,4),round(omuDif,4),round(Wo,4)),
    # file=ofileRout,col.names=F,row.names=F)
    
    # start fitting de-seasonalized Base series
    
    # transfer Ips(Base-Ref) to Ips(Base)
    Ips0 <- Ips
    IY1 <- bdata[, 1] * 10000 + bdata[, 2] * 100 + bdata[, 3]
    IYM <- bdata[, 2] * 100 + bdata[, 3]
    inds <- sort(unique(IYM))
    rtmp <- cbind(1:length(IY1), IY1)
    Ips <- merge(IY0[Ips0], rtmp, by.x = 1, by.y = "IY1")[, 2]
    Ips[Ns + 1] <- length(IY1)
    
    Ti <- TiB
    assign("Ti", Ti, envir = .GlobalEnv)
    IY0flg <- IYBflg
    assign("IY0flg", IY0flg, envir = .GlobalEnv)
    
    dtmp <- rmCycle(bdata)
    adjBase <- dtmp$Base
    EB <- rep(0, length(IY1))
    for (i in 1:length(IY1)) EB[i] <- dtmp$EB[inds == IYM[i]]
    N <- length(adjBase)
    for (i in 1:(Ns + 1)) {
        I0 <- if (i == 1) 
            1 else Ips[i - 1] + 1
        I2 <- if (i > Ns) 
            N else Ips[i]
        DeltaD <- muDif[i] - muDif[Iseg.adj]
        adjBase[I0:I2] <- adjBase[I0:I2] + EB[I0:I2] - DeltaD  # adjBase is base series adj to last seg
    }
    EPBa <- mean(adjBase)
    
    Ydata <- cbind(bdata[, 1:3], adjBase)
    dtmp <- rmCycle(Ydata)  # adjusted and de-seasonalized Base series
    EB0 <- dtmp$EB
    EEBd <- mean(EB0)
    EB <- rep(0, length(IY1))
    for (i in 1:length(IY1)) EB[i] <- dtmp$EB[inds == IYM[i]]
    Aadj <- dtmp$Base  # de-seasonalize Badj
    Ipd <- c(N)
    dtmp <- LSmultipleRed(Aadj, Ti, Ipd)
    # muD<-dtmp$mu[1]+EPBa-mean(bdata[,4])
    muD <- dtmp$mu[1]
    betaD <- dtmp$trend
    betaDL <- dtmp$betaL
    betaDU <- dtmp$betaU
    corD <- dtmp$cor
    corDL <- dtmp$corl
    corDU <- dtmp$corh
    p.trD <- dtmp$p.tr
    
    dtmp <- rmCycle(bdata)  # de-seasonalized Base series
    tbase <- dtmp$Base
    Ipd <- length(tbase)
    dtmp <- LSmultipleRed(tbase, Ti, Ipd)
    beta0 <- dtmp$trend
    meanhat0 <- dtmp$meanhat
    Ehat0 <- mean(meanhat0)
    
    
    
    #################################################### write '_Ustat.txt'
    
    cat(paste("Ignore changepoints -> trend0 =", round(beta0, 6), "(", round(dtmp$betaL, 6), ",", round(dtmp$betaU, 6), ")", "(p=", round(dtmp$p.tr, 4), "); cor=", 
        round(dtmp$cor, 4), "(", round(dtmp$corl, 4), ",", round(dtmp$corh, 4), ")\n\n"), file = ofileSout, append = TRUE)
    cat("Step-sizes estimated from difference series:\n", file = ofileSout, append = TRUE)
    cat(round(muDif[2:(Ns + 1)] - muDif[1:Ns], 4), file = ofileSout, append = TRUE, fill = 80)
    cat(paste("\n after such adjustments, the base series trend=", round(betaD, 6), "(", round(betaDL, 6), ",", round(betaDU, 6), ") (p=", round(p.trD, 4), "); cor=", 
        round(corD, 3), "(", round(corDL, 3), ",", round(corDU, 3), ")\n\n"), file = ofileSout, append = TRUE)
    
    
    
    otmp <- rmCycle(bdata)
    EB <- rep(0, length(IY1))
    for (i in 1:length(IY1)) EB[i] <- otmp$EB[inds == IYM[i]]
    Base <- otmp$Base
    EPB <- mean(bdata[, "data"], na.rm = T)
    tt <- TRUE
    Niter <- 0
    while (tt) {
        Niter <- Niter + 1
        EB00 <- EB
        otmp <- LSmultipleRed(Base, Ti, Ips)
        meanhat <- otmp$meanhat
        df <- (N - 2 - Nt - Ns)
        p.cor <- pt(abs(otmp$cor) * sqrt(df/(1 - otmp$cor^2)), df)
        corout <- c(otmp$cor, otmp$corl, otmp$corh, p.cor)
        sig <- otmp$sig
        p.tro <- otmp$p.tr
        for (i in 1:(Ns + 1)) {
            I0 <- if (i == 1) 
                1 else Ips[i - 1] + 1
            I2 <- if (i > Ns) 
                length(Base) else Ips[i]
            Delta <- sig[i + 1] - sig[Iseg.adj + 1]
            Base[I0:I2] <- Base[I0:I2] + EB00[I0:I2] - Delta
        }
        # re-estimate seasonal cycle using adjusted series:
        EB1 <- rep(0, length(inds))
        for (i in 1:length(inds)) EB1[i] <- mean(Base[IYM == inds[i]], na.rm = T)
        for (i in 1:length(IY1)) EB[i] <- EB1[inds == IYM[i]]
        for (i in 1:(Ns + 1)) {
            I0 <- if (i == 1) 
                1 else Ips[i - 1] + 1
            I2 <- if (i > Ns) 
                length(Base) else Ips[i]
            Delta <- sig[i + 1] - sig[Iseg.adj + 1]
            Base[I0:I2] <- Base[I0:I2] - EB[I0:I2] + Delta
        }
        VEB <- sqrt(var(EB1))
        if (is.na(VEB)) 
            tt <- FALSE else {
            if (max(abs(EB0 - EB1)) < VEB/1000 | Niter > 50) 
                tt <- FALSE
        }
        EB0 <- EB1
    }
    Ehat <- mean(meanhat)
    meanhat0 <- meanhat0 - Ehat0 + Ehat
    Ro <- Base - meanhat
    Ro[2:N] <- Ro[2:N] - corout[1] * Ro[1:(N - 1)]
    
    if (Ns > 0) {
        # Rb<-Base-otmp$trend*Ti+EB
        QMout <- QMadjGaussian.wRef(bdata[, 4], bdata[, 4] - bdata[, 5], Ips, Mq, Iseg.adj, Nadj, Nt, Ny4a)
        B <- QMout$PA
        
        
        #################################################### write '_Ustat.txt'
        
        
        cat(paste("Nseg_shortest =", QMout$Nseg.mn, "; Mq = ", QMout$Mq, "; Ny4a = ", Ny4a, "\n"), file = ofileSout, append = T)
        cat(paste("\n Adjust to segment", Iseg.adj, ": from", if (Iseg.adj == 1) 
            1 else Ips[Iseg.adj - 1] + 1, "to", Ips[Iseg.adj], "\n"), file = ofileSout, append = T)
        # cat('#Fcat, DP (CDF and Differnces in category mean)\n',file=ofileSout, append=T)
        oline <- paste("#Fcat: frequency category boundaries\n", "#DP: Difference in the category means\n#", sep = "")
        for (i in 1:Ns) oline <- paste(oline, paste("Fcat.Seg", i, sep = ""), paste("DP.Seg", i, sep = ""))
        oline <- paste(oline, "\n")
        cat(oline, file = ofileSout, append = T)
        
        write.table(round(QMout$osmean, 4), file = ofileSout, append = T, row.names = F, col.names = F)
        
        
        for (i in 1:(Ns + 1)) {
            I1 <- if (i == 1) 
                1 else Ips[i - 1] + 1
            I2 <- Ips[i]
            if (i != Iseg.adj) 
                cat(paste("Seg. ", i, ": mean of QM-adjustments =", round(QMout$AdjM[i], 4), "\n", sep = ""), file = ofileSout, append = T)
        }
    } else B <- Base
    # else B<-Base-otmp$trend*Ti+EB B<-B+otmp$trend*Ti
    
    ##################################################################################### 
    
    ofileAout <- paste(output, "_U.dat", sep = "")
    ofilePdf <- paste(output, "_U.pdf", sep = "")
    file.create(ofileAout)
    file.create(ofilePdf)
    
    
    
    ##################################################################################### PLOT
    
    pdf(file = ofilePdf, onefile = T)
    op <- par(no.readonly = TRUE)  # the whole list of settable par's.
    par(mfrow = c(3, 1))
    par(mar = c(3, 4, 3, 2) + 0.1, cex.main = 0.8, cex.lab = 0.8, cex.axis = 0.8, cex = 0.8)
    
    uyrs <- unique(floor(ori.bdata[, 1]/5)) * 5
    labels <- NULL
    ats <- NULL
    for (i in 1:length(uyrs)) {
        if (!is.na(match(uyrs[i], ori.bdata[, 1]))) {
            labels <- c(labels, uyrs[i])
            ats <- c(ats, match(uyrs[i], ori.bdata[, 1]))
        }
    }
    
    IY1 <- bdata[, 1] * 10000 + bdata[, 2] * 100 + bdata[, 3]
    adj <- Base + EB
    adjB <- Base + EB
    meanhatD <- rep(0, N)
    if (Ns > 0) 
        for (i in 1:(Ns + 1)) {
            I1 <- if (i == 1) 
                1 else Ips[i - 1] + 1
            I2 <- Ips[i]
            Delta <- sig[Iseg.adj + 1] - sig[i + 1]
            DeltaD <- muDif[Iseg.adj] - muDif[i]
            adj[I1:I2] <- adj[I1:I2] + Delta
            adjB[I1:I2] <- adjB[I1:I2] + DeltaD
            meanhatD[I1:I2] <- EEBd + muD + betaD * Ti[I1:I2] - DeltaD
        } else meanhatD <- EEBd + muD + betaD * Ti
    
    IYori <- ori.bdata[, 1] * 10000 + ori.bdata[, 2] * 100 + ori.bdata[, 3]
    rtmp <- cbind(IY0, oY0, omuDif)
    stmp <- merge(rtmp, t(t(IYori)), all.y = TRUE, by.x = "IY0", by.y = 1)
    pdata <- stmp[, 2]
    
    plot(1:dim(ori.bdata)[1], pdata, type = "l", xlab = "", ylab = "", ylim = c(min(oY0), max(oY0)), xaxt = "n", col = "black", lwd = 0.5, main = "a. Base-minus-reference series")
    axis(side = 1, at = ats, labels = labels)
    
    pdata <- stmp[, 3]
    lines(1:dim(ori.bdata)[1], pdata, col = "red")
    
    pdata[owflg] <- Base
    plot(1:dim(ori.bdata)[1], pdata, type = "l", xlab = "", ylab = "", ylim = c(min(Base, otmp$meanhat), max(Base, otmp$meanhat)), xaxt = "n", col = "black", lwd = 0.5, 
        main = "b. De-seasonalized base series")
    axis(side = 1, at = ats, labels = labels)
    pdata[owflg] <- otmp$meanhat
    lines(1:dim(ori.bdata)[1], pdata, col = "red")
    
    pdata[owflg] <- Base + EB
    plot(1:dim(ori.bdata)[1], pdata, type = "l", xlab = "", ylab = "", ylim = c(min(Base + EB), max(Base + EB)), xaxt = "n", col = "black", lwd = 0.5, main = "c. Base series")
    axis(side = 1, at = ats, labels = labels)
    pdata[owflg] <- otmp$meanhat + mean(EB1)
    lines(1:dim(ori.bdata)[1], pdata, col = "red")
    pdata[owflg] <- meanhatD
    lines(1:dim(ori.bdata)[1], pdata, col = "blue")
    
    xr <- dim(ori.bdata)[1] * 0.1
    yrr <- mean((Base + EB)[1:xr])
    if (abs(yrr - max(Base + EB)) < abs(yrr - min(Base + EB))) {
        yrr1 <- min(Base + EB) + 0.2 * (max(Base + EB) - min(Base + EB))
        yrr2 <- min(Base + EB) + 0.05 * (max(Base + EB) - min(Base + EB))
    } else {
        yrr1 <- max(Base + EB) - 0.05 * (max(Base + EB) - min(Base + EB))
        yrr2 <- max(Base + EB) - 0.2 * (max(Base + EB) - min(Base + EB))
    }
    text(2, yrr1, "Adjustments estimated from Base", adj = 0, cex = 0.8)
    lines(dim(ori.bdata)[1] * c(0.31, 0.33), rep(yrr1, 2), col = "red")
    text(2, yrr2, "Adjustments estimated from Diff", adj = 0, cex = 0.8)
    lines(dim(ori.bdata)[1] * c(0.31, 0.33), rep(yrr2, 2), col = "blue")
    
    pdata[owflg] <- adj
    plot(1:dim(ori.bdata)[1], pdata, type = "l", xlab = "", ylab = "", ylim = c(min(c(adj, B)), max(c(adj, B))), xaxt = "n", col = "black", lwd = 0.5, main = "d. Mean-adjusted base series")
    axis(side = 1, at = ats, labels = labels)
    pdata[owflg] <- adjB
    lines(1:dim(ori.bdata)[1], pdata, col = "red", lwd = 0.5)
    
    xr <- dim(ori.bdata)[1] * 0.1
    yrr <- mean(adj[1:xr])
    if (abs(yrr - max(c(adj, B))) < abs(yrr - min(c(adj, B)))) {
        yrr1 <- min(c(adj, B)) + 0.2 * (max(c(adj, B)) - min(c(adj, B)))
        yrr2 <- min(c(adj, B)) + 0.05 * (max(c(adj, B)) - min(c(adj, B)))
    } else {
        yrr1 <- max(c(adj, B)) - 0.05 * (max(c(adj, B)) - min(c(adj, B)))
        yrr2 <- max(c(adj, B)) - 0.2 * (max(c(adj, B)) - min(c(adj, B)))
    }
    text(2, yrr1, "Adjustments estimated from Base", adj = 0, cex = 0.8)
    lines(dim(ori.bdata)[1] * c(0.31, 0.33), rep(yrr1, 2), col = "black")
    text(2, yrr2, "Adjustments estimated from Diff", adj = 0, cex = 0.8)
    lines(dim(ori.bdata)[1] * c(0.31, 0.33), rep(yrr2, 2), col = "red")
    
    pdata[owflg] <- B
    plot(1:dim(ori.bdata)[1], pdata, type = "l", xlab = "", ylab = "", ylim = c(min(c(adj, B)), max(c(adj, B))), xaxt = "n", col = "black", lwd = 0.5, main = "e. QM-adjusted base series")
    axis(side = 1, at = ats, labels = labels)
    
    # test plot
    if (Ns > 0) {
        par(mar = c(4, 5, 3, 2) + 0.1, cex = 0.8, mfrow = c(2, 2), mgp = c(1.2, 0.5, 0))
        col <- 0
        np <- 0
        osp <- QMout$osp
        osmean <- QMout$osmean
        for (i in 1:(Ns + 1)) {
            Fd <- 0.5/QMout$Mq
            I1 <- if (i == 1) 1 else Ips[i - 1] + 1
            I2 <- Ips[i]

            ## nampiana
            I1 <- which(osp[, 1] == I1)
            I2 <- which(osp[, 1] == I2)

            ymax <- max(osp[, 2:3], na.rm = T)
            ymin <- min(osp[, 2:3], na.rm = T)
            if (i != Iseg.adj) {
                np <- np + 1
                if (col == 0) {
                  col <- 2
                  plot(osp[I1:I2, 2], osp[I1:I2, 3], xlim = c(0, 1), ylim = c(ymin, ymax), type = "l", lwd = 1, col = col, xlab = "Cumulative Frequency", ylab = "QM Adjustment")
                  title(cex.main = 0.9, main = paste("distribution of QM adjustments with Mq=", QMout$Mq), line = 0.5)
                  icol <- 2 * np
                  for (j in 1:QMout$Mq) {
                    lines(c(osmean[(j + 1), icol] - Fd, osmean[(j + 1), icol] + Fd), c(rep(osmean[(j + 1), (icol + 1)], 2)), col = col, lty = 2, lwd = 0.5)
                    if (j >= 1 & j < QMout$Mq) 
                      lines(rep(osmean[(j + 1), icol] + Fd, 2), c(osmean[(j + 1), (icol + 1)], osmean[(j + 2), (icol + 1)]), col = col, lty = 2, lwd = 0.5)
                  }
                } else {
                  col <- col + 1
                  lines(osp[I1:I2, 2], osp[I1:I2, 3], lwd = 1, col = col)
                  icol <- 2 * np
                  for (j in 1:QMout$Mq) {
                    lines(c(osmean[(j + 1), icol] - Fd, osmean[(j + 1), icol] + Fd), c(rep(osmean[(j + 1), (icol + 1)], 2)), col = col, lty = 2, lwd = 0.5)
                    if (j >= 1 & j < QMout$Mq) 
                      lines(rep(osmean[(j + 1), icol] + Fd, 2), c(osmean[(j + 1), (icol + 1)], osmean[(j + 2), (icol + 1)]), col = col, lty = 2, lwd = 0.5)
                  }
                }
                text(0.15, ymax - np * (ymax - ymin)/(Ns * 3), paste("Seg.", i))
                lines(c(0.25, 0.3), rep(ymax - np * (ymax - ymin)/(Ns * 3), 2), lwd = 2, col = col)
            } else np <- np + 1
        }
    }
    
    par(op)
    dev.off()
    
    
    #################################################### write '_Ustat.txt'
    
    
    cat("Common trend TPR fit to the de-seasonalized Base series:\n", file = ofileSout, append = TRUE)
    cat(paste("#steps= ", Ns, "; trend=", round(sig[2], 6), "(p=", round(p.tro, 4), "); cor=", round(corout[1], 4), "(", round(corout[2], 4), ",", round(corout[3], 
        4), ")  p=", round(corout[4], 4), "\n"), file = ofileSout, append = TRUE)
    oout <- NULL
    for (i in 1:Ns) {
        stepsize <- if (i == 1) 
            sig[i + 2] else sig[i + 2] - sig[i + 1]
        oout <- c(oout, stepsize)
    }
    cat(round(oout, 4), file = ofileSout, append = TRUE, fill = 80)
    
    
    
    odata <- matrix(NA, dim(ori.bdata)[1], 12)
    odata[owflg, 1] <- Ti
    odata[, 2] <- ori.bdata[, 1] * 10000 + ori.bdata[, 2] * 100 + ori.bdata[, 3]
    # odata[owflg,3]<-round(Base+EB,4)
    odata[, 3] <- ori.bdata[, 4]
    odata[owflg, 4] <- round(meanhatD, 4)
    odata[owflg, 5] <- round(adjB, 4)
    odata[owflg, 6] <- round(otmp$meanhat + mean(EB1), 4)
    odata[owflg, 7] <- round(adj, 4)
    odata[owflg, 8] <- round(Base, 4)
    odata[owflg, 9] <- round(otmp$meanhat, 4)
    odata[owflg, 10] <- round(otmp$meanhat + EB, 4)
    # odata[owflg,11]<-round(Ro,4)
    odata[owflg, 11] <- round(B, 4)
    odata[owflg, 12] <- round(meanhat0, 4)
    
    Imd1 <- ori.bdata[, 2] * 100 + ori.bdata[, 3]
    if (sum(is.na(ori.bdata[, 4]) == F & Imd1 == 229) > 0) {
        if (Ns > 0) {
            tdata <- ori.bdata[is.na(ori.bdata[, 4]) == F, ]
            IY1 <- tdata[, 1] * 10000 + tdata[, 2] * 100 + tdata[, 3]
            Ips.ymd <- IY0[Ips]
            Ips.1 <- rep(NA, Ns + 1)
            for (i in 1:Ns) Ips.1[i] <- c(1:length(IY1))[IY1 == Ips.ymd[i]]
            Ips.1[Ns + 1] <- length(IY1)
            # Ips.1<-c(1:length(IY1))[Ips.ymd==IY1]
            Imd2 <- tdata[, 2] * 100 + tdata[, 3]
            Ids.leap <- c(1:length(Imd2))[Imd2 == 229]
            Nl <- length(Ids.leap)
            Rb <- Base - otmp$trend * Ti + EB
            Rb1 <- tdata[, 4]
            Rb1[-Ids.leap] <- Rb
            Ti1 <- rep(NA, length(IY1))
            Ti1[-Ids.leap] <- Ti
            for (i in 1:length(Ids.leap)) {
                Rb1[Ids.leap[i]] <- tdata[Ids.leap[i], 4] + Rb1[Ids.leap[i] - 1] - tdata[Ids.leap[i] - 1, 4]
                Ti1[Ids.leap[i]] <- Ti1[Ids.leap[i] - 1]
            }
            B1 <- QMadjGaussian(Rb1, Ips.1, Mq, Iseg.adj, Nadj)$PA
            B1 <- B1 + otmp$trend * Ti1
            B1.leap <- B1[Ids.leap]
            odata[is.na(odata[, 3]) == F & Imd1 == 229, 11] <- round(B1.leap, 4)
        } else odata[Imd1 == 229, 11] <- odata[Imd1 == 229, 3]
        Ids.leapo <- c(1:dim(ori.bdata)[1])[is.na(ori.bdata[, 4]) == F & Imd1 == 229]
        for (jth in 1:length(Ids.leapo)) {
            kth <- Ids.leapo[jth]
            if (Ns > 0) {
                k1th <- if (odata[kth - 1, 2] %in% IY0[Ips]) 
                  (kth + 1) else (kth - 1)
            } else k1th <- kth - 1
            for (pth in c(4, 6, 9, 10, 12)) odata[kth, pth] <- odata[k1th, pth]
            for (pth in c(5, 7, 8)) {
                delta1 <- odata[k1th, 3] - odata[k1th, pth]
                odata[kth, pth] <- odata[kth, 3] - delta1
            }
        }
    }
    
    #################################################### write data *_U.dat
    
    write.table(file = ofileAout, odata, col.names = F, row.names = F, na = as.character(MissingValueCode))
    
    
    
    #################################################### 
    
    if (GUI) 
        return(0) else {
        file.copy(from = ofileIout, to = ofileMout, overwrite = TRUE)
        # cat('FindU.wRef finished successfully...\n')
        InsertMessagesTxt(main.txt.out, paste("FindU.wRef finished successfully for", station))
        return(0)
    }
}

