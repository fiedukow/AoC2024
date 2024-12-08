const std = @import("std");

pub fn main() !void {
    const allocator = &std.heap.page_allocator; // Use a pointer to the allocator

    // Replace "numbers.txt" with the path to your file
    const filePath = "input.txt";

    const result = try readIntegerFile(filePath);
    defer for (result.items) |line| allocator.free(line); // Free each line's allocation
 //   defer allocator.free(result); // Free the outer array

    // Print the parsed data

    var countGood: i32 = 0;
    for (result.items) |line| {
        if (isGoodLine(line)) {
            countGood += 1;
            // std.debug.print("G: {any}\n", .{line});
        } else {
            std.debug.print("B: {any}\n", .{line});
        }
    }

    std.debug.print("{any}\n", .{countGood});
}

pub fn mySign(val: i32) i32 {
    if (val < 0) {
        return -1;
    }
    if (val > 0) {
        return 1;
    }
    return 0;
}

pub fn isGoodLineWithOrder(line: []const i32, order: i32, startingAt: usize, withSkip: bool, initialJump: usize) bool {
    var i: usize = startingAt;
    i += initialJump;
    var inc: usize = initialJump;

    while (i < line.len) {        
        const incr = line[i] - line[i-inc];
        inc = 1;

        if (mySign(incr) != order) {
            if (withSkip) {
                return false;
            }
            return isGoodLineWithOrder(line, order, i-1, true, 1) or (i >= 2 and isGoodLineWithOrder(line, order, i - 2, true, 2));
        } else if (@abs(incr) > 3) {
            if (withSkip) {
                return false;
            }
            return isGoodLineWithOrder(line, order, i-1, true, 1) or (i >= 2 and isGoodLineWithOrder(line, order, i - 2, true, 2));
        }
        i += 1;
    }
    return true;
}

pub fn isGoodLine(line: []const i32) bool {
    if (line.len < 2) { return true; }
    if (line.len == 2) { return @abs(line[0] - line[1]) <= 3 and @abs(line[0] - line[1]) > 0; }

    var i: usize = 0;
    while (i < line.len) {
        if (isGoodLineN2(line, i)) {
            return true;
        }
        i += 1;
    }
    return false;
}

pub fn checkPair(line: []const i32, order: i32, it1: usize, it2: usize) bool {
    const incr = line[it2] - line[it1];
    if (mySign(incr) != order) {
        return false;
    } else if (@abs(incr) > 3) {
        return false;
    }
    return true;
}

pub fn isGoodLineN2(line: []const i32, skip: usize) bool {
    var i: usize = 0;
    var order: i32 = mySign(line[1] - line[0]);
    if (skip == 0) {
        order = mySign(line[2] - line[1]);
    }

    if (skip == 1) {
        order = mySign(line[2] - line[0]);
    }

    while (i < line.len - 1) {      
        if (i == skip) {
            i += 1;
            continue;
        }

        var it2: usize = i + 1;
        if (it2 == skip) {
            it2 += 1;
        }

        if (it2 >= line.len) {
            break;
        }

        if (!checkPair(line, order, i, it2)) {
            return false;
        }
        i += 1;
    }
    return true;
}

pub fn readIntegerFile(filePath: []const u8) !std.ArrayList([]i32) {
    // Open the file
    var file = try std.fs.cwd().openFile(filePath, .{});
    defer file.close();

    // Read the file content into a buffer
    var fileStream = file.reader();
    const buffer = fileStream.readAllAlloc(std.heap.page_allocator, std.math.maxInt(usize));
//    defer std.heap.page_allocator.free(buffer);

    // Split the content into lines
    var lines = std.mem.split(u8, try buffer, "\n");

    // Prepare the result array
    var result = std.ArrayList([]i32).init(std.heap.page_allocator);

    while (lines.next()) |line| {
        const trimmedLine = std.mem.trimLeft(u8, line, " \t");
        if (trimmedLine.len == 0) continue; // Skip empty lines

        var numbers = std.mem.split(u8, trimmedLine, " ");

        // Create a dynamic array to hold the results
        var slices = std.ArrayList([]const u8).init(std.heap.page_allocator);
        defer slices.deinit();

        // Collect all slices from the iterator
        while (numbers.next()) |number| {
            try slices.append(number);
        }
        
        var intArray = try std.heap.page_allocator.alloc(i32, slices.items.len);

        var idx: usize = 0;
        for (slices.items) |number| {
            intArray[idx] = try std.fmt.parseInt(i32, number, 10);
            idx += 1;
        }

        try result.append(intArray);
    }

    return result;
}
