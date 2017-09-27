
######Load all the functions
source(file.path(apps.dir, 'functions', 'cdtEnvir_functions.R'))

source(file.path(apps.dir, 'functions', 'cdtAccueil_functions.R'))
source(file.path(apps.dir, 'functions', 'cdtAbout_functions.R'))

source(file.path(apps.dir, 'functions', 'cdtInitialize_params_functions.R'))
source(file.path(apps.dir, 'functions', 'cdtExecute_functions.R'))

source(file.path(apps.dir, 'functions', 'cdtOpenWriteFiles_functions.R'))
source(file.path(apps.dir, 'functions', 'cdtPreview_df_functions.R'))
source(file.path(apps.dir, 'functions', 'cdtPreview_nc_functions.R'))

###
source(file.path(apps.dir, 'functions', 'cdtDistributions_functions.R'))

source(file.path(apps.dir, 'functions', 'cdtDisaggregateStnData_functions.R'))
source(file.path(apps.dir, 'functions', 'cdtClimato0_functions.R'))
source(file.path(apps.dir, 'functions', 'cdtClimato_functions.R'))

source(file.path(apps.dir, 'functions', 'cdtTables_functions.R'))
source(file.path(apps.dir, 'functions', 'cdtTabs_functions.R'))

source(file.path(apps.dir, 'functions', 'cdtPopupMenu_functions.R'))
source(file.path(apps.dir, 'functions', 'cdtOpenSave_Session_functions.R'))
source(file.path(apps.dir, 'functions', 'noteTabManup_functions.R'))

source(file.path(apps.dir, 'functions', 'ImagesZoom.R'))
source(file.path(apps.dir, 'functions', 'imageManup_functions.R'))
source(file.path(apps.dir, 'functions', 'customize_plot_functions.R'))

##
source(file.path(apps.dir, 'functions', 'qcGeneral_functions.R'))

source(file.path(apps.dir, 'functions', 'qcRR_dlgBox_functions.R'))
source(file.path(apps.dir, 'functions', 'qcRR_execute_functions.R'))
source(file.path(apps.dir, 'functions', 'qcRR_Procs_functions.R'))

source(file.path(apps.dir, 'functions', 'qcRR0Chk_dlgBox_functions.R'))
source(file.path(apps.dir, 'functions', 'qcRR0Chk_leftCmd_functions.R'))
source(file.path(apps.dir, 'functions', 'qcRR0Chk_execute_functions.R'))
source(file.path(apps.dir, 'functions', 'qcRR0Chk_Procs_functions.R'))

source(file.path(apps.dir, 'functions', 'qcTT_dlgBox_functions.R'))
source(file.path(apps.dir, 'functions', 'qcTT_execute_functions.R'))
source(file.path(apps.dir, 'functions', 'qcTT_Procs_functions.R'))

source(file.path(apps.dir, 'functions', 'homogenization_StatsTest_functions.R'))
source(file.path(apps.dir, 'functions', 'homogenization_CptDetect_functions.R'))
source(file.path(apps.dir, 'functions', 'homogenization_RefSeriesCreation_functions.R'))
source(file.path(apps.dir, 'functions', 'homogenization_dlgBox_functions.R'))
source(file.path(apps.dir, 'functions', 'homogenization_execute_functions.R'))
source(file.path(apps.dir, 'functions', 'homogenization_ProcsGAL_functions.R'))
source(file.path(apps.dir, 'functions', 'homogenization_leftCmd_functions.R'))
source(file.path(apps.dir, 'functions', 'homogenization_AdjPlot_functions.R'))
source(file.path(apps.dir, 'functions', 'homogenization_BreakPtPlot_functions.R'))

###
source(file.path(apps.dir, 'functions', 'merging_functions.R'))
source(file.path(apps.dir, 'functions', 'merging_dlgBox_functions.R'))
####

source(file.path(apps.dir, 'functions', 'merging_Scale.dlgBox_functions.R'))
source(file.path(apps.dir, 'functions', 'merging_Scale.Procs_functions.R'))

source(file.path(apps.dir, 'functions', 'Precip_merging.dlgBoxALL_functions.R'))
source(file.path(apps.dir, 'functions', 'Precip_merging.executeALL_functions.R'))

source(file.path(apps.dir, 'functions', 'Precip_merging.dlgBoxADV_functions.R'))
source(file.path(apps.dir, 'functions', 'Precip_merging.executeADV_functions.R'))

