/* Copyright (c) 2024 Tobias Scheipel, David Beikircher, Florian Riedl
 * Embedded Architectures & Systems Group, Graz University of Technology
 * SPDX-License-Identifier: MIT
 * ---------------------------------------------------------------------
 * File: fetch_stage.sv
 */



module fetch_stage (
    input logic clk,
    input logic rst,

    // Memory interface
    wishbone_interface.master wb,

    //  Output data
    output logic [31:0] instruction_reg_out,
    output logic [31:0] program_counter_reg_out,

    // Pipeline control
    output pipeline_status::forwards_t  status_forwards_out,
    input  pipeline_status::backwards_t status_backwards_in,
    input  logic [31:0] jump_address_backwards_in
);

    // Internal signals
    logic [31:0] pc;
    logic [31:0] instruction_mem [0:20];
    logic [31:0] if_id_pc;
    logic [31:0] if_id_instruction;

    initial begin
        instruction_mem[0] = constants.RESET_ADDRESS;
    end

    // PC update
    always_ff @( posedge clk or posedge rst ) begin : pcUpdate
        if (rst) begin
            pc <= constants.RESET_ADDRESS;
        end else if (status_backwards_in[0]) begin
            pc <= jump_address_backwards_in;
        end else if (status_backwards_in[1]) begin
            pc <= if_id_pc + 32'd4;
        end
    end

    // id/id pipeline register update
    always_ff @( posedge clk or posedge rst ) begin : if_id_update
        if (rst) begin
            if_id_pc <= 32'b0;
            if_id_instruction <= constants.NOP;
        end else if (status_backwards_in[1]) begin
            if_id_pc <= pc;
            if_id_instruction <= instruction_mem[pc >> 2];
        end
    end

    // outputs to decode stage
    assign instruction_reg_out = if_id_instruction;
    assign program_counter_reg_out = if_id_pc;

    ref_fetch_stage golden(.*);

endmodule
