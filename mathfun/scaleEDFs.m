%[a c medIdx] = scaleEDFs(samples, varargin) computes the x-scaling factor between the EDFs of the input sample sets
%
% Outputs:
%          a : scaling factor
%          c : estimated fraction of missing data
%

% Francois Aguet, 03/06/2012 (last modified 03/12/2013)

function [a, c, refIdx] = scaleEDFs(samples, varargin)

ip = inputParser;
ip.CaseSensitive = false;
ip.addOptional('RefSamples', []);
ip.addParamValue('Display', false, @islogical);
ip.addParamValue('Reference', 'med', @(x) isscalar(x) || any(strcmpi(x, {'max', 'med'})));
ip.addParamValue('FigureName', 'EDF scaling');
ip.addParamValue('XTick', []);
ip.parse(varargin{:});
refSamples = ip.Results.RefSamples;

if ~iscell(samples)
    samples = {samples(:)};
else
    samples = cellfun(@(i) i(:), samples, 'unif', 0);
end
nd = numel(samples);

if nd==1 && isempty(refSamples)
    a = 1;
    c = 0;
    refIdx = 1;
    return
end

opts = optimset('Jacobian', 'off', ...
    'MaxFunEvals', 1e4, ...
    'MaxIter', 1e4, ...
    'Display', 'off', ...
    'TolX', 1e-6, ...
    'Tolfun', 1e-6);

% Generate EDF for each set of samples and interpolate
F = cell(1,nd);
x = cell(1,nd);

fi = 0:0.001:1;
for i = 1:nd
    [F{i}, x{i}] = ecdf(samples{i});
end

%x0 = linspace(0,max(vertcat(samples{:})),1000);
%x0 = linspace(min(samples{refIdx}),max(samples{refIdx}),1000); % robust
x0 = linspace(prctile(vertcat(samples{:}),1), prctile(vertcat(samples{:}),99), 1000);

if isempty(refSamples)

    % scale to reference distribution, with offset for missing data
    switch ip.Results.Reference
        case 'max' % highest-valued (highest median) distribution
            mu = cellfun(@(i) median(i), samples);
            refIdx = find(mu==max(mu),1,'first');
        case 'med' % median distribution
            f = cell(1,nd);
            for i = 1:nd
                f{i} = interp1(F{i}, x{i}, fi);
            end
            M = vertcat(f{:});
            medianEDF = median(M,1);
            J = nansum((M-repmat(medianEDF, [nd 1])).^2, 2);
            refIdx = find(J==min(J),1,'first');
        otherwise
            refIdx = ip.Results.Reference;
    end
    T99 = prctile(samples{refIdx}, 99.5);
    samples(refIdx) = [];
    xRef = x{refIdx};
    FRef = F{refIdx};
    x(refIdx) = [];
    F(refIdx) = [];
else
    [FRef, xRef] = ecdf(refSamples);
    refIdx = [];
    T99 = prctile(refSamples, 99.5);
end
nd = numel(samples);
    
% scale each distribution to the reference
a = ones(1,nd);
c = zeros(1,nd);
refEDF = interpEDF(xRef, FRef, x0);
for i = 1:nd
    p = lsqnonlin(@cost, [1 0], [0 -1], [Inf 1], opts, x{i}, F{i}, refEDF, x0);
    a(i) = p(1);
    c(i) = p(2);
end

