local connections = {}
local file = io.open("input.txt", "r")

function add_to_key(map, key, value)
  if not map[key] then
      map[key] = {}
  end
  table.insert(map[key], value)
end

function intersect(arr1, arr2)
  local lhsSet = {}
  local result = {}

  for _, lhsItem in ipairs(arr1) do
    lhsSet[lhsItem] = true
  end

  for _, rhsItem in ipairs(arr2) do
    if lhsSet[rhsItem] then
      table.insert(result, rhsItem)
    end
  end

  return result
end

function table_copy(t)
  local r = { }
  for _, v in ipairs(t) do
    table.insert(r, v)
  end
  return r
end

function array_equal(arr1, arr2)
  if #arr1 ~= #arr2 then
      return false
  end

  for i = 1, #arr1 do
      if arr1[i] ~= arr2[i] then
          return false
      end
  end

  return true
end

function unique_arr_of_arr(arr)
  local res = {}
  local last = {}
  for _, element in ipairs(arr) do
    if not array_equal(last, element) then
      table.insert(res, element)
      last = element
    end
  end
  return res
end


function subsets(arr, subsetSize)
  local result = {}
  local subset = {}

  local function subsetsStartingAt(start, depth)
      if depth == subsetSize then
          table.insert(result, table_copy(subset))
          return
      end

      for i = start, #arr do
          table.insert(subset, arr[i])
          subsetsStartingAt(i + 1, depth + 1)
          table.remove(subset)
      end
  end

  subsetsStartingAt(1, 0)
  return result
end

function common_neighbours(connections, lhost, rhost)
  local lconnections = connections[lhost]
  local rconnections = connections[rhost]
  return intersect(lconnections, rconnections)
end

function all_triplets(subnets)
  local triplets = {}
  for _, subnet in ipairs(subnets) do
    for _, tri in ipairs(subsets(subnet, 3)) do
      table.sort(tri)
      table.insert(triplets, tri)
    end
  end
  table.sort(triplets, cmp_arr)
  return unique_arr_of_arr(triplets)
end

function cmp_arr(lhs, rhs)
  if #lhs < #rhs then return true end
  if #rhs < #lhs then return false end

  for i = 1, #lhs do
    if lhs[i] < rhs[i] then
      return true
    end
    if lhs[i] > rhs[i] then
      return false
    end
  end

  return false  
end

function triplets_of_pair(f, s, common)
  local result = {}
  for _, c in ipairs(common) do
    local tri = {f,s,c}
    table.sort(tri)
    table.insert(result, tri)
  end
  return result
end

function insert_all(t, toAppend)
  for _, v in ipairs(toAppend) do
    table.insert(t, v)
  end
end

function connection_trips(connections)
  local subnets = {}
  for host, links in pairs(connections) do
    for _, nhost in ipairs(links) do
      if host ~= nhost then
        local neighbours = common_neighbours(connections, host, nhost)
        local triplets = triplets_of_pair(host, nhost, neighbours)
        insert_all(subnets, triplets)
      end
    end
  end
  table.sort(subnets, cmp_arr)
  return unique_arr_of_arr(subnets)
end

function map_copy(m)
  local nm = {}
  for k, v in pairs(m) do
    nm[k] = v
  end
  return nm
end

function largest_subnet(connections, hosts, candidates, already_seen)
  local now_seen = map_copy(already_seen)
  local largest_so_far = table_copy(hosts)
  for _, candidate in ipairs(candidates) do
    local newCandidates = intersect(candidates, connections[candidate])
    table.insert(hosts, candidate)
    if #newCandidates + #hosts > #largest_so_far and not now_seen[candidate] then
      now_seen[candidate] = true
      filledSub = largest_subnet(connections, hosts, newCandidates, now_seen)
      if #filledSub > #largest_so_far then
        largest_so_far = filledSub
      end
    end
    now_seen[candidate] = true
    table.remove(hosts)
  end
  return largest_so_far
end

function map_size(map)
  local count = 0
  for _ in pairs(map) do
      count = count + 1
  end
  return count
end

function all_subnets(connections)
  local subnets = {}
  local already_seen = {}
  local c = 0
  local totals = map_size(connections)
  for host, links in pairs(connections) do
    -- print(host, c, "out of", totals)
    c = c + 1
    for i, nhost in ipairs(links) do
      local hosts = {host, nhost}
      local neighbours = common_neighbours(connections, host, nhost)
      local now_seen = map_copy(already_seen)
      now_seen[nhost] = true
      local lSub = largest_subnet(connections, hosts, neighbours, now_seen)
      table.sort(lSub)
      table.insert(subnets, lSub)
    end
    already_seen[host] = true
  end
  table.sort(subnets, cmp_arr)
  return unique_arr_of_arr(subnets)
end

function pretty_print_array(arr)
  for i, value in ipairs(arr) do
    io.write(value .. " ")
  end
end

function pretty_print_connections(connections)
  for key, values in pairs(connections) do
      io.write(key .. " -> [ ")
      for i, value in ipairs(values) do
        io.write(value .. " ")
      end
      io.write("]\n")
  end
end

function pretty_string_array(arr)
  local res = "[ "
  for i, value in ipairs(arr) do
    res = res .. value .. " "
  end
  return res .. "]"
end

function as_password(arr)
  local res = ""
  for i, value in ipairs(arr) do
    if i > 1 then
      res = res .. ","
    end
    res = res .. value
  end
  return res
end

function str_split(input, sep)
  if sep == nil then
    sep = "%s"
  end
  local t = {}
  for str in string.gmatch(input, "([^"..sep.."]+)") do
    table.insert(t, str)
  end
  return t
end

function array_contains_prefix(arr, value)
    for _, v in ipairs(arr) do
        if v:sub(1,#value) == value then
            return true
        end
    end
    return false
end

function filter_containing_prefix(subsets, element)
  local result = {}
  for _, subset in ipairs(subsets) do
    if array_contains_prefix(subset, element) then
      table.insert(result, subset)
    end
  end
  return result
end

function longest(arrs)
  longest_so_far = {}
  for _, arr in ipairs(arrs) do
    if #arr >= #longest_so_far then
      longest_so_far = arr
    end
  end
  return longest_so_far
end

if file then
  for line in file:lines() do
    hosts = str_split(line, "-")
    add_to_key(connections, hosts[1], hosts[2])
    add_to_key(connections, hosts[2], hosts[1])
  end
  file:close()
else
  print("Failed to open file.")
end

-- pretty_print_connections(connections)

local subnets = connection_trips(connections)
-- for _, subnet in ipairs(subnets) do
--   print("Triplet: ", pretty_string_array(subnet))
-- end

local fTriplets = filter_containing_prefix(subnets, "t")
-- for _, tri in ipairs(fTriplets) do
--   print("Filtered: ", pretty_string_array(tri))
-- end
print("Tiples with 't'", #fTriplets)

local actualSubnets = all_subnets(connections)
-- for _, subnet in ipairs(actualSubnets) do
--   print("Subnet: ", pretty_string_array(subnet))
-- end

print("Longest: ", as_password(longest(actualSubnets)))