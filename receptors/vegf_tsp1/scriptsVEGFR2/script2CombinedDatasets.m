
%% minus VEGF, minus AAL

condNameMM = {...
'mVEGF_mAAL_HMVEC_141028',...
'mVEGF_mAAL_HMVEC_141030',...
'mVEGF_mAAL_HMVEC_141031',...
'mVEGF_mAAL_HMVEC_150224',...
'mVEGF_mAAL_HMVEC_150302',...
};

condFileMM = {...
    ['/project/biophysics/jaqaman_lab/vegf_tsp1/slee/VEGFR2/2014/20141028_HMVECp6-R2-488/analysisKJ/resSummary_' condNameMM{1} '.mat'],...
    ['/project/biophysics/jaqaman_lab/vegf_tsp1/slee/VEGFR2/2014/20141030_HMVECp7_R2_1ugML-AF488/analysisKJ/resSummary_' condNameMM{2} '.mat'],...
    ['/project/biophysics/jaqaman_lab/vegf_tsp1/slee/VEGFR2/2014/20141031_HMVECp7-R2_half-ugML-488_original/analysisKJ/resSummary_' condNameMM{3} '.mat'],...
    ['/project/biophysics/jaqaman_lab/vegf_tsp1/slee/VEGFR2/2015/20150224_HMVECp6_VEGF/analysisKJ/resSummary_' condNameMM{4} '.mat'],...
    ['/project/biophysics/jaqaman_lab/vegf_tsp1/slee/VEGFR2/2015/20150302_HMVECp6_VEGF/analysisKJ/resSummary_' condNameMM{5} '.mat'],...
    };

%% minus VEGF, plus AAL

condNameMP = {...
    'mVEGF_pAAL_HMVEC_150225',...
    'mVEGF_pAAL_HMVEC_150303',...
    };

condFileMP = {...
    ['/project/biophysics/jaqaman_lab/vegf_tsp1/slee/VEGFR2/2015/20150225_HMVECp6_AAL_VEGF/analysisKJ/resSummary_' condNameMP{1} '.mat'],...
    ['/project/biophysics/jaqaman_lab/vegf_tsp1/slee/VEGFR2/2015/20150303_HMVECp6_AAL/analysisKJ/resSummary_' condNameMP{2} '.mat'],...
    };

%% plus VEGF, minus AAL

condNamePM = {...
    'pVEGF_mAAL_HMVEC_141030',...
    'pVEGF_mAAL_HMVEC_141031',...
    'pVEGF_mAAL_HMVEC_150129',...
    'pVEGF_mAAL_HMVEC_150224',...
    'pVEGF_mAAL_HMVEC_150302',...
    };

%     'pVEGF_mAAL_HMVEC_150128',... VEGF ADDED AROUND 30 MIN, MUCH LATER THAN ALL OTHER DATASETS, THUS DO NOT USE

condFilePM = {...
    ['/project/biophysics/jaqaman_lab/vegf_tsp1/slee/VEGFR2/2014/20141030_HMVECp7_R2_1ugML-AF488/analysisKJ/resSummary_' condNamePM{1} '.mat'],...
    ['/project/biophysics/jaqaman_lab/vegf_tsp1/slee/VEGFR2/2014/20141031_HMVECp7-R2_half-ugML-488_original/analysisKJ/resSummary_' condNamePM{2} '.mat'],...
    ['/project/biophysics/jaqaman_lab/vegf_tsp1/slee/VEGFR2/2015/20150129_HMVECp6_EICFab0.2ug/analysisKJ/resSummary_' condNamePM{3} '.mat'],...
    ['/project/biophysics/jaqaman_lab/vegf_tsp1/slee/VEGFR2/2015/20150224_HMVECp6_VEGF/analysisKJ/resSummary_' condNamePM{4} '.mat'],...
    ['/project/biophysics/jaqaman_lab/vegf_tsp1/slee/VEGFR2/2015/20150302_HMVECp6_VEGF/analysisKJ/resSummary_' condNamePM{5} '.mat'],...
    };


%% plus VEGF, plus AAL

condNamePP = {...
    'pVEGF_pAAL_HMVEC_150128',...
    'pVEGF_pAAL_HMVEC_150129',...
    'pVEGF_pAAL_HMVEC_150225',...
    'pVEGF_pAAL_HMVEC_150303',...
    };

condFilePP = {...
    ['/project/biophysics/jaqaman_lab/vegf_tsp1/slee/VEGFR2/2015/20150128_NGSBlockedHMVECp6_EIC1ug_FabAF488/analysisKJ/resSummary_' condNamePP{1} '.mat'],...
    ['/project/biophysics/jaqaman_lab/vegf_tsp1/slee/VEGFR2/2015/20150129_HMVECp6_EICFab0.2ug/analysisKJ/resSummary_' condNamePP{2} '.mat'],...
    ['/project/biophysics/jaqaman_lab/vegf_tsp1/slee/VEGFR2/2015/20150225_HMVECp6_AAL_VEGF/analysisKJ/resSummary_' condNamePP{3} '.mat'],...
    ['/project/biophysics/jaqaman_lab/vegf_tsp1/slee/VEGFR2/2015/20150303_HMVECp6_AAL/analysisKJ/resSummary_' condNamePP{4} '.mat'],...
    };

%% Combine results

timeListComb_mVEGF = [0 5 10 20 30 40 50 60]';
timeListComb_pVEGF = [-10 -5 0 5 10 20 30 40 50 60]';

[resSummaryCombMM,resSummaryIndMM] = resultsCombTimeCourse(condNameMM,condFileMM,timeListComb_mVEGF,'abs');
[resSummaryCombMP,resSummaryIndMP] = resultsCombTimeCourse(condNameMP,condFileMP,timeListComb_mVEGF,'abs');

[resSummaryCombPM,resSummaryIndPM] = resultsCombTimeCourse(condNamePM,condFilePM,timeListComb_pVEGF,'rel');
[resSummaryCombPP,resSummaryIndPP] = resultsCombTimeCourse(condNamePP,condFilePP,timeListComb_pVEGF,'rel');
