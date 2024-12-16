
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <limits.h>
#include <math.h>

#define MAX_SIZE 2048

typedef enum {
  N = 0,
  E = 1,
  S = 2,
  W = 3
} Dir;

typedef struct Vec2 {
  int x;
  int y;
} Vec2;

typedef struct Loc {
  Vec2 pos;
  Dir dir;
} Loc;

typedef struct Gameplay {
  char** map;
  Vec2 size;
  Vec2 startPos;
  Vec2 endPos;
} Gameplay;


Vec2 subVec(Vec2 v1, Vec2 v2) {
  Vec2 result = { .x = v1.x - v2.x, .y = v1.y - v2.y };
  return result;
}


int hValue(Gameplay* game, Loc from) {
  int totalH = 0;
  Vec2 diff = subVec(game->endPos, from.pos);
  totalH += abs(diff.x) + abs(diff.y);

  int rotH = 0;
  if (diff.x > 0) {
    if (from.dir == N || from.dir == S) {
      rotH += 1000;
    }
    if (from.dir == W) {
      rotH += 2000;
    }
  }
  if (diff.x < 0) {
    if (from.dir == N || from.dir == S) {
      rotH += 1000;
    }
    if (from.dir == E) {
      rotH += 2000;
    }
  }
  if (diff.y > 0) {
    if (from.dir == E || from.dir == W) {
      rotH += 1000;
    }
    if (from.dir == N) {
      rotH += 2000;
    }
  }
  if (diff.y < 0) {
    if (from.dir == E || from.dir == W) {
      rotH += 1000;
    }
    if (from.dir == S) {
      rotH += 2000;
    }
  }
  totalH += rotH > 2000 ? 2000 : rotH;

  return totalH;
}

Gameplay* newGameplay(char map[MAX_SIZE][MAX_SIZE], int width, int height) {
  Gameplay* gameplay = malloc(sizeof(Gameplay));
  gameplay->size.x = width;
  gameplay->size.y = height;

  gameplay->map = malloc(sizeof(char*) * gameplay->size.y);
  for (int i = 0; i < gameplay->size.y; ++i) {
    gameplay->map[i] = malloc(sizeof(char) * gameplay->size.x);
    strcpy(gameplay->map[i], map[i]);
  }

  for (int i = 0; i < gameplay->size.y; ++i) {
    for (int j = 0; j < gameplay->size.x; ++j) {
      if (gameplay->map[i][j] == 'S') {
        gameplay->startPos.x = j;
        gameplay->startPos.y = i;
        gameplay->map[i][j] = '.';
      }
      if (gameplay->map[i][j] == 'E') {
        gameplay->endPos.x = j;
        gameplay->endPos.y = i;
        gameplay->map[i][j] = '.';
      }
    }
  }
  
  return gameplay;
}

int Vec2Equal(Vec2 lhs, Vec2 rhs) {
  return lhs.x == rhs.x && lhs.y == rhs.y;
}

typedef struct PointToCheck {
  Loc loc;
  int scoreSoFar;
} PointToCheck;

typedef struct ListOfPointToCheck {
  PointToCheck value;
  struct ListOfPointToCheck* next;
} ListOfPointToCheck;

int count(ListOfPointToCheck* head) {
  int i = 0;
  while (head != NULL) {
    head = head->next;
    i++;
  }
  return i;
}

ListOfPointToCheck* insert(Gameplay* game, ListOfPointToCheck* head, PointToCheck newValue) {
  ListOfPointToCheck* current = head;
  ListOfPointToCheck* previous = NULL;
  int newValueH = hValue(game, newValue.loc);
  int newValueTotal = newValueH + newValue.scoreSoFar;
  while (current != NULL && (current->value.scoreSoFar + hValue(game, current->value.loc)) < newValueTotal) {
    previous = current;
    current = current->next;
  }

  ListOfPointToCheck* newElement = malloc(sizeof(ListOfPointToCheck));
  newElement->value = newValue;
  newElement->next = current;

  if (previous == NULL) {
    return newElement;
  }

  previous->next = newElement;
  return head;
}

PointToCheck pop(ListOfPointToCheck** head) {
  ListOfPointToCheck* oldHead = *head;
  PointToCheck ptc = oldHead->value;
  *head = oldHead->next; 
  free(oldHead);
  return ptc;
}

Vec2 addVec(Vec2 v1, Vec2 v2) {
  Vec2 result = { .x = v1.x + v2.x, .y = v1.y + v2.y };
  return result;
}


