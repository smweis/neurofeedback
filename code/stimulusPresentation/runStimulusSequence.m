function params = runStimulusSequence(subject,run,type,varargin)

% Run the stimulus sequence at the scanner.
%
% Syntax:
%   nextStim = runRealtimeQuestTFE(subject,run,atScanner,varargin)
%
% Description:
%
%
% Inputs:
%   subject                 - String. The name/ID of the subject.
%   run                     - String. The run or acquisition number.
%   type                    - String. The type of stimulus
%                                     options: screen, board, radial


% Optional key/value pairs:
%   checkerboardSize        - Int. size of the tiles of a checkerboard. If = 0,
%                             full screen flash (default - 60). 60 is a
%                             good option for a 1080 x 1920 display
%   allFreqs                - Vector. Frequencies from which to sample, in
%                             hertz.
%   blockDur                - Scalar. Duration of stimulus blocks   (default = 12   [seconds])
%   scanDur                 - Scalar. duration of total run (default = 336 seconds)
%   displayDistance         - Scalar. 106.5; % distance from screen (cm) - (UPenn - SC3T);
%   displayWidth            - Scalar. 69.7347; % width of screen (cm) - (UPenn - SC3T);
%   displayHeight           - Scalar. 39.2257; % height of screen (cm) - (UPenn - SC3T);
%   baselineTrialFrequency  - Int. how frequently a baseline trial occurs
%   tChar                   - String. Letter used for a trigger.
%
%
% Outputs:




%   Written by Andrew S Bock Jul 2016
%   Modified by Steven M Weisberg Jan 2019

% Examples:

%{

1. Sanity Check
subject = 'sub-102';
run = '1';
type = 'radial';
checkerboardSize = 0;
allFreqs = 15;
baselineTrialFrequency = 2;
runStimulusSequence(subject,run,type,'checkerboardSize',checkerboardSize,'allFreqs',allFreqs,'baselineTrialFrequency',baselineTrialFrequency);

1. Q+ Setup
subject = 'Ozzy_Test';
run = '1';
runStimulusSequence(subject,run)
%
%}

%% Parse input
debug = 0;
p = inputParser;

% Required input
p.addRequired('subject',@isstr);
p.addRequired('run',@isstr);
p.addRequired('type',@isstr);

% Optional params
p.addParameter('checkerboardSize',60,@isnumeric); % 60 = checker; 0 = screen flash
p.addParameter('allFreqs',[1.875,3.75,7.5,15,30],@isvector);
p.addParameter('blockDur',7.5,@isnumeric);
p.addParameter('scanDur',240,@isnumeric);
p.addParameter('displayDistance',106.5,@isnumeric);
p.addParameter('displayWidth',69.7347,@isnumeric);
p.addParameter('displayHeight',39.2257,@isnumeric);
p.addParameter('baselineTrialFrequency',6,@isnumeric);
p.addParameter('tChar','t',@isstr);

if ~debug
    varargin = param();
end
% Parse
% p.parse( subject, run, atScanner, model, varargin{:});
p.parse( subject, run, type, varargin{:});

display = struct;
display.distance = p.Results.displayDistance;
display.width = p.Results.displayWidth;
display.height = p.Results.displayHeight;

%% Get Relevant Paths

[bidsPath, scannerPath, ~, ~, ~,subjectPath] = getPaths(subject, 'neurofeedback');

%% TO DO BEFORE WE RUN THIS AGAIN
    %1.  Change the way baseline trials are handled so that we can use 200 as
    %       a "detect baseline".
    %2.  Perhaps also ensure that we present a baseline trial every X trials,
    %       if one has not already been presented by Quest+
    %3.  Change where actualStimuli.txt is stored.
    %4.  Change where nextStimuli[num].txt is stored.
    %5.  Both 3 and 4 could be solved by changing subjectPath to some
    %       scannerPath where scannerPath is a directory on the actual scanner
    %       computer.



%% Debugging?
% This will make the window extra small so you can test while still looking
% at the code.
debug = 1;

