///|
/// Library compatibility metadata exposed to deployment diagnostics.
pub fn library_name() -> String {
  "moonbit_cron"
}

///|
pub fn library_version() -> String {
  "0.1.1"
}

///|
pub fn supported_targets() -> Array[String] {
  ["wasm", "wasm-gc", "js", "native"]
}

///|
pub fn compatibility_summary() -> String {
  "\{library_name()} v\{library_version()} targets=\{supported_targets().join(",")}"
}
