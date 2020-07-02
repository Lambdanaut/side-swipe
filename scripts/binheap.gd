extends Node

# Priority Queue implementation with binary heap
# Found here: https://godotengine.org/qa/12915/priority-queue

var heaplist
var currentSize

func _init():
    heaplist = [[0]]
    currentSize = 0

func insert(k):
    # Insert an array of items into the heap
    # The first element in the array is the sorting key
    # Items are sorted from lowest to highest (min-heap)
    heaplist.append(k)
    currentSize += 1
    percUp(currentSize)

func percUp(i):
    var tmp
    while i / 2 > 0:
        if heaplist[i][0] < heaplist[i / 2][0]:
            tmp = heaplist[i / 2]
            heaplist[i / 2] = heaplist[i]
            heaplist[i] = tmp
        i = i / 2

func percDown(i):
    var tmp
    while (i * 2) <= currentSize:
        var mc = minChild(i)
        if heaplist[i][0] > heaplist[mc][0]:
            tmp = heaplist[i]
            heaplist[i] = heaplist[mc]
            heaplist[mc] = tmp
        i = mc

func minChild(i):
    if i * 2 + 1 > currentSize:
        return i * 2
    else:
        if heaplist[i*2][0] < heaplist[i*2+1][0]:
            return i * 2
        else:
            return i * 2 + 1

func pop():
    var retval = heaplist[1]
    heaplist[1] = heaplist[currentSize]
    heaplist.pop_back()
    currentSize -= 1
    percDown(1)
    return retval

func contains(val):
    var skip_first = true
    
    for item in heaplist:
        if skip_first:
            skip_first = false
            continue
        if item[1] == val:
            return true
    return false

func is_empty():
    return currentSize < 1
