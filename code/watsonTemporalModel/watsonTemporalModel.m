function y = watsonTemporalModel(frequenciesHz, params)
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
%   Note that there is a typo in original manuscript. Equation 45 should be:
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
% Inputs:
%   frequenciesHz         - as
%   params                - foo
%
% Outputs:
%   y                     - bar
%
% Examples:
%{
    frequenciesHz = [2,4,8,16,32,64];
    params = [0.0037, 2, 5, .5];
    y = watsonTemporalModel(frequenciesHz, params)
    semilogx(frequenciesHz, y, '-.r');
%}

% Fixed parameters (taken from Figure 6.4 and 6.5 of Watson 1986)
centerFilterOrder = 9; % Order of the center (usually fast) filter
surroundFilterOrder = 10; % Order of the surround (usually slow) filter

% Un-pack the passed parameters
params_tau = params(1);             % time constant of the center filter (in seconds)
params_kappa = params(2);           % multiplier of the time-constant for the surround
params_centerAmplitude = params(3); % amplitude of the center filter
params_zeta = params(4);            % multiplier that scales the amplitude of the surround filter

% Generate the model. We return H.
H1 = nStageLowPassFilter(params_tau,frequenciesHz,centerFilterOrder);
H2 = nStageLowPassFilter(params_kappa*params_tau,frequenciesHz,surroundFilterOrder);
y = (params_centerAmplitude * H1) - (params_zeta*params_centerAmplitude*H2);
end



function Hsub = nStageLowPassFilter(tau,frequenciesHz,filterOrder)
% This function implements the system response of the linear filter
% for temporal sensitivity of neural systems in Eq 42 of:
%
%   Watson, A.B. (1986). Temporal sensitivity. In Handbook of Perception
%   and Human Performance, Volume 1, K. Boff, L. Kaufman and
%   J. Thomas, eds. (New York: Wiley), pp. 6-1-6-43..
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
