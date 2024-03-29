MLPath='/home2/proudot/Danuser_lab/externBetzig/analysis/proudot/anaProject/sphericalProjection/';
movieListFileNames={'prometaphase/analysis/Cell1_12_half_vol_list.mat'};
%movieListFileNames={'prometaphase/analysis/fourProm.mat'};
% Build the array of MovieList (automatic)
aMovieListArray=cellfun(@(x) MovieList.loadMatFile([MLPath filesep x]), movieListFileNames,'unif',0);
aMovieListArray=aMovieListArray{:};

for k=1:length(aMovieListArray)
    ML=aMovieListArray(k);
    
    %% loop over each different cell in each condition
    for i=1:length(ML.movieDataFile_)
        MD=MovieData.loadMatFile(ML.movieDataFile_{i});
         captureDetection(MD)
         %detectMTAlignment(MD)
         %bundleStatistics(MD)
    end
end