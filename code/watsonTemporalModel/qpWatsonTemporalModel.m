function predictedProportions = qpWatsonTemporalModel(frequenciesToModel, params, nCategoriesIn, headroomIn)
% Express the Watson model TTF as amplitude proportions
%
% Syntax:
%  predictedProportions = qpWatsonTemporalModel(frequenciesToModel, params, nCategoriesIn, headroomIn)
%
% Description:
%	This function maps the 0-1 amplitude of the Watson TTF response to a
%	discrete response within one of nCategory bins. The shape of the Watson
%	TTF is determined by the first three elements of the params variable.
%	The fourth element of params is the degree of Gaussian smoothing to be
%	applied to the response categories across the y-axis. The units of this
%	sigma value are nCategory bins of the response. So, a sigma of 0.25
%	indicates a Gaussian kernel that has a SD equal to 1/4 of the respond
%	range.
%
% Inputs:
%   frequenciesToModel    - nx1 column vector of frequencies (in Hz) for 
%                           which the Watson TTF will be evaluated and 
%                           predicted proportions returned
%   params                - 1x5 vector. The first three values correspond
%                           to the three parameters of watsonTemporalModel.
%                           The second to last parameter is a scaling
%                           factor, mapping percent BOLD to a 0-1 range.
%                           The last parameter is the sigma of the Gaussian
%                           smoothing to apply across the category
%                           boundaries.
%   nCategoriesIn         - Scalar. Optional. Sets the number of bins into
%                           which the y-axis will be divided. Defaults to
%                           21 if not provided.
%   headroomIn            - 1x2 vector. Optional. Determines the proportion
%                           of the nCategories to reserve above and below
%                           the minimum and maximum output of the Watson
%                           model. Defaults to [0.1 0.1], which means that
%                           20% of the nCategories range will correspond to
%                           response values that are less than zero or
%                           greater than 1.
% Outputs:
%   predictedProportions  - An nFrequencies x nCategories matrix that
%                           provides for each of the frequencies to model
%                           the probability that a measured response will
%                           fall in a given amplitude bin.
%
% Examples:
%{
    % Demonstrate the conversion of a single modeled frequency into a
    % predicted proportion vector under the control of smoothing noise
    % Parameters of the Watson model
    tau = 1;	% time constant of the center filter (in msecs)
    kappa = 1.5;	% multiplier of the time-constant for the surround
	zeta = 1;	% multiplier that scales the amplitude of the surround

    % Plot the Watson TTF
    freqDomain = logspace(0,log10(100),100);
    figure
    subplot(2,1,1);
    semilogx(freqDomain,watsonTemporalModel(freqDomain,[tau kappa zeta]));
    xlabel('log Freq [Hz]');
    ylabel('Amplitude TTF [0-1]');
    title('Watson TTF');
    hold on

    % The frequency at which to obtain the predicted proportions
    freqHz = 40;

    % Indicate on the Watson TTF plot the frequency to model
    semilogx(freqHz,watsonTemporalModel(freqHz,[tau kappa zeta]),'*r');

    % Gaussian noise to be applied across the y-axis response categories
    sigma = 0.5;

    % Assemble the params with the noise modeled
    params = [tau kappa zeta sigma];

    % The number of bins into which to divide the response amplitude
    nCategories = 21;

    % Perform the calculation
    predictedProportions = qpWatsonTemporalModel(freqHz, params, nCategories);

    % Plot the predicted proportions
    subplot(2,1,2);
    plot(predictedProportions,1:nCategories,'*k')
    xlim([0 1]);
    ylim([1 nCategories]);
    xlabel('predicted proportion [0-1]');
    ylabel('Amplitude response bin');
    title('Predicted proportions');
%}

% The number of bins into which we will divide the range of y-axis response
% values. Either passed or set as a default
if nargin >= 3
    nCategories = nCategoriesIn;
else
    nCategories = 21;
end

% Ensure that nCategories is odd
assert(mod(nCategories,2)==1);

% Set the headroom if undefined
if nargin >= 4
    headroom = headroomIn;
else
    headroom = 0.1;
end

%% Params to vars
tau = params(1);	% time constant of the center filter (in msecs)
kappa = params(2);	% multiplier of the time-constant for the surround
zeta = params(3);	% multiplier of the amplitude of the surround
beta = params(4);   % multiplier of the Watson 0-1 to the bins
sigma = params(5);	% width of the BOLD fMRI noise against the 0-1 y vals

% Ensure that beta is less than or equal to unity
assert(beta<=1);

% Determine the number of bins to be reserved for upper and lower headroom
nLower = round(nCategories.*headroom);
nUpper = round(nCategories.*headroom);
nMid = nCategories - nLower - nUpper;

% Obtain the Watson response values for the frequencies to be modeled
yVals = watsonTemporalModel(frequenciesToModel, [tau kappa zeta]);

% Scale the yVals by the beta. This serves to adjust the 0-1 output of the
% Watson model to the empirical maximum BOLD fMRI response
yVals = yVals .* beta;

% Map the responses to categories
binAssignment = 1+round(yVals.*nMid)+nLower;
binAssignment(binAssignment > nCategories)=nCategories;

% Create a Gaussian kernel to reflect noise in the y-axis measurement
if params(end)==0
    gaussKernel = zeros(1,nCategories);
    gaussKernel(floor(nCategories/2)+1)=1;
else
    gaussKernel = gausswin(nCategories,nCategories/(10*sigma))';
end

% Initialize a variable to hold the result
predictedProportions = zeros(length(frequenciesToModel),nCategories);

% Loop over the array of frequenciesToModel
for ii = 1:length(frequenciesToModel)

    % Assign the bin
    predictedProportions(ii,binAssignment(ii))=1;

    % Apply smoothing across the proportions of response predicted for this
    % frequency. This models the effect of noise in the measurement of
    % response amplitude
    predictedProportions(ii,:) = conv(predictedProportions(ii,:),gaussKernel,'same');
    
    % Ensure that the sum of probabilities across categories for a given
    % frequency is unity
    predictedProportions(ii,:) = predictedProportions(ii,:)/sum(predictedProportions(ii,:));
    
end % loop over frequencies to model


end % main function

