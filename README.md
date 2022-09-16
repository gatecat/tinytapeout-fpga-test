This repo contains the tiny "FPGA" submitted to tinytapeout.

Each of the 15 tiles consists of a MUX2 and some simple routing on its inputs, with a DFF in 7 of the logic elements.

The input mapping is as follows (`io_in[0]` is `cfg_mode` selects between config and user mode):

I  | config       | user   |
---|--------------|--------|
0  | `1'b1`       | `1'b0` |
1  | `frameinc`   | `-`    |
2  | `framestrb`  | `-`    |
3  | `dataclk`    | `clk`  |
4  | `bitsel[0]`  | `i[0]` |
5  | `bitsel[1]`  | `i[1]` |
6  | `bitsel[2]`  | `i[2]` |
7  | `bitsel[3]`  | `i[3]` |

`io_out[7:0]` are always fabric outputs.

The configuration sequence is as follows:
 - raise `cfg_mode` from `0` to `1`
 - pulse `frameinc` 0-1-0 to reset the data register
 - pulse `cfg_mode` 1-0-1 to reset the frame address register
 - for each frame in the bitstream:
    - for each `1` in the frame, set `bitsel[3:0]` to the bit index of that `1` and pulse `dataclk` 0-1-0
    - pulse `framestrb` 0-1-0 to write the current frame data
    - pulse `frameinc` 0-1-0 to increment the frame address and clear the data register
 - lower `cfg_mode`

The device has 10 frames of 12 bits each, although a few bits are unused for the missing flipflops.
Each tile spans 2 frames and 4 bits, the top left tile is frame 0..1 and bits 0..3.
Tiles where `x[0] ^ y[0] == 1` have flipflops, forming a checkerboard pattern of tiles with and without flipflops.

The bitmap inside each tile is:

 F B| 0        | 1       | 2       | 3        |
----|----------|---------|---------|----------|
 0  | `I0[0]`  | `I0[1]` | `I1[0]` | `I1[1]`  |
 1  | `S[0]`   | `S[1]`  | `SI`    | `DFF`    |


`I0`, `I1` and `S` are the routing selections for the two data and select inputs for the MUX2 logic element. `SI` inverts select  (equivalent to swapping `I0`/`I1`) and `DFF` enables the D flip-flop in the output path for tiles that possess one.


route | I0     | I1     | S      |
------|--------|--------|--------|
0     | `1'b0` | `1'b1` | `1'b0` |
1     | `T`    | `~L`   | `T`    |
2     | `R`    | `B`    | `R`    |
3     | `L`    | `R`    | `L`    |

`T` is the output of the tile above; `L` the output of the tile to the left, etc.

On the left and top edge tiles, `L` and `T` inputs respectively are the user inputs `i[y]` (or `i[3]` in the `y==4` case) or `i[x]`) respectively. On the bottom and right edges, `B` and `R` loop back the cell output.

`io_out[2:0]` is the output from the bottom edge tiles, `io_out[7:3]` is the output from the right edge tiles.
