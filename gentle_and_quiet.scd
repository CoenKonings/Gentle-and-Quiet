(
{
  var noteA, noteB, modIndex, filter, noteDur, timeToNextNote;
  s.bootSync;

  ~numNotes = inf; // Set the number of notes you want to record.
  ~outBus = Bus.audio(s, 2);
  s.sync;

  SynthDef(
    \simplefm,
    {
      arg freq, harmRatio=1, modIndex=0.5, dur=1, filter = 0, gain = 0.1;
      var car, mod, sig, lowPassed, hiPassed, cutoffLow, cutoffHi;

      mod = SinOsc.ar(freq * harmRatio, mul: freq * modIndex);
      car = SinOsc.ar(freq + mod);

      // Filter out highs
      sig = BLowPass4.ar(car, 6000, 1);
      sig = BLowPass4.ar(sig, 6000, 1);
      sig = BLowPass4.ar(sig, 6000, 1);
      sig = BLowPass4.ar(sig, 6000, 1);

      cutoffLow = filter.lincurve(0, 19, 1, 5000, 1.5);
      cutoffHi = cutoffLow + 5000;

      sig = BLowPass.ar(sig, cutoffLow, 0.5);
      sig = BLowShelf.ar(sig, cutoffLow, db: 3.0);
      sig = BHiShelf.ar(sig, cutoffHi, db:3.0);

      sig = sig * EnvGen.kr(Env([0, 1, 1, 0], [0.25, dur, 3]), 1, doneAction: 2);

      Out.ar(~outBus, sig!2 * gain);
    }
  ).add;

  SynthDef(
    \masterOut,
    {
      var sig;

      sig = In.ar(~outBus, 2);
      sig = Limiter.ar(sig);
      sig = LeakDC.ar(sig);

      Out.ar(0, sig);
    }
  ).add;

  // Two Tristan chord inversions. The bottom notes descend a fifth.
  ~tristanChords = [
    [10, 15, 12, 18],
    [3, 6, 10, 12]
  ];

  ~octaves = [
    [0, -1, 0, 1],
    [2, -2, -1, -1],
    [-2, 1, -1, 1]
  ];

  ~noteDurs = [
    [5, 2.5, 5, 2.5],
    [7.5, 1.25, 0.625, 1.25],
    [1.25, 2.5, 8.5, 2.5],
  ];

  ~params = [
    [2, 3, 5, 3],
    [3, 5, 7, 5],
    [5, 7, 11, 7],
    [7, 11, 13, 11],
    [11, 17, 19, 17]
  ];

  ~baseNote = 65;

  s.sync;

  noteA = (
    \x: 0,
    \y: 0,
    \octX: 0,
    \octY: 0
  );

  noteB = (
    \x: 0,
    \y: 0,
    \octX: 0,
    \octY: 0
  );

  noteDur = (
    \x: 0,
    \y: 0
  );

  timeToNextNote = (
    \x: 3,
    \y: 2
  );

  modIndex = (
    \x: 2,
    \y: 1
  );

  filter = (
    \x: 1,
    \y: 0
  );

  Synth(\masterOut);
  s.sync;

  s.prepareForRecord;
  s.sync;
  s.record;

  ~numNotes.do({
    arg i; // Tracks number of played note combinations.

    "Playing notes".postln;

    // Play both notes.
    [noteA, noteB].do({
      arg note, i;

      Synth(
        \simplefm,
        [
          \freq, (~tristanChords[note.y][note.x] + ~baseNote + (~octaves[note.octY][note.octX] * 12)).midicps,
          \dur, ~noteDurs[noteDur.y][noteDur.x],
          \modIndex, ~params[modIndex.y][modIndex.x],
          \filter, ~params[filter.y][filter.x],
          \gain, ~params[filter.y][filter.x].linlin(2, 19, 0.1, 0.02);
        ]
      );
    });

    ("Notes played: " ++ (i + 1)).postln;

    ("waiting " ++ ~noteDurs[timeToNextNote.y][timeToNextNote.x] ++ " seconds").postln;
    ~noteDurs[timeToNextNote.y][timeToNextNote.x].wait;

    if ((i + 1) % 2 == 0) {
      "Rotating filter parameters".postln;
      filter.y = filter.y + 1;

      if (filter.y >= ~params.size) {
        filter.y = filter.y % ~params.size;
        filter.x = (filter.x + 3) % ~params[0].size;
      };
    };

    "Rotating FM parameters".postln;
    modIndex.x = modIndex.x + 1;

    if (modIndex.x >= ~params[0].size) {
      modIndex.x = modIndex.x % ~params[0].size;
      modIndex.y = (modIndex.y + 3) % ~params.size;
    };

    "Rotating note durations".postln;
    noteDur.x = noteDur.x + 1;
    timeToNextNote.x = timeToNextNote.x - 1;

    if (noteDur.x >= ~noteDurs[0].size) {
      noteDur.x = noteDur.x % ~noteDurs[0].size;
      noteDur.y = (noteDur.y + 1) % ~noteDurs.size;
    };

    if (timeToNextNote.x < 0) {
      timeToNextNote.x = timeToNextNote.x + ~noteDurs[0].size;
      timeToNextNote.y = (timeToNextNote.y - 1 + ~noteDurs.size) % ~noteDurs.size;
    };

    if ((i + 1) % 2 == 0) {
      "Rotating octaves".postln;
      noteA.octX = noteA.octX + 1;
      noteB.octX = (noteB.octX + 1) % ~octaves[0].size;
      noteB.octY = (noteB.octY + 1) % ~octaves.size;

      if (noteA.octX >= ~octaves[0].size) {
        noteA.octX = noteA.octX % ~octaves[0].size;
        noteA.octY = (noteA.octY + 1) % ~octaves.size;
      };
    };

    "Rotating midinote values".postln;
    noteA.y = (noteA.y + 1) % ~tristanChords.size;
    noteB.y = noteB.y + 1;

    if (noteB.y >= ~tristanChords.size) {
      noteB.y = noteB.y % ~tristanChords.size;
      noteB.x = (noteB.x - 1 + ~tristanChords[0].size) % ~tristanChords[0].size;
    };

    if (i % 5 == 4) {
      noteA.x = (noteA.x + 1) % ~tristanChords[0].size;
    };

    "=========================".postln;
  });

  10.wait;
  s.stopRecording;
  s.sync;
}.fork(AppClock);
)

(
s.meter;
s.plotTree;
FreqScope.new(800, 400, 0, server: s);
)