if debug
    stimWindow = [10 10 200 200];
else
    stimWindow = [];
end


run = p.Results.run;

%% Save input variables
params.stimFreq                 = nan(1,p.Results.scanDur/p.Results.blockDur);
params.trialTypeStrings         = cell(1,length(params.stimFreq));
params.p.Results.allFreqs       = p.Results.allFreqs;
params.checkerboardOrFullscreen = p.Results.checkerboardSize;

%% Set up actualStimuli.txt
% A text file that will serve as a record for all stimuli frequencies
% presented during this run number.
actualStimuliTextFile = fullfile(subjectPath,'stims',strcat('run',num2str(run)),strcat('actualStimuli',run,'.txt'));
fid = fopen(actualStimuliTextFile,'w');
fclose(fid);

%% Initial settings
PsychDefaultSetup(2);
Screen('Preference', 'SkipSyncTests', 2); % Skip sync tests
screens = Screen('Screens'); % get the number of screens
screenid = max(screens); % draw to the external screen

%% For Trigger
a = cd;
if a(1)=='/' % mac or linux
    a = PsychHID('Devices');
    for i = 1:length(a)
        d(i) = strcmp(a(i).usageName, 'Keyboard');
    end
    keybs = find(d);
else % windows
    keybs = [];
end


%% Define colors
black = BlackIndex(screenid);
white = WhiteIndex(screenid);
grey = white/2;
red = [1 0 0];
green = [0 1 0];

% generate red cross trial numbers
baseline = 0.5;
num_trials = p.Results.scanDur / (p.Results.blockDur + 0.5);
flip_trials = [];
for i = 1:floor(num_trials/10)+1
    flip_trials(i) = randi([1,9]) + ((i-1)*10);
end
disp(flip_trials);

%% Screen params
res = Screen('Resolution',max(Screen('screens')));
display.resolution = [res.width res.height];
PsychImaging('PrepareConfiguration');
PsychImaging('AddTask', 'General', 'UseRetinaResolution');
[winPtr, windowRect]            = PsychImaging('OpenWindow', screenid, grey, stimWindow);
[mint,~,~] = Screen('GetFlipInterval',winPtr,200);
display.frameRate = 1/mint; % 1/monitor flip interval = framerate (Hz)
display.screenAngle = pix2angle( display, display.resolution );
[center(1), center(2)]          = RectCenter(windowRect); % Get the center coordinate of the window
fix_dot                         = angle2pix(display,0.25); % For fixation cross (0.25 degree)

% create fixation cross
fix_cross_pix = 10;
xCoords = [-fix_cross_pix fix_cross_pix 0 0];
yCoords = [0 0 -fix_cross_pix fix_cross_pix];
allCoords = [xCoords; yCoords];
width_pix = 2;
fix_color = green;

% Screen resolution in Y
screenYpix = windowRect(4);
screenXpix = windowRect(3);
% Number of white/black circle pairs
rcycles = 8;

% Number of white/black angular segment pairs (integer)
tcycles = 24;

%% Make images
greyScreen = grey*ones(fliplr(display.resolution));

if strcmp(type,'screen')
    texture1 = black*ones(fliplr(display.resolution));
    texture2 = white*ones(fliplr(display.resolution));
    freqs = p.Results.allFreqs;
elseif strcmp(type,'board')
    texture1 = double(checkerboard(p.Results.checkerboardSize/2,res.height/p.Results.checkerboardSize,res.width/p.Results.checkerboardSize)>.5);
    texture2 = double(checkerboard(p.Results.checkerboardSize/2,res.height/p.Results.checkerboardSize,res.width/p.Results.checkerboardSize)<.5);
    freqs = p.Results.allFreqs;
