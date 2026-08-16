///|
/// Deterministic clock samples used by scheduler integrations and tests.
pub struct ClockSample {
  at : Time
  label : String
} derive(Debug, Eq)

///|
pub fn ClockSample::new(at : Time, label : String) -> ClockSample {
  { at, label }
}

///|
pub struct ClockSequence {
  samples : Array[ClockSample]
  mut cursor : Int
} derive(Debug)

///|
pub fn ClockSequence::new(samples : Array[ClockSample]) -> ClockSequence {
  { samples, cursor: 0 }
}

///|
pub fn ClockSequence::current(self : ClockSequence) -> ClockSample? {
  if self.cursor < self.samples.length() {
    Some(self.samples[self.cursor])
  } else {
    None
  }
}

///|
pub fn ClockSequence::advance(self : ClockSequence) -> ClockSample? {
  let value = self.current()
  if value is Some(_) {
    self.cursor += 1
  }
  value
}

///|
pub fn ClockSequence::remaining(self : ClockSequence) -> Int {
  self.samples.length() - self.cursor
}

///|
pub fn ClockSequence::reset(self : ClockSequence) -> Unit {
  self.cursor = 0
}
