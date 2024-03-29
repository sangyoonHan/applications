function idlist = linkerWriteQmatrices(idlist,goodTimes)
%linkerWriteQmatrices writes tag-based Qmatrices from spot-based Qmatrices

% read old q-matrices as 3-by-3, then make a new one. Go with cells
    % because it's both prettier and less error-prone.
    % read 3-by-3 submatrices into a cell array, keep the diagonal. Add a
    % zero-matrix at the beginning. Make a list of cells with
    % linklist(:,2)+1 (tag-not-found have Q==0 - maybe change that to NaN
    % later). Make new detectQ_Pix with blkdiag

qNames = {'detectQ_Pix','trackQ_Pix'};
QNames = {'Q','QT'};

for t = goodTimes'
isTracked = isfield(idlist(t).info,'QT') && ~isempty(idlist(t).info.QT);
    nSpots = max(idlist(t).linklist(:,2));
    for q = 1:1+isTracked
        qCell = mat2cell(idlist(t).info.(QNames{q}), ...
            3*ones(nSpots,1), 3*ones(nSpots,1));
        %         qCellDiag = [{zeros(3)}; diag(qCell)]; %KJ: replaced with
        %         below, no longer allowed in R2009b
        qCellDiag = {zeros(3)};
        for i = 1 : size(qCell,1)
            qCellDiag = [qCellDiag; qCell(i,i)];
        end
        qCellList = qCellDiag(idlist(t).linklist(:,2)+1);
        % make sparse to save some disk space
        idlist(t).info.(qNames{q}) = sparse(blkdiag(qCellList{:}));
    end
    
    % write back chi2
    spotIdx = idlist(t).linklist(:,2)>0 & idlist(t).linklist(3) ~= 4;
    idlist(t).linklist(spotIdx,12) = ...
        idlist(t).info.chi(idlist(t).linklist(spotIdx,2));
    
    % remove fields
    info = idlist(t).info;
    info = rmfield(info,{QNames{1:1+isTracked}});
    idlist(t).info = info;
end