Vec2 dirToVec(Dir dir) {
  switch (dir) {
    case N:
      return (Vec2) { .x = 0, .y = -1 };
    case E:
      return (Vec2) { .x = 1, .y = 0 };
    case S:
      return (Vec2) { .x = 0, .y = 1 };
    case W:
      return (Vec2) { .x = -1, .y = 0 };
  }
}

char at(Gameplay* game, Vec2 pos) {
  return game->map[pos.y][pos.x];
}

int canMove(Gameplay* game, Loc loc) {
  return at(game, addVec(loc.pos, dirToVec(loc.dir))) != '#';
}

Dir rotateDir(Dir dir, int mod) {
  dir += mod + 4;
  dir += 4;
  dir %= 4;
  return dir;
}

Loc rotate(Loc loc, int mod) {
  loc.dir = rotateDir(loc.dir, mod);
  return loc;
}

Loc move(Loc loc) {
  Loc result = loc;
  result.pos = addVec(loc.pos, dirToVec(loc.dir));
  return result;
}

typedef struct Visited {
  int* data;
  Vec2 size;
} Visited;

Visited* newVisitedForGameplay(Gameplay* game) {
  Visited* result = malloc(sizeof(Visited));
  int size = sizeof(int) * game->size.x * game->size.y;
  result->data = malloc(size);
  memset(result->data, 0, size);
  result->size = game->size;
  return result;
}

int wasVisited(Visited* visited, Loc loc) { 
  return *(visited->data + visited->size.x * loc.pos.y + loc.pos.x) & (1 << loc.dir);
}

void visit(Visited* visited, Loc loc) {
  *(visited->data + visited->size.x * loc.pos.y + loc.pos.x) |= (1 << loc.dir);
}

void freeVisited(Visited* visited) {
  free(visited->data);
  free(visited);
}

int solve(Gameplay* game) {
  Loc initialLoc = { .pos = game->startPos, .dir = E };
  PointToCheck initialPoint = { .loc = initialLoc, .scoreSoFar = 0 };
  ListOfPointToCheck* checklist = NULL;
  Visited* visited = newVisitedForGameplay(game);
  checklist = insert(game, checklist, initialPoint);

  while (checklist != NULL) {
    PointToCheck checking = pop(&checklist);
    int hHere = hValue(game, checking.loc);
    // printf("Checking: %d, %d in dir %d (score: %d, h: %d, total: %d)\n", checking.loc.pos.x, checking.loc.pos.y, checking.loc.dir, checking.scoreSoFar, hHere, checking.scoreSoFar + hHere);
    if (wasVisited(visited, checking.loc)) {
      continue;
    }
    visit(visited, checking.loc);
    if (Vec2Equal(checking.loc.pos, game->endPos)) {
      free(visited);
      return checking.scoreSoFar;
    }

    if (canMove(game, checking.loc)) {
      PointToCheck moveCheck = { .loc = move(checking.loc), .scoreSoFar = checking.scoreSoFar + 1 };
      checklist = insert(game, checklist, moveCheck);
    }
    checklist = insert(game, checklist, (PointToCheck) { .loc = rotate(checking.loc, 1), .scoreSoFar = checking.scoreSoFar + 1000 });
    checklist = insert(game, checklist, (PointToCheck) { .loc = rotate(checking.loc, -1), .scoreSoFar = checking.scoreSoFar + 1000 });
  }
  free(visited);
  return -1;
}

void freeGameplay(Gameplay* gameplay) {
  for (int i = 0; i < gameplay->size.y; ++i) {
    free(gameplay->map[i]);
  }
  free(gameplay->map);
  free(gameplay);
}

int main() {
  FILE *file = fopen("input.txt", "r");
  if (file == NULL) {
    printf("No input file\n");
  }

  char map[MAX_SIZE][MAX_SIZE];
  char buffer[MAX_SIZE];

  int width = 0;
  int height = 0;

  while (fgets(buffer, sizeof(buffer), file) != NULL) {
    if (width == 0) { width = strlen(buffer) - 1; }
    strcpy(map[height], buffer);
    ++height;
  }

  fclose(file);

  Gameplay* game = newGameplay(map, width, height);

  for (int i = 0; i < game->size.y; ++i) {
    for (int j = 0; j < game->size.x; ++j) {
      printf("%c", game->map[i][j]);
    }
    printf("\n");
  }

  printf("Score: %d\n", solve(game));
}