elseif strcmp(type,'radial')
    % create radial checkerboard
    xylim = 2 * pi * rcycles;
    [x, y] = meshgrid(-xylim: 2 * xylim / (screenYpix - 1): xylim,...
        -xylim: 2 * xylim / (screenYpix - 1): xylim);
    at = atan2(y, x);
    checks = ((1 + sign(sin(at * tcycles) + eps)...
        .* sign(sin(sqrt(x.^2 + y.^2)))) / 2) * (white - black) + black;
    circle = x.^2 + y.^2 <= xylim^2;
    checks = circle .* checks + grey * ~circle;
    texture1 = checks;
    texture2 = checks-1;
    
    %freqs = linspace(0.5,1,8); % creates 8 stimuli evenly spaced
    freqs = logspace(-0.301,0,8); % creates 8 log-spaced stimuli between 0.5 and 1
else
    error('type not supported. Supported types include screen, board, and radial.');
end

% create mask
r = screenXpix/25;
theta = 0:2*pi/360:2*pi;
x = r * cos(theta) + screenYpix/2;
y= r * sin(theta) + screenYpix/2;
mask = poly2mask(x,y,screenYpix,screenYpix);
texture1 = texture1 .* imcomplement(mask) + (mask .* 0.5);

Texture(1) = Screen('MakeTexture', winPtr, texture1);
Texture(2) = Screen('MakeTexture', winPtr, texture2);
Texture(3) = Screen('MakeTexture', winPtr, greyScreen);
%% Display Text, wait for Trigger

commandwindow;
Screen('FillRect',winPtr, grey);
% Screen('DrawDots', winPtr, [0;0], fix_dot,black, center, 1);
Screen('DrawLines', winPtr, allCoords,...
    width_pix, fix_color, [center(1) center(2)]);
% Screen( 'DrawTexture', winPtr, Texture(1) );
Screen('Flip',winPtr);
ListenChar(2);
%HideCursor;
disp('Ready, waiting for trigger...');

startTime = wait4T(p.Results.tChar);  %wait for 't' from scanner.

%% Drawing Loop
% initialize variables
breakIt = 0;
frameCt = 0;

