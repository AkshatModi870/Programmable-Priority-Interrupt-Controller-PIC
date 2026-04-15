# Programmable Priority Interrupt Controller (PIC)

## What is this project?

A computer's CPU (the brain of the computer) does many tasks – it calculates, moves data, talks to the keyboard, the mouse, the hard disk, etc. Sometimes a device (like a keyboard) needs immediate attention. For example, when you press a key, the computer must respond right away so that the letter appears on the screen. The keyboard cannot wait until the CPU finishes everything else; it needs to "interrupt" the CPU.

This project builds a small electronic circuit (written in a language called **Verilog**) that manages these interruptions. It is called a **Priority Interrupt Controller** (PIC). It listens to up to 8 different devices (numbered 0 to 7). When one or more devices ask for attention, the PIC decides which one is most important (highest priority). It then tells the CPU: "Stop what you are doing and handle device X". It also gives the CPU a number (a vector) so the CPU knows exactly which device needs service.

The PIC is **programmable**. That means the CPU can tell the PIC:
- "Ignore (mask) some devices – do not interrupt me for them."
- "Here is the base number for the vectors." (e.g., start at 0x40, then device 0 gets 0x40, device 1 gets 0x41, etc.)
- "I have finished handling a device – you can clear it from your memory."

## Why is this important?

Without a PIC, the CPU would have to constantly check each device to see if it needs service (this is called polling). That wastes a lot of time. With a PIC, the CPU can do useful work and only stops when a device actually needs attention. This makes computers faster and more efficient.

## How does the PIC work internally?

The PIC has three main internal registers (small storage areas):
- **IRR (Interrupt Request Register)**: remembers which devices have asked for attention. If device 2 sends a request, bit 2 of IRR becomes 1.
- **ISR (In‑Service Register)**: remembers which device the CPU is currently handling.
- **IMR (Interrupt Mask Register)**: a mask – if a bit is 1, that device is blocked (masked) and will not interrupt the CPU even if it asks.

When the PIC receives a request from a device, it stores it in IRR. Then it looks at the IMR: if the device is not masked, the PIC compares its priority with any device already in ISR. The lowest device number has the highest priority (0 is highest, 7 is lowest). If the new request has higher priority than the one being serviced, the PIC raises a signal called **INT_REQ** (Interrupt Request) to the CPU.

When the CPU is ready, it sends back an **INTA** (Interrupt Acknowledge) signal. The PIC then:
- Puts a vector number on the data bus (e.g., base vector + device number).
- Moves the request from IRR to ISR (because the CPU is now handling it).
- Clears that bit in IRR.
- Lowers INT_REQ.

After the CPU finishes handling the device, it sends an **EOI** (End of Interrupt) command to the PIC. The PIC then clears the corresponding bit in ISR, so that lower priority interrupts can now be accepted.

## What files are in this repository?

(1) design folder contains:
    - priority_encoder.v – finds the highest priority device among those requesting.
    - programmable_pic.v – the main PIC circuit.

(2) tb folder contains:
    - tb_programmable_pic.v – a testbench that pretends to be a CPU and some devices.

(3) sim – folder for simulation outputs (created when you run the simulation).

(4) .gitignore file – tells Git which files not to upload.

(5) README.md file – this file.

(6) outputs folder contains screenshots of outputs after executing the "vvp sim/pic_sim.vvp" command in the code editors like vscode.

## How to run this project on your own laptop (Windows)

You do not need any special hardware. You will use free software that simulates the electronic circuit on your computer.

### Step 1 – Install the required tools

You need two free programs:

1. **Icarus Verilog** – this compiles and runs the Verilog code.
2. **GTKWave** – this shows the signal waveforms (like a time‑based graph of what happens inside the PIC).

**Download and install Icarus Verilog (includes GTKWave):**

- Go to: http://bleyer.org/icarus/
- Download the file named `iverilog-v12-20220611-x64_setup.exe` (or the latest similar one).
- Run the downloaded file.
- During installation, when asked, choose the option **"Add executable folder(s) to the user PATH"** (this makes the tools work from the command line).
- Also make sure **"Install GTKWave"** is selected.
- Finish the installation.

