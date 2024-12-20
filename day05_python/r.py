def parse_input(file_path):
    """
    Parses the input file to extract rules and updates.
    """
    with open(file_path, 'r') as file:
        content = file.read().strip()
    
    # Split rules and updates based on the blank line
    rules_section, updates_section = content.split("\n\n")
    
    # Parse rules
    rules = []
    for line in rules_section.splitlines():
        before, after = map(int, line.split("|"))
        rules.append((before, after))
    
    # Parse updates
    updates = []
    for line in updates_section.splitlines():
        update = list(map(int, line.split(",")))
        updates.append(update)
    
    return rules, updates

def is_update_valid(rules, update):
    """
    Checks if the given update is valid based on the rules.
    """
    position_map = {page: idx for idx, page in enumerate(update)}
    
    for before, after in rules:
        if before in position_map and after in position_map:
            if position_map[before] > position_map[after]:
                return False
    return True

def find_middle_page(update):
    """
    Finds the middle page number of the given update.
    """
    mid_index = len(update) // 2
    return update[mid_index]

def solve_puzzle(file_path):
    """
    Reads input from the file, validates updates, and calculates the sum of middle pages.
    """
    # Parse the input
    rules, updates = parse_input(file_path)
    
    valid_updates = []
    for update in updates:
        if is_update_valid(rules, update):
            valid_updates.append(update)
    
    # Find middle pages of valid updates
    middle_pages = [find_middle_page(update) for update in valid_updates]
    
    # Calculate the sum of the middle pages
    return sum(middle_pages)

# Example Usage
file_path = "input.txt"  # Replace with your actual file path
result = solve_puzzle(file_path)
print("Sum of middle pages of valid updates:", result)


from collections import defaultdict, deque

def topological_sort(rules, update):
    """
    Sorts the update using the page ordering rules (topological sort).
    """
    # Filter rules to only include pages in the current update
    relevant_rules = [(before, after) for before, after in rules if before in update and after in update]

    # Build graph and indegree map
    graph = defaultdict(list)
    indegree = defaultdict(int)
    for before, after in relevant_rules:
        graph[before].append(after)
        indegree[after] += 1
        indegree.setdefault(before, 0)  # Ensure all nodes are in the indegree map

    # Topological sorting using Kahn's algorithm
    queue = deque([node for node in update if indegree[node] == 0])
    sorted_update = []

    while queue:
        node = queue.popleft()
        sorted_update.append(node)
        for neighbor in graph[node]:
            indegree[neighbor] -= 1
            if indegree[neighbor] == 0:
                queue.append(neighbor)

    return sorted_update

def solve_puzzle_part2(file_path):
    """
    Reads input from the file, fixes the order of invalid updates, and calculates the sum of middle pages.
    """
    # Parse the input
    rules, updates = parse_input(file_path)
    
    invalid_updates = []
    for update in updates:
        if not is_update_valid(rules, update):
            invalid_updates.append(update)
    
    # Fix the order of invalid updates
    corrected_updates = [topological_sort(rules, update) for update in invalid_updates]
    
    # Find middle pages of corrected updates
    middle_pages = [find_middle_page(update) for update in corrected_updates]
    
    # Calculate the sum of the middle pages
    return sum(middle_pages)

# Example Usage for Part 2
file_path = "input.txt"  # Replace with your actual file path
result_part2 = solve_puzzle_part2(file_path)
print("Sum of middle pages of corrected updates:", result_part2)
