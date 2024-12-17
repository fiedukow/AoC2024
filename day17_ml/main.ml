(* #load "str.cma" *)

let parse_registers_and_program input =
  let find_register name =
    let pattern = "Register " ^ name ^ ": \\([0-9]+\\)" in
    let re = Str.regexp pattern in
    try
      let _ = Str.search_forward re input 0 in
      int_of_string (Str.matched_group 1 input)
    with Not_found -> failwith ("Register " ^ name ^ " not found")
  in

  let re_program = Str.regexp "Program: \\(\\([0-9]+,\\)*[0-9]+\\)" in
  let find_program () =
    try
      let _ = Str.search_forward re_program input 0 in
      let program_str = Str.matched_group 1 input in
      program_str
      |> String.split_on_char ','
      |> List.map int_of_string
    with Not_found -> failwith "Program not found"
  in

  let register_a = find_register "A" in
  let register_b = find_register "B" in
  let register_c = find_register "C" in
  let program = find_program () in

  (register_a, register_b, register_c, program)

let read_file_to_string filename =
  let ic = open_in filename in
  let length = in_channel_length ic in
  let content = really_input_string ic length in
  close_in ic;
  content

type state = {
  a : int;
  b : int;
  c : int;
  program : int array;
  instruction_pointer : int;
  output : int list;
}

let pretty_print_state state =
  let max_line_width = 80 in
  let max_numbers_per_line = max_line_width / 2 in

  Printf.printf "A: %d (%d),  B: %d (%d),  C: %d (%d)\n" state.a (state.a mod 8) state.b (state.b mod 8) state.c (state.c mod 8);

  Printf.printf "Output: [%s]\n"
    (String.concat "," (List.map string_of_int state.output |> List.rev));

  Printf.printf "Program:\n";

  let program_length = Array.length state.program in
  let current_line = ref 0 in

  let target_line = state.instruction_pointer / max_numbers_per_line in
  let caret_position = state.instruction_pointer mod max_numbers_per_line in

  let print_pointer_line pos =
    Printf.printf("      ");
    for i = 0 to pos do
      if i = pos then Printf.printf "^"
      else Printf.printf "  "
    done;
    print_newline ()
  in

  for i = 0 to program_length - 1 do
    if i mod max_numbers_per_line = 0 then begin
      if i > 0 then print_newline ();
      if (!current_line) == target_line + 1 then begin
        print_pointer_line caret_position
      end;

      Printf.printf "%4d: " (!current_line * max_numbers_per_line);
      incr current_line
    end;
    Printf.printf "%d " state.program.(i)
  done;

  if (!current_line) == target_line + 1 then begin
    print_newline ();
    print_pointer_line caret_position
  end;

  print_newline ()

type instructionResult =
  | ContinueOn of state
  | Halt of state

let combo_op_value state operand =
  match operand with
  | n when n >= 0 && n <= 3 -> n
  | 4 -> state.a
  | 5 -> state.b
  | 6 -> state.c
  | n -> failwith ("Invalid combo operand " ^ string_of_int n)

let literal_op_value operand =
  match operand with
  | n when n >= 0 && n <= 7 -> n
  | n -> failwith ("Invalid literal operand " ^ string_of_int n)

let op_value_of state opCode operand =
  match opCode with
  | 0 -> combo_op_value state operand
  | 1 -> literal_op_value operand
  | 2 -> (combo_op_value state operand) mod 8
  | 3 -> literal_op_value operand
  | 4 -> 0
  | 5 -> (combo_op_value state operand) mod 8
  | 6 -> combo_op_value state operand
  | 7 -> combo_op_value state operand
  | _ -> failwith "Value out of range: expected 0-7"

let result_of state =
  let execute state opCode operand = 
    match opCode with
      | 0 -> { state with
        a = state.a / (1 lsl (op_value_of state opCode operand));
        instruction_pointer = state.instruction_pointer + 2
      }
      | 1 -> { state with
        b = state.b lxor (op_value_of state opCode operand);
        instruction_pointer = state.instruction_pointer + 2
      }
      | 2 -> { state with
        b = op_value_of state opCode operand;
        instruction_pointer = state.instruction_pointer + 2
      }
      | 3 -> (match state.a with         
        | 0 -> { state with instruction_pointer = state.instruction_pointer + 2 }
        | _ -> { state with instruction_pointer = op_value_of state opCode operand })
      | 4 -> { state with
        b = state.b lxor state.c;
        instruction_pointer = state.instruction_pointer + 2
      }
      | 5 -> { state with
        output = (op_value_of state opCode operand) :: state.output;
        instruction_pointer = state.instruction_pointer + 2
      }
      | 6 -> { state with
        b = state.a / (1 lsl (op_value_of state opCode operand));
        instruction_pointer = state.instruction_pointer + 2
      }
      | 7 -> { state with
        c = state.a / (1 lsl (op_value_of state opCode operand));
        instruction_pointer = state.instruction_pointer + 2
      }
      | _ -> failwith "Value out of range: expected 0-7"
  in

  if state.instruction_pointer < Array.length state.program then
    ContinueOn(execute state state.program.(state.instruction_pointer) state.program.(state.instruction_pointer + 1))
  else
    Halt(state)

let execute_one state =
  match result_of state with
  | ContinueOn(new_state) -> new_state
  | Halt(new_state) -> state

let rec execute_and_print state =
  pretty_print_state state;
  match result_of state with
    | ContinueOn(new_state) -> execute_and_print new_state
    | Halt(new_state) -> state

let rec execute state =
  match result_of state with
   | ContinueOn(new_state) -> execute new_state
   | Halt(new_state) -> state

let rec execute_pia state =
  if state.a mod 1000000 = 0 then begin
    Printf.printf "%d" state.a;
    print_newline ();
  end;
  execute state
  
let rec nats n () =
  Seq.Cons (n, nats (n + 1))

let scan_for_selfref state =
  let states = Seq.map (fun n -> (n, { state with a = n })) (nats 0) in
  let results = Seq.map (fun (n, s) -> (n, execute_pia s)) states in
  let eq_input (_, final_state) = 
    (Array.to_list state.program) = (List.rev final_state.output) 
  in
  let first_valid = Seq.find eq_input results in
  match first_valid with
  | Some(n, _) -> n
  | None -> failwith "Out of natural numbers?"

let () =
  let input = read_file_to_string "input.txt" in
  let (a, b, c, program) = parse_registers_and_program input in

  let initial_state = {
    a = a; 
    b = b; 
    c = c; 
    program = Array.of_list program;
    instruction_pointer = 0;
    output = [];
  } in

  let _ = execute_and_print initial_state in
  (* Printf.printf "%d" (scan_for_selfref initial_state); *)

  print_newline ()
