protocol Store {
  associatedtype Action
  func send(_ action: Action)
}
