![](../../workflows/wokwi/badge.svg)

(Original readme for the template repository [here](https://github.com/mattvenn/wokwi-verilog-gds-test/blob/main/README.md))

This repo is an experiment in using Verilog source files instead of Wokwi diagrams for [TinyTapeout](https://tinytapeout.com).

The Verilog flow is:

1) Fork this Repo
2) Create a [wokwi](https://wokwi.com/projects/339800239192932947) project to get an ID
3) Update WOWKI_PROJECT_ID in Makefile
4) `grep -rl "341154068332282450" ./src | sed -i "s/341154068332282450/YOUR_WOKWI_ID/g"` from the top of the repo to find and replace all occurences of the old ID in `src` with yours, and rename the `user_module`, `user_module_tb` and `scan_wrapper` files to use your ID
5) Replace behavioural code in user_module_ID.v with your own, likewise change the testbench
6) Push changes, which triggers the GitHub Action to build the project
