package main

import (
	"io/ioutil"
	"log"
)

import (
	"fmt"
	"strings"
)


type FileDescriptor struct {
	Id int
	Pos int
	Size int
}

type FreeSpaceDescriptor struct {
	Pos int
	Size int
}

type DiskIndex struct {
	TotalSize int
	Files []FileDescriptor
	FreeSpaces []FreeSpaceDescriptor
}

func charToInt(c rune) int {
	return int(c) - 48
}

func (d *DiskIndex) CleanupFreeSpaces() {
	cleaned := d.FreeSpaces[:0]
	for _, space := range d.FreeSpaces {
		if space.Size > 0 {
			cleaned = append(cleaned, space)
		}
	}
	d.FreeSpaces = cleaned
}

func CreateIndex(compressedContent string) DiskIndex {
	files := []FileDescriptor{}
	spaces := []FreeSpaceDescriptor{}

	isFile := true
	fileId := 0
	pos := 0

	for _, char := range compressedContent {
		size := charToInt(char)
		if isFile {
			files = append(files, FileDescriptor{Id: fileId, Pos: pos, Size: size})
			isFile = false
			fileId += 1
		} else {
			spaces = append(spaces, FreeSpaceDescriptor{Pos: pos, Size: size})
			isFile = true
		}

		pos += size
	}

	return DiskIndex{TotalSize: pos, Files: files, FreeSpaces: spaces}
}

// func (disk *DiskIndex) SortByPos() {
// 	sort.Slice(disk.Files, func(i, j int) bool {
// 		return disk.Files[i].Pos < disk.Files[j].Pos
// 	})
// 	sort.Slice(disk.FreeSpaces, func(i, j int) bool {
// 		return disk.FreeSpaces[i].Pos < disk.FreeSpaces[j].Pos
// 	})
// }

func repeat(v int, n int) []int {
	array := make([]int, n)
	for i := range array {
		array[i] = v
	}
	return array
}

func (disk DiskIndex) Dump() []int {
	dump := repeat(-1, disk.TotalSize)

	for _, file := range disk.Files {
		for i := file.Pos; i < (file.Pos + file.Size); i++ {
			dump[i] = file.Id
		}
	}

	return dump
}

func (disk *DiskIndex) Defragment() {
	fileIdx := len(disk.Files) - 1
	for fileIdx >= 0 {
		oFile := disk.Files[fileIdx]
		nPos := oFile.Pos
		for spaceIdx, space := range disk.FreeSpaces {
			if space.Pos > oFile.Pos { break; }
			if space.Size >= oFile.Size { // || space.Pos + oFile.Size > oFile.Pos  - this could be done if AoC wasn't stupid
				nPos = space.Pos
				space.Size = space.Size - oFile.Size
				space.Pos += oFile.Size
				disk.FreeSpaces[spaceIdx] = space
				break
			}
		}
		nFile := FileDescriptor{Id: oFile.Id, Pos: nPos, Size: oFile.Size}
		disk.Files[fileIdx] = nFile
		fileIdx -= 1;
	}

	disk.CleanupFreeSpaces()
}

func (disk DiskIndex) Checksum() int {
	sum := 0
	for _, file := range disk.Files {
		posSum := (file.Pos + file.Pos + file.Size - 1) * file.Size / 2
		sum += posSum * file.Id
	}
	return sum
}

func main() {
	data, err := ioutil.ReadFile("input.txt")
	if err != nil {
		log.Fatal(err)
	}
	content := strings.TrimSpace(string(data))
	index := CreateIndex(content)

	index.Defragment()
	fmt.Println(index.Dump())
	fmt.Println(index.Checksum())
}