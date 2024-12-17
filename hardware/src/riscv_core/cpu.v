`include "opcode.vh"
module cpu #(
    parameter CPU_CLOCK_FREQ = 50_000_000,
    parameter RESET_PC = 32'h4000_0000,
    parameter BAUD_RATE = 115200
) (
    input clk,
    input rst,
    input bp_enable,
    input serial_in,
    output serial_out
);
    // BIOS Memory
    // Synchronous read: read takes one cycle
    // Synchronous write: write takes one cycle
    wire [11:0] bios_addra, bios_addrb;
    wire [31:0] bios_douta, bios_doutb;
    reg bios_ena;
    reg bios_enb;
    bios_mem bios_mem (
      .clk(clk),
      .ena(bios_ena),
      .addra(bios_addra),
      .douta(bios_douta),
      .enb(bios_enb),
      .addrb(bios_addrb),
      .doutb(bios_doutb)
    );

    // Data Memory
    // Synchronous read: read takes one cycle
    // Synchronous write: write takes one cycle
    // Write-byte-enable: select which of the four bytes to write
    wire [13:0] dmem_addr;
    reg [31:0] dmem_din;
	wire [31:0] dmem_dout;
    reg [3:0] dmem_we;
    reg dmem_en;
    dmem dmem (
      .clk(clk),
      .en(dmem_en),
      .we(dmem_we),
      .addr(dmem_addr),
      .din(dmem_din),
      .dout(dmem_dout)
    );

    // Instruction Memory
    // Synchronous read: read takes one cycle
    // Synchronous write: write takes one cycle
    // Write-byte-enable: select which of the four bytes to write
    wire [31:0] imem_dina, imem_doutb;
    wire [13:0] imem_addra, imem_addrb;
    reg [3:0] imem_wea;
    reg imem_ena;
    imem imem (
      .clk(clk),
      .ena(imem_ena),
      .wea(imem_wea),
      .addra(imem_addra),
      .dina(imem_dina),
      .addrb(imem_addrb),
      .doutb(imem_doutb)
    );

    // Register file
    // Asynchronous read: read data is available in the same cycle
    // Synchronous write: write takes one cycle
    wire we;
    wire [4:0] ra1, ra2, wa;
    wire [31:0] wd;
    wire [31:0] rd1, rd2;
    reg_file rf (
        .clk(clk),
        .we(we),
        .ra1(ra1), .ra2(ra2), .wa(wa),
        .wd(wd),
        .rd1(rd1), .rd2(rd2)
    );

    // On-chip UART
    // UART Receiver
    wire [7:0] uart_rx_data_out;
    wire uart_rx_data_out_valid;
    reg uart_rx_data_out_ready; 
    // UART Transmitter
    wire [7:0] uart_tx_data_in;
    reg uart_tx_data_in_valid; 
    wire uart_tx_data_in_ready;
    uart #(
        .CLOCK_FREQ(CPU_CLOCK_FREQ),
        .BAUD_RATE(BAUD_RATE)
    ) on_chip_uart (
        .clk(clk),
        .reset(rst), 

        .serial_in(serial_in), 
        .data_out(uart_rx_data_out),
        .data_out_valid(uart_rx_data_out_valid), 
        .data_out_ready(uart_rx_data_out_ready), 

        .serial_out(serial_out), 
        .data_in(uart_tx_data_in),
        .data_in_valid(uart_tx_data_in_valid),
        .data_in_ready(uart_tx_data_in_ready)
    );

    reg [31:0] tohost_csr = 0;

    

	/*********************** IF STAGE ****************************/

    // PC MUX
    wire [2:0] PC_mux_select;
    wire [31:0] PC_mux_in_0, PC_mux_in_1, PC_mux_in_2, PC_mux_in_3, PC_mux_in_4;
    wire [31:0] PC_mux_out;
    MUX5 pc_mux (
        .sel(PC_mux_select),
        .in0(PC_mux_in_0),
        .in1(PC_mux_in_1),
        .in2(PC_mux_in_2),
        .in3(PC_mux_in_3),
        .in4(PC_mux_in_4),
        .out(PC_mux_out)
    );

	 // PC + 4
    wire [31:0] PCP4_in;
    wire [31:0] PCP4_out;
    assign PCP4_out = PCP4_in + 4;

    // PC REG
    wire [31:0] PC_reg_in;
    reg [31:0] PC_reg_out;
    always @(posedge clk) begin
        PC_reg_out <= PC_reg_in;
    end

    // PC[30] MUX
    wire PC30_mux_select;
    wire [31:0] PC30_mux_in_0, PC30_mux_in_1;
    wire [31:0] PC30_mux_out;
    MUX2 pc30_mux (
        .sel(PC30_mux_select),
        .in0(PC30_mux_in_0),
        .in1(PC30_mux_in_1),
        .out(PC30_mux_out)
    );

    // NOP MUX
    wire NOP_mux_select;
    wire [31:0] NOP_mux_in;
    wire [31:0] NOP_mux_out;
    MUX2 nop_mux (
        .sel(NOP_mux_select),
        .in0(NOP_mux_in),
        .in1(19),
        .out(NOP_mux_out)
    );

    // IF WIRING
    assign bios_addra = PC_mux_out[15:2];
    assign imem_addrb = PC_mux_out[15:2];


    assign PCP4_in = PC_reg_out;
    // assign PC_mux_in_2 = PCP4_out;
    assign PC_mux_in_0 = RESET_PC;

    assign PC_reg_in = PC_mux_out;
    assign PC_mux_in_4 = PC_reg_out;


    always @(*) begin
        if (PC_mux_out[31:28] == 4) bios_ena = 1;
        else bios_ena = 0;
    end



    /*********************** D STAGE ****************************/
	

    // BR Taken MUX
    wire br_taken_mux_sel;
  	wire [31:0] br_taken_mux_in0, br_taken_mux_in1;
	wire [31:0] br_taken_mux_out;
	MUX2 br_taken_mux (
		.sel(br_taken_mux_sel),
		.in0(br_taken_mux_in0),
		.in1(br_taken_mux_in1),
		.out(br_taken_mux_out)
	);

    // BP Enable MUX
    wire bp_enable_mux_sel;
  	wire [31:0] bp_enable_mux_in0, bp_enable_mux_in1;
	wire [31:0] bp_enable_mux_out;
	MUX2 bp_enable_mux (
		.sel(bp_enable_mux_sel),
		.in0(bp_enable_mux_in0),
		.in1(bp_enable_mux_in1),
		.out(bp_enable_mux_out)
	);

    // Branch Prediction Taken/Not Taken MUX
    wire bp_pred_taken_mux_sel;
  	wire [31:0] bp_pred_taken_mux_in0, bp_pred_taken_mux_in1;
	wire [31:0] bp_pred_taken_mux_out;
	MUX2 bp_pred_taken_mux (
		.sel(bp_pred_taken_mux_sel),
		.in0(bp_pred_taken_mux_in0),
		.in1(bp_pred_taken_mux_in1),
		.out(bp_pred_taken_mux_out)
	);


	// RS1 MUX
    wire RS1_mux_select;
    wire [31:0] RS1_mux_in_0, RS1_mux_in_1;
    wire [31:0] RS1_mux_out;
    MUX2 rs1_mux (
        .sel(RS1_mux_select),
        .in0(RS1_mux_in_0),
        .in1(RS1_mux_in_1),
        .out(RS1_mux_out)
    );

	// RS2 MUX
    wire RS2_mux_select;
    wire [31:0] RS2_mux_in_0, RS2_mux_in_1;
    wire [31:0] RS2_mux_out;
    MUX2 rs2_mux (
        .sel(RS2_mux_select),
        .in0(RS2_mux_in_0),
        .in1(RS2_mux_in_1),
        .out(RS2_mux_out)
    );

    // Branch Predictor
    wire [31:0] pc_guess, pc_check;
    wire is_br_guess, is_br_check, br_taken_check, br_pred_taken;
    branch_predictor br_predictor (
        .clk(clk),
        .reset(rst),
        .pc_guess(pc_guess),
        .is_br_guess(is_br_guess),
        .pc_check(pc_check),
        .is_br_check(is_br_check),
        .br_taken_check(br_taken_check),
        .br_pred_taken(br_pred_taken)
    );

    // RS1 REG
    wire [31:0] RS1_reg_in;
    reg [31:0] RS1_reg_out;
    always @(posedge clk) begin
        RS1_reg_out <= RS1_reg_in;
    end

    // RS2 REG
    wire [31:0] RS2_reg_in;
    reg [31:0] RS2_reg_out;
    always @(posedge clk) begin
        RS2_reg_out <= RS2_reg_in;
    end

    // INST D REG
    wire [31:0] INST_D_reg_in;
    reg [31:0] INST_D_reg_out;
    always @(posedge clk) begin
        INST_D_reg_out <= INST_D_reg_in;
    end

     // PC D REG
    wire [31:0] PC_D_reg_in;
    reg [31:0] PC_D_reg_out;
    always @(posedge clk) begin
        PC_D_reg_out <= PC_D_reg_in;
    end


    // BP REG
    wire [31:0] BR_pred_taken_reg_in;
    reg [31:0] BR_pred_taken_reg_out;
    always @(posedge clk) begin
        BR_pred_taken_reg_out <= BR_pred_taken_reg_in;
    end


	// JAL ADD
    wire [31:0] JAL_add_in_0, JAL_add_in_1;
    wire [31:0] JAL_add_out;
    assign JAL_add_out = JAL_add_in_0 + JAL_add_in_1;
	
	// Wiring for D stage

    assign PC_D_reg_in = PC_reg_out; // for pc pipeline register in decode stage
	assign INST_D_reg_in = NOP_mux_out; // for instruction pipeline register in decode stage

	assign PC30_mux_in_0 = imem_doutb;
	assign PC30_mux_in_1 = bios_douta;
	
	assign NOP_mux_in = PC30_mux_out;


    // wiring to regfile
    assign ra1 = NOP_mux_out[19:15];
    assign ra2 = NOP_mux_out[24:20];

	assign JAL_add_in_0 = PC_reg_out;
	assign JAL_add_in_1 = {{20{NOP_mux_out[31]}}, NOP_mux_out[19:12], NOP_mux_out[20], NOP_mux_out[30:21], 1'b0};

    assign RS1_reg_in = RS1_mux_out;
	assign RS2_reg_in = RS2_mux_out;

	assign PC_mux_in_1 = JAL_add_out;

	assign RS1_mux_in_0 = rd1;
	assign RS2_mux_in_0 = rd2;


    // Wiring for Branch Predictor
    assign pc_guess = PC_reg_out;
    assign is_br_guess = NOP_mux_out[6:2] == `OPC_BRANCH_5;

    // BP Enable MUX Wiring
    assign bp_enable_mux_sel = bp_enable;
    assign bp_enable_mux_in0 = PCP4_out;
    assign bp_enable_mux_in1 = br_taken_mux_out;

    // BR Taken MUX Wiring
    assign br_taken_mux_sel = (br_pred_taken) && (NOP_mux_out[6:2] == `OPC_BRANCH_5);
    assign br_taken_mux_in0 = PCP4_out;
    assign br_taken_mux_in1 = PC_reg_out + {{20{NOP_mux_out[31]}}, NOP_mux_out[7], NOP_mux_out[30:25], NOP_mux_out[11:8], 1'b0};

    // BR Pred Taken/Not Taken and BR Pred Taken Register
    assign bp_pred_taken_mux_sel = bp_enable;
    assign bp_pred_taken_mux_in0 = 0; // For no Branch prediction (always guess not taken)
    assign bp_pred_taken_mux_in1 = br_pred_taken; // Branch prediction output
    assign BR_pred_taken_reg_in = bp_pred_taken_mux_out;

    // PC Sel Input 2
    assign PC_mux_in_2 = bp_enable_mux_out;


    /*********************** EX STAGE ****************************/


    // INST EX REG
    wire [31:0] INST_X_reg_in;
    reg [31:0] INST_X_reg_out;
    always @(posedge clk) begin
        INST_X_reg_out <= INST_X_reg_in;
    end

    // PC EX REG
    wire [31:0] PC_X_reg_in;
    reg [31:0] PC_X_reg_out;
    always @(posedge clk) begin
        PC_X_reg_out <= PC_X_reg_in;
    end

    // RS1 MUX2
    wire [1:0] RS1_mux2_select;
    wire [31:0] RS1_mux2_in_0, RS1_mux2_in_1, RS1_mux2_in_2;
    wire [31:0] RS1_mux2_out;
    MUX4 RS1_mux2 (
        .sel(RS1_mux2_select),
        .in0(RS1_mux2_in_0),
        .in1(RS1_mux2_in_1),
        .in2(RS1_mux2_in_2),
        .in3(0),
        .out(RS1_mux2_out)
    );

    // RS2 MUX2
    wire [1:0] RS2_mux2_select;
    wire [31:0] RS2_mux2_in_0, RS2_mux2_in_1, RS2_mux2_in_2;
    wire [31:0] RS2_mux2_out;
    MUX4 RS2_mux2 (
        .sel(RS2_mux2_select),
        .in0(RS2_mux2_in_0),
        .in1(RS2_mux2_in_1),
        .in2(RS2_mux2_in_2),
        .in3(0),
        .out(RS2_mux2_out)
    );

     // ALU REG
    wire [31:0] ALU_reg_in;
    reg [31:0] ALU_reg_out;
    always @(posedge clk) begin
        ALU_reg_out <= ALU_reg_in;
    end

    // IMM GEN
    wire [31:0] IMMGEN_in;
    wire [31:0] IMMGEN_out;
    IMM_GEN imm_gen (
        .inst(IMMGEN_in), 
        .imm(IMMGEN_out)
    );



    // BRANCH COMP
    wire [31:0] RS1_br;
    wire [31:0] RS2_br;
    wire br_un;
    wire br_eq;
    wire br_lt;
    BRANCH_COMP branch_comp (
    .branch_unsigned(br_un),
        .amux_output(RS1_br),
        .bmux_output(RS2_br),
        .Equality(br_eq),
        .LessThan(br_lt)
    );

    // ALU
    wire [3:0] ALU_select;
    wire [31:0] ALU_RS1, ALU_RS2;
    wire [31:0] ALU_out;
    ALU alu (
        .alu_select(ALU_select), 
        .amux_output(ALU_RS1), 
        .bmux_output(ALU_RS2), 
        .result(ALU_out)
    );

    // A MUX
    wire [1:0] A_mux_select;
    wire [31:0] A_mux_in_0, A_mux_in_1, A_mux_in_2;
    wire [31:0] A_mux_out;
    MUX4 A_mux (
        .sel(A_mux_select),
        .in0(A_mux_in_0),
        .in1(A_mux_in_1),
        .in2(A_mux_in_2),
        .in3(0),
        .out(A_mux_out)
    );

    // B MUX
    wire [1:0] B_mux_select;
    wire [31:0] B_mux_in_0, B_mux_in_1;
    wire [31:0] B_mux_out;
    MUX2 B_mux (
        .sel(B_mux_select),
        .in0(B_mux_in_0),
        .in1(B_mux_in_1),
        .out(B_mux_out)
    );

    // CSR MUX
    wire [1:0] CSR_mux_select;
    wire [31:0] CSR_mux_in_0, CSR_mux_in_1, CSR_mux_in_2;
    wire [31:0] CSR_mux_out;
    MUX4 csr_mux (
        .sel(CSR_mux_select),
        .in0(CSR_mux_in_0),
        .in1(CSR_mux_in_1),
        .in2(CSR_mux_in_2),
        .in3(0),
        .out(CSR_mux_out)
    );

    wire br_result_mux_sel;
    wire [31:0] br_result_mux_in0, br_result_mux_in1;
    wire [31:0] br_result_mux_out;
    MUX2 br_result_mux (
		.sel(br_result_mux_sel),
		.in0(br_result_mux_in0),
		.in1(br_result_mux_in1),
		.out(br_result_mux_out)
	);

    wire [31:0] csr_in;
    always @(posedge clk) begin
        tohost_csr <= csr_in;
    end

    // RS2 MUX3 (MUX going to memory from RS2)
    wire [1:0] RS2_mux3_select;
    wire [31:0] RS2_mux3_in_0, RS2_mux3_in_1, RS2_mux3_in_2;
    wire [31:0] RS2_mux3_out;
    MUX4 rs2_mux3 (
        .sel(RS2_mux3_select),
        .in0(RS2_mux3_in_0),
        .in1(RS2_mux3_in_1),
        .in2(RS2_mux3_in_2),
        .in3(0),
        .out(RS2_mux3_out)
    );
    
    reg [1:0] Addr_mux_select;
    wire [31:0] Addr_mux_in_0, Addr_mux_in_1, Addr_mux_in_2, Addr_mux_in_3;
    wire [31:0] Addr_mux_out;
    MUX4 addr (
        .sel(Addr_mux_select),
        .in0(Addr_mux_in_0),
        .in1(Addr_mux_in_1),
        .in2(Addr_mux_in_2),
        .in3(Addr_mux_in_3),
        .out(Addr_mux_out)
    );

    // Addr_mux_select
    always @(*) begin
        case(ALU_reg_out[31:28])
            4'b0001: Addr_mux_select = 2'b01;
            4'b0011: Addr_mux_select = 2'b01;
            4'b0100: Addr_mux_select = 2'b00;
            4'b1000: Addr_mux_select = 2'b10;
            default: begin
                Addr_mux_select = 2'b01;
            end
        endcase
    end


    // MEM_MASK for LOAD/STORE
    wire [31:0] mem_mask_in;
    wire [2:0] mem_mask_select;
    wire [31:0] mem_mask_out;
	wire [31:0] mem_mask_alu_out;
    MEM_MASK ldx (
        .mem_mask_in(mem_mask_in), 
        .mem_mask_select(mem_mask_select), 
        .mem_mask_out(mem_mask_out),
		.mem_mask_alu_out(mem_mask_alu_out)
    );

    wire [31:0] PCP4_2_in;
    wire [31:0] PCP4_2_out;
    assign PCP4_2_out = PCP4_2_in + 4;


    wire [1:0] WB_mux_select;
  	wire [31:0] WB_mux_in_0, WB_mux_in_1, WB_mux_in_2, WB_mux_in_3;
	wire [31:0] WB_mux_out;
	MUX4 wb_mux (
		.sel(WB_mux_select),
		.in0(WB_mux_in_0),
		.in1(WB_mux_in_1),
		.in2(WB_mux_in_2),
		.in3(WB_mux_in_3),
		.out(WB_mux_out)
	);

	// Wiring for EX stage
	assign INST_X_reg_in = INST_D_reg_out;
	assign IMMGEN_in = INST_D_reg_out;

    // input to PC X REG
    assign PC_X_reg_in = PC_D_reg_out;

    // input to ALU REG
    assign ALU_reg_in = ALU_out;

    // inputs to A MUX
    assign A_mux_in_0 = RS1_mux2_out;
    assign A_mux_in_1 = PC_D_reg_out;
    assign A_mux_in_2 = mem_mask_out;

    // inputs to B MUX
    assign B_mux_in_0 = RS2_mux2_out;
    assign B_mux_in_1 = IMMGEN_out;

    // inputs to ALU
    assign ALU_RS1 = A_mux_out;
    assign ALU_RS2 = B_mux_out;

    // inputs to RS1 MUX2
	assign RS1_mux2_in_0 = RS1_reg_out;
	assign RS1_mux2_in_1 = ALU_reg_out; // ALU->ALU forwarding
	assign RS1_mux2_in_2 = mem_mask_out; // MEM->ALU forwarding

	assign RS2_mux2_in_0 = RS2_reg_out;
	assign RS2_mux2_in_1 = ALU_reg_out; // ALU->ALU forwarding
	assign RS2_mux2_in_2 = mem_mask_out; // MEM->ALU forwarding

    // inputs to BRANCH COMP
    assign RS1_br = RS1_mux2_out;
    assign RS2_br = RS2_mux2_out;

    // inputs to CSR_MUX
    assign CSR_mux_in_0 = csr_in;
    assign CSR_mux_in_1 = IMMGEN_out;
    assign CSR_mux_in_2 = RS1_mux2_out;

    // input to CSR REG
    assign csr_in = CSR_mux_out;

    // inputs to RS2_MUX3
    assign RS2_mux3_in_0 = RS2_mux2_out;
    assign RS2_mux3_in_1 = ALU_reg_out; 
    assign RS2_mux3_in_2 = mem_mask_out; 

	// input to mem_mask for load
	assign mem_mask_alu_out = ALU_reg_out;


    // FORWARD DATA D TO RS1 MUX and RS2 MUX
    assign RS1_mux_in_1 = WB_mux_out;
    assign RS2_mux_in_1 = WB_mux_out;

    // Branch Prediction Wiring
    assign pc_check = PC_D_reg_out;
    assign is_br_check = INST_D_reg_out[6:2] == `OPC_BRANCH_5;

    // BR Result Mux
    assign br_result_mux_in0 = ALU_out;
    assign br_result_mux_in1 = PC_D_reg_out + 4;
    assign PC_mux_in_3 = br_result_mux_out;


    /*********************** MEMORY ****************************/


    // input to DMEM
    assign dmem_addr = ALU_out[15:2];

	always @(*) begin
		dmem_din = RS2_mux3_out << (8 * ALU_out[1:0]);
	end

    //assign dmem_din = RS2_mux3_out;
    always @(*) begin
        case(INST_D_reg_out[6:2])
            `OPC_LOAD_5: begin
                if (ALU_out[31:28] == 4'b0001 || ALU_out[31:28] == 4'b0011) dmem_en = 1;
                else dmem_en = 0;
            end
            `OPC_STORE_5: begin
                if (ALU_out[31:28] == 4'b0001 || ALU_out[31:28] == 4'b0011) dmem_en = 1;
                else dmem_en = 0;
            end
            default: begin
                dmem_en = 0;
            end
        endcase
    end


    // input to BIOS
    assign bios_addrb = ALU_out[13:2];
    always @(*) begin
        if (INST_D_reg_out[6:2] == `OPC_LOAD_5 && ALU_out[31:28] == 4'b0100) bios_enb = 1;
        else bios_enb = 0;
    end

    // input to IMEM
    assign imem_addra = ALU_out[15:2];
    assign imem_dina = RS2_mux3_out;

    always @(*) begin
        if (INST_D_reg_out[6:2] == `OPC_STORE_5 && (ALU_out[31:28] == 4'b0010 || ALU_out[31:28] == 4'b0011) && PC_D_reg_out[30] == 1'b1) begin
            imem_ena = 1;
        end
        else begin 
            imem_ena = 0;
        end
    end

    // input to UART
    wire [31:0] INST_uart_lw, INST_uart_sw, Addr_uart_lw, Addr_uart_sw;
    reg [31:0] uart_out;

    assign INST_uart_sw = INST_D_reg_out;
    assign INST_uart_lw = INST_X_reg_out;
    assign Addr_uart_sw = ALU_out;
    assign Addr_uart_lw = ALU_reg_out;
    assign uart_tx_data_in = RS2_mux3_out[7:0];

    // Addr MUX input
    assign Addr_mux_in_0 = bios_doutb;
    assign Addr_mux_in_1 = dmem_dout;
    assign Addr_mux_in_2 = uart_out;
    assign Addr_mux_in_3 = 0;
    
    // mem_mask input
    assign mem_mask_in = Addr_mux_out;

    // PC + 4 in X stage input
    assign PCP4_2_in = PC_X_reg_out;

    // WB mux
    assign WB_mux_in_0 = mem_mask_out;
    assign WB_mux_in_1 = ALU_reg_out;
    assign WB_mux_in_2 = PCP4_2_out;

    // wb to regfile
    assign wa = INST_X_reg_out[11:7];
    assign wd = WB_mux_out;
    


    /*********************** IF CONTROL LOGIC ****************************/

    
    wire [31:0] INST_IF;
    wire [31:0] INST_IF_X;
    wire rf_we;
    wire [1:0] WB_select;
    wire [2:0] mem_mask_select_IF, PC_select_IF;
    wire jal_IF;
    wire jalr_IF;
    wire br_taken_IF;
    wire br_pred_correct_IF;
    IF_CONTROL_LOGIC if_control_logic (
        .rst(rst),
        .instruction(INST_IF), 
        .x_instruction(INST_IF_X), 
        .wb_select(WB_select), 
        .pc_select(PC_select_IF),
        .mem_mask_select(mem_mask_select_IF), 
        .rf_we(rf_we),
        .jal(jal_IF),
        .jalr(jalr_IF),
        .br_taken(br_taken_IF),
        .br_pred_correct(br_pred_correct_IF)
    );

    assign INST_IF = INST_X_reg_out;
    assign we = rf_we;
    assign WB_mux_select = WB_select;
    assign mem_mask_select = mem_mask_select_IF;
    assign PC_mux_select = PC_select_IF;
    assign jal_IF = (NOP_mux_out[6:2] == `OPC_JAL_5) ? 1 : 0;
    assign jalr_IF = (INST_D_reg_out[6:2] == `OPC_JALR_5) ? 1 : 0;
    assign INST_IF_X = INST_D_reg_out;


    /*********************** D CONTROL LOGIC ****************************/


    wire [31:0] INST_D;
    wire [31:0] PC_D;
    wire [31:0] INST_IF_W;
    wire [31:0] INST_X_D;
    wire PC30_D, NOP_select_D, orange_select_D, green_select_D;
    wire jalr_D;
    wire br_taken_D;
    wire br_pred_correct_D;
    D_CONTROL_LOGIC d_control_logic (
        .instruction(INST_D), 
        .IF_instruction(INST_IF_W),
        .X_instruction(INST_X_D),
        .PC(PC_D), 
        .PC30(PC30_D), 
        .NOP_select(NOP_select_D), 
        .hazard1(orange_select_D), 
        .hazard2(green_select_D),
        .jalr(jalr_D),
        .br_taken(br_taken_D),
        .br_pred_correct(br_pred_correct_D)
    );

    assign INST_D = NOP_mux_out;
    assign PC_D = PC_reg_out;
    assign PC30_mux_select = PC30_D;
    assign NOP_mux_select = NOP_select_D;
    assign RS1_mux_select = orange_select_D;
    assign RS2_mux_select = green_select_D;
    assign jalr_D = (INST_D_reg_out[6:2] == `OPC_JALR_5) ? 1 : 0;
    assign INST_IF_W = INST_X_reg_out;
    assign INST_X_D = INST_D_reg_out;
    
    /*********************** EX CONTROL LOGIC ****************************/


    wire [31:0] INST_X, INST_X_IF;
    wire br_eq_X, br_lt_X;
    wire br_un_X, b_select_X;
    wire [1:0] orange_select_X, green_select_X, a_select_X, RS2_select_X, CSR_select_X;
    wire [3:0] ALU_select_X;
	wire br_taken_X;
    wire br_pred_taken_X, br_pred_correct_X, br_result_X;
    X_CONTROL_LOGIC x_control_logic (
        .instruction(INST_X),
        .IF_instruction(INST_X_IF), 
        .a_select(a_select_X), 
        .b_select(b_select_X), 
        .hazard1(orange_select_X), 
        .hazard2(green_select_X), 
        .RS2_select(RS2_select_X), 
        .ALU_select(ALU_select_X), 
        .CSR_select(CSR_select_X),
        .br_un(br_un_X), 
        .br_eq(br_eq_X), 
        .br_lt(br_lt_X), 
		.br_taken(br_taken_X),
        .br_pred_taken(br_pred_taken_X),
        .br_pred_correct(br_pred_correct_X),
        .br_result(br_result_X)
    );

    assign INST_X = INST_D_reg_out;
    assign br_eq_X = br_eq;
    assign br_lt_X = br_lt;
    assign br_un = br_un_X;
    assign RS1_mux2_select = orange_select_X;
    assign RS2_mux2_select = green_select_X;
    assign A_mux_select = a_select_X;
    assign B_mux_select = b_select_X;
    assign RS2_mux3_select = RS2_select_X;
    assign ALU_select = ALU_select_X;
    assign CSR_mux_select = CSR_select_X;
	assign br_taken_IF = br_taken_X;
	assign INST_X_IF = INST_X_reg_out;
    assign br_pred_taken_X = BR_pred_taken_reg_out;

    assign br_taken_D = br_taken_X;

    // Wiring for Branch Predictor
    assign br_taken_check = br_taken_X;

    // Wiring for BR Result Mux
    assign br_result_mux_sel = br_result_X;

    // Wiring for br_pred_correct to other modules
    assign br_pred_correct_IF = br_pred_correct_X;
    assign br_pred_correct_D = br_pred_correct_X;

    IO_MEMORY_MAP io_memory_map (
        .clk(clk),
        .uart_rx_data_out_valid(uart_rx_data_out_valid),
        .uart_tx_data_in_ready(uart_tx_data_in_ready),
        .INST_uart_lw(INST_uart_lw),
        .INST_uart_sw(INST_uart_sw),
        .Addr_uart_lw(Addr_uart_lw),
        .Addr_uart_sw(Addr_uart_sw),
        .uart_rx_data_out(uart_rx_data_out),
        .br_pred_correct_X(br_pred_correct_X),
        .uart_out(uart_out),
        .uart_rx_data_out_ready(uart_rx_data_out_ready),
        .uart_tx_data_in_valid(uart_tx_data_in_valid)
    );


    // MEMORY COMBINATIONAL LOGIC for IMEM and DMEM
	MEM_CL mem_cl(
        .INST_X(INST_X),
        .ALU_out(ALU_out),
        .dmem_we(dmem_we),
        .imem_wea(imem_wea)
    );

endmodule
