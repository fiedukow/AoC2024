use std::fs::File;
use std::io::{self, BufRead};

fn read_file_and_store_as_arrays(file_path: &str) -> io::Result<(Vec<i32>, Vec<i32>)> {
    // Open the file
    let file = File::open(file_path)?;
    let reader = io::BufReader::new(file);

    // Create two vectors to store the integers from each column
    let mut column1: Vec<i32> = Vec::new();
    let mut column2: Vec<i32> = Vec::new();

    // Iterate through each line of the file
    for line in reader.lines() {
        let line = line?;
        let parts: Vec<&str> = line.split_whitespace().collect();

        if let (Ok(num1), Ok(num2)) = (parts[0].parse::<i32>(), parts[1].parse::<i32>()) {
            column1.push(num1);
            column2.push(num2);
        }
    }

    Ok((column1, column2))
}

fn part1() {
    let file_path = "puzzle1.input";
    let (mut arr1, mut arr2) = read_file_and_store_as_arrays(file_path).unwrap();

    arr1.sort();
    arr2.sort();

    let bothMaps = arr1.iter().zip(arr2.iter());
    let mut sum = 0;
    for (left, right) in bothMaps {
        sum += (right - left).abs();
    }

    println!("{}", sum)
}

fn part2() {
    let file_path = "puzzle1.input";
    let (mut arr1, mut arr2) = read_file_and_store_as_arrays(file_path).unwrap();

    arr1.sort();
    arr2.sort();

    let mut lastNumber = 0;
    let mut lastNumberCount = 0;
    let mut rIdx = 0;
    let mut sum = 0;

    for lValue in arr1 {
        if lastNumber == lValue {
            sum += lastNumber * lastNumberCount;
            continue;
        }

        lastNumber = lValue;
        lastNumberCount = 0;

        while arr2[rIdx] <= lastNumber && rIdx < arr2.len() {
            if lastNumber == arr2[rIdx] {
                lastNumberCount += 1;
            }
            rIdx += 1;
        }

        sum += lastNumber * lastNumberCount;
    }

    println!("{}", sum)
}

fn main() {
    part2();
}