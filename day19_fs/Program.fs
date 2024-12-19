open System.Threading.Tasks
open System.Collections.Generic
let patterns_matching_prefix_of (available_patterns: list<string>) (to_create: string) =
  available_patterns
    |> List.filter (fun pattern -> to_create.StartsWith(pattern))
    |> List.map(fun s -> to_create.Substring(s.Length))

let rec is_achievable available_patterns to_create =
  // printfn "Patterns: %A; expecting %A" available_patterns to_create;
  match to_create with
  | "" -> true
  | str ->
      patterns_matching_prefix_of available_patterns str
      |> List.exists (fun s -> is_achievable available_patterns s)
let count_achievable_options_one available_patterns to_create: int64 =
    let cache = Dictionary<string, int64>();

    let rec count_achievable_options_one_using_cache available_patterns to_create =
        if cache.ContainsKey(to_create) then
            cache.[to_create]
        else
            let result =
                match to_create with
                | "" -> 1L
                | str ->
                    patterns_matching_prefix_of available_patterns str
                    |> List.map (fun s -> count_achievable_options_one_using_cache available_patterns s)
                    |> List.sum
            cache.[to_create] <- result
            result;

    count_achievable_options_one_using_cache available_patterns to_create

let count_achievable available_patterns patterns_to_get =
  patterns_to_get
    |> List.toArray
    |> Array.Parallel.map (fun(to_create) -> is_achievable available_patterns to_create)
    |> Array.toList
    |> List.filter id
    |> List.length

let count_achievable_options available_patterns patterns_to_get =
  patterns_to_get
    |> List.toArray
    |> Array.Parallel.map (fun(to_create) -> count_achievable_options_one available_patterns to_create)
    |> Array.toList
    |> List.sum

let reduce_available_patterns available_patterns =
  let sorted_patterns = available_patterns |> List.sortBy String.length;
  sorted_patterns
    |> List.indexed
    |> List.filter (fun (id, pattern) -> not(is_achievable (List.take id sorted_patterns) pattern))
    |> List.map (fun (_, pattern) -> pattern)

let lines = System.IO.File.ReadAllLines("input.txt") |> Array.toList;
let available_patterns, patterns_to_get =
  match lines with
    | available_patterns :: _ :: patterns_to_get -> 
      (
        available_patterns.Split([|','|]) |> Array.map(fun s -> s.Trim()) |> Array.toList,
        patterns_to_get |> List.map(fun s -> s.Trim())
      )
    | _ -> failwith "Error";

let reduced_patterns = reduce_available_patterns available_patterns;

printfn "Reduced patterns: %A" reduced_patterns;
printfn "Achievable patterns: %A" (count_achievable reduced_patterns patterns_to_get);
printfn "Ways to achieve those patterns: %A" (count_achievable_options available_patterns patterns_to_get);
