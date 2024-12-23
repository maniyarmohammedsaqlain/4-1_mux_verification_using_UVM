`include "uvm_macros.svh";
import uvm_pkg::*;

class transaction extends uvm_sequence_item;
  `uvm_object_utils(transaction);
  rand bit [3:0]a;
  rand bit [3:0]b;
  rand bit [3:0]c;
  rand bit [3:0]d;
  rand bit [1:0]sel;
  bit [3:0]y;
        
  function new(string path="trans");
    super.new(path);
  endfunction
endclass

class sequence1 extends uvm_sequence#(transaction);
  `uvm_object_utils(sequence1);
  transaction trans;
  function new(string path="seq");
    super.new(path);
  endfunction
  
  virtual task body();
    trans=transaction::type_id::create("trans");
    repeat(10)
      begin
        start_item(trans);
        trans.randomize();
        `uvm_info("SEQ",$sformatf("A:%0d B:%0d C:%0d D:%0d SEL:%0d OUT:%0d",trans.a,trans.b,trans.c,trans.d,trans.sel,trans.y),UVM_NONE);
        finish_item(trans);
      end
  endtask
endclass

class driver extends uvm_driver#(transaction);
  `uvm_component_utils(driver);
  transaction trans;
  virtual mux_if inf;
  function new(string path="drv",uvm_component parent=null);
    super.new(path,parent);
  endfunction
  
  
  virtual function void build_phase(uvm_phase phase);
    trans=transaction::type_id::create("trans");
    
    if(!uvm_config_db #(virtual mux_if)::get(this,"","inf",inf))
       `uvm_info("DRV","Error in config of driver",UVM_NONE);
    
  endfunction
  
  virtual task run_phase(uvm_phase phase);
    forever
      begin
        seq_item_port.get_next_item(trans);
        inf.a<=trans.a;
        inf.b<=trans.b;
        inf.c<=trans.c;
        inf.d<=trans.d;
        inf.sel<=trans.sel;
        `uvm_info("DRV",$sformatf("A:%0d B:%0d C:%0d D:%0d SEL:%0d OUT:%0d",trans.a,trans.b,trans.c,trans.d,trans.sel,trans.y),UVM_NONE);
        seq_item_port.item_done(trans);
        #20;
      end
  endtask
endclass

class monitor extends uvm_monitor;
  `uvm_component_utils(monitor);
  transaction trans;
  virtual mux_if inf;
  uvm_analysis_port #(transaction)send;
  function new(string path="mon",uvm_component parent=null);
    super.new(path,parent);
    send=new("send",this);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    trans=transaction::type_id::create("trans",this);
    if(!uvm_config_db #(virtual mux_if)::get(this,"","inf",inf))
       `uvm_info("DRV","Error in config of driver",UVM_NONE);
  endfunction
  
  virtual task run_phase(uvm_phase phase);
    forever
      begin
        #20;
        trans.a=inf.a;
        trans.b=inf.b;
        trans.c=inf.c;
        trans.d=inf.d;
        trans.sel=inf.sel;
        trans.y=inf.y;
        send.write(trans);
        `uvm_info("MON",$sformatf("A:%0d B:%0d C:%0d D:%0d SEL:%0d OUT:%0d",trans.a,trans.b,trans.c,trans.d,trans.sel,trans.y),UVM_NONE);
      end
  endtask
endclass

class scoreboard extends uvm_scoreboard;
  `uvm_component_utils(scoreboard);
  transaction trans;
  uvm_analysis_imp #(transaction,scoreboard)recv;
  function new(string path="scb",uvm_component parent=null);
    super.new(path,parent);
    recv=new("recv",this);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    trans=transaction::type_id::create("trans");
  endfunction
  
  virtual function void write(transaction tr);
    trans=tr;
    `uvm_info("SCB",$sformatf("A:%0d B:%0d C:%0d D:%0d SEL:%0d OUT:%0d",trans.a,trans.b,trans.c,trans.d,trans.sel,trans.y),UVM_NONE);
    if((trans.sel==2'b00) && (trans.y==trans.a))
      begin
      	`uvm_info("SCB","PASSED",UVM_NONE);
      end
    else if((trans.sel==2'b01) && (trans.y==trans.b))
      begin
      	`uvm_info("SCB","PASSED",UVM_NONE);
      end
    else if((trans.sel==2'b10) && (trans.y==trans.c))
      begin
      	`uvm_info("SCB","PASSED",UVM_NONE);
      end
    else if((trans.sel==2'b11) && (trans.y==trans.d))
      begin
      	`uvm_info("SCB","PASSED",UVM_NONE);
      end
  endfunction
endclass

class agent extends uvm_agent;
  `uvm_component_utils(agent);
  driver drv;
  monitor mon;
  uvm_sequencer #(transaction)seqr;
  function new(string path="a",uvm_component parent=null);
    super.new(path,parent);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    drv=driver::type_id::create("drv",this);
    mon=monitor::type_id::create("mon",this);
    seqr=uvm_sequencer #(transaction)::type_id::create("seqr",this);
  endfunction
  
  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    drv.seq_item_port.connect(seqr.seq_item_export);
  endfunction
endclass

class env extends uvm_env;
  `uvm_component_utils(env);
  agent a;
  scoreboard scb;
  function new(string path="env",uvm_component parent=null);
    super.new(path,parent);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    a=agent::type_id::create("a",this);
    scb=scoreboard::type_id::create("scb",this);
  endfunction
  
  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    a.mon.send.connect(scb.recv);
  endfunction
endclass

class test extends uvm_test;
  `uvm_component_utils(test);
  env e;
  sequence1 seq;
  function new(string path="test",uvm_component parent=null);
    super.new(path,parent);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    e=env::type_id::create("e",this);
    seq=sequence1::type_id::create("seq",this);
  endfunction
  
  virtual task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    seq.start(e.a.seqr);
    #50;
    phase.drop_objection(this);
  endtask
endclass

module tb;
  mux_if inf();
  mux DUT(.a(inf.a),.b(inf.b),.c(inf.c),.d(inf.d),.sel(inf.sel),.y(inf.y));
  
  initial
    begin
      uvm_config_db #(virtual mux_if)::set(null,"*","inf",inf);
      run_test("test");
    end
endmodule
