## Instructions to compile and run the [doe,watson]Simulate.m scripts for UF hipergator

1. Log into Hipergator.
2. Create a directory in which to run things from and save output.
Suggested: `/ufrc/stevenweisberg/stevenweisberg/qpFmriResults/compiled[date]`
3. Git pull the latest version of the code and make sure you're on the branch you need.  
4. Load Matlab: `ml matlab` and open matlab `matlab`
5. Load the project with ToolboxToolbox and compile the code.
```
  tbUseProject('neurofeedback');
  mcc -R -singleCompThread -d /ufrc/stevenweisberg/stevenweisberg/qpFmriResults/compiled[date] -m simulate.m -a ../../toolboxes/bads/
```
Note: the Bayesian Adaptive search package appears to require being added in full, otherwise it does not load all required functions to the compiled version.

6.  To test it, start a srun session:
```
srun --mem=4gb --time=08:00:00 --pty bash -i
ml matlab
./simulate doeTemporalModel  [VARARGIN]
```

7.  To run a batch:
/code/qpfMRI/bash should have sample scripts: `deploy_sim.sh` and `sim_wrapper.sh`
`deploy_sim.sh` will call sbatch once to run the doeSimulate compiled on the cluster.
`sim_wrapper.sh` will call `deploy_sim.sh` with a number of jobs (sleeping .1 seconds between each
  call to ensure the rng in matlab receives a slightly different time stamp).
```
bash sim_wrapper.sh
```
