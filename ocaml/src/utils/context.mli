(** useful information provided by main essentially *)

(** the bound used to know whether a widening has to be set *)
val unroll: int ref

(** memory model *)
type memory_model_t =
  | Flat
  | Segmented

val memory_model: memory_model_t ref

(** file format *)
type format_t =
  | Pe
  | Elf

val format: format_t ref
		     
(** calling convention *)
type call_conv_t =
  | Cdecl
  | Stdcall
  | Fastcall
      
val call_conv: call_conv_t ref
			   
(** content of the text section *)
val text: string ref

(** address of the entry point of the code *)
val ep: string ref

(** starting address of the code *)
val code_addr_start: string ref

(** end address of the code *)
val code_addr_end: string ref

(** address of the beginning of the data *)
val data_addr: string ref

(** address of the beginning of the stack *)
val stack_addr: string ref
		      
(** default address size in bits *)
val address_sz: int ref

(** default operand size in bits *)
val operand_sz: int ref

(** default stack width in bits *)
val stack_width: int ref

(** address of the cs segment *)
val cs: string ref 

(** address of the ds segment *)
val ds: string ref

(** address of the ss segment *)
val ss: string ref

(** address of the es segment *)
val es: string ref 

(** address of the fs segment *)
val fs: string ref 

(** address of the gs segment *)
val gs: string ref

(** _init_register r v t adds the intial value _v_ and the initial taint _t_ (None means no initial value) to the register _r_ in the intial configuration *)
val init_register: string -> string option -> string option -> unit

(** _init_memory a v t adds the intial value _v_ and the initial taint _t_ (None means no initial value) to the memory address _a_ in the intial configuration *)
val init_memory: string -> string option -> string option -> unit

(** tainting kind for function arguments *)
type taint =
  | No_taint
  | Buf_taint
  | Addr_taint

(** type used to store information provided by the configuration file about the tainting rules of a function *)
(** the string is the name of the function *)
(** the calling convention is set either to a specific one or the default one *)
(** the first taint type in the tuple is for the return type (None is for function without return value) ; the second one is for the list of arguments *)
type tainting_fun = string * call_conv_t * taint option * taint list
				   
(** adds the tainting rules of the given function of the given libname *)
val add_tainting_rules: string -> tainting_fun -> unit 

