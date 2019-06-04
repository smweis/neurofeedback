# Real-time fMRI neurofeedback toolbox

## Introduction

This Matlab (with some bash scripting) toolbox consists of three related components for designing, testing, and implementing real-time fMRI neuroimaging experiments.

Component 1. `realTime` Real-time fMRI data prep and processing.

Component 2. `stimulusPresentation` Stimulus presentation with psychtoolbox.

Component 3. `qpfMRI` A set of tools for using Quest+ with the temporal fitting engine in designing Bayesian staircase procedures.

## Setup

### Install and configure
The best way to install and use the `neurofeedback` tools is to install `toolboxToolbox` on Matlab.

1. Git clone into '/Documents/MATLAB/projects/'

2. If using with Toolbox Toolbox, then tbUseProject('neurofeedback')

3. Configure `/config/neurofeedbackLocalHookTemplate.m` and place in `/MATLAB/localHookFolder`

4. You will also need to <a href="http://web.mit.edu/fsl_v5.0.10/fsl/doc/wiki/FslInstallation(2f)Linux.html">install FSL</a>.


### Test
To be completed. This section will describe how to use `neurofeedbackTemplate` and demonstrate how `validate_runNeurofeedback.m` will work.

`validate_runNeurofeedback.m` will

## Pre-scanner steps
Before you get to the scanner (or, possibly very quickly while you are at the scanner), you will want to do some pre-scanner work.

1. Acquire an ROI. Any ROI will work.

2. TO DO: edit `register_ROI_to_AP_and_PA` to be more accomodating of other ROIs. Integrate with MATLAB scripts. 
