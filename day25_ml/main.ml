type input_type =
  | Key of int list
  | Lock of int list

let pretty_print_input_type value =
  match value with
  | Key ints ->
      Printf.printf "Key: [%s]\n" (String.concat "; " (List.map string_of_int ints))
  | Lock ints ->
      Printf.printf "Lock: [%s]\n" (String.concat "; " (List.map string_of_int ints))

let read_file_to_string filename =
  let ic = open_in filename in
  let length = in_channel_length ic in
  let content = really_input_string ic length in
  close_in ic;
  content

  let rec transpose l =
  match l with
  | [] -> []
  | [] :: xs -> []
  | xs -> List.map List.hd xs :: transpose (List.map List.tl xs)

let counted col =
  (List.filter (fun x -> x == '#') col |> List.length) - 1

let as_char_matrix textList = 
  List.map String.to_seq textList |> List.map List.of_seq

let parse_one r1 r2 r3 r4 r5 r6 r7 =
  let content = [r1; r2; r3; r4; r5; r6; r7] in
  match r1 with
  | "#####" -> Lock(as_char_matrix content |> transpose |> List.map counted)
  | _ -> Key(as_char_matrix content |> transpose |> List.map counted)

let rec parse_all input_lines =
  match input_lines with
  | [] -> []
  | r1 :: r2 :: r3 :: r4 :: r5 :: r6 :: r7 :: _ :: rest -> (parse_one r1 r2 r3 r4 r5 r6 r7) :: parse_all rest
  | _ -> failwith "Bad input"

let split_keys_locks all_inputs =
  (
    List.filter_map (
      fun (input) -> match input with
      | Key(k) -> Some(k)
      | Lock(_) -> None
    ) all_inputs,
    List.filter_map (
      fun (input) -> match input with
      | Key(_) -> None
      | Lock(l) -> Some(l)
    ) all_inputs
  )

let cartesian l l' = 
  List.concat (List.map (fun e -> List.map (fun e' -> (e,e')) l') l)

let is_valid_pair (k, l) =
  List.combine k l |> List.filter (fun ((kv, lv)) -> kv + lv > 5) |> List.length == 0

(* Helper function to pretty print a list of integers *)
let string_of_int_list lst =
  "[" ^ (String.concat "; " (List.map string_of_int lst)) ^ "]"

(* Pretty print a list of pairs of integer lists *)
let print_list_of_pairs_of_lists pairs =
  let formatted_pairs = List.map (fun (l1, l2) ->
    Printf.sprintf "(%s, %s)" (string_of_int_list l1) (string_of_int_list l2)
  ) pairs in
  Printf.printf "[%s]\n" (String.concat ";\n " formatted_pairs)


let () =
  let input = read_file_to_string "input.txt" in
  let parsed_input = String.split_on_char '\n' input |> parse_all in
  let keys, locks = split_keys_locks parsed_input in
  let pairs_to_check = cartesian keys locks in
  let valid_pairs = List.filter is_valid_pair pairs_to_check in
  (* print_list_of_pairs_of_lists pairs_to_check; *)
  Printf.printf "Valid pairs: %d\n" (valid_pairs |> List.length)