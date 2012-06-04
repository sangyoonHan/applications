function [stat,res] = orchestraSubmit(i)
%Calls batchSub3DMigration on the movies specified by the input index

nMov = numel(i);
stat = cell(nMov,1);
res = cell(nMov,1);

for j = 1:numel(i)
   
    %submitCommand = ['bsub -R "rusage[mem=5000]" -q danuser_12h "matlab -nojvm -nosplash -nodesktop -nodisplay -r ''batchSub3DMigration(',num2str(i(j)),')'' "'];
    %submitCommand = ['bsub -R "rusage[mem=10000]" -q danuser_12h "matlab -nosplash -nodesktop -r ''batchSub3DMigration(',num2str(i(j)),')'' "'];
    submitCommand = ['bsub -R "rusage[mem=10000]" -q danuser_7d "/opt/matlab-2011b/bin/matlab -nosplash -nodesktop -r ''batchSub3DMigration(',num2str(i(j)),')'' "'];
    %submitCommand = ['bsub -R "rusage[mem=64000]" -q danuser_7d "/opt/matlab-2011b/bin/matlab -nosplash -nodesktop -r ''batchSub3DMigration(',num2str(i(j)),')'' "'];
    
    [stat, res] = system(submitCommand,'-echo');
    
end