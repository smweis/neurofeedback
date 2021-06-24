function c = param()

p.checkerboardSize=60; % 60 = checker; 0 = screen flash
p.allFreqs=[1.875,3.75,7.5,15,30];
p.blockDur=7.5;
p.scanDur=240;
p.displayDistance=106.5;
p.displayWidth=69.7347;
p.displayHeight=39.2257;
p.baselineTrialFrequency=6;
p.tChar='t';

% Formatting
f = fieldnames(p);
p = struct2cell(p);
d = [f(:),p(:)].';
c = rot90(d(:));
end

