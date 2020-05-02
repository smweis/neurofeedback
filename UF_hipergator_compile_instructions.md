## Instructions to compile and run the [doe,watson]Simulate.m scripts for UF hipergator

1. Log into Hipergator.
2. Create a directory in which to run things from and save output.
Suggested: `/ufrc/stevenweisberg/stevenweisberg/compiledDoe`
3. Git pull the latest version of the code and make sure you're on the branch you need.  
4. Load Matlab: `ml matlab` and open matlab `matlab`
5. Load the project with ToolboxToolbox and compile the code.
```
  tbUseProject('neurofeedback');
  mcc -R -singleCompThread -d /ufrc/stevenweisberg/stevenweisberg/compiledDoe -m doeSimulate.m -a ../../toolboxes/bads/
```
Note: the Bayesian Adaptive search package appears to require being added in full, otherwise it does not load all required functions to the compiled version.

6.  To test it, start a srun session:
```
srun --mem=4gb --time=08:00:00 --pty bash -i
ml matlab
./doeSimulate 1.05 .01 .06 1.00 .4 800 12 false 1
```