source(file.path(apps.dir, 'functions', 'Precip_merging.Bias_functions.R'))
source(file.path(apps.dir, 'functions', 'Precip_merging.LMCoef_functions.R'))
source(file.path(apps.dir, 'functions', 'Precip_merging.Merge_functions.R'))

###remove
source(file.path(apps.dir, 'functions', 'mergingRR_Procs_functions.R'))
###

source(file.path(apps.dir, 'functions', 'Temp_downscaling_dlgBox_functions.R'))
source(file.path(apps.dir, 'functions', 'Temp_downscaling_execute_functions.R'))
source(file.path(apps.dir, 'functions', 'Temp_downscaling_Procs_functions.R'))

###
source(file.path(apps.dir, 'functions', 'Temp_merging.dlgBoxALL_functions.R'))
source(file.path(apps.dir, 'functions', 'Temp_merging.executeALL_functions.R'))

source(file.path(apps.dir, 'functions', 'Temp_merging.Bias_functions.R'))
source(file.path(apps.dir, 'functions', 'Temp_merging.LMCoef_functions.R'))
source(file.path(apps.dir, 'functions', 'Temp_merging.Merge_functions.R'))

###
source(file.path(apps.dir, 'functions', 'Temp_merging.dlgBoxADV_functions.R'))
source(file.path(apps.dir, 'functions', 'Temp_merging.executeADV_functions.R'))

###remove
source(file.path(apps.dir, 'functions', 'Temp_merging_Procs_functions.R'))
###

source(file.path(apps.dir, 'functions', 'cdtFormatInputData_dlgBox_functions.R'))
source(file.path(apps.dir, 'functions', 'cdtFormatInputData_Procs_functions.R'))

source(file.path(apps.dir, 'functions', 'merge2CDTdata_leftCmd_functions.R'))
source(file.path(apps.dir, 'functions', 'merge2CDTdata_Procs_functions.R'))

source(file.path(apps.dir, 'functions', 'cdtFilterMissing_leftCmd_functions.R'))
source(file.path(apps.dir, 'functions', 'cdtFilterMissing_Procs_functions.R'))

source(file.path(apps.dir, 'functions', 'cdtAggregateOutputData_dlgBox_functions.R'))
source(file.path(apps.dir, 'functions', 'cdtAggregateOutputData_Procs_functions.R'))

####
source(file.path(apps.dir, 'functions', 'aggregateTimeSeries_dlgBox_functions.R'))
source(file.path(apps.dir, 'functions', 'aggregateTimeSeries_Procs_functions.R'))

source(file.path(apps.dir, 'functions', 'aggregateSpNcdf_dlgBox_functions.R'))
source(file.path(apps.dir, 'functions', 'aggregateSpNcdf_Procs_functions.R'))

####
source(file.path(apps.dir, 'functions', 'downloadRFE_functions.R'))
source(file.path(apps.dir, 'functions', 'downloadShapefile_functions.R'))
source(file.path(apps.dir, 'functions', 'downloadDEM_functions.R'))

source(file.path(apps.dir, 'functions', 'cdtCPT_functions.R'))

source(file.path(apps.dir, 'functions', 'extractTS_leftCmd_functions.R'))
source(file.path(apps.dir, 'functions', 'extractTS_dlgBox_functions.R'))
source(file.path(apps.dir, 'functions', 'extractTS_displayMap_functions.R'))
source(file.path(apps.dir, 'functions', 'extractTS_Procs_functions.R'))

source(file.path(apps.dir, 'functions', 'AssessDataAvail_leftCmd_functions.R'))
source(file.path(apps.dir, 'functions', 'AssessDataAvail_displayNA_functions.R'))

source(file.path(apps.dir, 'functions', 'chkCoords_dlgBox_functions.R'))
source(file.path(apps.dir, 'functions', 'chkCoords_lelfCmd_functions.R'))
source(file.path(apps.dir, 'functions', 'chkCoords_Procs_functions.R'))

source(file.path(apps.dir, 'functions', 'oneDekadMerge_dlgBox_functions.R'))
source(file.path(apps.dir, 'functions', 'oneDekadMerge_Procs_functions.R'))

####
source(file.path(apps.dir, 'functions', 'qcResults_leftCmd_functions.R'))
source(file.path(apps.dir, 'functions', 'qcResults_Manup_functions.R'))
source(file.path(apps.dir, 'functions', 'qcResults_OutliersPlot_functions.R'))
source(file.path(apps.dir, 'functions', 'qcResults_OutliersPlot2Files_functions.R'))
source(file.path(apps.dir, 'functions', 'qcResults_SpChkPlot_functions.R'))

