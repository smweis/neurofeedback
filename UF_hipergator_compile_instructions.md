## Instructions to compile and run the [doe,watson]Simulate.m scripts for UF hipergator

1. Log into Hipergator.
2. Create a directory in which to run things from and save output.
Suggested: `/ufrc/stevenweisberg/stevenweisberg/qpFmriResults/compiled[date]`
3. Git pull the latest version of the code and make sure you're on the branch you need.  
4. Load Matlab: `ml matlab` and open matlab `matlab`
5. Load the project with ToolboxToolbox and compile the code.
```
  tbUseProject('neurofeedback');
  mcc -R -singleCompThread -d /ufrc/stevenweisberg/stevenweisberg/qpFmriResults/compiled[date] -m compiledSimulate.m -a ../../toolboxes/bads/
```
Note: the Bayesian Adaptive search package appears to require being added in full, otherwise it does not load all required functions to the compiled version.

7.  To run a batch - positional arguments can be provided in sim_wrapper.sh IF they differ. Otherwise, they should be specified in deploy_sim.sh
/code/qpfMRI/bash should have sample scripts: `deploy_sim.sh` and `sim_wrapper.sh`
`deploy_sim.sh` will call sbatch once to run the doeSimulate compiled on the cluster.
`sim_wrapper.sh` will call `deploy_sim.sh` with a number of jobs (sleeping .1 seconds between each
  call to ensure the rng in matlab receives a slightly different time stamp).
```
cp /ufrc/stevenweisberg/stevenweisberg/MATLAB/projects/neurofeedback/code/qpfMRI/bash/deploy_sim.sh
cp /ufrc/stevenweisberg/stevenweisberg/MATLAB/projects/neurofeedback/code/qpfMRI/bash/sim_wrapper.sh
bash sim_wrapper.sh
```