curFrame = 0;
params.startDateTime    = datestr(now);
params.endDateTime      = datestr(now); % this is updated below
elapsedTime = 0;
disp(['Trigger received - ' params.startDateTime]);
blockNum = 0;
timings = [1500, 2000, 2500, 3000, 3500, 4000, 4500, 5000, 5500, 6000];
latency = 0;
params.onset = nan(5,(p.Results.scanDur/p.Results.blockDur));
% randomly select a stimulus frequency to start with
whichFreq = randi(length(freqs));
stimFreq = freqs(whichFreq);
trialStart = 0;
try
    while elapsedTime < p.Results.scanDur && ~breakIt  %loop until 'esc' pressed or time runs out
        thisBlock = ceil(elapsedTime/p.Results.blockDur);
        
        % If the block time has elapsed, then time to pick a new stimulus
        % frequency.
        if thisBlock > blockNum
            blockNum = thisBlock;
            trialStart = GetSecs;

            % assign random intra-trial onset of red cross (conditional)
            if ismember(blockNum,flip_trials)
                latency = timings(randi(length(timings)));
            else
                latency = 0;
            end
            
            fix_color = green;
            
            % baseline
            Screen( 'DrawTexture', winPtr, Texture( 3 )); % gray screen
            Screen('Flip', winPtr);
            Screen('DrawLines', winPtr, allCoords,...
                    width_pix, fix_color, [center(1) center(2)]);
            Screen('Flip',winPtr,0,1);
            
            % record onset times 
            params.onset(1,thisBlock) = GetSecs; % ISI
            params.onset(2,thisBlock) = GetSecs; % green cross
            params.onset(4,thisBlock) = latency/1000; % red cross
            pause(0.5);

            % load in stimulus suggestions
            stimFile = fullfile(subjectPath,'stims',strcat('run',num2str(run)),'suggestions.txt');
            trialTypeString = 'QUEST+';

            readFid = fopen(stimFile,'r');
            while ~feof(readFid)
                line = fgetl(readFid);
                disp(line);
            end
            stimFreq = str2double(line);
            fclose(readFid);

            % Write the stimulus that was presented to a text file so that
            % Quest+ can see what's actually been presented.

            fid = fopen(actualStimuliTextFile,'a');
            fprintf(fid,'%d\n',stimFreq);
            fclose(fid);

            % Print the last trial info to the terminal and save it to
            % params.
            disp(['Trial Type - ' trialTypeString]);
            if strcmp(type,'radial')
                disp(['Trial Number - ' num2str(blockNum) '; Contrast - ' num2str(stimFreq)]);
            else
                disp(['Trial Number - ' num2str(blockNum) '; Frequency - ' num2str(stimFreq)]);
            end

            params.stimFreq(thisBlock) = stimFreq;
            params.trialTypeStrings{thisBlock} = trialTypeString;

        end


        % We will handle stimFreq = 0 different to just present a gray
        % screen. If it's not zero, we'll flicker.
        % The flicker case:
        if stimFreq ~= baseline
            % Radial checkerboards must be redrawn with new contrast
            if strcmp(type,'radial')
                contrast = stimFreq;
                white = contrast;
                black = 1-contrast;
                xylim = 2 * pi * rcycles;
                [x, y] = meshgrid(-xylim: 2 * xylim / (screenYpix - 1): xylim,...
                    -xylim: 2 * xylim / (screenYpix - 1): xylim);
                at = atan2(y, x);
                checks = ((1 + sign(sin(at * tcycles) + eps)...
                    .* sign(sin(sqrt(x.^2 + y.^2)))) / 2) * (white - black) + black;
                circle = x.^2 + y.^2 <= xylim^2;
                checks = circle .* checks + grey * ~circle;
                texture1 = checks;
                % apply mask
                texture1 = texture1 .* imcomplement(mask) + (mask .* 0.5);
                Texture(1) = Screen('MakeTexture', winPtr, texture1);
            end
            
            if (elapsedTime - curFrame) > (1/(stimFreq*2))
                frameCt = frameCt + 1;
                % Screen( 'DrawTexture', winPtr, Texture( mod(frameCt,2) + 1 )); % current frame
                Screen( 'DrawTexture', winPtr, Texture(1) );
                Screen('Flip',winPtr,0,1);
                curFrame = GetSecs - startTime;
                params.onset(3,thisBlock) = GetSecs; % checkerboard
            end
        % The gray screen case.
        else
            Screen( 'DrawTexture', winPtr, Texture( 3 )); % gray screen
            Screen('Flip', winPtr,0,1);
        end
        
        if latency ~= 0 && GetSecs-trialStart >= latency/1000 && GetSecs-trialStart < (latency+50)/1000
            fix_color = red;
        else
            fix_color = green;
        end
        Screen('DrawLines', winPtr, allCoords,...
                    width_pix, fix_color, [center(1) center(2)]);
        Screen('Flip',winPtr,0,1);

        % update timers
        elapsedTime = GetSecs-startTime;
        params.endDateTime = datestr(now);
        % check to see if the "esc" button was pressed
        breakIt = escPressed(keybs);
        % check and record subject response
        if bPressed(keybs)
            params.onset(5,thisBlock) = GetSecs; % response recieved
        end
        WaitSecs(0.001);
        
        %pause(p.Results.blockDur);
    end

    % Close screen and save data.
    sca;
    save(fullfile(subjectPath,'stims',strcat('run',num2str(run)),strcat('stimFreqData_Run',run,'_',datestr(now,'mm_dd_yyyy_HH_MM'))),'params');
    disp(['elapsedTime = ' num2str(elapsedTime)]);
    ListenChar(1);
    ShowCursor;
    Screen('CloseAll');

catch ME
    Screen('CloseAll');
    save(fullfile(subjectPath,'stims',strcat('run',num2str(run)),strcat('stimFreqData_Run',run,datestr(now,'mm_dd_yyyy_HH_MM'))),'params');
    ListenChar;
    ShowCursor;
    rethrow(ME);
end