**Important:** After installation, **restart your computer** (or at least close all terminal windows and VS Code).

### Step 2 – Download this project from GitHub

- Open a web browser and go to the GitHub link of this project.
- Click the green button **"Code"** → **"Download ZIP"**.
- Save the ZIP file on your Desktop, then right‑click it and choose **"Extract All"**.
- You will get a folder named something like `Programmable-Priority-Interrupt-Controller-PIC-master`. Rename it to `PIC_Project` (shorter is easier).

### Step 3 – Open a terminal (command window)

- Press the **Windows** key, type `cmd`, and press Enter. A black window appears.
- Navigate to your project folder. For example, if the folder is on your Desktop:

cd Desktop\PIC_Project

(Press Enter after each command.)

### Step 4 – Compile the Verilog code

Type this command and press Enter:

iverilog -o sim/pic_sim.vvp design/priority_encoder.v design/programmable_pic.v tb/tb_programmable_pic.v

If you see no error messages, the compilation succeeded. If you see "No such file or directory", you are not in the correct folder – go back to Step 3.

### Step 5 – Run the simulation

Type:

```bash
vvp sim/pic_sim.vvp
```

The testbench sends random interrupt requests, and the PIC responds. The simulation runs for a short time and then finishes.

NOTE - The output which you will see after executing the above is attached in the outputs folder in the form of a .jpg file.

### Step 6 – View the waveform

Now type:

gtkwave wave.vcd

GTKWave will open.

**How to see the signals:**
- In the left panel, you see a list of signals. Click the `+` next to `tb_programmable_pic`, then click the `+` next to `dut`.
- Select the following signals by clicking on them (use Ctrl+click to select multiple):
  - `clk` (clock)
  - `rst` (reset)
  - `irq[7:0]` (interrupt requests from devices)
  - `int_req` (PIC asking CPU)
  - `inta` (CPU acknowledging)
  - `data_bus[7:0]` (vector value)
  - `dut.irr[7:0]` (request register)
  - `dut.isr[7:0]` (in‑service register)
  - `dut.imr[7:0]` (mask register)
- Click the **Append** button at the bottom of the panel. The signals will appear in the main window.

**Navigate the waveform:**
- Use the mouse to zoom in (right‑click and drag horizontally to select a region, then click "Zoom Fit" or use the magnifying glass icons).
- Place the cursor by left‑clicking on the waveform area. The time difference will be shown.

**What to look for:**
- After reset (rst goes low), the IMR is 0xFF (all bits 1). Then the testbench writes 0x00 to IMR (unmask all). You will see the IMR bits change.
- When an irq bit (e.g., irq[2]) goes high, the IRR bit 2 becomes 1, and then int_req goes high.
- When inta goes high, the data_bus shows a number (e.g., 0x42 if base is 0x40 and device is 2). Also the ISR bit 2 becomes 1 and IRR bit 2 becomes 0.
- Later, an EOI (command 0x20) clears the ISR bit.

## Understanding the testbench output

The testbench (tb_programmable_pic.v) does the following automatically:
1. Resets the PIC.
2. Writes base vector 0x40 (so device 0 will use vector 0x40, device 1 uses 0x41, etc.).
3. Writes 0x00 to IMR (unmask all devices).
4. Generates random interrupt requests (irq bits) every few nanoseconds.
5. When int_req is high, it simulates the CPU by sending inta and printing the received vector.
6. Sometimes it sends an EOI (0x20) to clear the ISR.

The printed lines like `CPU Received Vector: 0x42` tell you which device was acknowledged: 0x42 – 0x40 = 2 → device 2.

The `$monitor` line shows you the current state at each time step.

## This project ables you to understand...

By building this PIC, you can demonstrate:
- How to design a finite state machine in Verilog.
- How to handle multiple asynchronous events (interrupts).
- How to implement priority arbitration.
- How to make a circuit programmable via registers.
- How to simulate and verify digital logic using free tools.

## License

This project is open source. You may use it for learning or teaching.

## Author

AkshatModi 

---
