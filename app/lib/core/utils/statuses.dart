/// Lifecycle of data a screen fetches.
enum LoadStatus { initial, loading, ready, failure }

/// Lifecycle of a user-triggered save.
enum SubmitStatus { idle, submitting, success, failure }