%----------------------
% Display
%----------------------
if ip.Results.Display
    colorV = hsv(nd);
    fset = loadFigureSettings('print');
    if ~isempty(ip.Results.XTick)
        xa = ip.Results.XTick;
        T99 = xa(end);
    end
    lw = 1;
    axPos = fset.axPos;
    dx = 0.3*fset.axPos(4);
    
    [~,idxa] = sort(a);
    [~,idxa] = sort(idxa);
    
    figure(fset.fOpts{:}, 'Position', [5 5 8 1.5+axPos(4)*2+dx+1], 'Color', 'w', 'Name', ip.Results.FigureName);
    axPos(2) = axPos(2)+dx+axPos(4);
    ha(1) = axes(fset.axOpts{:}, 'Position', axPos);
    hold on;
    for i = nd:-1:1
        plot(x{i}, F{i}, '-', 'Color', colorV(idxa(i),:), 'LineWidth', lw);
    end
    hp = plot(xRef, FRef, 'k', 'LineWidth', lw+0.5);
    axis([0 T99 0 1.01]);
    set(gca, 'YTick', 0:0.2:1, 'XLim', [0 T99], 'XTickLabel', []);
    formatTickLabels(gca);
    ylabel('Cumulative frequency', fset.lfont{:});
    text(0, 1.1, 'Raw distributions', 'HorizontalAlignment', 'left', fset.lfont{:});
    hl = legend(hp, ' Median distr.', 'Location', 'SouthEast');
    set(hl, 'Box', 'off', fset.sfont{:}, 'Position', [5 6 1.5 1]);
    
    ha(2) = axes(fset.axOpts{:});
    hold on;
    plot(xRef, FRef, 'k', 'LineWidth', lw+0.5);
    for i = nd:-1:1
        plot(x{i}*a(i), c(i)+(1-c(i))*F{i}, 'Color', colorV(idxa(i),:), 'LineWidth', lw);
    end
    axis([0 T99 0 1.01]);
    set(gca, 'YTick', 0:0.2:1, 'XLim', [0 T99]);
    formatTickLabels(gca);
    xlabel('Max. fluo. intensity (A.U.)', fset.lfont{:});
    ylabel('Cumulative frequency', fset.lfont{:});
    text(0, 1.1, 'Scaled distributions', 'HorizontalAlignment', 'left', fset.lfont{:});
    
    % Plot inset with scales
    axPos = fset.axPos;
    axes(fset.axOpts{:}, 'Position', [axPos(1)+0.85*axPos(3) 1.5*axPos(2) axPos(3)/8 axPos(4)*0.5], 'Layer', 'bottom');
    hold on;
    av = [a 1];
    plot(zeros(numel(av)), av, 'o', 'Color', 0.4*[1 1 1], 'LineWidth', 1, 'MarkerSize', 5);
    he = errorbar(0, mean(av), std(av), 'Color', 0*[1 1 1], 'LineWidth', 1.5);
    plot(0.1*[-1 1], mean(av)*[1 1], 'Color', 0*[1 1 1], 'LineWidth', 1.5);
    setErrorbarStyle(he, 0.15);
    ylim = max(ceil([1-min(av) max(av)-1]/0.2));
    ylim = 1+[-ylim ylim]*0.2;
    axis([-0.5 0.5 ylim]);
    ya = linspace(ylim(1), ylim(2), 5);
    set(gca, 'TickLength', fset.TickLength*3, 'XTick', [], 'YTick', ya, 'XColor', 'w');
    formatTickLabels(gca);
    ylabel('Relative scale', fset.sfont{:});
    if ~isempty(ip.Results.XTick)
        set(ha, 'XTick', ip.Results.XTick);
    end
end

if isempty(refSamples)
    a = [a(1:refIdx-1) 1 a(refIdx:end)];
    c = [c(1:refIdx-1) 0 c(refIdx:end)];
end


function v = cost(p, xEDF, fEDF, refEDF, x0)
a = p(1);
c = p(2);

f_i = interpEDF(xEDF, fEDF, x0/a);
v = c+(1-c)*f_i - refEDF;
v(f_i==0 | f_i==1 | refEDF==0 | refEDF==1) = 0;


function f = interpEDF(xEDF, fEDF, x)
f = interp1(xEDF(2:end), fEDF(2:end), x(2:end), 'linear');
f(1:find(~isnan(f),1,'first')-1) = 0;
f(find(isnan(f),1,'first'):end) = 1;
f = [0 f];
