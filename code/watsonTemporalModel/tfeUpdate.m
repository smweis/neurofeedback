function [binOutcomes] = tfeUpdate(tfeObj, thePacket, varargin)
% My description
%
% Syntax:
%  [tfeObj, thePacket] = tfeInit(, varargin)
%
% Description:
%	.
%
% Inputs:
%   sceneGeometry         - Structure. SEE: createSceneGeometry
%
% Optional key/value pairs:
%  'eyePoseLB/UB'         - A 1x4 vector that provides the lower (upper)

%
% Outputs:
%   tfeObj               - Object handle
%   thePacket            - Structure.
%
% Examples:
%{
    [tfeObj, thePacket] = tfeInit();
    % We are using this next line to get the qpOutcomeF in memory
    validate_qpWatson
    stimulusVec = randsample([1.875,2.5,3.75,5,7.5,10,15,20,30],20,true);
    tfeUpdate(tfeObj, thePacket, 'qpOutcomeF', myQpParams.qpOutcomeF, 'stimulusVec',stimulusVec)
%}


%% Parse input
p = inputParser;

% Required input
p.addRequired('tfeObj',@isobject);
p.addRequired('thePacket',@isstruct);

% Optional params
p.addParameter('qpOutcomeF', [], @(x)(isempty(x) | isa(x,'function_handle')));
p.addParameter('stimulusVec', [], @isnumeric);
p.addParameter('verbose', false, @islogical);

% Parse and check the parameters
p.parse( tfeObj, thePacket, varargin{:});


%% Test if we are in simulate mode
if isempty(thePacket.response)
    
    defaultParamsInfo.nInstances = size(thePacket.stimulus.values,1);
    params0 = tfeObj.defaultParams('defaultParamsInfo', defaultParamsInfo);
    params0.noiseSd = 0.02;
    params0.noiseInverseFrequencyPower = 1;
    
    % Need to convert from bins to BOLD
    modelAmplitudes = p.Results.qpOutcomeF(p.Results.stimulusVec);
    params0.paramMainMatrix=modelAmplitudes;
    responseStruct = tfeObj.computeResponse(params0,thePacket.stimulus,thePacket.kernel,'AddNoise',true);
else
    responseStruct = thePacket.response;
end

% Fit the response struct with the IAMP model

end