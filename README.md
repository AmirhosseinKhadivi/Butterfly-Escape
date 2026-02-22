<h1 align="center">CAD Project (FPGA VGA Game)</h1>

<p align="center">
  <b>VHDL-Based FPGA Game Project with VGA Graphics and Peripheral Control</b>
</p>

<hr />

<h2>Overview</h2>
<p>
  This project implements an FPGA-based <b>VGA game system</b> written in <b>VHDL</b>.
  It uses a <b>24 MHz clock</b> to generate VGA RGB signals and synchronization signals
  (<code>HS</code>/<code>VS</code>). The design also supports interaction through
  <b>keys</b> and <b>switches</b>, and provides output via <b>LEDs</b> and a
  <b>7-segment display</b>.
</p>

<h2>Features</h2>
<ul>
  <li><b>VGA Graphics Output</b>: RGB + HS/VS signals for VGA display</li>
  <li><b>Game Controls</b>: Input handling using keys and switches</li>
  <li><b>LED Feedback</b>: Visual status output on onboard LEDs</li>
  <li><b>7-Segment Display</b>: Displays useful values (score/state/debug)</li>
</ul>

<h2>Hardware Requirements</h2>
<ul>
  <li>FPGA development board (Intel/Altera or Xilinx)</li>
  <li>VGA monitor + cable</li>
  <li>Keys, switches, LEDs (usually onboard)</li>
  <li>7-segment display (onboard or external)</li>
  <li>24 MHz clock source</li>
</ul>

<h2>Software Requirements</h2>
<ul>
  <li>VHDL-compatible toolchain (Xilinx ISE)</li>
  <li>Optional: simulator (ModelSim / Vivado Simulator)</li>
</ul>

<h2>Top-Level Module</h2>
<p>
  The main entity is <code>CAD</code> and includes ports for clock/reset, VGA output,
  keys/switches input, LED output, and 7-segment display output.
</p>

<h2>How to Use</h2>
<ol>
  <li>Open the project in your FPGA tool (just ISE because the Board is spartan 6).</li>
  <li>Assign pins based on your board’s VGA/LED/7-seg connections.</li>
  <li>Compile / synthesize the design and program the FPGA.</li>
  <li>Connect a VGA monitor and use keys/switches to play/control the game.</li>
</ol>

<h2>Example (VGA Output Mapping)</h2>
<pre><code class="language-vhdl">VGA_R  &lt;= VGA_R_port;
VGA_G  &lt;= VGA_G_port;
VGA_B  &lt;= VGA_B_port;
VGA_HS &lt;= VGA_HS_port;
VGA_VS &lt;= VGA_VS_port;</code></pre>


<h2>Contributors</h2>
<ul>
  <li><b>Amirhossein Khadivi</b></li>
  <li><b>Behnam Moayedi</b></li>
</ul>

<h2>License</h2>
<p>
  This project is licensed under the <b>MIT License</b>. See the <code>LICENSE</code> file for details.
</p>
