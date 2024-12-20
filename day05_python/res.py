with open('input.txt', 'r') as file:
    lines = file.readlines()

pairs = []
lists = []

for line in lines:
    if "|" in line:
        pairs.append([int(s) for s in line.strip().split('|')])
    elif line.strip() != "":
        lists.append([int(s) for s in line.strip().split(",")])

print(pairs)
print(lists)

graph = {}

for p in pairs:
    graph.setdefault(p[0], []).append(p[1])

print(graph)

def isCorrectPos(graph, l, i):
    for j in range(i + 1, len(l)):
        if not l[i] in graph:
            return False
        if not l[j] in graph[l[i]]:
            return False
    return True

# sum = 0

# for l in lists:
#     allCorrect = True
#     for i in range(len(l)):
#         if not isCorrectPos(graph, l, i):
#            allCorrect = False
#            break
#     if allCorrect:
#         print(l)
#         sum += l[len(l)//2]


sum = 0

notCorrect = []

for l in lists:
    allCorrect = True
    for i in range(len(l)):
        if not isCorrectPos(graph, l, i):
           allCorrect = False
           break
    if not allCorrect:
        notCorrect.append(l)

corrected = []

def custom_sort(lst, compare_function):
    # Wrapper to convert the comparison function to a key function
    class KeyWrapper:
        def __init__(self, obj):
            self.obj = obj

        def __lt__(self, other):
            return compare_function(self.obj, other.obj)

    return sorted(lst, key=KeyWrapper)

def compare(x, y):
    return x in graph and y in graph[x]

for l in notCorrect:
    sorted_list = custom_sort(l, compare)
    sum += sorted_list[len(sorted_list) // 2]

print(sum)