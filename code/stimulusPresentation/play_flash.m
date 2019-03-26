function play_flash(runNumber,subjectPath,checkerboardSize,allFreqs,blockDur,scanDur,baselineTrialFrequency,display)

%% Displays a black/white full-field flicker
%
%   Usage:
%   play_flash(runNumber,subjectPath,checkerboardSize,allFreqs,blockDur,scanDur,baselineTrialFrequency,display)
%
%   Required inputs:
%   runNumber               - which run. To determine save data. 
%
%   Defaults:
%   allFreqs                - the domain of possible frequencies to present
%   subjectPath             - passed from default for
%                               tbUseProject('neurofeedback') (default - test subject)
%   checkerboardSize        - size of the tiles of a checkerboard. If = 0,
%                               full screen flash (default - 0). 60 is a 
%                               good option for a 1080 x 1920 display
%   blockDur                - duration of stimulus blocks   (default = 12   [seconds])
%   scanDur                 - duration of total run (default = 336 seconds)
%   display.distance        - 106.5; % distance from screen (cm) - (UPenn - SC3T);
%   display.width           - 69.7347; % width of screen (cm) - (UPenn - SC3T);
%   display.height          - 39.2257; % height of screen (cm) - (UPenn - SC3T);
%   baselineTrialFrequency  - how frequently a baseline trial occurs

%   Stimulus will flicker at 'stimFreq', occilating between flicker and
%   grey screen based on 'blockDur'
%
%   Written by Andrew S Bock Jul 2016
%   Modified by Steven M Weisberg Jan 2019

%% Set defaults
if ~exist('allFreqs','var') || isempty(allFreqs)
    allFreqs = [1.875,3.75,7.5,15,30];
end

% block duration
if ~exist('blockDur','var')
    blockDur = 12; % seconds
end


% checkerboard pattern or full screen
if ~exist('checkerboardSize','var')
    checkerboardSize = 0; % seconds
end


% run duration
if ~exist('scanDur','var')
    scanDur = 360;
end

% scanner trigger
if ~exist('tChar','var') || isempty(tChar)
    tChar = {'t'};
end

% display parameters
if ~exist('display','var') || isempty(display)
    display.distance = 106.5; % distance from screen (cm) - (UPenn - SC3T);
    display.width = 69.7347; % width of screen (cm) - (UPenn - SC3T);
    display.height = 39.2257; % height of screen (cm) - (UPenn - SC3T);
end


% how often baseline trials occur
if ~exist('baselineTrialFrequency','var')
    baselineTrialFrequency = 6;
end

if ~exist('subjectPath','var') || isempty(subjectPath)
    [subjectPath] = getPaths('TOME_3040_TEST');
end


%% Debugging?
debug = 0;

if debug
    stimWindow = [10 10 200 200];
else
    stimWindow = [];
end




%% Save input variables
params.stimFreq                 = nan(1,scanDur/blockDur);
params.trialTypeStrings         = cell(1,length(params.stimFreq));
params.allFreqs                 = allFreqs;
params.checkerboardOrFullscreen = checkerboardSize;

%% Set up actualStimuli.txt
% A text file that will serve as a record for all stimuli frequencies
% presented during this run number.

fid = fopen(fullfile(subjectPath,strcat('actualStimuli',num2str(runNumber),'.txt')),'w');
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


%% Define black and white
black = BlackIndex(screenid);
white = WhiteIndex(screenid);
grey = white/2;


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


%% Make images
greyScreen = grey*ones(fliplr(display.resolution));

if checkerboardSize == 0
    texture1 = black*ones(fliplr(display.resolution));
    texture2 = white*ones(fliplr(display.resolution));
else
    texture1 = double(checkerboard(checkerboardSize/2,res.height/checkerboardSize,res.width/checkerboardSize)>.5);
    texture2 = double(checkerboard(checkerboardSize/2,res.height/checkerboardSize,res.width/checkerboardSize)<.5);
end

Texture(1) = Screen('MakeTexture', winPtr, texture1);
Texture(2) = Screen('MakeTexture', winPtr, texture2);
Texture(3) = Screen('MakeTexture', winPtr, greyScreen);

%% Display Text, wait for Trigger

