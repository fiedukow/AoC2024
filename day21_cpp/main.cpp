#include <iostream>
#include <fstream>
#include <string>
#include <vector>
#include <unordered_map>
#include <unordered_set>
#include <tuple>
#include <map>

std::vector<std::vector<char>> ARROWS_KEYS = {
  { ' ', '^', 'A' },
  { '<', 'v', '>' }
};

std::vector<std::vector<char>> KEYPAD_KEYS = {
  { '7', '8', '9' },
  { '4', '5', '6' },
  { '1', '2', '3' },
  { ' ', '0', 'A' }
};

struct pairhash {
public:
  template <typename T, typename U>
  std::size_t operator()(const std::pair<T, U> &x) const
  {
    return std::hash<T>()(x.first) ^ std::hash<U>()(x.second);
  }
};


struct PathState {
  std::vector<char> pathSoFar;
  char character;
  long costSoFar;
  std::vector<PathState> controlPath;

  void printRecursivelongernal(long lvl, std::map<long, std::string>& collector) {
    for (auto& c : pathSoFar) {
      collector[lvl] += c;
    }
    for (auto& cp : controlPath) {
      cp.printRecursivelongernal(lvl + 1, collector); 
    }
  }

  static void printCollected(const std::map<long, std::string>& collector) {
    for (auto [lvl, data] : collector) {
      std::cout << lvl << ". " << data << std::endl;
    }
  }

  void printRecurisve() {
    std::map<long, std::string> collector;
    printRecursivelongernal(0, collector);
    printCollected(collector);
  }
};

struct Keyboard {
  std::vector<std::vector<char>> keyboardLayout;
  std::unordered_map<char, std::pair<long, long>> charToPos;
  std::unique_ptr<Keyboard> controlKeyboard;

  std::unordered_map<std::pair<char, char>, long, pairhash> cache;

  Keyboard(
    std::vector<std::vector<char>> keyboardLayout,
    std::unique_ptr<Keyboard> controlKeyboard
  )
    : keyboardLayout(std::move(keyboardLayout)),
      controlKeyboard(std::move(controlKeyboard))
  {
    for (long i = 0; i < this->keyboardLayout.size(); ++i) {
      for (long j = 0; j < this->keyboardLayout[0].size(); ++j) {
        charToPos[this->keyboardLayout[i][j]] = std::make_pair(i, j);
      }
    }
  }

  std::vector<char> allKeys() {
    std::vector<char> result;
    for (auto row : keyboardLayout) {
      for (auto ch : row) {
        if (ch != ' ') result.push_back(ch);
      }
    }
    return result;
  }

  std::vector<std::pair<char, char>> availableNeighbours(char start) {
    auto pos = charToPos.at(start);

    std::vector<std::pair<char, char>> confirmedNeighbours;
    std::vector<std::pair<char, std::pair<long, long>>> candidates = {
      { '^', { -1,  0 } },
      { 'v', {  1,  0 } },
      { '<', {  0, -1 } },
      { '>', {  0,  1 } },
    };
    for (auto candidate : candidates) {
      long ny = pos.first + candidate.second.first;
      long nx = pos.second + candidate.second.second;
      if (ny < 0 || ny >= keyboardLayout.size()) { continue; }
      if (nx < 0 || nx >= keyboardLayout[0].size()) { continue; }
      if (keyboardLayout[ny][nx] == ' ') { continue; }
      confirmedNeighbours.push_back(std::make_pair(candidate.first, keyboardLayout[ny][nx]));
    }
    return confirmedNeighbours;
  }

  long pathFrom(char start, char end) {
    if (controlKeyboard == nullptr) return 1;

    auto cacheIt = cache.find(std::make_pair(start, end));
    if (cacheIt != cache.end()) {
      return cacheIt->second;
    }

    const auto order = [](PathState lhs, PathState rhs) { return lhs.costSoFar > rhs.costSoFar; };
    std::priority_queue<PathState, std::vector<PathState>, decltype(order)> toVisit(order);
    toVisit.push({ .pathSoFar = {}, .character = start, 0, {} });

    long bestSoFar = LONG_MAX;

    while (!toVisit.empty()) {
      auto current = toVisit.top();
      toVisit.pop();

      if (current.costSoFar > bestSoFar) {
        break;
      }

      if (current.character == end) {
        const char from = current.pathSoFar.empty() ? 'A' : current.pathSoFar.back();
        auto newControlPath = current.controlPath;
        long cost = 1;
        if (controlKeyboard != nullptr) {
          cost = controlKeyboard->pathFrom(from, 'A');
        }
        if (current.costSoFar + cost < bestSoFar) {
          auto newPath = current.pathSoFar;
          newPath.push_back('A');
          bestSoFar = current.costSoFar + cost;
        }
      }

      const auto neighbours = availableNeighbours(current.character);
      for (auto neighbour : neighbours) {
        auto newPath = current.pathSoFar;
        newPath.push_back(neighbour.first);
        
        long cost = 0;
        auto newControlPath = current.controlPath;
        if (controlKeyboard != nullptr) {
          const char from = current.pathSoFar.empty() ? 'A' : current.pathSoFar.back();
          cost = controlKeyboard->pathFrom(from, neighbour.first);
        }
        toVisit.push({
          .pathSoFar = newPath,
          .character = neighbour.second,
          .costSoFar = current.costSoFar + cost,
          .controlPath = newControlPath
        });
      }
    }
    cache[std::make_pair(start, end)] = bestSoFar;
    return bestSoFar;
  }

  long crackCode(std::string code) {
    long codeValue = [code] () {
      std::string codeStr = code;
      codeStr.pop_back();
      return std::stoi(codeStr);
    }();

    auto current = 'A';
    long i = 0;
    long total = 0;
    std::map<long, std::string> collector;
    while (current != '\0') {
      if (code[i] != '\0') {
        auto path = pathFrom(current, code[i]);
        total += path;
        // path.printRecursivelongernal(0, collector);
      }
      current = code[i++];
    }

    PathState::printCollected(collector);

    std::cout << "Code total: " << total << ", value: " << codeValue << std::endl;

    return total * codeValue;
  }
};

struct RobotHand {
  Keyboard keyboard;
  char currentChar;
};


int main() {
    std::ifstream file("input.txt");
    std::vector<std::string> codes;
    std::string line;

    if (file.is_open()) {
        while (std::getline(file, line)) {
            codes.push_back(line);
        }
        file.close();
    } else {
        std::cerr << "Unable to open file" << std::endl;
    }

    std::unique_ptr<Keyboard> myKeyboard = std::make_unique<Keyboard>(ARROWS_KEYS, std::unique_ptr<Keyboard>());
    std::unique_ptr<Keyboard> theKeyboard = std::move(myKeyboard);
    for (long i = 0; i < 25; ++i) {
      theKeyboard = std::make_unique<Keyboard>(ARROWS_KEYS, std::move(theKeyboard));
    }
    std::unique_ptr<Keyboard> keypad = std::make_unique<Keyboard>(KEYPAD_KEYS, std::move(theKeyboard));

    long grandTotal = 0;
    for (auto code : codes) {
      grandTotal += keypad->crackCode(code);
    }

    std::cout << "Total: " << grandTotal << std::endl;

    // std::cout << keypad->pathFrom('A', '0') + keypad->pathFrom('0', '2') + keypad->pathFrom('2', '9') + keypad->pathFrom('9', 'A') << std::endl;

    return 0;
}

