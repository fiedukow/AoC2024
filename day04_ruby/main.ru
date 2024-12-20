class DirectionalIterator
    include Enumerable

    def initialize(puzzleInput, x, y, xdir, ydir)
        @puzzleInput = puzzleInput
        @x = x
        @y = y
        @xdir = xdir
        @ydir = ydir
    end
  
    def each
        i = @x;
        j = @y;
        while i >= 0 && i < @puzzleInput.size && j >= 0 && j < @puzzleInput[0].size do
            yield @puzzleInput[i][j]
            i += @xdir;
            j += @ydir;
        end
    end
  end

def check(iterator)
  iterator.take(4).join == "XMAS"
end

def directions
    pr = [-1, 0, 1].product([-1, 0, 1])
    pr.each do |tuple|
      next if tuple == [0, 0]
      yield tuple
    end
  end

def safeIdx(puzzleInput, x, y)
    if x < 0 || x >= puzzleInput.size || y < 0 || y >= puzzleInput[0].size then
        return ''
    end
    return puzzleInput[x][y]
end

# \ - bDiag
# / - fDiag
def fDiag(puzzleInput, x, y)
    [safeIdx(puzzleInput, x - 1, y - 1), safeIdx(puzzleInput, x, y), safeIdx(puzzleInput, x + 1, y + 1)].join
end

def bDiag(puzzleInput, x, y)
    [safeIdx(puzzleInput, x - 1, y + 1), safeIdx(puzzleInput, x, y), safeIdx(puzzleInput, x + 1, y - 1)].join
end

def isDiagOk(diagContent)
    diagContent == "MAS" || diagContent == "SAM"
end

file_path = 'input.txt'
puzzleInput = File.readlines(file_path).map { |line| line.chomp.chars }

count = 0;

# (0...puzzleInput.size).each { |i|
#     (0...puzzleInput[0].size).each { |j|
#         directions do |dir|
#             if check(DirectionalIterator.new(puzzleInput, i, j, dir[0], dir[1])) then count += 1 end
#         end
#     }
# }


(0...puzzleInput.size).each { |i|
    (0...puzzleInput[0].size).each { |j|
        if isDiagOk(fDiag(puzzleInput, i, j)) && isDiagOk(bDiag(puzzleInput, i, j)) then count += 1 end
    }
}


puts count

# puzzleInput.each { |row| p row }