commandwindow;
Screen('FillRect',winPtr, grey);
Screen('DrawDots', winPtr, [0;0], fix_dot,black, center, 1);
Screen('Flip',winPtr);
ListenChar(2);
HideCursor;
disp('Ready, waiting for trigger...');

startTime = wait4T(tChar);  %wait for 't' from scanner.

%% Drawing Loop
breakIt = 0;
frameCt = 0;

curFrame = 0;
params.startDateTime    = datestr(now);
params.endDateTime      = datestr(now); % this is updated below
elapsedTime = 0;
disp(['Trigger received - ' params.startDateTime]);
blockNum = 0;

% randomly select a stimulus frequency to start with 
whichFreq = randi(length(allFreqs));
stimFreq = allFreqs(whichFreq);

try
    while elapsedTime < scanDur && ~breakIt  %loop until 'esc' pressed or time runs out
        thisBlock = ceil(elapsedTime/blockDur);
        
        
        % If the block time has elapsed, then time to pick a new stimulus
        % frequency. 
        if thisBlock > blockNum
            blockNum = thisBlock;
            
            % Every sixth block, set stimFreq = 0. Will display gray screen
            if mod(blockNum,baselineTrialFrequency) == 1 
                trialTypeString = 'baseline';
                stimFreq = 0;
            
            % If it's not the 6th block, then see if Quest+ has a
            % recommendation for which stimulus frequency to present next. 
            elseif ~isempty(dir(fullfile(subjectPath,'stimLog','nextStim*')))
                
                d = dir(fullfile(subjectPath,'stimLog','nextStim*'));
                [~,idx] = max([d.datenum]);
                filename = d(idx).name;
                nextStimNum = sscanf(filename,'nextStimuli%d');
                trialTypeString = ['quest recommendation - ' num2str(nextStimNum)];
                readFid = fopen(fullfile(subjectPath,'stimLog',filename),'r');
                stimFreq = fscanf(readFid,'%d');
                fclose(readFid);
            
            % If there's no Quest+ recommendation yet, randomly pick a
            % frequency from allFreqs. 
            else 
                trialTypeString = 'random';
                whichFreq = randi(length(allFreqs));
                stimFreq = allFreqs(whichFreq);
            end
            
            % Write the stimulus that was presented to a text file so that
            % Quest+ can see what's actually been presented. 
            fid = fopen(fullfile(subjectPath,'actualStimuli.txt'),'a');
            fprintf(fid,'%d\n',stimFreq);
            fclose(fid);
            
            % Print the last trial info to the terminal and save it to
            % params. 
            disp(['Trial Type - ' trialTypeString]);
            disp(['Trial Number - ' num2str(blockNum) '; Frequency - ' num2str(stimFreq)]);
            
            params.stimFreq(thisBlock) = stimFreq;
            params.trialTypeStrings{thisBlock} = trialTypeString;
            
        end
        
     
        % We will handle stimFreq = 0 different to just present a gray
        % screen. If it's not zero, we'll flicker. 
        % The flicker case:
        if stimFreq ~= 0 
            if (elapsedTime - curFrame) > (1/(stimFreq*2))
                frameCt = frameCt + 1;
                Screen( 'DrawTexture', winPtr, Texture( mod(frameCt,2) + 1 )); % current frame
                Screen('Flip', winPtr);
                curFrame = GetSecs - startTime;
            end
        % The gray screen case. 
        else 
            Screen( 'DrawTexture', winPtr, Texture( 3 )); % gray screen
            Screen('Flip', winPtr);
        end
        
        
        
        % update timers
        elapsedTime = GetSecs-startTime;
        params.endDateTime = datestr(now);
        % check to see if the "esc" button was pressed
        breakIt = escPressed(keybs);
        WaitSecs(0.001);
        
    end
    
    % Close screen and save data. 
    sca;
    save(fullfile(subjectPath,strcat('stimFreqData_Run',num2str(runNumber),'_',datestr(now,'mm_dd_yyyy_HH_MM'))),'params');
    disp(['elapsedTime = ' num2str(elapsedTime)]);
    ListenChar(1);
    ShowCursor;
    Screen('CloseAll');
    
catch ME
    Screen('CloseAll');
    save(fullfile(subjectPath,strcat('stimFreqData_Run',num2str(runNumber))),'params');
    ListenChar;
    ShowCursor;
    rethrow(ME);
end
