const fs = require('fs');

function prune(input) {
  return input % 16777216n;
}

function singleStep(input) {
  out = prune((input * 64n) ^ input);
  out = prune((out / 32n) ^ out);
  out = prune((out * 2048n) ^ out);
  return out;
}

function* rngIterator(input) {
  yield input;
  currentVal = input;
  while (true) {
    currentVal = singleStep(currentVal);
    yield currentVal;
  }
}

function afterNIt(input, n) {
  it = rngIterator(input);
  for (i = 0; i < n; ++i) {
    it.next();
  }
  return it.next().value;
}

function arrayEqual(arr1, arr2) {
  for (i = 0; i < arr1.length; ++i) {
    if (arr1[i] !== arr2[i]) {
      return false;
    }
  }
  return true;
}

function priceAchievedWith(priceSeries, diffSequence) {
  for (let i = 0; i <= priceSeries.length - 4; i++) {
    const currentSeq = priceSeries.slice(i, i + 4).map(priceAndDiff => priceAndDiff[1]);
    if (arrayEqual(currentSeq, diffSequence)) {
      return priceSeries[i + 3][0];
    }
  }
  return 0;
}

function priceTotalWithSeq(pricesWithDiffs, diffSequence) {
  return pricesWithDiffs
    .map(priceSeries => priceAchievedWith(priceSeries, diffSequence))
    .reduce((acc, v) => acc + v, 0);
}

function validSequences() {
  let sequences = [];
  for (let a = -9; a <= 9; a++)
    for (let b = -9; b <= 9; b++)
      for (let c = -9; c <= 9; c++)
        for (let d = -9; d <= 9; d++)
          sequences.push([a, b, c, d]);
  return sequences
}

function existingSequences(pricesWithDiffs) {
  let sequences = pricesWithDiffs.map(
    priceSeries =>
      priceSeries
        .slice(0, -3)
        .map(
          (_, idx) =>
            priceSeries.slice(idx, idx + 4)
              .map(priceAndDiff => priceAndDiff[1])
        )
    ).flat();

  const uniqueArrays = Array.from(
    new Set(sequences.map(JSON.stringify)), 
    JSON.parse
  );    
  return uniqueArrays;
}

function existingSequencesWithValues(pricesWithDiffs) {
  let sequences = pricesWithDiffs.map(
    priceSeries =>
      new Map(
        priceSeries
          .slice(0, -3)
          .map( (_, idx) =>
            [
              JSON.stringify(
                priceSeries.slice(idx, idx + 4)
                  .map(priceAndDiff => priceAndDiff[1])
              ),
              priceSeries[idx + 3][0]
            ]
          ).reverse()
      )
    );
    return sequences;
}

const take = (gen, n) => Array.from({ length: n }, () => gen.next().value);

const numbers = fs.readFileSync('input.txt', 'utf-8')
  .split('\n')
  .map(line => parseInt(line.trim(), 10))
  .filter(number => !isNaN(number))
  .map(n => BigInt(n));

let total = numbers
  .map(n => afterNIt(n, 2000))
  .reduce((acc, v) => acc + v, 0n);
console.log(total);

let prices = numbers
  .map(n =>
    take(rngIterator(n), 2000)
      .map(wholePrice => Number(wholePrice % 10n))
  )

let pricesWithDiffs = prices.map( priceSeries =>
  priceSeries
    .slice(1)
    .map((value, index) => [value, value - priceSeries[index]])
);

const EXISTING_SEQUENECES = existingSequences(pricesWithDiffs);
const seqToPriceMap = existingSequencesWithValues(pricesWithDiffs);

const best = EXISTING_SEQUENECES
  .map(seq => {
      if (seq.length != 4) console.log("ERROR");
      let seqS = JSON.stringify(seq);
      return seqToPriceMap
        .map(priceSeq => priceSeq.has(seqS) ? priceSeq.get(seqS) : 0)
        .reduce((acc, v) => acc + v, 0)
    }
  ).reduce((a, b) => (a > b ? a : b));

console.log(best);
