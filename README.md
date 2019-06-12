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

### Imaging directory structure

Recommended directory structure:

-rtQuest
  -KastnerParcels
  -subject1
  -subject2
    -raw
    -processed
      -run1
      -run2


Top level is project-specific. (`rtQuest`)

Two types of directories within the main directory.

A templates directory in which you should place any ROIs that are in standard space. (`KastnerParcels`)

A set of subject-specific directories (the name of this directory should be able to be referred to as a string). Within that directory are two main directories: `raw` and `processed`

`raw` contains the MPRAGE and any sbrefs you want to use.

`processed` will contain all files generated through registration and neurofeedback. The scripts will put run-specific data in run-specific directories nested within `processed`


## ROI acquisition and registration
Before you get to the scanner (or, possibly very quickly while you are at the scanner), we need to set up the ROI.

Acquire an ROI. Any ROI will work.

`realTime/brainProcessing` has three scripts useful for preprocessing.

`brain_extraction.sh` performs bet brain extraction on the MPRAGE and the two ROIs.

`makeMaskFromRetino.m` creates a retinotopic mask from functional data. Unless you collected this specifically for your subject as part of a separate scan, it is unlikely that you can use it.

`register_ROI_to_APandPA.sh` will register the ROI (the way it's set up now will take a Kastner V1 parcel and register it to the first volume).

At the end, you should have an ROI registered to EPI space that can be used in `runNeurofeedback.m`. Specifically `runNeurofeedback.m` will call `registerToFirstDICOM.m`.

### Test
To be completed. This section will describe how to use `runNeurofeedback.m`.

If your system is set up correctly, you should be able to copy and paste the first set of example code from `runNeurofeedback`. Provided that you have raw DICOMs and set up your directories as described in that script (and `getPaths`), you should be able to copy DICOMs from the main directory into the "scanner directory" and see a live plot of the mean of the ROI you provided.