####
source(file.path(apps.dir, 'functions', 'colorKey_functions.R'))
source(file.path(apps.dir, 'functions', 'mapLevel_functions.R'))

####
source(file.path(apps.dir, 'functions', 'plotMerging_leftCmd_functions.R'))
source(file.path(apps.dir, 'functions', 'plotMerging_displayPlot_functions.R'))

source(file.path(apps.dir, 'functions', 'plotCDTdata_leftCmd_functions.R'))
source(file.path(apps.dir, 'functions', 'plotCDTdata_displayPlot_functions.R'))

source(file.path(apps.dir, 'functions', 'plotGrdNcdf_leftCmd_functions.R'))
source(file.path(apps.dir, 'functions', 'plotGrdNcdf_displayPlot_functions.R'))

#####
source(file.path(apps.dir, 'functions', 'RHtests_leftCmd_functions.R'))
source(file.path(apps.dir, 'functions', 'RHtestsV4_User_Agreement.R'))
source(file.path(apps.dir, 'functions', 'RHtests_dataInput_functions.R'))
source(file.path(apps.dir, 'functions', 'RHtests_getData_functions.R'))
source(file.path(apps.dir, 'functions', 'RHtests_execute_functions.R'))

rhtests_files <- list.files(file.path(apps.dir, 'RHtestsV4'), full.names = TRUE)
for(fl in rhtests_files) source(fl)

#####
source(file.path(apps.dir, 'functions', 'interpol_leftCmd_functions.R'))
source(file.path(apps.dir, 'functions', 'interpol_displayVgm_functions.R'))
source(file.path(apps.dir, 'functions', 'interpol_Proc_functions.R'))

#####
source(file.path(apps.dir, 'functions', 'validation_functions.R'))
source(file.path(apps.dir, 'functions', 'validation_leftCmd_functions.R'))
source(file.path(apps.dir, 'functions', 'validation_Proc_functions.R'))
source(file.path(apps.dir, 'functions', 'validation_displayGG-Sat_functions.R'))
source(file.path(apps.dir, 'functions', 'validation_displayMap_functions.R'))
source(file.path(apps.dir, 'functions', 'mergingRR_ProcsValidation_functions.R'))

#####
source(file.path(apps.dir, 'functions', 'gapFillTemp_dlgBox_functions.R'))
source(file.path(apps.dir, 'functions', 'gapFillTemp_Procs_functions.R'))

#####
source(file.path(apps.dir, 'functions', 'cdtOnsetCessation_functions.R'))
source(file.path(apps.dir, 'functions', 'cdtAggrTSMatClimato_functions.R'))

#####
source(file.path(apps.dir, 'functions', 'climdex_functions.R'))
source(file.path(apps.dir, 'functions', 'climdex_dlgBox_functions.R'))
source(file.path(apps.dir, 'functions', 'climdexRR_leftCmd_functions.R'))
source(file.path(apps.dir, 'functions', 'climdexTT_leftCmd_functions.R'))
source(file.path(apps.dir, 'functions', 'climdexRR_Procs_functions.R'))
source(file.path(apps.dir, 'functions', 'climdexTT_Procs_functions.R'))

#####
source(file.path(apps.dir, 'functions', 'climatoAnalysis_dlgBox_functions.R'))
source(file.path(apps.dir, 'functions', 'climatoAnalysis_lelfCmd_functions.R'))
source(file.path(apps.dir, 'functions', 'climatoAnalysis_Procs_functions.R'))

#####
source(file.path(apps.dir, 'functions', 'PICSA_leftCmd_functions.R'))
source(file.path(apps.dir, 'functions', 'PICSA_dlgBox_functions.R'))
source(file.path(apps.dir, 'functions', 'PICSA_Procs_functions.R'))
source(file.path(apps.dir, 'functions', 'PICSA_Plot_functions.R'))
source(file.path(apps.dir, 'functions', 'PICSA_displayPLOT_functions.R'))
source(file.path(apps.dir, 'functions', 'SkewNormalDistribution_functions.R'))


#####
#
#source(file.path(apps.dir, 'functions', ''))
#source(file.path(apps.dir, 'functions', ''))
#source(file.path(apps.dir, 'functions', ''))
