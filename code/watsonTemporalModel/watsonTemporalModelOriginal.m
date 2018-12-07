function y = watsonTemporalModelOriginal(frequenciesHz, params)
% Beau Watson's 1986 center-surround neural temporal sensitivity model
%
% Syntax:
%  y = watsonTemporalModel(frequenciesHz, params)
%
% Description:
%	Calculates the two-component (center-surround) Watson temporal model
%   The parameters (p) defines both the "center" and the "surround" linear
%   filter components. The entire model is the difference between these two
%   filter components.
%
%	The model is expressed in Eq 45 of:
%
%       Watson, A.B. (1986). Temporal sensitivity. In Handbook of Perception
%       and Human Performance, Volume 1, K. Boff, L. Kaufman and
%       J. Thomas, eds. (New York: Wiley), pp. 6-1-6-43.
%
%   Note that there is a typo in original manuscript. Equation 45 should
%   be:
%
%       H(frequenciesHz) = a[H1(frequenciesHz) - bH2(frequenciesHz)]
%
%   where a and b are scale factors. We have modified the implementation of
%   scale factors here.
%
%   Additionally, Watson (1986) gives the time-constant of the model in
%   units of milliseconds, but we find that, to reproduce the presented
%   figures, this time-constant is converted at some point to units of
%   seconds prior to its entry into the equations.
%
%   The model is the difference between two linear impulse response
%   filters, each of which is themselves a cascade of low-pass filters. The
%   number of filters in the cascade (the "filterOrder") is set
%   empirically. Center and surround orders of "9" and "10" are presented
%   in (e.g.) Figure 6.5 of Watson (1986).
%
%   Note that the model can only return positive amplitudes of response,
%   although some empirical data may have a negative amplitude (e.g., BOLD
%   fMRI data of a low temporal frequency stimulus as compared to a blank
%   screen). To handle this circumstance, it is recommended that data be
%   offset so that the minimum amplitude value is zero prior to fitting.
%
% Inputs:
%   frequenciesHz         - 1xn vector that provides the stimulus
%                           frequencies for which the model will be
%                           evaluated
%   params                - 1x4 vector of model parameters:
%                             tau - time constant of the center filter (in
%                                   seconds)
%                           kappa - multiplier of the time-constant for the
%                                   surround
%                 centerAmplitude - amplitude of the center filter
%                            zeta - multiplier that scales the amplitude of
%                                   the surround filter
%
% Outputs:
%   y                     - 1xn vector of modeled amplitude values.
%
% Examples:
%{
    stimulusFreqHz = [2,4,8,16,32,64];
    pctBOLDresponse = [0.4, 0.75, 0.80, 0.37, 0.1, 0.0];
    myObj = @(p) sqrt(sum((pctBOLDresponse-watsonTemporalModel(stimulusFreqHz,p)).^2));
    x0 = [0.004 2 1 1];
    params = fmincon(myObj,x0,[],[]);
    stimulusFreqHzFine = stimulusFreqHz(1):0.1:stimulusFreqHz(end);
    semilogx(stimulusFreqHzFine,watsonTemporalModel(stimulusFreqHzFine,params),'-k');
    hold on
    semilogx(stimulusFreqHz, pctBOLDresponse, '*r');
%}

% Fixed parameters (taken from Figure 6.4 and 6.5 of Watson 1986)
centerFilterOrder = 9; % Order of the center (usually fast) filter
surroundFilterOrder = 10; % Order of the surround (usually slow) filter

% Un-pack the passed parameters
params_tau = params(1);
params_kappa = params(2);
params_centerAmplitude = params(3);
params_zeta = params(4);

% Generate the model. We return y for each stimulus.

for i = 1:length(frequenciesHz)

    H1 = nStageLowPassFilter(params_tau,frequenciesHz(i),centerFilterOrder);
    H2 = nStageLowPassFilter(params_kappa*params_tau,frequenciesHz(i),surroundFilterOrder);
    rawY = (params_centerAmplitude * H1) - (params_zeta*params_centerAmplitude*H2);

% The model calculates a vector of complex values that define the Fourier
% transform of the system output. As we are implementing a model of just
% the amplitude component of a temporal transfer function, the absolute
% value of the model output is returned.
    y(i,:) = abs(rawY);

end



function Hsub = nStageLowPassFilter(tau,frequenciesHz,filterOrder)
% This function implements the system response of the linear filter
% for temporal sensitivity of neural systems in Eq 42 of Watson (1986).
%
% The implemented function is the "system respone" (Fourier transform) of
% the impulse response of an nth-order filter which is of the form:
%
% h(t) = u(t) * (1/(tau*(n-1)!)) * (t/tau)^(n-1) * exp(-t/tau)
%
% tau -- Time constant of the filter (in seconds)
% frequenciesHz -- a vector of frequencies at which to realize the model
% filterOrder -- the number of low-pass filters which are cascaded in
%                the model
Hsub = (1i*2*pi*frequenciesHz*tau + 1) .^ (-filterOrder);

end

end
